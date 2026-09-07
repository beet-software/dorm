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

import 'dart:convert';

import 'package:dorm_framework/dorm_framework.dart';
import 'package:firebase_auth/firebase_auth.dart' as fa;
import 'package:firebase_database/firebase_database.dart' as fd;
import 'package:http/http.dart' as http;

import 'firebase_instance.dart';
import 'offline.dart';
import 'query.dart';

/// A [BaseReference] that uses Firebase Realtime Database as engine.
class Reference implements BaseReference<Query, OffsetPageRequest> {
  final FirebaseInstance instance;
  final fd.DatabaseReference _ref;

  Reference(FirebaseInstance instance, [String? path])
    : this._(instance, instance.database.ref(path));

  const Reference._(this.instance, this._ref);

  fd.DatabaseReference _refOf<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
  ) {
    return _ref.child(entity.schema.tableName);
  }

  String _key<I extends Object>(I id) {
    if (id case String value) return value;
    throw ArgumentError.value(id, 'id', 'Firebase IDs must be String values');
  }

  I _id<I extends Object>(String key) {
    if (key is I) return key as I;
    throw ArgumentError.value(key, 'key', 'Firebase IDs must be String values');
  }

  @override
  Future<Model?> peek<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
    I id,
  ) {
    return _refOf(entity) //
        .child(_key(id))
        .get()
        .then((snapshot) => snapshot.value)
        .then(
          (value) => value == null ? null : entity.fromJson(id, value as Map),
        );
  }

  @override
  Future<List<Model>> peekAll<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
    BaseFilter<Query> filter, [
    QueryOptions options = const QueryOptions(),
  ]) {
    final Query query = QueryOptions(
      orderBy: options.orderBy,
      limit: options.limit == null ? null : options.limit! + options.offset,
    ).apply(filter.accept(Query(_refOf(entity))));
    final Future<List<Model>> read = query.query
        .get()
        .then((snapshot) {
          return {
            for (fd.DataSnapshot child in snapshot.children)
              _id<I>(child.key as String): child.value as Object,
          };
        })
        .then((values) {
          if (values.isEmpty) return [];
          return values.entries.map((entry) {
            final I key = entry.key;
            final Map value = entry.value as Map;
            return entity.fromJson(key, value);
          }).toList();
        });
    return read.then(
      (models) => models
          .skip(options.offset)
          .take(options.limit ?? models.length)
          .toList(),
    );
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
  Future<void> pop<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
    I id,
  ) {
    return _refOf(entity).child(_key(id)).remove();
  }

  @override
  Future<void> popKeys<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
    Iterable<I> ids,
  ) {
    return _refOf(entity).update({for (I id in ids) _key(id): null});
  }

  @override
  Future<void> popAll<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
    BaseFilter<Query> filter,
  ) async {
    // TODO Refactor this operation as atomic.
    // Firebase does not have `runTransaction` as a method of fd.Query.
    // Also, a fd.Query can't be used inside a fd.TransactionHandler.
    final List<Model> models = await peekAll(entity, filter);
    await popKeys(entity, models.map(entity.identify));
  }

  @override
  Future<void> patch<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
    I id,
    Model? Function(Model?) update,
  ) {
    return _refOf(entity).child(_key(id)).runTransaction((value) {
      final Model? model;
      if (value == null) {
        model = null;
      } else {
        model = entity.fromJson(id, value as Map);
      }

      final Model? updatedModel;
      try {
        updatedModel = update(model);
      } catch (_) {
        return fd.Transaction.abort();
      }

      if (updatedModel == null) {
        return fd.Transaction.success(null);
      }
      return fd.Transaction.success(entity.toJson(updatedModel));
    });
  }

  @override
  Stream<Model?> pull<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
    I id,
  ) {
    return _onValueOf(_refOf(entity).child(_key(id)))
        .map((snapshot) => snapshot.value)
        .map(
          (value) => value == null ? null : entity.fromJson(id, value as Map),
        );
  }

  Stream<fd.DataSnapshot> _onValueOf(fd.Query query) {
    switch (instance.offlineMode) {
      case OfflineMode.exclude:
        return query.onValue.map((event) => event.snapshot);
      case OfflineMode.include:
        return OfflineAdapter(instance: instance.database, query: query).stream;
    }
  }

  @override
  Stream<List<Model>> pullAll<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
    BaseFilter<Query> filter, [
    QueryOptions options = const QueryOptions(),
  ]) {
    final Query query = options.apply(filter.accept(Query(_refOf(entity))));
    return _onValueOf(query.query)
        .map((snapshot) {
          return {
            for (fd.DataSnapshot child in snapshot.children)
              _id<I>(child.key as String): child.value as Object,
          };
        })
        .map((values) {
          if (values.isEmpty) return [];
          return values.entries.map((entry) {
            final I key = entry.key;
            final Map value = entry.value as Map;
            return entity.fromJson(key, value);
          }).toList();
        });
  }

  @override
  Future<Model> put<
    Data,
    Model extends Data,
    I extends Object,
    C extends Creation<Data, I>
  >(Entity<Data, Model, I, C> entity, C creation) {
    return putAll(entity, [creation]).then((models) => models.single);
  }

  @override
  Future<List<Model>> putAll<
    Data,
    Model extends Data,
    I extends Object,
    C extends Creation<Data, I>
  >(Entity<Data, Model, I, C> entity, List<C> creations) async {
    final List<Model> models = [];
    for (final C creation in creations) {
      final ResolvedCreation<Data, I> resolved = _resolveCreation(
        entity,
        creation,
      );
      final Model model = entity.fromData(resolved);
      models.add(model);
    }
    await _refOf(entity).update({
      for (Model model in models)
        _key(entity.identify(model)): entity.toJson(model),
    });
    return models;
  }

  ResolvedCreation<Data, I>
  _resolveCreation<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
    Creation<Data, I> creation,
  ) {
    return switch (creation.identity) {
      AutoIdentity<I>() => _resolveAutoCreation(entity, creation),
      ExplicitIdentity<I>(:final value) => _resolveExplicitCreation(
        entity,
        creation,
        value,
      ),
    };
  }

  ResolvedCreation<Data, I>
  _resolveAutoCreation<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
    Creation<Data, I> creation,
  ) {
    if (entity.schema.isCompositePrimaryKey ||
        !entity.supportsAutomaticIdentity) {
      throw UnsupportedError(
        'Firebase creation requires an explicit simple String identity.',
      );
    }
    final fd.DatabaseReference ref = _refOf(entity).push();
    return ResolvedCreation(
      dependency: creation.dependency,
      data: creation.data,
      id: _id<I>(ref.key as String),
      wasGenerated: true,
    );
  }

  ResolvedCreation<Data, I>
  _resolveExplicitCreation<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
    Creation<Data, I> creation,
    I id,
  ) {
    if (entity.schema.isCompositePrimaryKey) {
      throw UnsupportedError('Firebase does not support composite identities.');
    }
    _validateIdentity(entity, id);
    _key(id);
    return ResolvedCreation(
      dependency: creation.dependency,
      data: creation.data,
      id: id,
      wasGenerated: false,
    );
  }

  void _validateIdentity<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
    I id,
  ) {
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

  @override
  Future<void> push<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
    Model model,
  ) {
    return pushAll(entity, [model]);
  }

  @override
  Future<void> pushAll<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
    List<Model> models,
  ) {
    return _refOf(entity).update({
      for (Model model in models)
        _key(entity.identify(model)): entity.toJson(model),
    });
  }

  @override
  Future<void> purge<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
  ) {
    return _refOf(entity).remove();
  }

  @override
  Future<List<I>> peekAllKeys<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
  ) async {
    final String path = _refOf(entity).path;
    final String projectId = instance.app.options.projectId;
    final fa.User? user = instance.auth.currentUser;
    final http.Response response = await http.get(
      Uri(
        scheme: 'https',
        host: '$projectId-default-rtdb.firebaseio.com',
        path: '$path.json',
        queryParameters: {
          if (user != null) 'auth': await user.getIdToken(),
          'shallow': 'true',
        },
      ),
    );
    final Map? data = json.decode(response.body) as Map?;
    if (data == null) return [];
    return data.keys.map((key) => _id<I>(key as String)).toList();
  }
}
