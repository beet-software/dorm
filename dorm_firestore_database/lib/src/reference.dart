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

import 'package:cloud_firestore/cloud_firestore.dart' as fs;
import 'package:dorm_framework/dorm_framework.dart';

import 'query.dart';
import 'helpers.dart';

const int _maxBatchWrites = 500;

/// A [BaseReference] backed by Cloud Firestore.
class Reference implements BaseReference<Query, OffsetPageRequest> {
  final fs.FirebaseFirestore firestore;
  final String? parentPath;

  const Reference(this.firestore, {this.parentPath});

  String _collectionPath(String tableName) {
    return firestoreCollectionPath(tableName, parentPath);
  }

  fs.CollectionReference<Map<String, dynamic>> _collection<
    Data,
    Model extends Data,
    I extends Object
  >(Entity<Data, Model, I, Creation<Data, I>> entity) {
    return firestore.collection(_collectionPath(entity.schema.tableName));
  }

  String _key<I extends Object>(I id) {
    return firestoreDocumentId(id);
  }

  I _id<I extends Object>(String id) {
    if (I != String) {
      throw ArgumentError.value(
        id,
        'id',
        'Cloud Firestore dORM identities must be String values.',
      );
    }
    return id as I;
  }

  Map<String, dynamic> _json<
    Data,
    Model extends Data,
    I extends Object,
    C extends Creation<Data, I>
  >(Entity<Data, Model, I, C> entity, Model model) {
    return Map<String, dynamic>.from(entity.toJson(model));
  }

