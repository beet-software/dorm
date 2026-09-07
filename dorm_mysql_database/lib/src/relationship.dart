import 'dart:convert';

import 'package:dorm_framework/dorm_framework.dart';
import 'package:mysql_client/mysql_client.dart';

import 'query.dart';

class _DecodedRow {
  final Object key;
  final Object model;
  final Map<String, Object?> data;

  const _DecodedRow({
    required this.key,
    required this.model,
    required this.data,
  });
}

TableRelationPlanBase? _tablePlan<Model, I extends Object>(
  RelationSource<Model, I, Query> source,
) {
  final RelationPlan<Model, I> plan = source.plan;
  if (plan is TableRelationPlanBase) return plan as TableRelationPlanBase;
  return null;
}

Future<List<_DecodedRow>> _readRows(
  MySQLConnection connection,
  TableRelationPlanBase plan, {
  required String where,
  required Map<String, Object?> params,
}) async {
  final IResultSet result = await connection.execute(
    'SELECT * FROM ${plan.schema.tableName} WHERE $where;',
    params,
  );
  return result.rows.map((row) {
    final Map<String, Object?> data = _decodeDerived(
      plan.schema,
      row.typedAssoc(),
    );
    final Object key = plan.decodeKey(data)!;
    return _DecodedRow(key: key, model: plan.decode(data)!, data: data);
  }).toList();
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

Future<Map<Object, Object>> _readByIds(
  MySQLConnection connection,
  TableRelationPlanBase plan,
  Iterable<Object> ids,
) async {
  final List<Object> values = ids.toSet().toList();
  if (values.isEmpty) return {};
  final List<FieldSchema> fields = plan.schema.primaryKeys;
  final Map<String, Object?> params = {};
  final String where;
  if (fields.length == 1) {
    where =
        '${fields.single.columnName} IN ('
        '${List.generate(values.length, (i) => ':relation_id_$i').join(', ')})';
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
        '(${List.generate(parts.length, (part) => ':relation_id_${i}_$part').join(', ')})',
      );
      for (int part = 0; part < parts.length; part++) {
        params['relation_id_${i}_$part'] = parts[part];
      }
    }
    where =
        '(${fields.map((field) => field.columnName).join(', ')}) IN '
        '(${tuples.join(', ')})';
  }
  final List<_DecodedRow> rows = await _readRows(
    connection,
    plan,
    where: where,
    params: params,
  );
  return {for (final _DecodedRow row in rows) row.key: row.model};
}

Future<Map<Object, List<Object>>> _readByForeignKey(
  MySQLConnection connection,
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
    (i) => ':relation_fk_$i',
  ).join(', ');
  final List<_DecodedRow> rows = await _readRows(
    connection,
    plan,
    where: '${field.columnName} IN ($placeholders)',
    params: params,
  );
  final Map<Object, List<Object>> result = {};
  for (final _DecodedRow row in rows) {
    final Object? foreignKey = row.data[field.columnName];
    if (foreignKey != null) {
      result.putIfAbsent(foreignKey, () => []).add(row.model);
    }
  }
  return result;
}

/// Resolves callback-based relationships through MySQL reads.
///
/// Direct table sources are batched when their plan is available. Callbacks
/// that cannot be represented structurally remain on the readable fallback,
/// which keeps custom and computed relationships usable. The underlying MySQL
/// reference is currently one-shot for streams, so relationship streams are
/// one-shot too.
class Relationship implements BaseRelationship<Query> {
  final MySQLConnection? connection;

  const Relationship([this.connection]);

  @override
  OneToOneAssociation<L, I, R, Query>
  oneToOne<L, I extends Object, R, J extends Object>(
    RelationSource<L, I, Query> left,
    RelationSource<R, J, Query> right,
    J Function(L) on,
  ) {
    return _OneToOne(left: left, right: right, on: on, connection: connection);
  }

  @override
  OneToManyAssociation<L, I, R, Query>
  oneToMany<L, I extends Object, R, J extends Object>(
    RelationSource<L, I, Query> left,
    RelationSource<R, J, Query> right,
    BaseFilter<Query> Function(L) on,
  ) {
    return _OneToMany(left: left, right: right, on: on, connection: connection);
  }

  @override
  ManyToOneAssociation<L, I, R, J, Query>
  manyToOne<L, I extends Object, R, J extends Object>(
    RelationSource<L, I, Query> left,
    RelationSource<R, J, Query> right,
    J Function(L) on,
  ) {
    return _ManyToOne(left: left, right: right, on: on, connection: connection);
  }

  @override
  ManyToManyAssociation<M, I, L, R, Query>
  manyToMany<M, I extends Object, L, J extends Object, R, K extends Object>(
    RelationSource<M, I, Query> middle,
    RelationSource<L, J, Query> left,
    J Function(M) onLeft,
    RelationSource<R, K, Query> right,
    K Function(M) onRight,
  ) {
    return _ManyToMany(
      middle: middle,
      left: left,
      right: right,
      onLeft: onLeft,
      onRight: onRight,
      connection: connection,
    );
  }
}

