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
import 'package:sqlite3/sqlite3.dart';
import 'package:sqlite_async/sqlite_async.dart' hide quoteIdentifier;
import 'package:uuid/uuid.dart';

import 'query.dart';
import 'sql.dart';

const Uuid _uuid = Uuid();

String _keyPredicate(EntitySchema schema) => schema.primaryKeys
    .map((field) => '${quoteIdentifier(field.columnName)} = ?')
    .join(' AND ');

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
  return [for (final Object? value in values) sqliteValue(value)];
}

class _Statement {
  final String sql;
  final List<Object?> params;

  const _Statement(this.sql, this.params);
}

class Reference implements BaseReference<Query, OffsetPageRequest> {
  final SqliteDatabase database;
  final SqliteWriteContext? transaction;
  final Map<String, Future<Set<String>>> _booleanColumns = {};

  Reference(this.database, {this.transaction});

  Future<T> _read<T>(Future<T> Function(SqliteReadContext context) action) {
    final SqliteWriteContext? tx = transaction;
    return tx == null ? action(database) : action(tx);
  }

  Future<T> _write<T>(Future<T> Function(SqliteWriteContext context) action) {
    final SqliteWriteContext? tx = transaction;
    return tx == null ? action(database) : action(tx);
  }

  Future<T> _writeTransaction<T>(
    Future<T> Function(SqliteWriteContext context) action,
  ) {
    final SqliteWriteContext? tx = transaction;
    return tx == null ? database.writeTransaction(action) : action(tx);
  }

