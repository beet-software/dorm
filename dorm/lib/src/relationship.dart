import 'dart:async';

import 'filter.dart';
import 'merge.dart';
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
///     .pullAll(const Filter.value(true, key: 'active'));
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
  Stream<Join<L, R?>?> pull(String id) {
    return ForwardLinkMerge<L, R?>(
      left: left.pull(id),
      map: (leftModel) => right.pull(on(leftModel)),
    ).stream;
  }

  @override
  Stream<List<Join<L, R?>>> pullAll([
    Filter filter = const Filter.empty(),
  ]) {
    return ExpandMerge<L, R?>(
      left: left.pullAll(filter),
      map: (leftModel) => right.pull(on(leftModel)),
    ).stream;
  }
}

/// Represents an one-to-many relationship.
///
/// Let's suppose you have two tables: `School` and `Student`:
///
/// ```none
/// |                    `School`                   |
/// |:----:|:---------------------------:|:--------:|
/// | `id` |            `name`           | `active` |
/// |   0  |    School of Happy Valley   |   true   |
/// |   1  |     Sacred Heart Academy    |   false  |
/// |   2  | Horizon Education Institute |   true   |
///
/// |                      `Student`                     |
/// |:----:|:--------------:|:------------:|:-----------:|
/// | `id` |     `name`     | `birth-date` | `school-id` |
/// |  10  | Kennedy Heaven |  2017-06-13  |      0      |
/// |  11  |    Rolf Finn   |  2018-01-29  |      0      |
/// |  12  |   Byron Phil   |  2019-07-17  |      1      |
/// ```
///
/// Since a `School` can have more than one `Student`, this is a 1-to-N relationship.
///
/// In SQL, you'd do:
///
/// ```sql
/// SELECT A.id, A.name, A.active, B.id, B.school-id, B.name, B.birth-date
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
///   on: (school) => Filter.value(school.id, key: 'school-id'),
/// );
/// final Stream<List<Join<School, List<Student>>>> s0 = relationship
///     .pullAll(const Filter.value(true, key: 'active'));
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

  @override
  Future<Join<L, List<R>>?> peek(String id) async {
    final L? leftModel = await left.peek(id);
    if (leftModel == null) return null;
    final List<R> rightModels = await right.peekAll(on(leftModel));
    return Join(left: leftModel, right: rightModels);
  }

  @override
  Future<List<Join<L, List<R>>>> peekAll([
    Filter filter = const Filter.empty(),
  ]) async {
    final List<L> leftModels = await left.peekAll(filter);
    final List<List<R>> associatedModels = await Future.wait(
        leftModels.map((leftModel) => right.peekAll(on(leftModel))).toList());

    final List<Join<L, List<R>>> joins = [];
    for (int i = 0; i < leftModels.length; i++) {
      final L leftModel = leftModels[i];
      final List<R> rightModels = associatedModels[i];
      joins.add(Join(left: leftModel, right: rightModels));
    }
    return joins;
  }

  @override
  Stream<Join<L, List<R>>?> pull(String id) {
    return ForwardLinkMerge<L, List<R>>(
      left: left.pull(id),
      map: (leftModel) => right.pullAll(on(leftModel)),
    ).stream;
  }

  @override
  Stream<List<Join<L, List<R>>>> pullAll([
    Filter filter = const Filter.empty(),
  ]) {
    return ExpandMerge<L, List<R>>(
      left: left.pullAll(filter),
      map: (leftModel) => right.pullAll(on(leftModel)),
    ).stream;
  }
}

/// Represents an many-to-one relationship.
///
/// Let's suppose you have two tables: `School` and `Student`:
///
/// ```none
/// |                    `School`                   |
/// |:----:|:---------------------------:|:--------:|
/// | `id` |            `name`           | `active` |
/// |   0  |    School of Happy Valley   |   true   |
/// |   1  |     Sacred Heart Academy    |   false  |
/// |   2  | Horizon Education Institute |   true   |
///
/// |                      `Student`                     |
/// |:----:|:--------------:|:------------:|:-----------:|
/// | `id` |     `name`     | `birth-date` | `school-id` |
/// |  10  | Kennedy Heaven |  2017-06-13  |      0      |
/// |  11  |    Rolf Finn   |  2018-01-29  |      0      |
/// |  12  |   Byron Phil   |  2019-07-17  |      1      |
/// ```
///
/// Since a `School` can have more than one `Student`, this is a 1-to-N relationship.
/// If you want to fetch all schools and their respective students, you can use
/// [OneToManyRelationship]. However, not all schools have students (in the
/// example above, school 2).
///
/// In SQL, you'd do:
///
/// ```sql
/// SELECT A.id, A.name, A.active, B.id, B.school-id, B.name, B.birth-date
/// FROM School A
/// RIGHT JOIN Student B
/// ON A.id = B.school-id
/// WHERE YEAR(birth-date) = 2018
/// ```
///
/// In Dorm, you'd do:
///
/// ```dart
/// final ModelRepository<School> schools = ...;
/// final ModelRepository<Student> students = ...;
///
/// final ManyToOneRelationship<Student, School> relationship = ManyToOneRelationship(
///   left: students,
///   right: schools,
///   on: (student) => student.schoolId,
/// );
/// final Stream<List<Join<School, List<Student>>>> s0 = relationship
///     .pullAll(Filter.date(DateTime(2018), key: 'birth-date', unit: DateFilterUnit.year));
/// ```
class ManyToOneRelationship<L, R>
    implements
        SingleReadOperation<Join<R, L>>,
        BatchReadOperation<Join<R, List<L>>> {
  final Mergeable<L> left;
  final Mergeable<R> right;
  final String Function(L) on;

  const ManyToOneRelationship({
    required this.left,
    required this.right,
    required this.on,
  });

  @override
  Future<Join<R, L>?> peek(String id) async {
    final L? leftModel = await left.peek(id);
    if (leftModel == null) return null;
    final R? rightModel = await right.peek(on(leftModel));
    if (rightModel == null) return null;
    return Join(left: rightModel, right: leftModel);
  }

  @override
  Future<List<Join<R, List<L>>>> peekAll([
    Filter filter = const Filter.empty(),
  ]) async {
    final List<L> leftModels = await left.peekAll(filter);
    final Map<String, List<L>> groups = {};
    for (L leftModel in leftModels) {
      groups.putIfAbsent(on(leftModel), () => []).add(leftModel);
    }
    final List<MapEntry<String, List<L>>> entries = groups.entries.toList();
    final List<R?> rightModels = await Future.wait(
        entries.map((entry) => right.peek(entry.key)).toList());

    final List<Join<R, List<L>>> joins = [];
    for (int i = 0; i < entries.length; i++) {
      final MapEntry<String, List<L>> entry = entries[i];
      final List<L> leftModels = entry.value;
      final R? rightModel = rightModels[i];
      if (rightModel == null) continue;
      joins.add(Join(left: rightModel, right: leftModels));
    }
    return joins;
  }

  @override
  Stream<Join<R, L>?> pull(String id) {
    return BackwardLinkMerge<L, R>(
      left: left.pull(id),
      map: (leftModel) => right.pull(on(leftModel)),
    ).stream;
  }

  @override
  Stream<List<Join<R, List<L>>>> pullAll([
    Filter filter = const Filter.empty(),
  ]) {
    return CollapseMerge<L, R>(
      left: left.pullAll(filter),
      onLeft: (leftModel) => on(leftModel),
      onRight: (rightId) => right.pull(rightId),
    ).stream;
  }
}
