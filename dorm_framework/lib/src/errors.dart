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
import 'entity.dart';
import 'filter.dart';
import 'query.dart';
import 'read_options.dart';
import 'reference.dart';
import 'synchronization.dart';
import 'relationship.dart';

/// Classifies errors produced by dORM database engines.
enum DormErrorKind {
  /// The database or service could not currently be reached.
  unavailable,

  /// The operation exceeded a configured time limit.
  timeout,

  /// The credentials were missing or rejected.
  authentication,

  /// The credentials were valid but lacked permission.
  authorization,

  /// The requested resource was not found and the operation treats that as an error.
  notFound,

  /// The operation conflicts with the current state of the resource.
  conflict,

  /// The database rejected a constraint, such as a foreign or unique key.
  constraint,

  /// The query could not be parsed or executed because it is invalid.
  invalidQuery,

  /// Data returned by the provider could not be decoded or validated.
  invalidData,

  /// A transaction was aborted or could not be completed.
  transaction,

  /// The operation was explicitly cancelled.
  cancelled,

  /// The selected engine or provider does not support the operation.
  unsupported,

  /// The engine could not classify the provider failure.
  unknown,
}

/// Describes whether retrying a failed operation is safe.
enum DormRetryability {
  /// Retrying can repeat or worsen the operation.
  never,

  /// The provider indicates that retrying is safe.
  safe,

  /// The dORM cannot determine whether retrying is safe.
  unknown,
}

/// A portable database error exposed by a dORM engine.
final class DormDatabaseException implements Exception {
  /// Creates a portable database exception.
  const DormDatabaseException({
    required this.kind,
    required this.retryability,
    required this.message,
    this.engine,
    this.operation,
    this.providerCode,
    this.cause,
    this.stackTrace,
  });

  /// The portable category of the failure.
  final DormErrorKind kind;

  /// Whether retrying this failure is safe.
  final DormRetryability retryability;

  /// A human-readable description of the failure.
  final String message;

  /// The dORM engine that produced the failure.
  final String? engine;

  /// The operation being performed when the failure occurred.
  final String? operation;

  /// The native provider code, when one was available.
  final Object? providerCode;

  /// The original provider error.
  final Object? cause;

  /// The stack trace captured with [cause].
  final StackTrace? stackTrace;

  /// Whether retrying this failure is explicitly safe.
  bool get isRetryable => retryability == DormRetryability.safe;

  /// Whether this error describes a temporary primary-read failure.
  bool get isAvailabilityFailure =>
      kind == DormErrorKind.unavailable || kind == DormErrorKind.timeout;

  @override
  String toString() {
    final StringBuffer result = StringBuffer('DormDatabaseException(')
      ..write(kind.name)
      ..write(': ')
      ..write(message);
    if (engine != null) result.write(', engine: $engine');
    if (operation != null) result.write(', operation: $operation');
    if (providerCode != null) result.write(', code: $providerCode');
    if (cause != null) result.write(', cause: $cause');
    result.write(')');
    return result.toString();
  }
}

/// Converts provider-specific errors into [DormDatabaseException] values.
abstract interface class DormErrorMapper {
  /// Maps [error] while preserving its original [stackTrace].
  DormDatabaseException map(
    Object error,
    StackTrace stackTrace, {
    String? operation,
  });
}

/// An optional engine capability that exposes a provider error mapper.
abstract interface class ErrorAwareEngine {
  /// The mapper used by this engine at provider boundaries.
  DormErrorMapper get errorMapper;
}

String _mutationOperation(MutationRequest request) => switch (request) {
  PutMutation() => 'put',
  PutAllMutation() => 'putAll',
  PushMutation() => 'push',
  PushAllMutation() => 'pushAll',
  PopMutation() => 'pop',
  PopKeysMutation() => 'popKeys',
  PopAllMutation() => 'popAll',
  PatchMutation() => 'patch',
  PurgeMutation() => 'purge',
};
bool _isFrameworkError(Object error) {
  return error is ArgumentError ||
      error is StateError ||
      error is UnsupportedError ||
      error is FormatException;
}