  Future<Model?> _peek<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
    I id,
    SqliteReadContext context,
  ) async {
    final ResultSet result = await context.getAll(
      'SELECT * FROM ${quoteIdentifier(entity.schema.tableName)} '
      'WHERE ${_keyPredicate(entity.schema)}',
      _keyValues(entity, id),
    );
    if (result.isEmpty) return null;
    return entity.fromJson(
      id,
      decodeRow(
        entity.schema,
        rowMap(result.first),
        await _booleanFields(context, entity.schema.tableName),
      ),
    );
  }

  Future<Set<String>> _booleanFields(
    SqliteReadContext context,
    String tableName,
  ) => _booleanColumns.putIfAbsent(tableName, () async {
    final ResultSet result = await context.getAll(
      'PRAGMA table_info(${quoteIdentifier(tableName)})',
    );
    return {
      for (final Row row in result)
        if ('${row['type']}'.toUpperCase() == 'BOOLEAN') '${row['name']}',
    };
  });

  _Statement _insert<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
    Model model, {
    required bool upsert,
  }) {
    final Map<String, Object?> json = entity.toJson(model);
    final List<FieldSchema> keys = entity.schema.primaryKeys;
    final List<Object?> keyValues = _keyValues(entity, entity.identify(model));
    final Set<String> keyNames = {
      for (final FieldSchema field in keys) field.columnName,
    };
    final Map<String, Object?> data = {
      for (final MapEntry<String, Object?> entry in json.entries)
        if (!keyNames.contains(entry.key)) entry.key: sqliteValue(entry.value),
    };
    final List<String> columns = [
      ...keys.map((field) => field.columnName),
      ...data.keys,
    ];
    final List<Object?> params = [...keyValues, ...data.values];
    final String sql =
        (StringBuffer()
              ..write(
                'INSERT INTO ${quoteIdentifier(entity.schema.tableName)} (',
              )
              ..write(columns.map(quoteIdentifier).join(', '))
              ..write(') VALUES (')
              ..write(List.filled(columns.length, '?').join(', '))
              ..write(')')
              ..write(
                upsert
                    ? ' ON CONFLICT (${keys.map((field) => quoteIdentifier(field.columnName)).join(', ')}) '
                    : '',
              )
              ..write(
                upsert
                    ? data.isEmpty
                          ? 'DO NOTHING'
                          : 'DO UPDATE SET ${data.keys.map((column) => '${quoteIdentifier(column)} = excluded.${quoteIdentifier(column)}').join(', ')}'
                    : '',
              ))
            .toString();
    return _Statement(sql, params);
  }

  _Statement _insertData<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
    Data value,
  ) {
    final Map<String, Object?> json = entity.toJson(value);
    final Set<String> primaryKeyNames = {
      for (final FieldSchema field in entity.schema.primaryKeys)
        field.columnName,
    };
    final Map<String, Object?> data = {
      for (final MapEntry<String, Object?> entry in json.entries)
        if (!primaryKeyNames.contains(entry.key))
          entry.key: sqliteValue(entry.value),
    };
    final List<String> columns = data.keys.toList();
    final String sql = columns.isEmpty
        ? 'INSERT INTO ${quoteIdentifier(entity.schema.tableName)} '
              'DEFAULT VALUES'
        : 'INSERT INTO ${quoteIdentifier(entity.schema.tableName)} '
              '(${columns.map(quoteIdentifier).join(', ')}) '
              'VALUES (${List.filled(columns.length, '?').join(', ')})';
    return _Statement(sql, data.values.toList());
  }

  @override
  Future<Model?> peek<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
    I id,
  ) => _read((context) => _peek(entity, id, context));

  @override
  Future<List<Model>> peekAll<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
    BaseFilter<Query> filter, [
    QueryOptions options = const QueryOptions(),
  ]) => _read((context) async {
    final Query query = options.apply(
      filter.accept(
        Query(
          'SELECT * FROM ${quoteIdentifier(entity.schema.tableName)}',
          schema: entity.schema,
        ),
      ),
    );
    final ResultSet result = await context.getAll(query.query, query.params);
    final Set<String> booleanColumns = await _booleanFields(
      context,
      entity.schema.tableName,
    );
    return result.map((row) {
      final Map<String, Object?> data = decodeRow(
        entity.schema,
        rowMap(row),
        booleanColumns,
      );
      final I id = entity.primaryKeyCodec.decode(
        entity.schema.primaryKeys.map((field) => data[field.columnName]),
      );
      return entity.fromJson(id, data);
    }).toList();
  });

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
  ) => _read((context) async {
    final String columns = entity.schema.primaryKeys
        .map((field) => quoteIdentifier(field.columnName))
        .join(', ');
    final ResultSet result = await context.getAll(
      'SELECT $columns FROM ${quoteIdentifier(entity.schema.tableName)}',
    );
    return result.map((row) {
      final Map<String, Object?> data = rowMap(row);
      return entity.primaryKeyCodec.decode(
        entity.schema.primaryKeys.map((field) => data[field.columnName]),
      );
    }).toList();
  });

  @override
  Future<void> pop<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
    I id,
  ) => _write((context) async {
    await context.execute(
      'DELETE FROM ${quoteIdentifier(entity.schema.tableName)} '
      'WHERE ${_keyPredicate(entity.schema)}',
      _keyValues(entity, id),
    );
  });

  @override
  Future<void> popKeys<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
    Iterable<I> ids,
  ) {
    final List<I> keys = ids.toList();
    if (keys.isEmpty) return Future.value();
    final List<String> predicates = [];
    final List<Object?> params = [];
    for (final I id in keys) {
      predicates.add('(${_keyPredicate(entity.schema)})');
      params.addAll(_keyValues(entity, id));
    }
    return _write((context) async {
      await context.execute(
        'DELETE FROM ${quoteIdentifier(entity.schema.tableName)} '
        'WHERE ${predicates.join(' OR ')}',
        params,
      );
    });
  }

  @override
  Future<void> push<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
    Model model,
  ) => _write((context) async {
    final _Statement statement = _insert(entity, model, upsert: true);
    await context.execute(statement.sql, statement.params);
  });

  @override
  Future<void> pushAll<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
    List<Model> models,
  ) => _writeTransaction((context) async {
    for (final Model model in models) {
      final _Statement statement = _insert(entity, model, upsert: true);
      await context.execute(statement.sql, statement.params);
    }
  });

  @override
  Future<void> popAll<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
    BaseFilter<Query> filter,
  ) => _write((context) async {
    final Query query = filter.accept(
      Query(
        'DELETE FROM ${quoteIdentifier(entity.schema.tableName)}',
        schema: entity.schema,
      ),
    );
    await context.execute(query.query, query.params);
  });

  @override
  Future<void> patch<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
    I id,
    Model? Function(Model?) update,
  ) => _writeTransaction((context) async {
    final Model? existing = await _peek(entity, id, context);
    final Model? updated = update(existing);
    if (updated == null) {
      await context.execute(
        'DELETE FROM ${quoteIdentifier(entity.schema.tableName)} '
        'WHERE ${_keyPredicate(entity.schema)}',
        _keyValues(entity, id),
      );
      return;
    }
    final _Statement statement = _insert(entity, updated, upsert: true);
    await context.execute(statement.sql, statement.params);
  });

  @override
  Future<Model> put<
    Data,
    Model extends Data,
    I extends Object,
    C extends Creation<Data, I>
  >(Entity<Data, Model, I, C> entity, C creation) async {
    if (creation case AutoCreation<Data, I>()) {
      if (entity.identityGeneration == IdentityGenerationStrategy.database) {
        return _writeTransaction((context) {
          return _putDatabaseGenerated(entity, creation, context);
        });
      }
    }
    final ResolvedCreation<Data, I> resolved = _resolveCreation(
      entity,
      creation,
    );
    final Model model = entity.fromData(resolved);
    await _write((context) async {
      final _Statement statement = _insert(entity, model, upsert: false);
      await context.execute(statement.sql, statement.params);
    });
    return model;
  }

  Future<Model> _putDatabaseGenerated<
    Data,
    Model extends Data,
    I extends Object,
    C extends Creation<Data, I>
  >(
    Entity<Data, Model, I, C> entity,
    C creation,
    SqliteWriteContext context,
  ) async {
    if (entity.schema.isCompositePrimaryKey ||
        entity.identityGeneration != IdentityGenerationStrategy.database) {
      throw UnsupportedError(
        'SQLite database-generated identities require a supported '
        'single-key entity.',
      );
    }
    final _Statement statement = _insertData(entity, creation.data);
    await context.execute(statement.sql, statement.params);
    final Row row = await context.get('SELECT last_insert_rowid() AS id');
    final I id = entity.primaryKeyCodec.decode([row['id']]);
    _validateIdentity(entity, id);
    return entity.fromData(
      ResolvedCreation(
        dependency: creation.dependency,
        data: creation.data,
        id: id,
        identitySource: CreationIdentitySource.database,
      ),
    );
  }

  @override
  Future<List<Model>> putAll<
    Data,
    Model extends Data,
    I extends Object,
    C extends Creation<Data, I>
  >(Entity<Data, Model, I, C> entity, List<C> creations) => _writeTransaction((
    context,
  ) async {
    final List<Model> models = [];
    for (final C creation in creations) {
      if (creation case AutoCreation<Data, I>()) {
        if (entity.identityGeneration == IdentityGenerationStrategy.database) {
          models.add(await _putDatabaseGenerated(entity, creation, context));
          continue;
        }
      }
      final ResolvedCreation<Data, I> resolved = _resolveCreation(
        entity,
        creation,
      );
      final Model model = entity.fromData(resolved);
      final _Statement statement = _insert(entity, model, upsert: false);
      await context.execute(statement.sql, statement.params);
      models.add(model);
    }
    return models;
  });

  ResolvedCreation<Data, I> _resolveCreation<
    Data,
    Model extends Data,
    I extends Object,
    C extends Creation<Data, I>
  >(Entity<Data, Model, I, C> entity, C creation) {
    return switch (creation) {
      AutoCreation<Data, I>() => _resolveAuto(entity, creation),
      ExplicitCreation<Data, I>(:final identity) => () {
        _validateIdentity(entity, identity);
        return ResolvedCreation(
          dependency: creation.dependency,
          data: creation.data,
          id: identity,
          identitySource: CreationIdentitySource.explicit,
        );
      }(),
    };
  }

  ResolvedCreation<Data, I>
  _resolveAuto<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
    Creation<Data, I> creation,
  ) {
    if (entity.schema.isCompositePrimaryKey ||
        entity.identityGeneration != IdentityGenerationStrategy.engine) {
      throw UnsupportedError(
        'SQLite creation requires an explicit identity for this entity.',
      );
    }
    return ResolvedCreation(
      dependency: creation.dependency,
      data: creation.data,
      id: _uuid.v4() as I,
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
  ) => _write((context) async {
    await context.execute(
      'DELETE FROM ${quoteIdentifier(entity.schema.tableName)}',
    );
  });

  @override
  Stream<Model?> pull<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
    I id,
  ) {
    if (transaction != null) {
      throw UnsupportedError('Streams are not available in a transaction.');
    }
    final String sql =
        'SELECT * FROM ${quoteIdentifier(entity.schema.tableName)} '
        'WHERE ${_keyPredicate(entity.schema)}';
    final List<Object?> params = _keyValues(entity, id);
    return database
        .watch(
          sql,
          parameters: params,
          triggerOnTables: [entity.schema.tableName],
        )
        .asyncMap((result) async {
          if (result.isEmpty) return null;
          return entity.fromJson(
            id,
            decodeRow(
              entity.schema,
              rowMap(result.first),
              await _booleanFields(database, entity.schema.tableName),
            ),
          );
        });
  }

  @override
  Stream<List<Model>> pullAll<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
    BaseFilter<Query> filter, [
    QueryOptions options = const QueryOptions(),
  ]) {
    if (transaction != null) {
      throw UnsupportedError('Streams are not available in a transaction.');
    }
    final Query query = options.apply(
      filter.accept(
        Query(
          'SELECT * FROM ${quoteIdentifier(entity.schema.tableName)}',
          schema: entity.schema,
        ),
      ),
    );
    return database
        .watch(
          query.query,
          parameters: query.params,
          triggerOnTables: [entity.schema.tableName],
        )
        .asyncMap((result) async {
          final Set<String> booleanColumns = await _booleanFields(
            database,
            entity.schema.tableName,
          );
          return [
            for (final Row row in result)
              _decodeModel(entity, row, booleanColumns),
          ];
        });
  }

  Model _decodeModel<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
    Row row,
    Set<String> booleanColumns,
  ) {
    final Map<String, Object?> data = decodeRow(
      entity.schema,
      rowMap(row),
      booleanColumns,
    );
    final I id = entity.primaryKeyCodec.decode(
      entity.schema.primaryKeys.map((field) => data[field.columnName]),
    );
    return entity.fromJson(id, data);
  }
}
