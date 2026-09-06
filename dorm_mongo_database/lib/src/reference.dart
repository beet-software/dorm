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
  Entity<Data, Model, I> entity,
  I id,
) {
  final List<Object?> values = entity.primaryKeyCodec.encode(id);
  if (values.length != entity.schema.keyFields.length) {
    throw StateError(
      'The primary-key codec returned ${values.length} values for '
      '${entity.schema.keyFields.length} schema fields.',
    );
  }
  return values;
}

Map<String, Object?> _keySelector(EntitySchema schema, List<Object?> values) {
  final List<FieldSchema> fields = schema.keyFields;
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
  final List<FieldSchema> fields = schema.keyFields;
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
  Entity<Data, Model, I> entity,
  Model model,
) {
  final Map<String, dynamic> data = _document(entity.toJson(model));
  final List<Object?> values = _keyValues(entity, entity.identify(model));
  for (int i = 0; i < entity.schema.keyFields.length; i++) {
    data[entity.schema.keyFields[i].columnName] = values[i];
  }
  return data;
}

class Reference implements BaseReference<Query> {
  final Db database;

  const Reference(this.database);

  DbCollection _collection(EntitySchema schema) =>
      database.collection(schema.tableName);

  Map<String, dynamic> _selectorForId<
    Data,
    Model extends Data,
    I extends Object
  >(Entity<Data, Model, I> entity, I id) {
    return _document(_keySelector(entity.schema, _keyValues(entity, id)));
  }

  Future<Model?> _decodeOne<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I> entity,
    Map<String, dynamic>? document,
  ) async {
    if (document == null) return null;
    final Map<String, Object?> data = _data(document);
    final I id = entity.primaryKeyCodec.decode(
      entity.schema.keyFields.map((field) => data[field.columnName]),
    );
    return entity.fromJson(id, data);
  }

  Future<List<Model>> _find<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I> entity,
    Query query,
  ) async {
    final Stream<Map<String, dynamic>> documents = _collection(entity.schema)
        .modernFind(
          filter: _document(query.filter),
          sort: query.sort.isEmpty ? null : query.sort,
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
  >(Entity<Data, Model, I> entity, Query query) async {
    final Map<String, Object> projection = {
      for (final FieldSchema field in entity.schema.keyFields)
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
        for (final FieldSchema field in entity.schema.keyFields)
          data[field.columnName],
      ]);
    }
    return values;
  }

  @override
  Future<Model?> peek<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I> entity,
    I id,
  ) async {
    final Map<String, dynamic>? document = await _collection(
      entity.schema,
    ).modernFindOne(filter: _selectorForId(entity, id));
    return _decodeOne(entity, document);
  }

  @override
  Future<List<Model>> peekAll<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I> entity,
    BaseFilter<Query> filter,
  ) {
    return _find(entity, filter.accept(Query(schema: entity.schema)));
  }

  @override
  Future<List<I>> peekAllKeys<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I> entity,
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
    Entity<Data, Model, I> entity,
    I id,
  ) async {
    await _collection(entity.schema).deleteOne(_selectorForId(entity, id));
  }

  @override
  Future<void> popKeys<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I> entity,
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
    Entity<Data, Model, I> entity,
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
    Entity<Data, Model, I> entity,
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
    Entity<Data, Model, I> entity,
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
    Entity<Data, Model, I> entity,
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
  Future<Model> put<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I> entity,
    Dependency<Data> dependency,
    Data data,
  ) async {
    if (entity.schema.isCompositePrimaryKey) {
      throw UnsupportedError(
        'MongoDB put requires an explicitly identified model for composite '
        'primary keys; use push instead.',
      );
    }
    final I id = const Uuid().v4() as I;
    final Model model = entity.fromData(dependency, id, data);
    await _collection(entity.schema).insertOne(_withIdentity(entity, model));
    return model;
  }

  @override
  Future<List<Model>> putAll<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I> entity,
    Dependency<Data> dependency,
    List<Data> datum,
  ) async {
    if (entity.schema.isCompositePrimaryKey) {
      throw UnsupportedError(
        'MongoDB put requires an explicitly identified model for composite '
        'primary keys; use push instead.',
      );
    }
    final List<Model> models = [
      for (final Data data in datum)
        entity.fromData(dependency, const Uuid().v4() as I, data),
    ];
    if (models.isNotEmpty) {
      await _collection(entity.schema).insertMany([
        for (final Model model in models) _withIdentity(entity, model),
      ]);
    }
    return models;
  }

  @override
  Future<void> purge<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I> entity,
  ) async {
    await _collection(entity.schema).deleteMany({});
  }

  @override
  Stream<Model?> pull<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I> entity,
    I id,
  ) async* {
    yield await peek(entity, id);
  }

  @override
  Stream<List<Model>> pullAll<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I> entity,
    BaseFilter<Query> filter,
  ) async* {
    yield await peekAll(entity, filter);
  }
}