/// Maps a provider future while preserving errors from the dORM layer.
Future<T> mapDormErrors<T>(
  Future<T> Function() action,
  DormErrorMapper mapper, {
  String? operation,
  bool mapFormatExceptions = false,
}) async {
  try {
    return await action();
  } catch (error, stackTrace) {
    if ((_isFrameworkError(error) &&
            !(mapFormatExceptions && error is FormatException)) ||
        error is DormDatabaseException) {
      rethrow;
    }
    Error.throwWithStackTrace(
      mapper.map(error, stackTrace, operation: operation),
      stackTrace,
    );
  }
}

/// Maps errors emitted by a provider stream.
Stream<T> mapDormStreamErrors<T>(
  Stream<T> stream,
  DormErrorMapper mapper, {
  String? operation,
  bool mapFormatExceptions = false,
}) async* {
  try {
    await for (final T value in stream) {
      yield value;
    }
  } catch (error, stackTrace) {
    if ((_isFrameworkError(error) &&
            !(mapFormatExceptions && error is FormatException)) ||
        error is DormDatabaseException) {
      rethrow;
    }
    Error.throwWithStackTrace(
      mapper.map(error, stackTrace, operation: operation),
      stackTrace,
    );
  }
}

/// Adds portable error mapping to a reference without changing its contract.
class ErrorMappedReference<Q extends BaseQuery<Q>, P extends PageRequest>
    implements BaseReference<Q, P> {
  /// Creates an error-mapped reference around [delegate].
  const ErrorMappedReference(
    this.delegate,
    this.mapper, {
    this.mapFormatExceptions = false,
  });

  /// The wrapped reference.
  final BaseReference<Q, P> delegate;

  /// The mapper used for provider failures.
  final DormErrorMapper mapper;

  /// Whether response format errors should be normalized as provider data errors.
  final bool mapFormatExceptions;

  @override
  Future<Model?> peek<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
    I id,
  ) => mapDormErrors(
    () => delegate.peek(entity, id),
    mapper,
    operation: 'peek',
    mapFormatExceptions: mapFormatExceptions,
  );

  @override
  Stream<Model?> pull<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
    I id,
  ) => mapDormStreamErrors(
    delegate.pull(entity, id),
    mapper,
    operation: 'pull',
    mapFormatExceptions: mapFormatExceptions,
  );

  @override
  Future<List<Model>> peekAll<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
    BaseFilter<Q> filter, [
    QueryOptions options = const QueryOptions(),
  ]) => mapDormErrors(
    () => delegate.peekAll(entity, filter, options),
    mapper,
    operation: 'peekAll',
    mapFormatExceptions: mapFormatExceptions,
  );

  @override
  Future<Page<Model>> peekPage<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
    BaseFilter<Q> filter,
    P request,
  ) => mapDormErrors(
    () => delegate.peekPage(entity, filter, request),
    mapper,
    operation: 'peekPage',
    mapFormatExceptions: mapFormatExceptions,
  );

  @override
  Stream<List<Model>> pullAll<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
    BaseFilter<Q> filter, [
    QueryOptions options = const QueryOptions(),
  ]) => mapDormStreamErrors(
    delegate.pullAll(entity, filter, options),
    mapper,
    operation: 'pullAll',
    mapFormatExceptions: mapFormatExceptions,
  );

  @override
  Future<List<I>> peekAllKeys<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
  ) => mapDormErrors(
    () => delegate.peekAllKeys(entity),
    mapper,
    operation: 'peekAllKeys',
    mapFormatExceptions: mapFormatExceptions,
  );

  @override
  Future<void> pop<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
    I id,
  ) => mapDormErrors(
    () => delegate.pop(entity, id),
    mapper,
    operation: 'pop',
    mapFormatExceptions: mapFormatExceptions,
  );

  @override
  Future<void> popKeys<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
    Iterable<I> ids,
  ) => mapDormErrors(
    () => delegate.popKeys(entity, ids),
    mapper,
    operation: 'popKeys',
    mapFormatExceptions: mapFormatExceptions,
  );

  @override
  Future<void> push<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
    Model model,
  ) => mapDormErrors(
    () => delegate.push(entity, model),
    mapper,
    operation: 'push',
    mapFormatExceptions: mapFormatExceptions,
  );

  @override
  Future<void> pushAll<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
    List<Model> models,
  ) => mapDormErrors(
    () => delegate.pushAll(entity, models),
    mapper,
    operation: 'pushAll',
    mapFormatExceptions: mapFormatExceptions,
  );

  @override
  Future<void> popAll<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
    BaseFilter<Q> filter,
  ) => mapDormErrors(
    () => delegate.popAll(entity, filter),
    mapper,
    operation: 'popAll',
    mapFormatExceptions: mapFormatExceptions,
  );

  @override
  Future<void> patch<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
    I id,
    Model? Function(Model?) update,
  ) => mapDormErrors(
    () => delegate.patch(entity, id, update),
    mapper,
    operation: 'patch',
    mapFormatExceptions: mapFormatExceptions,
  );

  @override
  Future<Model> put<
    Data,
    Model extends Data,
    I extends Object,
    C extends Creation<Data, I>
  >(Entity<Data, Model, I, C> entity, C creation) => mapDormErrors(
    () => delegate.put(entity, creation),
    mapper,
    operation: 'put',
    mapFormatExceptions: mapFormatExceptions,
  );

  @override
  Future<List<Model>> putAll<
    Data,
    Model extends Data,
    I extends Object,
    C extends Creation<Data, I>
  >(Entity<Data, Model, I, C> entity, List<C> creations) => mapDormErrors(
    () => delegate.putAll(entity, creations),
    mapper,
    operation: 'putAll',
    mapFormatExceptions: mapFormatExceptions,
  );

  @override
  Future<void> purge<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
  ) => mapDormErrors(
    () => delegate.purge(entity),
    mapper,
    operation: 'purge',
    mapFormatExceptions: mapFormatExceptions,
  );
}

