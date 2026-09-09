import 'package:dorm_framework/dorm_framework.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:uuid/uuid.dart';

import 'query.dart';

Map<String, dynamic> _document(Map<String, Object?> data) {
  return Map<String, dynamic>.from(data);
}

Map<String, Object?> _data(Map<String, dynamic> document) {
  return Map<String, Object?>.from(document);
}

List<Object?> _keyValues<Data, Model extends Data, I extends Object>(
  Entity<Data, Model, I, Creation<Data, I>> entity,
  I id,
) {
  final List<Object?> values = entity.primaryKeyCodec.encode(id);
  if (values.length != entity.schema.primaryKeys.length) {
    throw StateError(
      'The primary-key codec returned ${values.length} values for '
      '${entity.schema.primaryKeys.length} schema fields.',
    );
  }
  return values;
}

Map<String, Object?> _keySelector(EntitySchema schema, List<Object?> values) {
  final List<FieldSchema> fields = schema.primaryKeys;
  if (fields.length == 1) return {fields.single.columnName: values.single};
  return {
    r'$and': [
      for (int i = 0; i < fields.length; i++) {fields[i].columnName: values[i]},
    ],
  };
}

Map<String, Object?> _keysSelector(
  EntitySchema schema,
  List<List<Object?>> values,
) {
  final List<FieldSchema> fields = schema.primaryKeys;
  if (fields.length == 1) {
    return {
      fields.single.columnName: {
        r'$in': [for (final List<Object?> value in values) value.single],
      },
    };
  }
  return {
    r'$or': [
      for (final List<Object?> value in values) _keySelector(schema, value),
    ],
  };
}

Map<String, dynamic> _withIdentity<Data, Model extends Data, I extends Object>(
  Entity<Data, Model, I, Creation<Data, I>> entity,
  Model model,
) {
  final Map<String, dynamic> data = _document(entity.toJson(model));
  final List<Object?> values = _keyValues(entity, entity.identify(model));
  for (int i = 0; i < entity.schema.primaryKeys.length; i++) {
    data[entity.schema.primaryKeys[i].columnName] = values[i];
  }
  return data;
}

class Reference implements BaseReference<Query, OffsetPageRequest> {
  final Db database;

  const Reference(this.database);

  DbCollection _collection(EntitySchema schema) =>
      database.collection(schema.tableName);

  Map<String, dynamic> _selectorForId<
    Data,
    Model extends Data,
    I extends Object
  >(Entity<Data, Model, I, Creation<Data, I>> entity, I id) {
    return _document(_keySelector(entity.schema, _keyValues(entity, id)));
  }

