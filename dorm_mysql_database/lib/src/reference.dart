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
import 'dart:convert';

import 'package:dorm_framework/dorm_framework.dart';
import 'package:mysql_client/mysql_client.dart';
import 'package:uuid/uuid.dart';

import 'query.dart';

String _primaryKeyPredicate(EntitySchema schema, {String prefix = 'id'}) {
  final List<FieldSchema> fields = schema.keyFields;
  if (fields.length == 1) return '${fields.single.columnName} = :$prefix';
  return fields
      .asMap()
      .entries
      .map((entry) => '${entry.value.columnName} = :$prefix${entry.key}')
      .join(' AND ');
}

Map<String, Object?> _primaryKeyParameters<
  Data,
  Model extends Data,
  I extends Object
>(Entity<Data, Model, I> entity, I id, {String prefix = 'id'}) {
  final List<Object?> values = entity.primaryKeyCodec.encode(id);
  final List<FieldSchema> fields = entity.schema.keyFields;
  if (values.length != fields.length) {
    throw StateError(
      'The primary-key codec returned ${values.length} values for '
      '${fields.length} schema fields.',
    );
  }
  final Map<String, Object?> parameters = {};
  for (int i = 0; i < values.length; i++) {
    parameters[fields.length == 1 ? prefix : '$prefix$i'] = values[i];
  }
  return parameters;
}

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

/// A [BaseReference] that uses MySQL as engine.
class Reference implements BaseReference<Query> {
  final MySQLConnection connection;

  const Reference(this.connection);

  @override
  Future<void> patch<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I> entity,
    I id,
    Model? Function(Model?) update,
  ) {
    return connection.transactional((connection) async {
      final Model? existingModel = await peek<Data, Model, I>(
        entity,
        id,
        connection: connection,
      );
      final Model? updatedModel = update(existingModel);
      if (updatedModel == null) {
        await pop<Data, Model, I>(entity, id, connection: connection);
      } else {
        await push<Data, Model, I>(
          entity,
          updatedModel,
          connection: connection,
        );
      }
    });
  }

  @override
  Future<Model?> peek<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I> entity,
    I id, {
    MySQLConnection? connection,
  }) {
    connection ??= this.connection;

    final StringBuffer buffer = StringBuffer()
      ..write('SELECT * FROM ')
      ..write(entity.schema.tableName)
      ..write(' WHERE ')
      ..write(_primaryKeyPredicate(entity.schema))
      ..write(';');

    return connection
        .execute('$buffer', _primaryKeyParameters(entity, id))
        .then((result) => result.rows.firstOrNull)
        .then(
          (row) => row == null
              ? null
              : entity.fromJson(
                  id,
                  _decodeDerived(entity.schema, row.typedAssoc()),
                ),
        );
  }

  @override
  Future<List<Model>> peekAll<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I> entity,
    BaseFilter<Query> filter,
  ) {
    final StringBuffer preBuffer = StringBuffer()
      ..write('SELECT * FROM ')
      ..write(entity.schema.tableName);

    final Query query = filter.accept(
      Query('$preBuffer', schema: entity.schema),
    );
    final StringBuffer buffer = StringBuffer()
      ..write(query.query)
      ..write(';');

    return connection
        .execute('$buffer', query.params)
        .then(
          (result) => result.rows
              .map((row) => _decodeDerived(entity.schema, row.typedAssoc()))
              .map(
                (json) => entity.fromJson(
                  entity.primaryKeyCodec.decode(
                    entity.schema.keyFields.map(
                      (field) => json[field.columnName],
                    ),
                  ),
                  json,
                ),
              )
              .toList(),
        );
  }

  @override
  Future<List<I>> peekAllKeys<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I> entity,
  ) {
    final StringBuffer buffer = StringBuffer()
      ..write('SELECT ')
      ..writeAll(entity.schema.keyFields.map((field) => field.columnName), ', ')
      ..write(' FROM ')
      ..write(entity.schema.tableName)
      ..write(';');

    return connection
        .execute('$buffer')
        .then(
          (result) => result.rows
              .map(
                (row) => entity.primaryKeyCodec.decode(
                  entity.schema.keyFields.map(
                    (field) => row.typedAssoc()[field.columnName],
                  ),
                ),
              )
              .toList(),
        );
  }

  @override
  Future<void> pop<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I> entity,
    I id, {
    MySQLConnection? connection,
  }) {
    connection ??= this.connection;

    final StringBuffer buffer = StringBuffer()
      ..write('DELETE FROM ')
      ..write(entity.schema.tableName)
      ..write(' WHERE ')
      ..write(_primaryKeyPredicate(entity.schema))
      ..write(';');

    return connection.execute('$buffer', _primaryKeyParameters(entity, id));
  }

  @override
  Future<void> popAll<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I> entity,
    BaseFilter<Query> filter,
  ) {
    final StringBuffer preBuffer = StringBuffer()
      ..write('DELETE FROM ')
      ..write(entity.schema.tableName);

    final Query query = filter.accept(
      Query('$preBuffer', schema: entity.schema),
    );
    final StringBuffer buffer = StringBuffer()
      ..write(query.query)
      ..write(';');

    return connection.execute('$buffer', query.params).then<void>((_) {});
  }

  @override
  Future<void> popKeys<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I> entity,
    Iterable<I> ids,
  ) {
    final List<I> keys = ids.toList();
    if (keys.isEmpty) return Future.value();
    final List<FieldSchema> fields = entity.schema.keyFields;
    final Map<String, Object?> params = {};
    final StringBuffer buffer = StringBuffer()
      ..write('DELETE FROM ')
      ..write(entity.schema.tableName)
      ..write(' WHERE ');
    if (fields.length == 1) {
      buffer
        ..write(fields.single.columnName)
        ..write(' IN (')
        ..writeAll(List.generate(keys.length, (i) => ':id$i'), ', ')
        ..write(');');
      params.addAll({
        for (int i = 0; i < keys.length; i++)
          'id$i': entity.primaryKeyCodec.encode(keys[i]).single,
      });
    } else {
      buffer
        ..write('(')
        ..writeAll(fields.map((field) => field.columnName), ', ')
        ..write(') IN (');
      for (int i = 0; i < keys.length; i++) {
        final List<Object?> values = entity.primaryKeyCodec.encode(keys[i]);
        if (values.length != fields.length) {
          throw StateError(
            'Primary-key codec returned an invalid value count.',
          );
        }
        if (i > 0) buffer.write(', ');
        buffer
          ..write('(')
          ..writeAll(
            List.generate(values.length, (part) => ':id${i}_$part'),
            ', ',
          )
          ..write(')');
        params.addAll({
          for (int part = 0; part < values.length; part++)
            'id${i}_$part': values[part],
        });
      }
      buffer.write(');');
    }
    return connection.execute('$buffer', params);
  }

  @override
  Stream<Model?> pull<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I> entity,
    I id,
  ) {
    // TODO: make pull realtime somehow
    final StreamController<Model?> controller = StreamController.broadcast();
    peek(entity, id).then(controller.add);
    return controller.stream;
  }

  @override
  Stream<List<Model>> pullAll<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I> entity,
    BaseFilter<Query> filter,
  ) {
    // TODO: make pullAll realtime somehow
    final StreamController<List<Model>> controller =
        StreamController.broadcast();
    peekAll(entity, filter).then(controller.add);
    return controller.stream;
  }

  @override
  Future<void> purge<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I> entity, {
    MySQLConnection? connection,
  }) {
    connection ??= this.connection;
    final StringBuffer buffer = StringBuffer()
      ..write('DELETE FROM ')
      ..write(entity.schema.tableName)
      ..write(';');

    return connection.execute('$buffer');
  }

  @override
  Future<void> push<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I> entity,
    Model model, {
    MySQLConnection? connection,
  }) {
    connection ??= this.connection;
    final StringBuffer buffer = StringBuffer();
    final Map<String, Object?>? params = _QueryBuilder(
      entity,
    ).push(buffer, model, replace: true);
    return connection.execute('$buffer', params);
  }

  @override
  Future<void> pushAll<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I> entity,
    List<Model> models,
  ) {
    return connection.transactional((connection) async {
      for (Model model in models) {
        await push<Data, Model, I>(entity, model, connection: connection);
      }
    });
  }

  @override
  Future<Model> put<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I> entity,
    Dependency<Data> dependency,
    Data data, {
    MySQLConnection? connection,
  }) {
    if (entity.schema.isCompositePrimaryKey) {
      throw UnsupportedError(
        'MySQL put requires an explicitly identified model for composite '
        'primary keys; use push instead.',
      );
    }
    final I id = const Uuid().v4() as I;
    final Model model = entity.fromData(dependency, id, data);
    final StringBuffer buffer = StringBuffer();
    final Map<String, Object?>? params = _QueryBuilder(
      entity,
    ).push(buffer, model, replace: false);
    return (connection ?? this.connection)
        .execute('$buffer', params)
        .then((_) => model);
  }

  @override
  Future<List<Model>> putAll<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I> entity,
    Dependency<Data> dependency,
    List<Data> datum,
  ) async {
    final List<Model> models = [];
    await connection.transactional((connection) async {
      for (Data data in datum) {
        models.add(await put(entity, dependency, data, connection: connection));
      }
    });
    return models;
  }
}