class _ErrorMappedReadable<
  SingleModel,
  I extends Object,
  BatchModel,
  Q extends BaseQuery<Q>
>
    implements Readable2<SingleModel, I, BatchModel, Q> {
  const _ErrorMappedReadable(
    this.delegate,
    this.mapper,
    this.operation,
    this.mapFormatExceptions,
  );

  final Readable2<SingleModel, I, BatchModel, Q> delegate;
  final DormErrorMapper mapper;
  final String operation;
  final bool mapFormatExceptions;

  @override
  Future<SingleModel?> peek(I id) => mapDormErrors(
    () => delegate.peek(id),
    mapper,
    operation: '$operation.peek',
    mapFormatExceptions: mapFormatExceptions,
  );

  @override
  Future<List<BatchModel>> peekAll([
    BaseFilter<Q> filter = const BaseFilter.empty(),
    QueryOptions options = const QueryOptions(),
  ]) => mapDormErrors(
    () => delegate.peekAll(filter, options),
    mapper,
    operation: '$operation.peekAll',
    mapFormatExceptions: mapFormatExceptions,
  );

  @override
  Stream<SingleModel?> pull(I id) => mapDormStreamErrors(
    delegate.pull(id),
    mapper,
    operation: '$operation.pull',
    mapFormatExceptions: mapFormatExceptions,
  );

  @override
  Stream<List<BatchModel>> pullAll([
    BaseFilter<Q> filter = const BaseFilter.empty(),
    QueryOptions options = const QueryOptions(),
  ]) => mapDormStreamErrors(
    delegate.pullAll(filter, options),
    mapper,
    operation: '$operation.pullAll',
    mapFormatExceptions: mapFormatExceptions,
  );
}