  Future<Model?> _decodeOne<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
    Map<String, dynamic>? document,
  ) async {
    if (document == null) return null;
    final Map<String, Object?> data = _data(document);
    final I id = entity.primaryKeyCodec.decode(
      entity.schema.primaryKeys.map((field) => data[field.columnName]),
    );
    return entity.fromJson(id, data);
  }

  Future<List<Model>> _find<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
    Query query,
  ) async {
    final Stream<Map<String, dynamic>> documents = _collection(entity.schema)
        .modernFind(
          filter: _document(query.filter),
          sort: query.sort.isEmpty ? null : query.sort,
          skip: query.offsetCount,
          limit: query.limitCount,
        );
    final List<Model> models = [];
    await for (final Map<String, dynamic> document in documents) {
      final Model? model = await _decodeOne(entity, document);
      if (model != null) models.add(model);
    }
    return models;
  }

  Future<List<List<Object?>>> _findKeys<
    Data,
    Model extends Data,
    I extends Object
  >(Entity<Data, Model, I, Creation<Data, I>> entity, Query query) async {
    final Map<String, Object> projection = {
      for (final FieldSchema field in entity.schema.primaryKeys)
        field.columnName: 1,
    };
    final Stream<Map<String, dynamic>> documents = _collection(entity.schema)
        .modernFind(
          filter: _document(query.filter),
          sort: query.sort.isEmpty ? null : query.sort,
          limit: query.limitCount,
          projection: projection,
        );
    final List<List<Object?>> values = [];
    await for (final Map<String, dynamic> document in documents) {
      final Map<String, Object?> data = _data(document);
      values.add([
        for (final FieldSchema field in entity.schema.primaryKeys)
          data[field.columnName],
      ]);
    }
    return values;
  }

  @override
  Future<Model?> peek<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
    I id,
  ) async {
    final Map<String, dynamic>? document = await _collection(
      entity.schema,
    ).modernFindOne(filter: _selectorForId(entity, id));
    return _decodeOne(entity, document);
  }

  @override
  Future<List<Model>> peekAll<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
    BaseFilter<Query> filter, [
    QueryOptions options = const QueryOptions(),
  ]) {
    return _find(
      entity,
      options.apply(filter.accept(Query(schema: entity.schema))),
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
        limit: request.size + 1,
        offset: request.offset,
      ),
    );
    return Page(
      items: models.take(request.size).toList(),
      hasNext: models.length > request.size,
    );
  }

  @override
  Future<List<I>> peekAllKeys<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
  ) async {
    final List<List<Object?>> values = await _findKeys(
      entity,
      Query(schema: entity.schema),
    );
    return [
      for (final List<Object?> value in values)
        entity.primaryKeyCodec.decode(value),
    ];
  }

  @override
  Future<void> pop<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
    I id,
  ) async {
    await _collection(entity.schema).deleteOne(_selectorForId(entity, id));
  }

  @override
  Future<void> popKeys<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
    Iterable<I> ids,
  ) async {
    final List<List<Object?>> values = [
      for (final I id in ids) _keyValues(entity, id),
    ];
    if (values.isEmpty) return;
    await _collection(
      entity.schema,
    ).deleteMany(_document(_keysSelector(entity.schema, values)));
  }

  @override
  Future<void> popAll<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
    BaseFilter<Query> filter,
  ) async {
    final Query query = filter.accept(Query(schema: entity.schema));
    final DbCollection collection = _collection(entity.schema);
    if (query.limitCount == null && query.sort.isEmpty) {
      await collection.deleteMany(_document(query.filter));
      return;
    }
    final List<List<Object?>> values = await _findKeys(entity, query);
    if (values.isNotEmpty) {
      await collection.deleteMany(
        _document(_keysSelector(entity.schema, values)),
      );
    }
  }

  @override
  Future<void> push<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
    Model model,
  ) async {
    await _collection(entity.schema).replaceOne(
      _selectorForId(entity, entity.identify(model)),
      _withIdentity(entity, model),
      upsert: true,
    );
  }

  @override
  Future<void> pushAll<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
    List<Model> models,
  ) async {
    final DbCollection collection = _collection(entity.schema);
    for (final Model model in models) {
      await collection.replaceOne(
        _selectorForId(entity, entity.identify(model)),
        _withIdentity(entity, model),
        upsert: true,
      );
    }
  }

  @override
  Future<void> patch<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
    I id,
    Model? Function(Model?) update,
  ) async {
    final Model? existing = await peek(entity, id);
    final Model? updated = update(existing);
    if (updated == null) {
      await pop(entity, id);
    } else {
      await push(entity, updated);
    }
  }

  @override
  Future<Model> put<
    Data,
    Model extends Data,
    I extends Object,
    C extends Creation<Data, I>
  >(Entity<Data, Model, I, C> entity, C creation) async {
    final Model model = entity.fromData(_resolveCreation(entity, creation));
    await _collection(entity.schema).insertOne(_withIdentity(entity, model));
    return model;
  }

  @override
  Future<List<Model>> putAll<
    Data,
    Model extends Data,
    I extends Object,
    C extends Creation<Data, I>
  >(Entity<Data, Model, I, C> entity, List<C> creations) async {
    final List<Model> models = [
      for (final C creation in creations)
        entity.fromData(_resolveCreation(entity, creation)),
    ];
    if (models.isNotEmpty) {
      await _collection(entity.schema).insertMany([
        for (final Model model in models) _withIdentity(entity, model),
      ]);
    }
    return models;
  }

  ResolvedCreation<Data, I>
  _resolveCreation<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
    Creation<Data, I> creation,
  ) {
    return switch (creation) {
      AutoCreation<Data, I>() => _resolveAutoCreation(entity, creation),
      ExplicitCreation<Data, I>(:final identity) => _resolveExplicitCreation(
        entity,
        creation,
        identity,
      ),
    };
  }

  ResolvedCreation<Data, I>
  _resolveExplicitCreation<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
    Creation<Data, I> creation,
    I id,
  ) {
    _validateIdentity(entity, id);
    return ResolvedCreation(
      dependency: creation.dependency,
      data: creation.data,
      id: id,
      identitySource: CreationIdentitySource.explicit,
    );
  }

  ResolvedCreation<Data, I>
  _resolveAutoCreation<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
    Creation<Data, I> creation,
  ) {
    if (entity.schema.isCompositePrimaryKey ||
        entity.identityGeneration != IdentityGenerationStrategy.engine) {
      throw UnsupportedError(
        'MongoDB creation requires an explicit identity for this entity.',
      );
    }
    return ResolvedCreation(
      dependency: creation.dependency,
      data: creation.data,
      id: const Uuid().v4() as I,
      identitySource: CreationIdentitySource.generated,
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
  Future<void> purge<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
  ) async {
    await _collection(entity.schema).deleteMany({});
  }

  @override
  Stream<Model?> pull<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
    I id,
  ) async* {
    yield await peek(entity, id);
  }

  @override
  Stream<List<Model>> pullAll<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
    BaseFilter<Query> filter, [
    QueryOptions options = const QueryOptions(),
  ]) async* {
    yield await peekAll(entity, filter, options);
  }
}
