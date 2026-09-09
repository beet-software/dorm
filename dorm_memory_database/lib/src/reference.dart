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

import 'package:dorm_framework/dorm_framework.dart';
import 'package:uuid/uuid.dart';

import 'query.dart';
import 'relationship.dart';

const Uuid _uuid = Uuid();

class _EntityReference<
  Data,
  Model extends Data,
  I extends Object,
  C extends Creation<Data, I>
> {
  final Entity<Data, Model, I, C> entity;
  final Map<I, Model> models = {};
  final StreamController<Map<I, Model>> _controller =
      StreamController<Map<I, Model>>.broadcast();
  bool emitEvents = true;

  _EntityReference(this.entity) {
    _controller.onListen = () => _controller.add(Map.of(models));
  }

  _EntityReference<Data, Model, I, C> copyForTransaction() {
    final _EntityReference<Data, Model, I, C> copy =
        _EntityReference<Data, Model, I, C>(entity);
    copy.models.addAll(models);
    copy.emitEvents = false;
    return copy;
  }

  Stream<Map<I, Model>> get dataStream => _controller.stream;

  R _emit<R>(R Function() action) {
    final R result = action();
    if (emitEvents) _controller.add(Map.of(models));
    return result;
  }

  void notify() => _controller.add(Map.of(models));

  Future<void> close() => _controller.close();

  void pop(I id) => _emit(() => models.remove(id));

  void popKeys(Iterable<I> ids) {
    _emit(() => models.removeWhere((id, _) => ids.contains(id)));
  }

  void push(Model model) {
    _emit(() => models[entity.identify(model)] = model);
  }

  void pushAll(List<Model> values) {
    _emit(() {
      models.addAll({
        for (final Model model in values) entity.identify(model): model,
      });
    });
  }

  void popAll(TableOperator<I> operator) {
    _emit(() {
      final Map<I, TableRow> values = {
        for (final MapEntry<I, Model> entry in models.entries)
          entry.key: entity.toJson(entry.value),
      };
      final Set<I> keys = operator(values).keys.toSet();
      models.removeWhere((key, _) => keys.contains(key));
    });
  }

  void patch(I id, Model? Function(Model?) update) {
    _emit(() {
      final Model? model = update(models[id]);
      if (model == null) {
        models.remove(id);
      } else {
        models[id] = model;
      }
    });
  }

  void purge() => _emit(() {
    models.clear();
  });

  Model put(C creation) {
    return _emit(() {
      final Model model = entity.fromData(_resolvedCreation(creation));
      models[entity.identify(model)] = model;
      return model;
    });
  }

  List<Model> putAll(List<C> creations) {
    return _emit(() {
      final List<Model> values = creations
          .map((creation) => entity.fromData(_resolvedCreation(creation)))
          .toList();
      models.addAll({
        for (final Model model in values) entity.identify(model): model,
      });
      return values;
    });
  }

  ResolvedCreation<Data, I> _resolvedCreation(C creation) {
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
        'Memory creation requires an explicit identity for this entity.',
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
        id,
        'identity',
        'Identity cannot be encoded for this schema.',
      );
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
}

/// A [BaseReference] implementation backed by Dart maps and streams.
class Reference implements BaseReference<Query, OffsetPageRequest> {
  final Map<String, Object> _references = {};
  bool _transactionActive = false;

  Reference();

  _EntityReference<Data, Model, I, C> _access<
    Data,
    Model extends Data,
    I extends Object,
    C extends Creation<Data, I>
  >(Entity<Data, Model, I, C> entity) {
    final String tableName = entity.schema.tableName;
    final Object? current = _references[tableName];
    if (current != null) {
      return current as _EntityReference<Data, Model, I, C>;
    }
    final _EntityReference<Data, Model, I, C> reference = _EntityReference(
      entity,
    );
    reference.emitEvents = !_transactionActive;
    _references[tableName] = reference;
    return reference;
  }