/// Adds portable error mapping to a change-tracked reference.
class ErrorMappedChangeTrackedReference<
  Q extends BaseQuery<Q>,
  P extends PageRequest
>
    extends ErrorMappedReference<Q, P>
    implements ChangeTrackedReference<Q, P> {
  /// Creates an error-mapped change-tracked reference.
  const ErrorMappedChangeTrackedReference(
    super.delegate,
    super.mapper, {
    super.mapFormatExceptions,
  }) : changeTrackedDelegate = delegate as ChangeTrackedReference<Q, P>;

  /// The wrapped change-tracked reference.
  final ChangeTrackedReference<Q, P> changeTrackedDelegate;

  @override
  Future<MutationResult<Object?>> mutate<
    Data,
    Model extends Data,
    I extends Object,
    C extends Creation<Data, I>
  >(Entity<Data, Model, I, C> entity, MutationRequest request) => mapDormErrors(
    () => changeTrackedDelegate.mutate(entity, request),
    mapper,
    operation: _mutationOperation(request),
    mapFormatExceptions: mapFormatExceptions,
  );
}

/// Adds portable error mapping to relationship associations.
class ErrorMappedRelationship<Q extends BaseQuery<Q>>
    implements BaseRelationship<Q> {
  /// Creates an error-mapped relationship around [delegate].
  const ErrorMappedRelationship(
    this.delegate,
    this.mapper, {
    this.mapFormatExceptions = false,
  });

  /// The wrapped relationship implementation.
  final BaseRelationship<Q> delegate;

  /// The mapper used for provider failures.
  final DormErrorMapper mapper;

  final bool mapFormatExceptions;

  @override
  OneToOneAssociation<L, I, R, Q>
  oneToOne<L, I extends Object, R, J extends Object>(
    RelationSource<L, I, Q> left,
    RelationSource<R, J, Q> right,
    J Function(L) on,
  ) => _ErrorMappedReadable<Join<L, R?>, I, Join<L, R?>, Q>(
    delegate.oneToOne(left, right, on),
    mapper,
    'relationship.oneToOne',
    mapFormatExceptions,
  );

  @override
  OneToManyAssociation<L, I, R, Q>
  oneToMany<L, I extends Object, R, J extends Object>(
    RelationSource<L, I, Q> left,
    RelationSource<R, J, Q> right,
    BaseFilter<Q> Function(L) on,
  ) => _ErrorMappedReadable<Join<L, List<R>>, I, Join<L, List<R>>, Q>(
    delegate.oneToMany(left, right, on),
    mapper,
    'relationship.oneToMany',
    mapFormatExceptions,
  );

  @override
  ManyToOneAssociation<L, I, R, J, Q>
  manyToOne<L, I extends Object, R, J extends Object>(
    RelationSource<L, I, Q> left,
    RelationSource<R, J, Q> right,
    J Function(L) on,
  ) => _ErrorMappedReadable<Join<R, L>, I, Join<R, List<L>>, Q>(
    delegate.manyToOne(left, right, on),
    mapper,
    'relationship.manyToOne',
    mapFormatExceptions,
  );

  @override
  ManyToManyAssociation<M, I, L, R, Q>
  manyToMany<M, I extends Object, L, J extends Object, R, K extends Object>(
    RelationSource<M, I, Q> middle,
    RelationSource<L, J, Q> left,
    J Function(M) onLeft,
    RelationSource<R, K, Q> right,
    K Function(M) onRight,
  ) => _ErrorMappedReadable<Join<M, (L?, R?)>, I, Join<M, (L?, R?)>, Q>(
    delegate.manyToMany(middle, left, onLeft, right, onRight),
    mapper,
    'relationship.manyToMany',
    mapFormatExceptions,
  );
}
