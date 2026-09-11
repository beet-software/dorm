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

import 'package:dorm_framework/dorm_framework.dart';

/// A target that supports finite reads and streams.
///
/// The composed reference uses this capability for the primary and for
/// explicitly classified finite-read fallback. Stream methods are never
/// switched automatically after a primary error.
abstract interface class SyncReadTarget {
  /// Stable target identifier.
  String get id;

  /// Reads one entity by identity.
  Future<Model?> peek<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
    I id,
  );

  /// Reads matching models using a structured filter expression.
  Future<List<Model>> peekAll<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
    FilterExpression expression,
    QueryOptions options,
  );

  /// Reads one page using a composed-engine page request.
  Future<Page<Model>> peekPage<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
    FilterExpression expression,
    PageRequest request,
  );

  /// Reads all identities from an entity.
  Future<List<I>> peekAllKeys<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
  );

  /// Reads one stream from this target.
  Stream<Model?> pull<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
    I id,
  );

  /// Reads a stream of matching models from this target.
  Stream<List<Model>> pullAll<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
    FilterExpression expression,
    QueryOptions options,
  );
}

/// A target that can apply an already materialized change set.
///
/// Applying a change set must be idempotent. The target receives final model
/// data and identities, not the original application callback or filter.
abstract interface class SyncApplyTarget {
  /// Stable target identifier.
  String get id;

  /// Applies a previously materialized change set.
  Future<void> apply<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
    MutationChangeSet changeSet,
  );
}

/// A target that supports reads and materialized change-set delivery.
abstract interface class SyncReadApplyTarget
    implements SyncReadTarget, SyncApplyTarget {}

/// A target that can execute primary mutations as well as reads and delivery.
///
/// Only the primary needs this capability. Its mutation result must include
/// an exact change set suitable for replay on a different backend.
abstract interface class SyncMutationTarget implements SyncReadApplyTarget {
  /// Executes a change-tracked mutation.
  Future<MutationResult<Object?>> mutate<
    Data,
    Model extends Data,
    I extends Object,
    C extends Creation<Data, I>
  >(Entity<Data, Model, I, C> entity, MutationRequest request);
}

/// A complete synchronization target.
abstract interface class SyncTarget implements SyncMutationTarget {}

mixin _SyncReadAdapter<Q extends BaseQuery<Q>, P extends PageRequest>
    implements SyncReadTarget {
  BaseReference<Q, P> get syncReference;

  FilterCompiler<Q> get syncCompileFilter;

  P Function(PageRequest request) get syncMapPage;

  @override
  Future<Model?> peek<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
    I id,
  ) => syncReference.peek(entity, id);

  @override
  Future<List<Model>> peekAll<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
    FilterExpression expression,
    QueryOptions options,
  ) => syncReference.peekAll(entity, syncCompileFilter(expression), options);

  @override
  Future<Page<Model>> peekPage<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
    FilterExpression expression,
    PageRequest request,
  ) => syncReference.peekPage(
    entity,
    syncCompileFilter(expression),
    syncMapPage(request),
  );

  @override
  Future<List<I>> peekAllKeys<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
  ) => syncReference.peekAllKeys(entity);

  @override
  Stream<Model?> pull<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
    I id,
  ) => syncReference.pull(entity, id);

  @override
  Stream<List<Model>> pullAll<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
    FilterExpression expression,
    QueryOptions options,
  ) => syncReference.pullAll(entity, syncCompileFilter(expression), options);
}

/// Applies a change set through a normal reference.
///
/// This helper validates the entity table and primary-key shape before it
/// performs the materialized operation.
Future<void> applyChangeSet<Data, Model extends Data, I extends Object>(
  BaseReference<dynamic, dynamic> reference,
  Entity<Data, Model, I, Creation<Data, I>> entity,
  MutationChangeSet changeSet,
) async {
  if (changeSet.tableName != entity.schema.tableName) {
    throw StateError(
      'Change set table ${changeSet.tableName} does not match '
      'entity table ${entity.schema.tableName}.',
    );
  }
  final int keyCount = entity.schema.primaryKeys.length;
  if (changeSet.records.any((record) => record.key.length != keyCount)) {
    throw StateError(
      'Change set identity shape does not match ${entity.schema.tableName}.',
    );
  }
  final List<I> ids = [
    for (final MutationRecord record in changeSet.records)
      entity.primaryKeyCodec.decode(record.key),
  ];
  switch (changeSet.kind) {
    case MutationKind.put:
    case MutationKind.push:
    case MutationKind.patch:
      final List<Model> models = [
        for (final MutationRecord record in changeSet.records)
          if (record.data case final Map<String, Object?> data)
            entity.fromJson(entity.primaryKeyCodec.decode(record.key), data),
      ];
      if (models.isNotEmpty) {
        await reference.push(entity, models.single);
      } else {
        await reference.popKeys(entity, ids);
      }
    case MutationKind.putAll:
    case MutationKind.pushAll:
      final List<Model> models = [
        for (final MutationRecord record in changeSet.records)
          if (record.data case final Map<String, Object?> data)
            entity.fromJson(entity.primaryKeyCodec.decode(record.key), data),
      ];
      if (models.isNotEmpty) await reference.pushAll(entity, models);
    case MutationKind.pop:
    case MutationKind.popKeys:
    case MutationKind.popAll:
      await reference.popKeys(entity, ids);
    case MutationKind.purge:
      await reference.purge(entity);
  }
}

