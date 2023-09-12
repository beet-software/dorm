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
import 'package:mysql_client/mysql_client.dart';
import 'package:uuid/uuid.dart';

/// A [BaseReference] that uses MySQL as engine.
class Reference implements BaseReference {
  final MySQLConnection connection;

  const Reference(this.connection);

  @override
  Future<void> patch<Data, Model extends Data>(
    Entity<Data, Model> entity,
    String id,
    Model? Function(Model?) update,
  ) {
    return connection.transactional((connection) async {
      final Model? existingModel =
          await peek<Data, Model>(entity, id, connection: connection);
      final Model? updatedModel = update(existingModel);
      if (updatedModel == null) {
        await pop<Data, Model>(entity, id, connection: connection);
      } else {
        await push<Data, Model>(entity, updatedModel, connection: connection);
      }
    });
  }

  @override
  Future<Model?> peek<Data, Model extends Data>(
    Entity<Data, Model> entity,
    String id, {
    MySQLConnection? connection,
  }) {
    connection ??= this.connection;

    final StringBuffer buffer = StringBuffer()
      ..write('SELECT * FROM ')
      ..write(entity.tableName)
      ..write(' WHERE id = :id;');

    return connection
        .execute('$buffer', {'id': id})
        .then((result) => result.rows.firstOrNull)
        .then((row) =>
            row == null ? null : entity.fromJson(id, row.typedAssoc()));
  }

  @override
  Future<List<Model>> peekAll<Data, Model extends Data>(
    Entity<Data, Model> entity,
    Filter filter,
  ) {
    final StringBuffer buffer = StringBuffer()
      ..write('SELECT * FROM ')
      ..write(entity.tableName)
      ..write(';');

    return connection.execute('$buffer').then((result) => result.rows
        .map((row) => row.typedAssoc())
        .map((json) => entity.fromJson(json['id'], json))
        .toList());
  }

  @override
  Future<List<String>> peekAllKeys<Data, Model extends Data>(
    Entity<Data, Model> entity,
  ) {
    final StringBuffer buffer = StringBuffer()
      ..write('SELECT id FROM ')
      ..write(entity.tableName)
      ..write(';');

    return connection.execute('$buffer').then((result) =>
        result.rows.map((row) => row.typedAssoc()['id'] as String).toList());
  }

  @override
  Future<void> pop<Data, Model extends Data>(
    Entity<Data, Model> entity,
    String id, {
    MySQLConnection? connection,
  }) {
    connection ??= this.connection;

    final StringBuffer buffer = StringBuffer()
      ..write('DELETE FROM ')
      ..write(entity.tableName)
      ..write(' WHERE id = :id;');

    return connection.execute('$buffer', {'id': id});
  }

  @override
  Future<void> popAll<Data, Model extends Data>(
    Entity<Data, Model> entity,
    Filter filter,
  ) {
    // TODO: implement popAll
    throw UnimplementedError();
  }

  @override
  Future<void> popKeys<Data, Model extends Data>(
    Entity<Data, Model> entity,
    Iterable<String> ids,
  ) {
    final StringBuffer buffer = StringBuffer();
    final List<String> keys = ids.toList();
    for (int i = 0; i < keys.length; i++) {
      buffer
        ..write('DELETE FROM ')
        ..write(entity.tableName)
        ..writeln(' WHERE id = :id$i;');
    }
    return connection.execute('$buffer', {
      for (int i = 0; i < keys.length; i++) 'id$i': keys[i],
    });
  }

  @override
  Stream<Model?> pull<Data, Model extends Data>(
    Entity<Data, Model> entity,
    String id,
  ) {
    // TODO: implement pull
    throw UnimplementedError();
  }

  @override
  Stream<List<Model>> pullAll<Data, Model extends Data>(
    Entity<Data, Model> entity,
    Filter filter,
  ) {
    // TODO: implement pullAll
    throw UnimplementedError();
  }

  @override
  Future<void> purge<Data, Model extends Data>(
    Entity<Data, Model> entity, {
    MySQLConnection? connection,
  }) {
    connection ??= this.connection;
    final StringBuffer buffer = StringBuffer()
      ..write('DELETE FROM ')
      ..write(entity.tableName)
      ..write(';');

    return connection.execute('$buffer');
  }

  @override
  Future<void> push<Data, Model extends Data>(
    Entity<Data, Model> entity,
    Model model, {
    MySQLConnection? connection,
  }) {
    connection ??= this.connection;
    final StringBuffer buffer = StringBuffer();
    final Map<String, Object?>? params =
        _QueryBuilder(entity).push(buffer, model, replace: true);
    return connection.execute('$buffer', params);
  }

  @override
  Future<void> pushAll<Data, Model extends Data>(
    Entity<Data, Model> entity,
    List<Model> models,
  ) {
    // TODO
    throw UnimplementedError();
  }

  @override
  Future<Model> put<Data, Model extends Data>(
    Entity<Data, Model> entity,
    Dependency<Data> dependency,
    Data data,
  ) {
    final String id = const Uuid().v4();
    final Model model = entity.fromData(dependency, id, data);
    final StringBuffer buffer = StringBuffer();
    final Map<String, Object?>? params =
        _QueryBuilder(entity).push(buffer, model, replace: false);
    return connection.execute('$buffer', params).then((_) => model);
  }

  @override
  Future<List<Model>> putAll<Data, Model extends Data>(
    Entity<Data, Model> entity,
    Dependency<Data> dependency,
    List<Data> datum,
  ) {
    // TODO: implement putAll
    throw UnimplementedError();
  }
}

class _QueryBuilder<Data, Model extends Data> {
  final Entity<Data, Model> entity;

  const _QueryBuilder(this.entity);

  Map<String, Object?>? push(
    StringBuffer buffer,
    Model model, {
    bool replace = true,
  }) {
    final Map<String, Object?> json = entity.toJson(model);
    final List<String> columns = json.keys.toList();
    final List<String> keys = ['id', ...columns];

    final List<MapEntry<String, Object?>> valuesParams = [
      MapEntry('val0', entity.identify(model)),
      for (int i = 0; i < columns.length; i++)
        MapEntry('val${i + 1}', json[columns[i]]),
    ];

    buffer
      ..write(replace ? 'REPLACE' : 'INSERT')
      ..write(' INTO ')
      ..write(entity.tableName)
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
