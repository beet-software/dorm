// dORM
// Copyright (C) 2023  Beet Software
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

import 'creation.dart';
import 'engine.dart';
import 'entity.dart';
import 'filter.dart';
import 'query.dart';
import 'read_options.dart';
import 'reference.dart';

/// Describes the mutation represented by a synchronization change set.
///
/// Change sets are materialized after the primary operation. A replica applies
/// the recorded result and must not re-execute an application callback or
/// recompute a filter against its own state.
enum MutationKind {
  put,
  putAll,
  push,
  pushAll,
  pop,
  popKeys,
  popAll,
  patch,
  purge,
}

/// A persisted record affected by a mutation.
///
/// The key is encoded in the entity primary-key order. A null data value
/// represents deletion; a non-null value is the final serialized model.
class MutationRecord {
  /// Creates a mutation record from an encoded primary key and optional data.
  const MutationRecord({required this.key, this.data});

  /// Primary-key values in schema order.
  final List<Object?> key;

  /// Serialized model data. A null value represents a deletion.
  final Map<String, Object?>? data;

  /// Converts this record to JSON-compatible data for a durable outbox.
  Map<String, Object?> toJson() => {'key': key, 'data': data};

  /// Rebuilds a record from JSON-compatible data.
  factory MutationRecord.fromJson(Map<String, Object?> json) => MutationRecord(
    key: List<Object?>.from(json['key']! as List<Object?>),
    data: json['data'] == null
        ? null
        : Map<String, Object?>.from(json['data']! as Map),
  );
}

/// Describes the exact records affected by one primary mutation.
///
/// The operation id is the idempotency key. Sequence is the source order used
/// by synchronization coordinators to preserve delivery order per replica.
class MutationChangeSet {
  /// Creates a change set.
  const MutationChangeSet({
    required this.operationId,
    required this.sequence,
    required this.tableName,
    required this.kind,
    required this.records,
  });

  /// Stable identifier used when retrying delivery.
  final String operationId;

  /// Monotonic order assigned by the source engine.
  final int sequence;

  /// Entity table or collection name.
  final String tableName;

  /// Mutation kind.
  final MutationKind kind;

  /// Exact records affected by the mutation.
  final List<MutationRecord> records;

  /// Converts this change set to JSON-compatible data for a durable outbox.
  Map<String, Object?> toJson() => {
    'operationId': operationId,
    'sequence': sequence,
    'tableName': tableName,
    'kind': kind.name,
    'records': [for (final MutationRecord record in records) record.toJson()],
  };

  /// Rebuilds a change set from JSON-compatible data.
  factory MutationChangeSet.fromJson(Map<String, Object?> json) =>
      MutationChangeSet(
        operationId: json['operationId']! as String,
        sequence: json['sequence']! as int,
        tableName: json['tableName']! as String,
        kind: MutationKind.values.byName(json['kind']! as String),
        records: [
          for (final Object? record in json['records']! as List<Object?>)
            MutationRecord.fromJson(record! as Map<String, Object?>),
        ],
      );

  /// Returns a copy with selected synchronization metadata replaced.
  MutationChangeSet copyWith({String? operationId, int? sequence}) {
    return MutationChangeSet(
      operationId: operationId ?? this.operationId,
      sequence: sequence ?? this.sequence,
      tableName: tableName,
      kind: kind,
      records: records,
    );
  }
}

/// The result of a mutation together with its exact change set.
class MutationResult<T> {
  /// Creates a mutation result.
  const MutationResult({required this.value, required this.changeSet});

  /// The normal result returned by the underlying repository operation.
  final T value;

  /// The exact persisted change.
  final MutationChangeSet changeSet;
}

/// A mutation request understood by a change-tracking reference.
sealed class MutationRequest {
  const MutationRequest({this.operationId, this.sequence});

  /// Optional operation identifier supplied by a coordinator.
  ///
  /// A backend should preserve this value in the resulting change set when
  /// it can. Otherwise it generates a stable operation id for that mutation.
  final String? operationId;

