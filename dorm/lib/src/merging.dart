import 'dart:async';

import 'package:rxdart/rxdart.dart';

import 'filter.dart';
import 'repository.dart';

class Join<LeftModel, RightModel> {
  final LeftModel left;
  final RightModel right;

  const Join({required this.left, required this.right});
}

abstract class Mergeable<Model>
    implements SingleReadOperation<Model>, BatchReadOperation<Model> {}

/// Represents an one-to-one relationship.
///
/// Let's suppose you have two tables: `School` and `Principal`:
///
/// ```none
/// |                            `School`                            |
/// |:----:|:---------------------------:|:--------------:|:--------:|
/// | `id` |            `name`           | `principal-id` | `active` |
/// |   0  |    School of Happy Valley   |       10       |   true   |
/// |   1  |     Sacred Heart Academy    |       11       |   false  |
/// |   2  | Horizon Education Institute |       12       |   true   |
///
/// |      `Principal`      |
/// |:----:|:--------------:|
/// | `id` |     `name`     |
/// |  10  | Kennedy Heaven |
/// |  11  |    Rolf Finn   |
/// |  12  |   Byron Phil   |
/// ```
///
/// Since a `School` has only one `Principal`, this is a 1-to-1 relationship.
///
/// In SQL, you'd do:
///
/// ```sql
/// SELECT A.id, A.name, A.principal-id, A.active, B.id, B.name
/// FROM School A
/// LEFT JOIN Principal B
/// ON A.principal-id = B.id
/// WHERE A.active = true
/// ```
///
/// In Dorm, you'd do:
///
/// ```dart
/// final ModelRepository<School> schools = ...;
/// final ModelRepository<Principal> principals = ...;
///
/// final OneToOneRelationship<School, Principal> relationship = OneToOneRelationship(
///   left: schools,
///   right: principals,
///   on: (school) => school.principalId,
/// );
/// final Stream<List<Join<School, Principal?>>> s0 = relationship
///     .pullAll(Filter.value(key: 'active', value: true));
/// ```
class OneToOneRelationship<L, R> implements Mergeable<Join<L, R?>> {
  final Mergeable<L> left;
  final Mergeable<R> right;
  final String Function(L) on;

  const OneToOneRelationship({
    required this.left,
    required this.right,
    required this.on,
  });

  OneToOneRelationship<L, Join<R, T?>?> map1to1<T>(
    Mergeable<T> child, {
    required String Function(R) on,
  }) {
    return OneToOneRelationship(
      left: left,
      right: OneToOneRelationship(left: right, right: child, on: on),
      on: this.on,
    );
  }

  OneToOneRelationship<L, Join<R, List<T>>?> map1toN<T>(
    Mergeable<T> child, {
    required Filter Function(R) on,
  }) {
    return OneToOneRelationship(
      left: left,
      right: OneToManyRelationship(left: right, right: child, on: on),
      on: this.on,
    );
  }

  @override
  Future<Join<L, R?>?> peek(String id) async {
    final L? leftModel = await left.peek(id);
    if (leftModel == null) return null;
    final R? rightModel = await right.peek(on(leftModel));
    return Join(left: leftModel, right: rightModel);
  }

  @override
  Future<List<Join<L, R?>>> peekAll([
    Filter filter = const Filter.empty(),
  ]) async {
    final List<L> leftModels = await left.peekAll(filter);
    final List<Join<L, R?>> joins = [];
    for (L leftModel in leftModels) {
      final R? rightModel = await right.peek(on(leftModel));
      joins.add(Join(left: leftModel, right: rightModel));
    }
    return joins;
  }

  @override
  Stream<List<Join<L, R?>>> pullAll([
    Filter filter = const Filter.empty(),
  ]) {
    return left //
        .pullAll(filter)
        .flatMap((leftModels) => CombineLatestStream.list(leftModels //
            .map((leftModel) => right //
                .pull(on(leftModel))
                .map((rightModel) =>
                    Join(left: leftModel, right: rightModel)))));
  }

  @override
  Stream<Join<L, R?>?> pull(String id) {
    return left.pull(id).flatMap((leftModel) {
      if (leftModel == null) return Stream.value(null);
      return right
          .pull(on(leftModel))
          .map((rightModel) => Join(left: leftModel, right: rightModel));
    });
  }
}