  Future<T> transaction<T>(
    Future<T> Function(BaseEngine<Query, OffsetPageRequest> engine) action,
  ) async {
    if (_transactionActive) {
      throw StateError('Nested dORM transactions are not supported.');
    }
    final Reference transactionReference = Reference._forTransaction(this);
    _transactionActive = true;
    final _TransactionEngine transactionEngine = _TransactionEngine(
      transactionReference,
    );
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

  Reference._forTransaction(Reference source) {
    for (final MapEntry<String, Object> entry in source._references.entries) {
      _references[entry.key] = (entry.value as dynamic).copyForTransaction();
    }
    _transactionActive = true;
  }

  Future<void> _commit(Reference transactionReference) async {
    for (final MapEntry<String, Object> entry
        in transactionReference._references.entries) {
      final dynamic transactional = entry.value;
      final dynamic current = _references[entry.key];
      if (current == null) {
        transactional.emitEvents = true;
        _references[entry.key] = transactional;
      } else {
        current.models
          ..clear()
          ..addAll(transactional.models);
        current.emitEvents = true;
        current.notify();
        await transactional.close();
      }
    }
    transactionReference._references.clear();
    transactionReference._transactionActive = false;
  }

  Future<void> _close() async {
    for (final Object value in _references.values) {
      await (value as dynamic).close();
    }
    _references.clear();
    _transactionActive = false;
  }

  @override
  Future<Model?> peek<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
    I id,
  ) async {
    return _access(entity).models[id];
  }

  @override
  Future<List<Model>> peekAll<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
    BaseFilter<Query> filter, [
    QueryOptions options = const QueryOptions(),
  ]) async {
    final _EntityReference<Data, Model, I, Creation<Data, I>> reference =
        _access(entity);
    final Query<I> query = QueryOptions(
      orderBy: options.orderBy,
      limit: options.limit == null ? null : options.limit! + options.offset,
    ).apply(filter.accept(Query<I>()) as Query<I>);
    final Iterable<MapEntry<I, TableRow>> entries = query
        .operator(
          reference.models.map(
            (key, value) => MapEntry(key, entity.toJson(value)),
          ),
        )
        .entries
        .skip(options.offset)
        .take(options.limit ?? reference.models.length);
    return entries
        .map((entry) => entity.fromJson(entry.key, entry.value))
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
    final List<Model> page = models
        .skip(request.offset)
        .take(request.size + 1)
        .toList();
    return Page(
      items: page.take(request.size).toList(),
      hasNext: page.length > request.size,
    );
  }

  @override
  Future<List<I>> peekAllKeys<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
  ) async {
    return _access(entity).models.keys.toList();
  }

  @override
  Future<void> pop<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
    I id,
  ) async {
    _access(entity).pop(id);
  }

  @override
  Future<void> popAll<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
    BaseFilter<Query> filter,
  ) async {
    final Query<I> query = filter.accept(Query<I>()) as Query<I>;
    _access(entity).popAll(query.operator);
  }

  @override
  Future<void> popKeys<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
    Iterable<I> ids,
  ) async {
    _access(entity).popKeys(ids.toSet());
  }

  @override
  Stream<Model?> pull<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
    I id,
  ) {
    if (_transactionActive) {
      throw UnsupportedError('Streams are not available in a transaction.');
    }
    return _access(entity).dataStream.map((models) => models[id]);
  }

  @override
  Stream<List<Model>> pullAll<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
    BaseFilter<Query> filter, [
    QueryOptions options = const QueryOptions(),
  ]) {
    if (_transactionActive) {
      throw UnsupportedError('Streams are not available in a transaction.');
    }
    final Query<I> query = QueryOptions(
      orderBy: options.orderBy,
      limit: options.limit == null ? null : options.limit! + options.offset,
    ).apply(filter.accept(Query<I>()) as Query<I>);
    return _access(entity).dataStream.map(
      (models) => query
          .operator(
            models.map((key, value) => MapEntry(key, entity.toJson(value))),
          )
          .entries
          .skip(options.offset)
          .take(options.limit ?? models.length)
          .map((entry) => entity.fromJson(entry.key, entry.value))
          .toList(),
    );
  }

  @override
  Future<void> patch<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
    I id,
    Model? Function(Model?) update,
  ) async {
    _access(entity).patch(id, update);
  }

  @override
  Future<void> push<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
    Model model,
  ) async {
    _access(entity).push(model);
  }

  @override
  Future<void> pushAll<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
    List<Model> models,
  ) async {
    _access(entity).pushAll(models);
  }

  @override
  Future<Model> put<
    Data,
    Model extends Data,
    I extends Object,
    C extends Creation<Data, I>
  >(Entity<Data, Model, I, C> entity, C creation) async {
    return _access(entity).put(creation);
  }

  @override
  Future<List<Model>> putAll<
    Data,
    Model extends Data,
    I extends Object,
    C extends Creation<Data, I>
  >(Entity<Data, Model, I, C> entity, List<C> creations) async {
    return _access(entity).putAll(creations);
  }

  @override
  Future<void> purge<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
  ) async {
    _access(entity).purge();
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