class _OneToOne<L, I extends Object, R, J extends Object>
    implements OneToOneAssociation<L, I, R, Query> {
  final MySQLConnection? connection;
  final RelationSource<L, I, Query> left;
  final RelationSource<R, J, Query> right;
  final J Function(L) on;

  const _OneToOne({
    required this.left,
    required this.right,
    required this.on,
    required this.connection,
  });

  @override
  Future<Join<L, R?>?> peek(I id) async {
    final L? leftModel = await left.peek(id);
    if (leftModel == null) return null;
    return Join(left: leftModel, right: await right.peek(on(leftModel)));
  }

  @override
  Future<List<Join<L, R?>>> peekAll([
    BaseFilter<Query> filter = const BaseFilter.empty(),
  ]) async {
    final List<L> leftModels = await left.peekAll(filter);
    final TableRelationPlanBase? rightPlan = _tablePlan(right);
    if (connection != null && rightPlan != null) {
      final List<J> ids = leftModels.map(on).toList();
      final Map<Object, Object> rightModels = await _readByIds(
        connection!,
        rightPlan,
        ids,
      );
      return [
        for (int i = 0; i < leftModels.length; i++)
          Join(left: leftModels[i], right: rightModels[ids[i]] as R?),
      ];
    }
    final List<R?> rightModels = await Future.wait(
      leftModels.map((model) => right.peek(on(model))),
    );
    return [
      for (int i = 0; i < leftModels.length; i++)
        Join(left: leftModels[i], right: rightModels[i]),
    ];
  }

  @override
  Stream<Join<L, R?>?> pull(I id) async* {
    yield await peek(id);
  }

  @override
  Stream<List<Join<L, R?>>> pullAll([
    BaseFilter<Query> filter = const BaseFilter.empty(),
  ]) async* {
    yield await peekAll(filter);
  }
}

class _OneToMany<L, I extends Object, R, J extends Object>
    implements OneToManyAssociation<L, I, R, Query> {
  final MySQLConnection? connection;
  final RelationSource<L, I, Query> left;
  final RelationSource<R, J, Query> right;
  final BaseFilter<Query> Function(L) on;

  const _OneToMany({
    required this.left,
    required this.right,
    required this.on,
    required this.connection,
  });

  @override
  Future<Join<L, List<R>>?> peek(I id) async {
    final L? leftModel = await left.peek(id);
    if (leftModel == null) return null;
    return Join(left: leftModel, right: await right.peekAll(on(leftModel)));
  }

  @override
  Future<List<Join<L, List<R>>>> peekAll([
    BaseFilter<Query> filter = const BaseFilter.empty(),
  ]) async {
    final List<L> leftModels = await left.peekAll(filter);
    final TableRelationPlanBase? leftPlan = _tablePlan(left);
    final TableRelationPlanBase? rightPlan = _tablePlan(right);
    if (connection != null && leftPlan != null && rightPlan != null) {
      final List<ValueFilter<Query>> relationFilters = [];
      for (final L model in leftModels) {
        final BaseFilter<Query> relationFilter = on(model);
        if (relationFilter is! ValueFilter<Query> ||
            relationFilter.field is! ForeignKeySchema ||
            relationFilter.value == null) {
          break;
        }
        relationFilters.add(relationFilter);
      }
      if (relationFilters.length == leftModels.length &&
          relationFilters.isNotEmpty) {
        final ForeignKeySchema field =
            relationFilters.first.field! as ForeignKeySchema;
        final bool targetsLeft =
            field.targetTableName == leftPlan.schema.tableName &&
            field.targetColumnName ==
                leftPlan.schema.primaryKeys.first.columnName;
        final bool sameField = relationFilters.every((relationFilter) {
          final ForeignKeySchema current =
              relationFilter.field! as ForeignKeySchema;
          return current.columnName == field.columnName &&
              current.targetTableName == field.targetTableName &&
              current.targetColumnName == field.targetColumnName;
        });
        if (targetsLeft && sameField) {
          final Map<Object, List<Object>> associated = await _readByForeignKey(
            connection!,
            rightPlan,
            field,
            relationFilters.map((relationFilter) => relationFilter.value!),
          );
          return [
            for (int i = 0; i < leftModels.length; i++)
              Join(
                left: leftModels[i],
                right: associated[relationFilters[i].value]?.cast<R>() ?? <R>[],
              ),
          ];
        }
      }
    }
    final List<List<R>> rightModels = await Future.wait(
      leftModels.map((model) => right.peekAll(on(model))),
    );
    return [
      for (int i = 0; i < leftModels.length; i++)
        Join(left: leftModels[i], right: rightModels[i]),
    ];
  }

  @override
  Stream<Join<L, List<R>>?> pull(I id) async* {
    yield await peek(id);
  }

  @override
  Stream<List<Join<L, List<R>>>> pullAll([
    BaseFilter<Query> filter = const BaseFilter.empty(),
  ]) async* {
    yield await peekAll(filter);
  }
}

