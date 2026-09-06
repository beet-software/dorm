import 'package:dorm_framework/dorm_framework.dart';
import 'package:postgres/postgres.dart';
import 'package:uuid/uuid.dart';

import 'query.dart';

String _keyPredicate(EntitySchema schema, {String prefix = 'id'}) {
  final List<FieldSchema> fields = schema.keyFields;
  if (fields.length == 1) {
    return '${fields.single.columnName} = @$prefix';
  }
  return fields
      .asMap()
      .entries
      .map((entry) => '${entry.value.columnName} = @$prefix${entry.key}')
      .join(' AND ');
}

Map<String, Object?> _keyParameters<Data, Model extends Data, I extends Object>(
  Entity<Data, Model, I> entity,
  I id, {
  String prefix = 'id',
}) {
  final List<Object?> values = entity.primaryKeyCodec.encode(id);
  final List<FieldSchema> fields = entity.schema.keyFields;
  if (values.length != fields.length) {
    throw StateError(
      'The primary-key codec returned ${values.length} values for '
      '${fields.length} schema fields.',
    );
  }
  return {
    for (int i = 0; i < values.length; i++)
      fields.length == 1 ? prefix : '$prefix$i': values[i],
  };
}

Future<Result> _execute(
  Session session,
  String sql, [
  Map<String, Object?> params = const {},
]) {
  return session.execute(Sql.named(sql), parameters: params);
}

Map<String, Object?> _row(ResultRow row) => row.toColumnMap();

class Reference implements BaseReference<Query> {
  final SessionExecutor executor;

  const Reference(this.executor);

  Future<T> _run<T>(Future<T> Function(Session session) action) {
    return executor.run(action);
  }