/// Represents an one-to-many relationship.
///
/// Let's suppose you have two tables: `School` and `Student`:
///
/// ```none
/// |                            `School`                            |
/// |:----:|:---------------------------:|:--------------:|:--------:|
/// | `id` |            `name`           | `principal-id` | `active` |
/// |   0  |    School of Happy Valley   |       10       |   true   |
/// |   1  |     Sacred Heart Academy    |       11       |   false  |
/// |   2  | Horizon Education Institute |       12       |   true   |
///
/// |       `Student`       |
/// |:----:|:--------------:|
/// | `id` |     `name`     |
/// |  10  | Kennedy Heaven |
/// |  11  |    Rolf Finn   |
/// |  12  |   Byron Phil   |
/// ```
///
/// Since a `School` can have more than one `Student`, this is a 1-to-N relationship.
///
/// In SQL, you'd do:
///
/// ```sql
/// SELECT A.id, A.name, A.active, B.id, B.school-id, B.name, B.birthdate
/// FROM School A
/// LEFT JOIN Student B
/// ON A.id = B.school-id
/// WHERE A.active = true
/// ```
///
/// In Dorm, you'd do:
///
/// ```dart
/// final ModelRepository<School> schools = ...;
/// final ModelRepository<Student> students = ...;
///
/// final OneToManyRelationship<School, Student> relationship = OneToManyRelationship(
///   left: schools,
///   right: students,
///   on: (school) => Filter.value(key: 'school-id', value: school.id),
/// );
/// final Stream<List<Join<School, List<Student>>>> s0 = relationship
///     .pullAll(Filter.value(key: 'active', value: true));
/// ```
class OneToManyRelationship<L, R> implements Mergeable<Join<L, List<R>>> {
  final Mergeable<L> left;
  final Mergeable<R> right;
  final Filter Function(L) on;

  const OneToManyRelationship({
    required this.left,
    required this.right,
    required this.on,
  });

  OneToManyRelationship<L, Join<R, T?>> map1to1<T>(
    Mergeable<T> child, {
    required String Function(R) on,
  }) {
    return OneToManyRelationship(
      left: left,
      right: OneToOneRelationship(left: right, right: child, on: on),
      on: this.on,
    );
  }

  OneToManyRelationship<L, Join<R, List<T>>> map1toN<T>(
    Mergeable<T> child, {
    required Filter Function(R) on,
  }) {
    return OneToManyRelationship(
      left: left,
      right: OneToManyRelationship(left: right, right: child, on: on),
      on: this.on,
    );
  }

  @override
  Stream<List<Join<L, List<R>>>> pullAll([
    Filter filter = const Filter.empty(),
  ]) {
    return left.pullAll(filter).flatMap((leftModels) {
      if (leftModels.isEmpty) return Stream.value([]);
      return CombineLatestStream.list(leftModels.map((leftModel) {
        return right.pullAll(on(leftModel)).map((rightModels) {
          return Join(left: leftModel, right: rightModels);
        });
      }));
    });
  }

  @override
  Future<List<Join<L, List<R>>>> peekAll([
    Filter filter = const Filter.empty(),
  ]) async {
    final List<L> leftModels = await left.peekAll(filter);
    final List<Join<L, List<R>>> joins = [];
    for (L leftModel in leftModels) {
      final List<R> rightModels = await right.peekAll(on(leftModel));
      joins.add(Join(left: leftModel, right: rightModels));
    }
    return joins;
  }

  @override
  Future<Join<L, List<R>>?> peek(String id) async {
    final L? leftModel = await left.peek(id);
    if (leftModel == null) return null;
    final List<R> rightModels = await right.peekAll(on(leftModel));
    return Join(left: leftModel, right: rightModels);
  }

  @override
  Stream<Join<L, List<R>>?> pull(String id) {
    return left.pull(id).flatMap((leftModel) {
      if (leftModel == null) return Stream.value(null);
      return right.pullAll(on(leftModel)).map((rightModels) {
        return Join(left: leftModel, right: rightModels);
      });
    });
  }
}
