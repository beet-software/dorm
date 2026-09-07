import 'package:dorm_framework/dorm_framework.dart';
import 'package:mongo_dart/mongo_dart.dart';

import 'query.dart';
import 'sql.dart';

class Relationship implements BaseRelationship<Query> {
  final Db? database;

  const Relationship([this.database]);

  @override
  OneToOneAssociation<L, I, R, Query>
  oneToOne<L, I extends Object, R, J extends Object>(
    RelationSource<L, I, Query> left,
    RelationSource<R, J, Query> right,
    J Function(L) on,
  ) {
    return _OneToOne(database: database, left: left, right: right, on: on);
  }

  @override
  OneToManyAssociation<L, I, R, Query>
  oneToMany<L, I extends Object, R, J extends Object>(
    RelationSource<L, I, Query> left,
    RelationSource<R, J, Query> right,
    BaseFilter<Query> Function(L) on,
  ) {
    return _OneToMany(database: database, left: left, right: right, on: on);
  }

  @override
  ManyToOneAssociation<L, I, R, J, Query>
  manyToOne<L, I extends Object, R, J extends Object>(
    RelationSource<L, I, Query> left,
    RelationSource<R, J, Query> right,
    J Function(L) on,
  ) {
    return _ManyToOne(database: database, left: left, right: right, on: on);
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
      database: database,
      middle: middle,
      left: left,
      right: right,
      onLeft: onLeft,
      onRight: onRight,
    );
  }
}

class _OneToOne<L, I extends Object, R, J extends Object>
    implements OneToOneAssociation<L, I, R, Query> {
  final Db? database;
  final RelationSource<L, I, Query> left;
  final RelationSource<R, J, Query> right;
  final J Function(L) on;

  const _OneToOne({
    required this.database,
    required this.left,
    required this.right,
    required this.on,
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
    QueryOptions options = const QueryOptions(),
  ]) async {
    final List<L> leftModels = await left.peekAll(filter, options);
    final TableRelationPlanBase? plan = tablePlan(right);
    if (database != null && plan != null) {
      final List<J> ids = leftModels.map(on).toList();
      final Map<Object, Object> models = await readByIds(database!, plan, ids);
      return [
        for (int i = 0; i < leftModels.length; i++)
          Join(left: leftModels[i], right: models[ids[i]] as R?),
      ];
    }
    final List<R?> models = await Future.wait(
      leftModels.map((model) => right.peek(on(model))),
    );
    return [
      for (int i = 0; i < leftModels.length; i++)
        Join(left: leftModels[i], right: models[i]),
    ];
  }

  @override
  Stream<Join<L, R?>?> pull(I id) async* {
    yield await peek(id);
  }

  @override
  Stream<List<Join<L, R?>>> pullAll([
    BaseFilter<Query> filter = const BaseFilter.empty(),
    QueryOptions options = const QueryOptions(),
  ]) async* {
    yield await peekAll(filter, options);
  }
}