class _QueryBuilder<Data, Model extends Data, I extends Object> {
  final Entity<Data, Model, I> entity;

  const _QueryBuilder(this.entity);

  Map<String, Object?>? push(
    StringBuffer buffer,
    Model model, {
    bool replace = true,
  }) {
    final Map<String, Object?> json = _encodeDerived(
      entity.schema,
      entity.toJson(model),
    );
    final List<String> columns = json.keys.toList();
    final List<FieldSchema> primaryKeyFields = entity.schema.keyFields;
    final List<Object?> primaryKeyValues = entity.primaryKeyCodec.encode(
      entity.identify(model),
    );
    if (primaryKeyValues.length != primaryKeyFields.length) {
      throw StateError('Primary-key codec returned an invalid value count.');
    }
    final List<String> keys = [
      ...primaryKeyFields.map((field) => field.columnName),
      ...columns,
    ];

    final List<MapEntry<String, Object?>> valuesParams = [
      for (int i = 0; i < primaryKeyValues.length; i++)
        MapEntry('val$i', primaryKeyValues[i]),
      for (int i = 0; i < columns.length; i++)
        MapEntry('val${i + primaryKeyValues.length}', json[columns[i]]),
    ];

    buffer
      ..write(replace ? 'REPLACE' : 'INSERT')
      ..write(' INTO ')
      ..write(entity.schema.tableName)
      ..writeln(' (');
    for (int i = 0; i < keys.length; i++) {
      final String value = keys[i];
      buffer
        ..write(value)
        ..writeln(i == keys.length - 1 ? '' : ',');
    }
    buffer.writeln(') VALUES (');
    for (int i = 0; i < valuesParams.length; i++) {
      final String key = valuesParams[i].key;
      buffer
        ..write(':')
        ..write(key)
        ..writeln(i == valuesParams.length - 1 ? '' : ',');
    }
    buffer.writeln(');');
    return Map.fromEntries(valuesParams);
  }
}