  /// Optional source sequence supplied by a coordinator.
  ///
  /// Sequences are compared only within the synchronization source. They are
  /// not timestamps and do not establish a global order across engines.
  final int? sequence;
}

/// Creates one model.
final class PutMutation<Data, I extends Object> extends MutationRequest {
  /// Creates a put request.
  const PutMutation(this.creation, {super.operationId, super.sequence});

  /// Creation request.
  final Creation<Data, I> creation;
}

/// Creates multiple models.
final class PutAllMutation<Data, I extends Object> extends MutationRequest {
  /// Creates a put-all request.
  const PutAllMutation(this.creations, {super.operationId, super.sequence});

  /// Creation requests.
  final List<Creation<Data, I>> creations;
}

/// Replaces one model.
final class PushMutation<Model> extends MutationRequest {
  /// Creates a push request.
  const PushMutation(this.model, {super.operationId, super.sequence});

  /// Model to persist.
  final Model model;
}

/// Replaces multiple models.
final class PushAllMutation<Model> extends MutationRequest {
  /// Creates a push-all request.
  const PushAllMutation(this.models, {super.operationId, super.sequence});

  /// Models to persist.
  final List<Model> models;
}

/// Deletes one model.
final class PopMutation<I extends Object> extends MutationRequest {
  /// Creates a pop request.
  const PopMutation(this.id, {super.operationId, super.sequence});

  /// Identity to delete.
  final I id;
}

/// Deletes multiple models by identity.
final class PopKeysMutation<I extends Object> extends MutationRequest {
  /// Creates a pop-keys request.
  const PopKeysMutation(this.ids, {super.operationId, super.sequence});

  /// Identities to delete.
  final Iterable<I> ids;
}

/// Deletes models matching a filter.
final class PopAllMutation<Q extends BaseQuery<Q>> extends MutationRequest {
  /// Creates a pop-all request.
  const PopAllMutation(this.filter, {super.operationId, super.sequence});

  /// Filter selecting the models to delete.
  final BaseFilter<Q> filter;
}

/// Applies an update callback to one model.
final class PatchMutation<Model, I extends Object> extends MutationRequest {
  /// Creates a patch request.
  const PatchMutation(
    this.id,
    this.update, {
    super.operationId,
    super.sequence,
  });

  /// Identity to update.
  final I id;

  /// Update callback.
  final Model? Function(Model?) update;
}

/// Removes every model from an entity.
final class PurgeMutation extends MutationRequest {
  /// Creates a purge request.
  const PurgeMutation({super.operationId, super.sequence});
}

/// A reference that can report exact persisted mutations.
abstract interface class ChangeTrackedReference<
  Q extends BaseQuery<Q>,
  P extends PageRequest
>
    implements BaseReference<Q, P> {
  /// Executes [request] and reports the exact change it produced.
  Future<MutationResult<Object?>> mutate<
    Data,
    Model extends Data,
    I extends Object,
    C extends Creation<Data, I>
  >(Entity<Data, Model, I, C> entity, MutationRequest request);
}

/// Optional engine capability required by synchronization targets.
abstract interface class ChangeTrackedEngine<
  Q extends BaseQuery<Q>,
  P extends PageRequest
>
    implements BaseEngine<Q, P> {
  /// Creates a reference that can report exact persisted mutations.
  ///
  /// The reference must report the final identity generated by the primary,
  /// the final serialized model, and the exact identities selected by a
  /// destructive filter operation.
  ChangeTrackedReference<Q, P> createChangeTrackedReference();
}

/// Converts a structured filter expression to a backend query filter.
///
/// Implementations should reject unsupported operators instead of silently
/// changing the meaning of the expression.
typedef FilterCompiler<Q extends BaseQuery<Q>> =
    BaseFilter<Q> Function(FilterExpression expression);

/// Converts a page request from a composed engine to a target engine.
typedef PageRequestMapper<From extends PageRequest, To extends PageRequest> =
    To Function(From request);