class _OneToMany<L, I extends Object, R, J extends Object>
    implements OneToManyAssociation<L, I, R, Query> {
  final Db? database;
  final RelationSource<L, I, Query> left;
  final RelationSource<R, J, Query> right;
  final BaseFilter<Query> Function(L) on;

  const _OneToMany({
    required this.database,
    required this.left,
    required this.right,
    required this.on,
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
    QueryOptions options = const QueryOptions(),
  ]) async {
    final List<L> leftModels = await left.peekAll(filter, options);
    final TableRelationPlanBase? leftPlan = tablePlan(left);
    final TableRelationPlanBase? rightPlan = tablePlan(right);
    if (database != null && leftPlan != null && rightPlan != null) {
      final List<ValueFilter<Query>> relationFilters = [];
      for (final L model in leftModels) {
        final BaseFilter<Query> relationFilter = on(model);
        if (relationFilter is! ValueFilter<Query> ||
            relationFilter.field is! ForeignKeySchema ||
            relationFilter.value == null) {
          relationFilters.clear();
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
          final Map<Object, List<Object>> associated = await readByForeignKey(
            database!,
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
    final List<List<R>> models = await Future.wait(
      leftModels.map((model) => right.peekAll(on(model))),
    );
    return [
      for (int i = 0; i < leftModels.length; i++)
        Join(left: leftModels[i], right: models[i]),
    ];
  }

  @override
  Stream<Join<L, List<R>>?> pull(I id) async* {
    yield await peek(id);
  }

  @override
  Stream<List<Join<L, List<R>>>> pullAll([
    BaseFilter<Query> filter = const BaseFilter.empty(),
    QueryOptions options = const QueryOptions(),
  ]) async* {
    yield await peekAll(filter, options);
  }
}

class _ManyToOne<L, I extends Object, R, J extends Object>
    implements ManyToOneAssociation<L, I, R, J, Query> {
  final Db? database;
  final RelationSource<L, I, Query> left;
  final RelationSource<R, J, Query> right;
  final J Function(L) on;

  const _ManyToOne({
    required this.database,
    required this.left,
    required this.right,
    required this.on,
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
    QueryOptions options = const QueryOptions(),
  ]) async {
    final List<L> leftModels = await left.peekAll(filter, options);
    final Map<J, List<L>> groups = {};
    for (final L model in leftModels) {
      groups.putIfAbsent(on(model), () => []).add(model);
    }
    final List<MapEntry<J, List<L>>> entries = groups.entries.toList();
    final TableRelationPlanBase? plan = tablePlan(right);
    if (database != null && plan != null) {
      final Map<Object, Object> models = await readByIds(
        database!,
        plan,
        entries.map((entry) => entry.key),
      );
      return [
        for (final MapEntry<J, List<L>> entry in entries)
          if (models[entry.key] != null)
            Join(left: models[entry.key] as R, right: entry.value),
      ];
    }
    final List<R?> models = await Future.wait(
      entries.map((entry) => right.peek(entry.key)),
    );
    return [
      for (int i = 0; i < entries.length; i++)
        if (models[i] != null)
          Join(left: models[i] as R, right: entries[i].value),
    ];
  }

  @override
  Stream<Join<R, L>?> pull(I id) async* {
    yield await peek(id);
  }

  @override
  Stream<List<Join<R, List<L>>>> pullAll([
    BaseFilter<Query> filter = const BaseFilter.empty(),
    QueryOptions options = const QueryOptions(),
  ]) async* {
    yield await peekAll(filter, options);
  }
}

class _ManyToMany<M, I extends Object, L, J extends Object, R, K extends Object>
    implements ManyToManyAssociation<M, I, L, R, Query> {
  final Db? database;
  final RelationSource<M, I, Query> middle;
  final RelationSource<L, J, Query> left;
  final RelationSource<R, K, Query> right;
  final J Function(M) onLeft;
  final K Function(M) onRight;

  const _ManyToMany({
    required this.database,
    required this.middle,
    required this.left,
    required this.right,
    required this.onLeft,
    required this.onRight,
  });

  @override
  Future<Join<M, (L?, R?)>?> peek(I id) async {
    final M? middleModel = await middle.peek(id);
    if (middleModel == null) return null;
    final List<Object?> models = await Future.wait<Object?>([
      left.peek(onLeft(middleModel)),
      right.peek(onRight(middleModel)),
    ]);
    return Join(left: middleModel, right: (models[0] as L?, models[1] as R?));
  }

  @override
  Future<List<Join<M, (L?, R?)>>> peekAll([
    BaseFilter<Query> filter = const BaseFilter.empty(),
    QueryOptions options = const QueryOptions(),
  ]) async {
    final List<M> middleModels = await middle.peekAll(filter, options);
    final TableRelationPlanBase? leftPlan = tablePlan(left);
    final TableRelationPlanBase? rightPlan = tablePlan(right);
    if (database != null && leftPlan != null && rightPlan != null) {
      final List<J> leftIds = middleModels.map(onLeft).toList();
      final List<K> rightIds = middleModels.map(onRight).toList();
      final Map<Object, Object> leftModels = await readByIds(
        database!,
        leftPlan,
        leftIds,
      );
      final Map<Object, Object> rightModels = await readByIds(
        database!,
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
    final List<Join<M, (L?, R?)>> result = [];
    for (final M model in middleModels) {
      final List<Object?> models = await Future.wait<Object?>([
        left.peek(onLeft(model)),
        right.peek(onRight(model)),
      ]);
      result.add(Join(left: model, right: (models[0] as L?, models[1] as R?)));
    }
    return result;
  }

  @override
  Stream<Join<M, (L?, R?)>?> pull(I id) async* {
    yield await peek(id);
  }

  @override
  Stream<List<Join<M, (L?, R?)>>> pullAll([
    BaseFilter<Query> filter = const BaseFilter.empty(),
    QueryOptions options = const QueryOptions(),
  ]) async* {
    yield await peekAll(filter, options);
  }
}
