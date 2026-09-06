import 'dart:convert';

import 'package:dorm_framework/dorm_framework.dart';
import 'package:postgres/postgres.dart';

class DecodedRow {
  final Object key;
  final Object model;
  final Map<String, Object?> data;

  const DecodedRow({
    required this.key,
    required this.model,
    required this.data,
  });
}

Future<List<DecodedRow>> readRows(
  SessionExecutor executor,
  TableRelationPlanBase plan, {
  required String where,
  required Map<String, Object?> params,
}) {
  return executor.run((session) async {
    final Result result = await session.execute(
      Sql.named('SELECT * FROM ${plan.schema.tableName} WHERE $where'),
      parameters: params,
    );
    return result.map((row) {
      final Map<String, Object?> raw = row.toColumnMap();
      final Map<String, Object?> data = {...raw};
      for (final DerivedFieldSchema field in plan.schema.derivedFields) {
        if (field.path.length == 1) continue;
        final Object? value = data[field.storageName];
        if (value is String) data[field.storageName] = jsonDecode(value);
      }
      return DecodedRow(
        key: plan.decodeKey(data)!,
        model: plan.decode(data)!,
        data: data,
      );
    }).toList();
  });
}

Future<Map<Object, Object>> readByIds(
  SessionExecutor executor,
  TableRelationPlanBase plan,
  Iterable<Object> ids,
) async {
  final List<Object> values = ids.toSet().toList();
  if (values.isEmpty) return {};
  final List<FieldSchema> fields = plan.schema.keyFields;
  final Map<String, Object?> params = {};
  final String where;
  if (fields.length == 1) {
    where =
        '${fields.single.columnName} IN '
        '(${List.generate(values.length, (i) => '@relation_id_$i').join(', ')})';
    for (int i = 0; i < values.length; i++) {
      params['relation_id_$i'] = plan.encodeKey(values[i]).single;
    }
  } else {
    final List<String> tuples = [];
    for (int i = 0; i < values.length; i++) {
      final List<Object?> parts = plan.encodeKey(values[i]);
      if (parts.length != fields.length) {
        throw StateError('Primary-key codec returned an invalid value count.');
      }
      tuples.add(
        '(${List.generate(parts.length, (part) => '@relation_id_${i}_$part').join(', ')})',
      );
      for (int part = 0; part < parts.length; part++) {
        params['relation_id_${i}_$part'] = parts[part];
      }
    }
    where =
        '(${fields.map((field) => field.columnName).join(', ')}) IN '
        '(${tuples.join(', ')})';
  }
  final List<DecodedRow> rows = await readRows(
    executor,
    plan,
    where: where,
    params: params,
  );
  return {for (final DecodedRow row in rows) row.key: row.model};
}

Future<Map<Object, List<Object>>> readByForeignKey(
  SessionExecutor executor,
  TableRelationPlanBase plan,
  ForeignKeySchema field,
  Iterable<Object> values,
) async {
  final List<Object> keys = values.toSet().toList();
  if (keys.isEmpty) return {};
  final Map<String, Object?> params = {
    for (int i = 0; i < keys.length; i++) 'relation_fk_$i': keys[i],
  };
  final String placeholders = List.generate(
    keys.length,
    (i) => '@relation_fk_$i',
  ).join(', ');
  final List<DecodedRow> rows = await readRows(
    executor,
    plan,
    where: '${field.columnName} IN ($placeholders)',
    params: params,
  );
  final Map<Object, List<Object>> result = {};
  for (final DecodedRow row in rows) {
    final Object? foreignKey = row.data[field.columnName];
    if (foreignKey != null) {
      result.putIfAbsent(foreignKey, () => []).add(row.model);
    }
  }
  return result;
}
