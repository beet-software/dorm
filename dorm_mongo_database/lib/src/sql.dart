import 'package:dorm_framework/dorm_framework.dart';
import 'package:mongo_dart/mongo_dart.dart';

import 'query.dart';

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

TableRelationPlanBase? tablePlan<Model, I extends Object>(
  RelationSource<Model, I, Query> source,
) {
  final RelationPlan<Model, I> plan = source.plan;
  return plan is TableRelationPlanBase ? plan as TableRelationPlanBase : null;
}

Future<List<DecodedRow>> readRows(
  Db database,
  TableRelationPlanBase plan, {
  required Map<String, dynamic> filter,
}) async {
  final Stream<Map<String, dynamic>> documents = database
      .collection(plan.schema.tableName)
      .modernFind(filter: filter);
  final List<DecodedRow> rows = [];
  await for (final Map<String, dynamic> document in documents) {
    final Map<String, Object?> data = Map<String, Object?>.from(document);
    rows.add(
      DecodedRow(
        key: plan.decodeKey(data)!,
        model: plan.decode(data)!,
        data: data,
      ),
    );
  }
  return rows;
}

Future<Map<Object, Object>> readByIds(
  Db database,
  TableRelationPlanBase plan,
  Iterable<Object> ids,
) async {
  final List<Object> values = ids.toSet().toList();
  if (values.isEmpty) return {};
  final List<FieldSchema> fields = plan.schema.keyFields;
  final List<List<Object?>> encoded = [
    for (final Object id in values) plan.encodeKey(id),
  ];
  if (encoded.any((value) => value.length != fields.length)) {
    throw StateError(
      'The primary-key codec returned a different number of values than '
      'the schema key fields.',
    );
  }
  final Map<String, dynamic> filter;
  if (fields.length == 1) {
    filter = {
      fields.single.columnName: {
        r'$in': [for (final List<Object?> value in encoded) value.single],
      },
    };
  } else {
    filter = {
      r'$or': [
        for (final List<Object?> value in encoded)
          {
            for (int i = 0; i < fields.length; i++)
              fields[i].columnName: value[i],
          },
      ],
    };
  }
  final List<DecodedRow> rows = await readRows(database, plan, filter: filter);
  return {for (final DecodedRow row in rows) row.key: row.model};
}

Future<Map<Object, List<Object>>> readByForeignKey(
  Db database,
  TableRelationPlanBase plan,
  ForeignKeySchema field,
  Iterable<Object> values,
) async {
  final List<Object> keys = values.toSet().toList();
  if (keys.isEmpty) return {};
  final List<DecodedRow> rows = await readRows(
    database,
    plan,
    filter: {
      field.columnName: {r'$in': keys},
    },
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