class _ManyToOne<L, I extends Object, R, J extends Object>
    implements ManyToOneAssociation<L, I, R, J, Query> {
  final MySQLConnection? connection;
  final RelationSource<L, I, Query> left;
  final RelationSource<R, J, Query> right;
  final J Function(L) on;

  const _ManyToOne({
    required this.left,
    required this.right,
    required this.on,
    required this.connection,
  });

  @override
  Future<Join<R, L>?> peek(I id) async {
    final L? leftModel = await left.peek(id);
    if (leftModel == null) return null;
    final R? rightModel = await right.peek(on(leftModel));
    if (rightModel == null) return null;
    return Join(left: rightModel, right: leftModel);
  }

  @override
  Future<List<Join<R, List<L>>>> peekAll([
    BaseFilter<Query> filter = const BaseFilter.empty(),
  ]) async {
    final List<L> leftModels = await left.peekAll(filter);
    final Map<J, List<L>> groups = {};
    for (final L model in leftModels) {
      groups.putIfAbsent(on(model), () => []).add(model);
    }

    final List<MapEntry<J, List<L>>> entries = groups.entries.toList();
    final TableRelationPlanBase? rightPlan = _tablePlan(right);
    if (connection != null && rightPlan != null) {
      final Map<Object, Object> rightModels = await _readByIds(
        connection!,
        rightPlan,
        entries.map((entry) => entry.key),
      );
      return [
        for (final MapEntry<J, List<L>> entry in entries)
          if (rightModels[entry.key] != null)
            Join(left: rightModels[entry.key] as R, right: entry.value),
      ];
    }
    final List<R?> rightModels = await Future.wait(
      entries.map((entry) => right.peek(entry.key)),
    );
    final List<Join<R, List<L>>> joins = [];
    for (int i = 0; i < entries.length; i++) {
      final R? rightModel = rightModels[i];
      if (rightModel == null) continue;
      joins.add(Join(left: rightModel, right: entries[i].value));
    }
    return joins;
  }

  @override
  Stream<Join<R, L>?> pull(I id) async* {
    yield await peek(id);
  }

  @override
  Stream<List<Join<R, List<L>>>> pullAll([
    BaseFilter<Query> filter = const BaseFilter.empty(),
  ]) async* {
    yield await peekAll(filter);
  }
}

class _ManyToMany<M, I extends Object, L, J extends Object, R, K extends Object>
    implements ManyToManyAssociation<M, I, L, R, Query> {
  final MySQLConnection? connection;
  final RelationSource<M, I, Query> middle;
  final RelationSource<L, J, Query> left;
  final RelationSource<R, K, Query> right;
  final J Function(M) onLeft;
  final K Function(M) onRight;

  const _ManyToMany({
    required this.middle,
    required this.left,
    required this.right,
    required this.onLeft,
    required this.onRight,
    required this.connection,
  });

  @override
  Future<Join<M, (L?, R?)>?> peek(I id) async {
    final M? middleModel = await middle.peek(id);
    if (middleModel == null) return null;
    final (L?, R?) models = await (
      left.peek(onLeft(middleModel)),
      right.peek(onRight(middleModel)),
    ).wait;
    return Join(left: middleModel, right: models);
  }

  @override
  Future<List<Join<M, (L?, R?)>>> peekAll([
    BaseFilter<Query> filter = const BaseFilter.empty(),
  ]) async {
    final List<M> middleModels = await middle.peekAll(filter);
    final TableRelationPlanBase? leftPlan = _tablePlan(left);
    final TableRelationPlanBase? rightPlan = _tablePlan(right);
    if (connection != null && leftPlan != null && rightPlan != null) {
      final List<J> leftIds = middleModels.map(onLeft).toList();
      final List<K> rightIds = middleModels.map(onRight).toList();
      final Map<Object, Object> leftModels = await _readByIds(
        connection!,
        leftPlan,
        leftIds,
      );
      final Map<Object, Object> rightModels = await _readByIds(
        connection!,
        rightPlan,
        rightIds,
      );
      return [
        for (int i = 0; i < middleModels.length; i++)
          Join(
            left: middleModels[i],
            right: (
              leftModels[leftIds[i]] as L?,
              rightModels[rightIds[i]] as R?,
            ),
          ),
      ];
    }
    final List<Join<M, (L?, R?)>> joins = [];
    for (final M model in middleModels) {
      final (L?, R?) models = await (
        left.peek(onLeft(model)),
        right.peek(onRight(model)),
      ).wait;
      joins.add(Join(left: model, right: models));
    }
    return joins;
  }

  @override
  Stream<Join<M, (L?, R?)>?> pull(I id) async* {
    yield await peek(id);
  }

  @override
  Stream<List<Join<M, (L?, R?)>>> pullAll([
    BaseFilter<Query> filter = const BaseFilter.empty(),
  ]) async* {
    yield await peekAll(filter);
  }
}
