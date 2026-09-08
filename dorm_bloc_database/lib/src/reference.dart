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

import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:dorm_framework/dorm_framework.dart';
import 'package:uuid/uuid.dart';

import 'query.dart';
import 'relationship.dart';

class _State {
  final Map<String, _EntityReference<Object, Object, Object>> references;

  const _State(this.references);

  _EntityReference<Data, Model, I>
      access<Data, Model extends Data, I extends Object>(String key) {
    return references[key] as _EntityReference<Data, Model, I>;
  }
}

const Uuid _uuid = Uuid();

class _EntityState<I extends Object, Model> {
  final Map<I, Model> models;

  const _EntityState(this.models);
}

class _EntityReference<Data, Model extends Data, I extends Object>
    extends Cubit<_EntityState<I, Model>> {
  final Entity<Data, Model, I, Creation<Data, I>> entity;
  StreamSubscription<void>? _subscription;
  late final StreamController<Map<I, Model>> _controller;
  bool emitEvents = true;

  _EntityReference(this.entity) : super(_EntityState<I, Model>({})) {
    _controller = StreamController.broadcast(
      onListen: () => _controller.add(state.models),
    );
    _subscription = stream.map((state) => state.models).listen(_controller.add);
  }

  _EntityReference<Data, Model, I> copyForTransaction() {
    final _EntityReference<Data, Model, I> copy =
        _EntityReference<Data, Model, I>(entity);
    copy.state.models.addAll(state.models);
    copy.emitEvents = false;
    return copy;
  }

  Stream<Map<I, Model>> get dataStream => _controller.stream;

  R _emit<R>(R Function(Map<I, Model> models) action) {
    final Map<I, Model> models = Map.of(state.models);
    final R result = action(models);
    if (emitEvents) {
      emit(_EntityState(models));
    } else {
      state.models
        ..clear()
        ..addAll(models);
    }
    return result;
  }

  void notify() => emit(_EntityState(Map.of(state.models)));

  void pop(I id) {
    _emit((models) => models.remove(id));
  }

  void popKeys(Iterable<I> ids) {
    _emit((models) => models.removeWhere((id, _) => ids.contains(id)));
  }

  void push(Model model) {
    _emit((models) => models[entity.identify(model)] = model);
  }

  void pushAll(List<Model> models) {
    _emit((current) {
      current.addAll({
        for (Model model in models) entity.identify(model): model,
      });
    });
  }

  void popAll(TableOperator operator) {
    _emit((models) {
      final Map<Object, TableRow> values = {
        for (MapEntry<I, Model> entry in models.entries)
          entry.key: entity.toJson(entry.value),
      };
      final Set<I> keys = operator(values).keys.whereType<I>().toSet();
      models.removeWhere((key, _) => keys.contains(key));
    });
  }

  void patch(I id, Model? Function(Model?) update) {
    _emit((models) {
      final Model? model = update(models[id]);
      if (model == null) {
        models.remove(id);
      } else {
        models[id] = model;
      }
    });
  }

  void purge() {
    _emit((models) {
      models.clear();
    });
  }

  Model put(Creation<Data, I> creation) {
    return _emit((models) {
      final Model model = entity.fromData(_resolvedCreation(creation));
      models[entity.identify(model)] = model;
      return model;
    });
  }

  List<Model> putAll(List<Creation<Data, I>> creations) {
    return _emit((current) {
      final List<Model> models = creations
          .map((creation) => entity.fromData(_resolvedCreation(creation)))
          .toList();

      current.addAll({
        for (Model model in models) entity.identify(model): model,
      });
      return models;
    });
  }

  ResolvedCreation<Data, I> _resolvedCreation(Creation<Data, I> creation) {
    return switch (creation) {
      AutoCreation<Data, I>() => ResolvedCreation(
          dependency: creation.dependency,
          data: creation.data,
          id: _generatedId(),
          identitySource: CreationIdentitySource.generated,
        ),
      ExplicitCreation<Data, I>(:final identity) => () {
          _validateIdentity(identity);
          return ResolvedCreation(
            dependency: creation.dependency,
            data: creation.data,
            id: identity,
            identitySource: CreationIdentitySource.explicit,
          );
        }(),
    };
  }

  I _generatedId() {
    if (entity.schema.isCompositePrimaryKey ||
        entity.identityGeneration != IdentityGenerationStrategy.engine) {
      throw UnsupportedError(
        'BLoC creation requires an explicit identity for this entity.',
      );
    }
    return _uuid.v4() as I;
  }

  void _validateIdentity(I id) {
    final List<Object?> values;
    try {
      values = entity.primaryKeyCodec.encode(id);
    } catch (_) {
      throw ArgumentError.value(
          id, 'identity', 'Identity cannot be encoded for this schema.');
    }
    if (values.length != entity.schema.primaryKeys.length) {
      throw ArgumentError.value(
        id,
        'identity',
        'Identity has ${values.length} values, but the schema requires '
            '${entity.schema.primaryKeys.length}.',
      );
    }
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}

/// A [BaseReference] implementation backed by a [Bloc].
class Reference extends Cubit<_State>
    implements BaseReference<Query, OffsetPageRequest> {
  bool _transactionActive = false;
  Reference() : super(_State({}));

  _EntityReference<Data, Model, I>
      _access<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
  ) {
    final Map<String, _EntityReference<Object, Object, Object>> blocs =
        Map.of(state.references);
    final String tableName = entity.schema.tableName;
    final _EntityReference<Object, Object, Object>? current = blocs[tableName];
    if (current != null) return current as _EntityReference<Data, Model, I>;
    final _EntityReference<Data, Model, I> bloc = _EntityReference(entity);
    blocs[tableName] = bloc as _EntityReference<Object, Object, Object>;
    bloc.emitEvents = !_transactionActive;
    if (_transactionActive) {
      state.references[tableName] =
          bloc as _EntityReference<Object, Object, Object>;
    } else {
      emit(_State(blocs));
    }
    return bloc;
  }

  Future<T> transaction<T>(
    Future<T> Function(BaseEngine<Query, OffsetPageRequest> engine) action,
  ) async {
    if (_transactionActive) {
      throw StateError('Nested dORM transactions are not supported.');
    }
    final Reference transactionReference = Reference._forTransaction(this);
    _transactionActive = true;
    final _TransactionEngine transactionEngine =
        _TransactionEngine(transactionReference);
    try {
      final T result = await action(transactionEngine);
      await _commit(transactionReference);
      transactionEngine.active = false;
      _transactionActive = false;
      return result;
    } catch (_) {
      _transactionActive = false;
      transactionEngine.active = false;
      await transactionReference._close();
      rethrow;
    }
  }

  Reference._forTransaction(Reference source) : super(_State({})) {
    for (final MapEntry<String, _EntityReference<Object, Object, Object>> entry
        in source.state.references.entries) {
      state.references[entry.key] = entry.value.copyForTransaction();
    }
    _transactionActive = true;
  }

  Future<void> _commit(Reference transactionReference) async {
    for (final MapEntry<String, _EntityReference<Object, Object, Object>> entry
        in transactionReference.state.references.entries) {
      final _EntityReference<Object, Object, Object> transactional =
          entry.value;
      final _EntityReference<Object, Object, Object>? current =
          state.references[entry.key];
      if (current == null) {
        transactional.emitEvents = true;
        state.references[entry.key] = transactional;
      } else {
        current.state.models
          ..clear()
          ..addAll(transactional.state.models);
        current.emitEvents = true;
        current.notify();
        await transactional.close();
      }
    }
    transactionReference.state.references.clear();
    transactionReference._transactionActive = false;
  }

  Future<void> _close() async {
    for (final _EntityReference<Object, Object, Object> value
        in state.references.values) {
      await value.close();
    }
    state.references.clear();
    _transactionActive = false;
  }

  @override
  Future<Model?> peek<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
    I id,
  ) async {
    final _EntityReference<Data, Model, I> bloc = _access(entity);
    return bloc.state.models[id];
  }

  @override
  Future<List<Model>> peekAll<Data, Model extends Data, I extends Object>(
      Entity<Data, Model, I, Creation<Data, I>> entity,
      BaseFilter<Query> filter,
      [QueryOptions options = const QueryOptions()]) async {
    final _EntityReference<Data, Model, I> bloc = _access(entity);
    final Query query = QueryOptions(
      orderBy: options.orderBy,
      limit: options.limit == null ? null : options.limit! + options.offset,
    ).apply(filter.accept(const Query()));
    return query
        .operator(bloc.state.models
            .map((key, value) => MapEntry(key, entity.toJson(value))))
        .entries
        .skip(options.offset)
        .take(options.limit ?? bloc.state.models.length)
        .map((entry) => entity.fromJson(entry.key as I, entry.value))
        .toList();
  }

  @override
  Future<Page<Model>> peekPage<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
    BaseFilter<Query> filter,
    OffsetPageRequest request,
  ) async {
    final List<Model> models = await peekAll(
      entity,
      filter,
      QueryOptions(
        orderBy: request.orderBy,
        limit: request.size + request.offset + 1,
      ),
    );
    final List<Model> page =
        models.skip(request.offset).take(request.size + 1).toList();
    return Page(
      items: page.take(request.size).toList(),
      hasNext: page.length > request.size,
    );
  }

  @override
  Future<List<I>> peekAllKeys<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
  ) async {
    final _EntityReference<Data, Model, I> bloc = _access(entity);
    return bloc.state.models.keys.toList();
  }

  @override
  Future<void> pop<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
    I id,
  ) async {
    final _EntityReference<Data, Model, I> bloc = _access(entity);
    bloc.pop(id);
  }

  @override
  Future<void> popAll<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
    BaseFilter<Query> filter,
  ) async {
    final _EntityReference<Data, Model, I> bloc = _access(entity);
    final Query query = filter.accept(const Query());
    bloc.popAll(query.operator);
  }

  @override
  Future<void> popKeys<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
    Iterable<I> ids,
  ) async {
    final _EntityReference<Data, Model, I> bloc = _access(entity);
    bloc.popKeys(ids.toSet());
  }

  @override
  Stream<Model?> pull<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
    I id,
  ) {
    if (_transactionActive) {
      throw UnsupportedError('Streams are not available in a transaction.');
    }
    final _EntityReference<Data, Model, I> bloc = _access(entity);
    return bloc.dataStream.map((models) => models[id]);
  }

  @override
  Stream<List<Model>> pullAll<Data, Model extends Data, I extends Object>(
      Entity<Data, Model, I, Creation<Data, I>> entity,
      BaseFilter<Query> filter,
      [QueryOptions options = const QueryOptions()]) {
    if (_transactionActive) {
      throw UnsupportedError('Streams are not available in a transaction.');
    }
    final _EntityReference<Data, Model, I> bloc = _access(entity);
    final Query query = QueryOptions(
      orderBy: options.orderBy,
      limit: options.limit == null ? null : options.limit! + options.offset,
    ).apply(filter.accept(const Query()));
    return bloc.dataStream.map((models) => query
        .operator(
            models.map((key, value) => MapEntry(key, entity.toJson(value))))
        .entries
        .skip(options.offset)
        .take(options.limit ?? models.length)
        .map((entry) => entity.fromJson(entry.key as I, entry.value))
        .toList());
  }

  @override
  Future<void> patch<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
    I id,
    Model? Function(Model?) update,
  ) async {
    final _EntityReference<Data, Model, I> bloc = _access(entity);
    bloc.patch(id, update);
  }

  @override
  Future<void> push<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
    Model model,
  ) async {
    final _EntityReference<Data, Model, I> bloc = _access(entity);
    bloc.push(model);
  }

  @override
  Future<void> pushAll<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
    List<Model> models,
  ) async {
    final _EntityReference<Data, Model, I> bloc = _access(entity);
    bloc.pushAll(models);
  }

  @override
  Future<Model> put<Data, Model extends Data, I extends Object,
      C extends Creation<Data, I>>(
    Entity<Data, Model, I, C> entity,
    C creation,
  ) async {
    final _EntityReference<Data, Model, I> bloc = _access(entity);
    return bloc.put(creation);
  }

  @override
  Future<void> purge<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
  ) async {
    final _EntityReference<Data, Model, I> bloc = _access(entity);
    bloc.purge();
  }

  @override
  Future<List<Model>> putAll<Data, Model extends Data, I extends Object,
      C extends Creation<Data, I>>(
    Entity<Data, Model, I, C> entity,
    List<C> creations,
  ) async {
    final _EntityReference<Data, Model, I> bloc = _access(entity);
    return bloc.putAll(creations);
  }
}

class _TransactionEngine implements BaseEngine<Query, OffsetPageRequest> {
  final Reference reference;
  bool active = true;

  _TransactionEngine(this.reference);

  @override
  BaseReference<Query, OffsetPageRequest> createReference() {
    _checkActive();
    return reference;
  }

  @override
  BaseRelationship<Query> createRelationship() {
    _checkActive();
    return const Relationship();
  }

  void _checkActive() {
    if (!active) {
      throw StateError('The transaction context is no longer active.');
    }
  }
}
