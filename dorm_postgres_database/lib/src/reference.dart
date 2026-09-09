import 'dart:convert';

import 'package:dorm_framework/dorm_framework.dart';
import 'package:postgres/postgres.dart';
import 'package:uuid/uuid.dart';

import 'query.dart';

String _keyPredicate(EntitySchema schema, {String prefix = 'id'}) {
  final List<FieldSchema> fields = schema.primaryKeys;
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
  Entity<Data, Model, I, Creation<Data, I>> entity,
  I id, {
  String prefix = 'id',
}) {
  final List<Object?> values = entity.primaryKeyCodec.encode(id);
  final List<FieldSchema> fields = entity.schema.primaryKeys;
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

Map<String, Object?> _decodeDerived(
  EntitySchema schema,
  Map<String, Object?> json,
) {
  final Map<String, Object?> result = {...json};
  for (final DerivedFieldSchema field in schema.derivedFields) {
    if (field.path.length == 1) continue;
    final Object? value = result[field.storageName];
    if (value is String) result[field.storageName] = jsonDecode(value);
  }
  return result;
}

Map<String, Object?> _row(EntitySchema schema, ResultRow row) =>
    _decodeDerived(schema, row.toColumnMap());

Map<String, Object?> _encodeDerived(
  EntitySchema schema,
  Map<String, Object?> json,
) {
  final Map<String, Object?> result = {...json};
  for (final DerivedFieldSchema field in schema.derivedFields) {
    if (field.path.length == 1) continue;
    final Object? value = result[field.storageName];
    if (value is Map) result[field.storageName] = jsonEncode(value);
  }
  return result;
}

class Reference implements BaseReference<Query, OffsetPageRequest> {
  final SessionExecutor executor;
  final Session? session;

  const Reference(this.executor, {this.session});

  Future<T> _run<T>(Future<T> Function(Session session) action) {
    if (session case final Session transactionSession) {
      return action(transactionSession);
    }
    return executor.run(action);
  }

  Future<T> _runTx<T>(Future<T> Function(Session session) action) {
    if (session case final Session transactionSession) {
      return action(transactionSession);
    }
    return executor.runTx(action);
  }

  Future<Model?> _peek<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
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
    return entity.fromJson(id, _row(entity.schema, row));
  }

  Future<Result> _insert<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
    Data value, {
    I? identity,
    required Session session,
    required bool upsert,
    bool databaseGenerated = false,
  }) async {
    if (databaseGenerated &&
        (entity.schema.isCompositePrimaryKey ||
            entity.identityGeneration != IdentityGenerationStrategy.database)) {
      throw UnsupportedError(
        'PostgreSQL database-generated identities require a supported '
        'single-key entity.',
      );
    }
    final Map<String, Object?> json = _encodeDerived(
      entity.schema,
      entity.toJson(value),
    );
    final List<FieldSchema> primaryKeys = entity.schema.primaryKeys;
    final List<Object?> keyValues = identity == null
        ? const []
        : entity.primaryKeyCodec.encode(identity);
    if (identity == null && !databaseGenerated) {
      throw StateError('An identity is required for this PostgreSQL insert.');
    }
    if (identity != null && keyValues.length != primaryKeys.length) {
      throw StateError('Primary-key codec returned an invalid value count.');
    }
    final Set<String> keyNames = {
      for (final FieldSchema field in primaryKeys) field.columnName,
    };
    final Map<String, Object?> data = {
      for (final MapEntry<String, Object?> entry in json.entries)
        if (!keyNames.contains(entry.key)) entry.key: entry.value,
    };
    final List<String> columns = identity == null
        ? data.keys.toList()
        : [...primaryKeys.map((field) => field.columnName), ...data.keys];
    final Map<String, Object?> params = {
      for (int i = 0; i < keyValues.length; i++) 'key$i': keyValues[i],
      for (int i = 0; i < data.length; i++) 'value$i': data.values.elementAt(i),
    };
    final List<String> values = identity == null
        ? [for (int i = 0; i < data.length; i++) '@value$i']
        : [
            for (int i = 0; i < keyValues.length; i++) '@key$i',
            for (int i = 0; i < data.length; i++) '@value$i',
          ];
    final StringBuffer sql = StringBuffer()
      ..write('INSERT INTO ${entity.schema.tableName} ');
    if (columns.isEmpty) {
      sql.write('DEFAULT VALUES');
    } else {
      sql
        ..write('(')
        ..write(columns.join(', '))
        ..write(') VALUES (')
        ..write(values.join(', '))
        ..write(')');
    }
    if (upsert) {
      sql
        ..write(' ON CONFLICT (')
        ..write(primaryKeys.map((field) => field.columnName).join(', '))
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
    if (databaseGenerated) {
      sql
        ..write(' RETURNING ')
        ..write(primaryKeys.map((field) => field.columnName).join(', '));
    }
    return _execute(session, '$sql', params);
  }

  @override
  Future<Model?> peek<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
    I id,
  ) {
    return _run((session) => _peek(entity, id, session: session));
  }

  @override
  Future<List<Model>> peekAll<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
    BaseFilter<Query> filter, [
    QueryOptions options = const QueryOptions(),
  ]) {
    return _run((session) async {
      final Query query = options.apply(
        filter.accept(
          Query(
            'SELECT * FROM ${entity.schema.tableName}',
            schema: entity.schema,
          ),
        ),
      );
      final Result result = await _execute(session, query.query, query.params);
      return result.map((row) {
        final Map<String, Object?> data = _row(entity.schema, row);
        final I id = entity.primaryKeyCodec.decode(
          entity.schema.primaryKeys.map((field) => data[field.columnName]),
        );
        return entity.fromJson(id, data);
      }).toList();
    });
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
  ) {
    return _run((session) async {
      final Result result = await _execute(
        session,
        'SELECT ${entity.schema.primaryKeys.map((field) => field.columnName).join(', ')} '
        'FROM ${entity.schema.tableName}',
      );
      return result.map((row) {
        final Map<String, Object?> data = _row(entity.schema, row);
        return entity.primaryKeyCodec.decode(
          entity.schema.primaryKeys.map((field) => data[field.columnName]),
        );
      }).toList();
    });
  }

  @override
  Future<void> pop<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
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
    Entity<Data, Model, I, Creation<Data, I>> entity,
    Iterable<I> ids,
  ) {
    final List<I> keys = ids.toList();
    if (keys.isEmpty) return Future.value();
    return _run((session) async {
      final List<FieldSchema> fields = entity.schema.primaryKeys;
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
    Entity<Data, Model, I, Creation<Data, I>> entity,
    BaseFilter<Query> filter,
  ) {
    return _run((session) async {
      final Query query = filter.accept(
        Query('DELETE FROM ${entity.schema.tableName}', schema: entity.schema),
      );
      await _execute(session, query.query, query.params);
    });
  }

  @override
  Future<void> push<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
    Model model,
  ) {
    return _run(
      (session) => _insert(
        entity,
        model,
        identity: entity.identify(model),
        session: session,
        upsert: true,
      ),
    );
  }

  @override
  Future<void> pushAll<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
    List<Model> models,
  ) {
    return _runTx((session) async {
      for (final Model model in models) {
        await _insert(
          entity,
          model,
          identity: entity.identify(model),
          session: session,
          upsert: true,
        );
      }
    });
  }

  @override
  Future<void> patch<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
    I id,
    Model? Function(Model?) update,
  ) {
    return _runTx((session) async {
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
        await _insert(
          entity,
          updated,
          identity: entity.identify(updated),
          session: session,
          upsert: true,
        );
      }
    });
  }

  @override
  Future<Model> put<
    Data,
    Model extends Data,
    I extends Object,
    C extends Creation<Data, I>
  >(Entity<Data, Model, I, C> entity, C creation) {
    if (creation case AutoCreation<Data, I>()) {
      if (entity.identityGeneration == IdentityGenerationStrategy.database) {
        return _run((session) async {
          final Result result = await _insert(
            entity,
            creation.data,
            session: session,
            upsert: false,
            databaseGenerated: true,
          );
          final ResolvedCreation<Data, I> resolved = _resolveDatabaseCreation(
            entity,
            creation,
            result,
          );
          return entity.fromData(resolved);
        });
      }
    }
    final ResolvedCreation<Data, I> resolved = _resolveCreation(
      entity,
      creation,
    );
    final Model model = entity.fromData(resolved);
    return _run((session) async {
      await _insert(
        entity,
        model,
        identity: entity.identify(model),
        session: session,
        upsert: false,
      );
      return model;
    });
  }

  ResolvedCreation<Data, I> _resolveCreation<
    Data,
    Model extends Data,
    I extends Object,
    C extends Creation<Data, I>
  >(Entity<Data, Model, I, C> entity, C creation) {
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
        'PostgreSQL creation requires an explicit identity for this entity.',
      );
    }
    return ResolvedCreation(
      dependency: creation.dependency,
      data: creation.data,
      id: const Uuid().v4() as I,
      identitySource: CreationIdentitySource.generated,
    );
  }

  ResolvedCreation<Data, I>
  _resolveDatabaseCreation<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
    Creation<Data, I> creation,
    Result result,
  ) {
    if (entity.schema.isCompositePrimaryKey ||
        entity.identityGeneration != IdentityGenerationStrategy.database) {
      throw UnsupportedError(
        'PostgreSQL database-generated identities require a supported '
        'single-key entity.',
      );
    }
    if (result.isEmpty) {
      throw StateError(
        'PostgreSQL did not return the database-generated identity.',
      );
    }
    final Map<String, Object?> values = result.first.toColumnMap();
    final I id = entity.primaryKeyCodec.decode([
      for (final FieldSchema field in entity.schema.primaryKeys)
        values[field.columnName],
    ]);
    _validateIdentity(entity, id);
    return ResolvedCreation(
      dependency: creation.dependency,
      data: creation.data,
      id: id,
      identitySource: CreationIdentitySource.database,
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
  Future<List<Model>> putAll<
    Data,
    Model extends Data,
    I extends Object,
    C extends Creation<Data, I>
  >(Entity<Data, Model, I, C> entity, List<C> creations) {
    return _runTx((session) async {
      final List<Model> models = [];
      for (final C creation in creations) {
        if (creation case AutoCreation<Data, I>()) {
          if (entity.identityGeneration ==
              IdentityGenerationStrategy.database) {
            final Result result = await _insert(
              entity,
              creation.data,
              session: session,
              upsert: false,
              databaseGenerated: true,
            );
            final ResolvedCreation<Data, I> resolved = _resolveDatabaseCreation(
              entity,
              creation,
              result,
            );
            models.add(entity.fromData(resolved));
            continue;
          }
        }
        final ResolvedCreation<Data, I> resolved = _resolveCreation(
          entity,
          creation,
        );
        final Model model = entity.fromData(resolved);
        await _insert(
          entity,
          model,
          identity: entity.identify(model),
          session: session,
          upsert: false,
        );
        models.add(model);
      }
      return models;
    });
  }

  @override
  Future<void> purge<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
  ) {
    return _run((session) async {
      await _execute(session, 'DELETE FROM ${entity.schema.tableName}');
    });
  }

  @override
  Stream<Model?> pull<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
    I id,
  ) async* {
    if (session != null) {
      throw UnsupportedError('Streams are not available in a transaction.');
    }
    yield await peek(entity, id);
  }

  @override
  Stream<List<Model>> pullAll<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
    BaseFilter<Query> filter, [
    QueryOptions options = const QueryOptions(),
  ]) async* {
    if (session != null) {
      throw UnsupportedError('Streams are not available in a transaction.');
    }
    yield await peekAll(entity, filter, options);
  }
}
