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

import 'engine.dart';
import 'target.dart';

class SynchronizedReference<Q extends BaseQuery<Q>, P extends PageRequest>
    implements BaseReference<Q, P> {
  const SynchronizedReference({
    required this.coordinator,
    required this.fallback,
  });

  final SyncCoordinator coordinator;
  final SyncFallbackPolicy fallback;

  Future<T> _read<T>(Future<T> Function(SyncReadTarget target) action) async {
    try {
      return await action(coordinator.primary);
    } catch (error, stackTrace) {
      if (!fallback(error, stackTrace)) {
        Error.throwWithStackTrace(error, stackTrace);
      }
      Object? lastError = error;
      StackTrace lastStackTrace = stackTrace;
      for (final SyncReadApplyTarget replica in coordinator.replicas) {
        try {
          return await action(replica);
        } catch (replicaError, replicaStackTrace) {
          lastError = replicaError;
          lastStackTrace = replicaStackTrace;
        }
      }
      Error.throwWithStackTrace(lastError!, lastStackTrace);
    }
  }

  Future<void> _write<
    Data,
    Model extends Data,
    I extends Object,
    C extends Creation<Data, I>
  >(Entity<Data, Model, I, C> entity, MutationRequest request) async {
    final MutationResult<Object?> result = await coordinator.primary.mutate(
      entity,
      request,
    );
    await coordinator.enqueue(
      (target, changeSet) => target.apply(entity, changeSet),
      result.changeSet,
    );
  }

  Future<T> _writeValue<
    T,
    Data,
    Model extends Data,
    I extends Object,
    C extends Creation<Data, I>
  >(Entity<Data, Model, I, C> entity, MutationRequest request) async {
    final MutationResult<Object?> result = await coordinator.primary.mutate(
      entity,
      request,
    );
    await coordinator.enqueue(
      (target, changeSet) => target.apply(entity, changeSet),
      result.changeSet,
    );
    return result.value as T;
  }

  @override
  Future<Model?> peek<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
    I id,
  ) => _read((target) => target.peek(entity, id)).then((value) => value);

  @override
  Stream<Model?> pull<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
    I id,
  ) => coordinator.primary.pull(entity, id).map((value) => value);

  @override
  Future<List<Model>> peekAll<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
    BaseFilter<Q> filter, [
    QueryOptions options = const QueryOptions(),
  ]) async => [
    for (final Object? value in await _read(
      (target) =>
          target.peekAll<Data, Model, I>(entity, filter.expression, options),
    ))
      value as Model,
  ];

  @override
  Future<Page<Model>> peekPage<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
    BaseFilter<Q> filter,
    P request,
  ) async {
    final Page<Object?> page = await _read(
      (target) =>
          target.peekPage<Data, Model, I>(entity, filter.expression, request),
    );
    return Page<Model>(
      items: [for (final Object? value in page.items) value as Model],
      hasNext: page.hasNext,
      nextCursor: page.nextCursor,
    );
  }

  @override
  Stream<List<Model>> pullAll<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
    BaseFilter<Q> filter, [
    QueryOptions options = const QueryOptions(),
  ]) => coordinator.primary
      .pullAll(entity, filter.expression, options)
      .map((values) => [for (final Object? value in values) value as Model]);

  @override
  Future<List<I>> peekAllKeys<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
  ) async => [
    for (final Object? value in await _read(
      (target) => target.peekAllKeys(entity),
    ))
      value as I,
  ];

  @override
  Future<void> pop<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
    I id,
  ) => _write(entity, PopMutation<I>(id));

  @override
  Future<void> popKeys<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
    Iterable<I> ids,
  ) => _write(entity, PopKeysMutation<I>(ids));

  @override
  Future<void> push<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
    Model model,
  ) => _write(entity, PushMutation<Model>(model));

  @override
  Future<void> pushAll<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
    List<Model> models,
  ) => _write(entity, PushAllMutation<Model>(models));

  @override
  Future<void> popAll<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
    BaseFilter<Q> filter,
  ) => _write(entity, PopAllMutation<Q>(filter));

  @override
  Future<void> patch<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
    I id,
    Model? Function(Model?) update,
  ) => _write(entity, PatchMutation<Model, I>(id, update));

  @override
  Future<Model> put<
    Data,
    Model extends Data,
    I extends Object,
    C extends Creation<Data, I>
  >(Entity<Data, Model, I, C> entity, C creation) =>
      _writeValue<Model, Data, Model, I, C>(
        entity,
        PutMutation<Data, I>(creation),
      );

  @override
  Future<List<Model>> putAll<
    Data,
    Model extends Data,
    I extends Object,
    C extends Creation<Data, I>
  >(Entity<Data, Model, I, C> entity, List<C> creations) =>
      _writeValue<List<Model>, Data, Model, I, C>(
        entity,
        PutAllMutation<Data, I>(creations),
      );

  @override
  Future<void> purge<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
  ) => _write(entity, const PurgeMutation());
}
