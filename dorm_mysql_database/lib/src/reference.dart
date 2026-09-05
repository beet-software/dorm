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
import 'package:mysql_client/mysql_client.dart';
import 'package:uuid/uuid.dart';

import 'query.dart';

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
      final Model? existingModel =
          await peek<Data, Model, I>(entity, id, connection: connection);
      final Model? updatedModel = update(existingModel);
      if (updatedModel == null) {
        await pop<Data, Model, I>(entity, id, connection: connection);
      } else {
        await push<Data, Model, I>(entity, updatedModel, connection: connection);
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
      ..write(' WHERE id = :id;');

    return connection
        .execute('$buffer', {'id': id})
        .then((result) => result.rows.firstOrNull)
        .then((row) =>
            row == null ? null : entity.fromJson(id, row.typedAssoc()));
  }

  @override
  Future<List<Model>> peekAll<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I> entity,
    BaseFilter<Query> filter,
  ) {
    final StringBuffer preBuffer = StringBuffer()
      ..write('SELECT * FROM ')
      ..write(entity.schema.tableName);

    final Query query = filter.accept(Query('$preBuffer'));
    final StringBuffer buffer = StringBuffer()
      ..write(query.query)
      ..write(';');

    return connection.execute('$buffer', query.params).then((result) => result
        .rows
        .map((row) => row.typedAssoc())
        .map((json) => entity.fromJson(json['id'] as I, json))
        .toList());
  }

  @override
  Future<List<I>> peekAllKeys<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I> entity,
  ) {
    final StringBuffer buffer = StringBuffer()
      ..write('SELECT id FROM ')
      ..write(entity.schema.tableName)
      ..write(';');

    return connection.execute('$buffer').then((result) =>
        result.rows.map((row) => row.typedAssoc()['id'] as I).toList());
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
      ..write(' WHERE id = :id;');

    return connection.execute('$buffer', {'id': id});
  }

  @override
  Future<void> popAll<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I> entity,
    BaseFilter<Query> filter,
  ) {
    final StringBuffer preBuffer = StringBuffer()
      ..write('DELETE FROM ')
      ..write(entity.schema.tableName);

    final Query query = filter.accept(Query('$preBuffer'));
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
    final StringBuffer buffer = StringBuffer()
      ..write('DELETE FROM ')
      ..write(entity.schema.tableName)
      ..write(' WHERE id IN (')
      ..writeAll(List.generate(keys.length, (i) => ':id$i'), ', ')
      ..write(');');
    return connection.execute('$buffer', {
      for (int i = 0; i < keys.length; i++) 'id$i': keys[i],
    });
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
    final Map<String, Object?>? params =
        _QueryBuilder(entity).push(buffer, model, replace: true);
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
    final I id = const Uuid().v4() as I;
    final Model model = entity.fromData(dependency, id, data);
    final StringBuffer buffer = StringBuffer();
    final Map<String, Object?>? params =
        _QueryBuilder(entity).push(buffer, model, replace: false);
    return (connection ?? this.connection).execute('$buffer', params).then((_) => model);
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