  Future<Model?> _peek<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I> entity,
    I id, {
    required Session session,
  }) async {
    final Result result = await _execute(
      session,
      'SELECT * FROM ${entity.schema.tableName} '
      'WHERE ${_keyPredicate(entity.schema)}',
      _keyParameters(entity, id),
    );
    final ResultRow? row = result.isEmpty ? null : result.first;
    if (row == null) return null;
    return entity.fromJson(id, _row(row));
  }

  Future<void> _insert<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I> entity,
    Model model, {
    required Session session,
    required bool upsert,
  }) async {
    final Map<String, Object?> json = entity.toJson(model);
    final List<FieldSchema> keyFields = entity.schema.keyFields;
    final List<Object?> keyValues = entity.primaryKeyCodec.encode(
      entity.identify(model),
    );
    if (keyValues.length != keyFields.length) {
      throw StateError('Primary-key codec returned an invalid value count.');
    }
    final Set<String> keyNames = {
      for (final FieldSchema field in keyFields) field.columnName,
    };
    final Map<String, Object?> data = {
      for (final MapEntry<String, Object?> entry in json.entries)
        if (!keyNames.contains(entry.key)) entry.key: entry.value,
    };
    final List<String> columns = [
      ...keyFields.map((field) => field.columnName),
      ...data.keys,
    ];
    final Map<String, Object?> params = {
      for (int i = 0; i < keyValues.length; i++) 'key$i': keyValues[i],
      for (int i = 0; i < data.length; i++) 'value$i': data.values.elementAt(i),
    };
    final List<String> values = [
      for (int i = 0; i < keyValues.length; i++) '@key$i',
      for (int i = 0; i < data.length; i++) '@value$i',
    ];
    final StringBuffer sql = StringBuffer()
      ..write('INSERT INTO ${entity.schema.tableName} (')
      ..write(columns.join(', '))
      ..write(') VALUES (')
      ..write(values.join(', '))
      ..write(')');
    if (upsert) {
      sql
        ..write(' ON CONFLICT (')
        ..write(keyFields.map((field) => field.columnName).join(', '))
        ..write(') ');
      if (data.isEmpty) {
        sql.write('DO NOTHING');
      } else {
        sql
          ..write('DO UPDATE SET ')
          ..write(
            data.keys.map((column) => '$column = EXCLUDED.$column').join(', '),
          );
      }
    }
    await _execute(session, '$sql', params);
  }

  @override
  Future<Model?> peek<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I> entity,
    I id,
  ) {
    return _run((session) => _peek(entity, id, session: session));
  }

  @override
  Future<List<Model>> peekAll<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I> entity,
    BaseFilter<Query> filter,
  ) {
    return _run((session) async {
      final Query query = filter.accept(
        Query('SELECT * FROM ${entity.schema.tableName}'),
      );
      final Result result = await _execute(session, query.query, query.params);
      return result.map((row) {
        final Map<String, Object?> data = _row(row);
        final I id = entity.primaryKeyCodec.decode(
          entity.schema.keyFields.map((field) => data[field.columnName]),
        );
        return entity.fromJson(id, data);
      }).toList();
    });
  }

  @override
  Future<List<I>> peekAllKeys<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I> entity,
  ) {
    return _run((session) async {
      final Result result = await _execute(
        session,
        'SELECT ${entity.schema.keyFields.map((field) => field.columnName).join(', ')} '
        'FROM ${entity.schema.tableName}',
      );
      return result.map((row) {
        final Map<String, Object?> data = _row(row);
        return entity.primaryKeyCodec.decode(
          entity.schema.keyFields.map((field) => data[field.columnName]),
        );
      }).toList();
    });
  }

  @override
  Future<void> pop<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I> entity,
    I id,
  ) {
    return _run((session) async {
      await _execute(
        session,
        'DELETE FROM ${entity.schema.tableName} '
        'WHERE ${_keyPredicate(entity.schema)}',
        _keyParameters(entity, id),
      );
    });
  }

  @override
  Future<void> popKeys<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I> entity,
    Iterable<I> ids,
  ) {
    final List<I> keys = ids.toList();
    if (keys.isEmpty) return Future.value();
    return _run((session) async {
      final List<FieldSchema> fields = entity.schema.keyFields;
      final Map<String, Object?> params = {};
      final String where;
      if (fields.length == 1) {
        where =
            '${fields.single.columnName} IN '
            '(${List.generate(keys.length, (i) => '@id$i').join(', ')})';
        for (int i = 0; i < keys.length; i++) {
          params['id$i'] = entity.primaryKeyCodec.encode(keys[i]).single;
        }
      } else {
        final List<String> tuples = [];
        for (int i = 0; i < keys.length; i++) {
          final List<Object?> values = entity.primaryKeyCodec.encode(keys[i]);
          if (values.length != fields.length) {
            throw StateError(
              'Primary-key codec returned an invalid value count.',
            );
          }
          tuples.add(
            '(${List.generate(values.length, (part) => '@id${i}_$part').join(', ')})',
          );
          for (int part = 0; part < values.length; part++) {
            params['id${i}_$part'] = values[part];
          }
        }
        where =
            '(${fields.map((field) => field.columnName).join(', ')}) IN '
            '(${tuples.join(', ')})';
      }
      await _execute(
        session,
        'DELETE FROM ${entity.schema.tableName} WHERE $where',
        params,
      );
    });
  }

  @override
  Future<void> popAll<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I> entity,
    BaseFilter<Query> filter,
  ) {
    return _run((session) async {
      final Query query = filter.accept(
        Query('DELETE FROM ${entity.schema.tableName}'),
      );
      await _execute(session, query.query, query.params);
    });
  }

  @override
  Future<void> push<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I> entity,
    Model model,
  ) {
    return _run(
      (session) => _insert(entity, model, session: session, upsert: true),
    );
  }

  @override
  Future<void> pushAll<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I> entity,
    List<Model> models,
  ) {
    return executor.runTx((session) async {
      for (final Model model in models) {
        await _insert(entity, model, session: session, upsert: true);
      }
    });
  }

  @override
  Future<void> patch<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I> entity,
    I id,
    Model? Function(Model?) update,
  ) {
    return executor.runTx((session) async {
      final Model? existing = await _peek(entity, id, session: session);
      final Model? updated = update(existing);
      if (updated == null) {
        await _execute(
          session,
          'DELETE FROM ${entity.schema.tableName} '
          'WHERE ${_keyPredicate(entity.schema)}',
          _keyParameters(entity, id),
        );
      } else {
        await _insert(entity, updated, session: session, upsert: true);
      }
    });
  }

  @override
  Future<Model> put<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I> entity,
    Dependency<Data> dependency,
    Data data,
  ) {
    if (entity.schema.isCompositePrimaryKey) {
      throw UnsupportedError(
        'PostgreSQL put requires an explicitly identified model for '
        'composite primary keys; use push instead.',
      );
    }
    final I id = const Uuid().v4() as I;
    final Model model = entity.fromData(dependency, id, data);
    return _run((session) async {
      await _insert(entity, model, session: session, upsert: false);
      return model;
    });
  }

  @override
  Future<List<Model>> putAll<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I> entity,
    Dependency<Data> dependency,
    List<Data> datum,
  ) {
    return executor.runTx((session) async {
      final List<Model> models = [];
      for (final Data data in datum) {
        if (entity.schema.isCompositePrimaryKey) {
          throw UnsupportedError(
            'PostgreSQL put requires an explicitly identified model for '
            'composite primary keys; use push instead.',
          );
        }
        final I id = const Uuid().v4() as I;
        final Model model = entity.fromData(dependency, id, data);
        await _insert(entity, model, session: session, upsert: false);
        models.add(model);
      }
      return models;
    });
  }

  @override
  Future<void> purge<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I> entity,
  ) {
    return _run((session) async {
      await _execute(session, 'DELETE FROM ${entity.schema.tableName}');
    });
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