ChangeTrackedReference<Q, P> _mappedChangeTrackedReference<
  Q extends BaseQuery<Q>,
  P extends PageRequest
>(ChangeTrackedEngine<Q, P> engine) {
  final ChangeTrackedReference<Q, P> reference = engine
      .createChangeTrackedReference();
  if (engine case final ErrorAwareEngine aware) {
    return ErrorMappedChangeTrackedReference(reference, aware.errorMapper);
  }
  return reference;
}

BaseReference<Q, P> _mappedReference<
  Q extends BaseQuery<Q>,
  P extends PageRequest
>(BaseEngine<Q, P> engine) {
  final BaseReference<Q, P> reference = engine.createReference();
  if (engine case final ErrorAwareEngine aware) {
    return ErrorMappedReference(reference, aware.errorMapper);
  }
  return reference;
}

/// Adapts a [ChangeTrackedEngine] to a complete synchronization target.
class EngineSyncTarget<Q extends BaseQuery<Q>, P extends PageRequest>
    with _SyncReadAdapter<Q, P>
    implements SyncTarget {
  /// Creates a complete target from a change-tracked engine.
  EngineSyncTarget(
    this.engine, {
    required this.id,
    FilterCompiler<Q>? compileFilter,
    P Function(PageRequest request)? mapPage,
  }) : _compileFilter = compileFilter ?? BaseFilter.fromExpression,
       _mapPage = mapPage ?? ((request) => request as P),
       _reference = _mappedChangeTrackedReference(engine);

  /// Underlying engine.
  final ChangeTrackedEngine<Q, P> engine;

  @override
  final String id;

  final FilterCompiler<Q> _compileFilter;
  final P Function(PageRequest request) _mapPage;
  final ChangeTrackedReference<Q, P> _reference;

  @override
  BaseReference<Q, P> get syncReference => _reference;

  @override
  FilterCompiler<Q> get syncCompileFilter => _compileFilter;

  @override
  P Function(PageRequest request) get syncMapPage => _mapPage;

  @override
  Future<MutationResult<Object?>> mutate<
    Data,
    Model extends Data,
    I extends Object,
    C extends Creation<Data, I>
  >(Entity<Data, Model, I, C> entity, MutationRequest request) =>
      _reference.mutate(entity, request);

  @override
  Future<void> apply<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
    MutationChangeSet changeSet,
  ) => applyChangeSet(_reference, entity, changeSet);
}

/// Adapts a regular [BaseEngine] for reads and materialized replica writes.
///
/// The wrapped engine can be unaware of synchronization. It only needs to
/// accept the final models and identity values supplied by the primary.
///
/// The wrapped engine does not need to implement [ChangeTrackedEngine], because
/// only the primary needs to report mutations.
class EngineReplicaTarget<Q extends BaseQuery<Q>, P extends PageRequest>
    with _SyncReadAdapter<Q, P>
    implements SyncReadApplyTarget {
  /// Creates a read/apply target from a regular engine.
  EngineReplicaTarget(
    this.engine, {
    required this.id,
    FilterCompiler<Q>? compileFilter,
    P Function(PageRequest request)? mapPage,
  }) : _compileFilter = compileFilter ?? BaseFilter.fromExpression,
       _mapPage = mapPage ?? ((request) => request as P),
       _reference = _mappedReference(engine);

  /// Underlying engine.
  final BaseEngine<Q, P> engine;

  @override
  final String id;

  final FilterCompiler<Q> _compileFilter;
  final P Function(PageRequest request) _mapPage;
  final BaseReference<Q, P> _reference;

  @override
  BaseReference<Q, P> get syncReference => _reference;

  @override
  FilterCompiler<Q> get syncCompileFilter => _compileFilter;

  @override
  P Function(PageRequest request) get syncMapPage => _mapPage;

  @override
  Future<void> apply<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
    MutationChangeSet changeSet,
  ) => applyChangeSet(_reference, entity, changeSet);
}