  Future<List<Model>>
  _decodeSnapshot<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
    fs.QuerySnapshot<Map<String, dynamic>> snapshot,
  ) async {
    return [
      for (final fs.QueryDocumentSnapshot<Map<String, dynamic>> document
          in snapshot.docs)
        entity.fromJson(_id<I>(document.id), document.data()),
    ];
  }

  Query _query<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
    BaseFilter<Query> filter,
    QueryOptions options, {
    int? limit,
  }) {
    Query result = filter.accept(Query(_collection(entity)));
    for (final OrderBy order in options.orderBy) {
      result = result.sorted(
        order.field.columnName,
        ascending: order.direction == SortDirection.ascending,
      );
    }
    final int? requestedLimit = limit ?? options.limit;
    if (requestedLimit != null) result = result.limit(requestedLimit);
    return result;
  }

  Future<void> _commitDeletes(
    Iterable<fs.DocumentReference<Map<String, dynamic>>> references,
  ) async {
    final List<fs.DocumentReference<Map<String, dynamic>>> values = references
        .toList();
    if (values.length > _maxBatchWrites) {
      throw ArgumentError.value(
        values.length,
        'references',
        'Firestore batch operations support at most $_maxBatchWrites writes.',
      );
    }
    if (values.isEmpty) return;
    final fs.WriteBatch batch = firestore.batch();
    for (final fs.DocumentReference<Map<String, dynamic>> reference in values) {
      batch.delete(reference);
    }
    await batch.commit();
  }

  ResolvedCreation<Data, I> _resolveCreation<
    Data,
    Model extends Data,
    I extends Object,
    C extends Creation<Data, I>
  >(Entity<Data, Model, I, C> entity, C creation, String generatedId) {
    return switch (creation) {
      AutoCreation<Data, I>() => () {
        if (entity.schema.isCompositePrimaryKey ||
            entity.identityGeneration != IdentityGenerationStrategy.engine) {
          throw UnsupportedError(
            'Firestore creation requires an explicit identity for this entity.',
          );
        }
        return ResolvedCreation(
          dependency: creation.dependency,
          data: creation.data,
          id: generatedId as I,
          identitySource: CreationIdentitySource.generated,
        );
      }(),
      ExplicitCreation<Data, I>(:final identity) => () {
        _key(identity);
        final List<Object?> values;
        try {
          values = entity.primaryKeyCodec.encode(identity);
        } catch (_) {
          throw ArgumentError.value(
            identity,
            'identity',
            'Identity cannot be encoded for this schema.',
          );
        }
        if (values.length != entity.schema.primaryKeys.length) {
          throw ArgumentError.value(
            identity,
            'identity',
            'Identity has ${values.length} values, but the schema requires '
                '${entity.schema.primaryKeys.length}.',
          );
        }
        return ResolvedCreation(
          dependency: creation.dependency,
          data: creation.data,
          id: identity,
          identitySource: CreationIdentitySource.explicit,
        );
      }(),
    };
  }

  @override
  Future<Model?> peek<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
    I id,
  ) async {
    final fs.DocumentSnapshot<Map<String, dynamic>> snapshot =
        await _collection(entity).doc(_key(id)).get();
    if (!snapshot.exists) return null;
    return entity.fromJson(id, snapshot.data() ?? const {});
  }

  @override
  Future<List<Model>> peekAll<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
    BaseFilter<Query> filter, [
    QueryOptions options = const QueryOptions(),
  ]) async {
    final Query query = _query(
      entity,
      filter,
      options,
      limit: options.limit == null ? null : options.limit! + options.offset,
    );
    final List<Model> models = await _decodeSnapshot(
      entity,
      await query.query.get(),
    );
    return models
        .skip(options.offset)
        .take(options.limit ?? models.length)
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
    final fs.QuerySnapshot<Map<String, dynamic>> snapshot = await _collection(
      entity,
    ).get();
    return [for (final document in snapshot.docs) _id<I>(document.id)];
  }

  @override
  Future<void> pop<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
    I id,
  ) => _collection(entity).doc(_key(id)).delete();

  @override
  Future<void> popKeys<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
    Iterable<I> ids,
  ) {
    final Set<String> keys = ids.map(_key).toSet();
    return _commitDeletes(keys.map(_collection(entity).doc));
  }

  @override
  Future<void> popAll<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
    BaseFilter<Query> filter,
  ) async {
    final Query query = filter.accept(Query(_collection(entity)));
    final fs.QuerySnapshot<Map<String, dynamic>> snapshot = await query.query
        .get();
    await _commitDeletes(snapshot.docs.map((document) => document.reference));
  }

  @override
  Future<void> patch<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
    I id,
    Model? Function(Model?) update,
  ) async {
    final fs.DocumentReference<Map<String, dynamic>> reference = _collection(
      entity,
    ).doc(_key(id));
    await firestore.runTransaction((transaction) async {
      final fs.DocumentSnapshot<Map<String, dynamic>> snapshot =
          await transaction.get(reference);
      final Model? model = snapshot.exists
          ? entity.fromJson(id, snapshot.data() ?? const {})
          : null;
      final Model? updated = update(model);
      if (updated == null) {
        transaction.delete(reference);
      } else {
        transaction.set(reference, _json(entity, updated));
      }
    });
  }

  @override
  Stream<Model?> pull<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
    I id,
  ) {
    return _collection(entity).doc(_key(id)).snapshots().map((snapshot) {
      if (!snapshot.exists) return null;
      return entity.fromJson(id, snapshot.data() ?? const {});
    });
  }

  @override
  Stream<List<Model>> pullAll<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
    BaseFilter<Query> filter, [
    QueryOptions options = const QueryOptions(),
  ]) {
    final Query query = _query(
      entity,
      filter,
      options,
      limit: options.limit == null ? null : options.limit! + options.offset,
    );
    return query.query.snapshots().asyncMap((snapshot) async {
      final List<Model> models = await _decodeSnapshot(entity, snapshot);
      return models
          .skip(options.offset)
          .take(options.limit ?? models.length)
          .toList();
    });
  }

  @override
  Future<void> push<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
    Model model,
  ) {
    return _collection(
      entity,
    ).doc(_key(entity.identify(model))).set(_json(entity, model));
  }

  @override
  Future<void> pushAll<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
    List<Model> models,
  ) async {
    if (models.length > _maxBatchWrites) {
      throw ArgumentError.value(
        models.length,
        'models',
        'Firestore batch operations support at most $_maxBatchWrites writes.',
      );
    }
    if (models.isEmpty) return;
    final fs.WriteBatch batch = firestore.batch();
    for (final Model model in models) {
      batch.set(
        _collection(entity).doc(_key(entity.identify(model))),
        _json(entity, model),
      );
    }
    await batch.commit();
  }

  @override
  Future<Model> put<
    Data,
    Model extends Data,
    I extends Object,
    C extends Creation<Data, I>
  >(Entity<Data, Model, I, C> entity, C creation) async {
    final fs.DocumentReference<Map<String, dynamic>> reference = _collection(
      entity,
    ).doc();
    final ResolvedCreation<Data, I> resolved = _resolveCreation(
      entity,
      creation,
      reference.id,
    );
    final Model model = entity.fromData(resolved);
    await reference.set(_json(entity, model));
    return model;
  }

  @override
  Future<List<Model>> putAll<
    Data,
    Model extends Data,
    I extends Object,
    C extends Creation<Data, I>
  >(Entity<Data, Model, I, C> entity, List<C> creations) async {
    if (creations.length > _maxBatchWrites) {
      throw ArgumentError.value(
        creations.length,
        'creations',
        'Firestore batch operations support at most $_maxBatchWrites writes.',
      );
    }
    if (creations.isEmpty) return [];
    final List<(fs.DocumentReference<Map<String, dynamic>>, Model)> values = [];
    for (final C creation in creations) {
      final fs.DocumentReference<Map<String, dynamic>> reference = _collection(
        entity,
      ).doc();
      final ResolvedCreation<Data, I> resolved = _resolveCreation(
        entity,
        creation,
        reference.id,
      );
      values.add((reference, entity.fromData(resolved)));
    }
    final fs.WriteBatch batch = firestore.batch();
    for (final (reference, model) in values) {
      batch.set(reference, _json(entity, model));
    }
    await batch.commit();
    return [for (final (_, model) in values) model];
  }

  @override
  Future<void> purge<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
  ) async {
    final fs.QuerySnapshot<Map<String, dynamic>> snapshot = await _collection(
      entity,
    ).get();
    await _commitDeletes(snapshot.docs.map((document) => document.reference));
  }
}
