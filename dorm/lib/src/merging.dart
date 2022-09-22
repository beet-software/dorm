import 'dart:async';

import 'filter.dart';
import 'repository.dart';

class Join<LeftModel, RightModel> {
  final LeftModel left;
  final RightModel right;

  const Join({required this.left, required this.right});
}

typedef SingleStream<T> = Stream<T>;
typedef Single1to1Stream<L, R> = SingleStream<Join<L, R?>>;
typedef Single1toNStream<L, R> = SingleStream<Join<L, List<R>>>;
typedef MultipleStream<T> = SingleStream<List<T>>;
typedef Multiple1to1Stream<L, R> = MultipleStream<Join<L, R?>>;
typedef Multiple1toNStream<L, R> = MultipleStream<Join<L, List<R>>>;
typedef MtoNStream<L, M, R> = MultipleStream<Join<L, List<Join<M, R?>>>>;

abstract class Mergeable<LeftModel> {
  Mergeable<Join<LeftModel, RightModel?>> merge1to1<RightModel>(
    ModelRepository<RightModel> right, {
    required String Function(LeftModel) on,
    Filter where = const Filter.empty(),
  });

  Mergeable<Join<LeftModel, List<RightModel>>> merge1toN<RightModel>(
    ModelRepository<RightModel> right, {
    required Filter Function(LeftModel) on,
    Filter where = const Filter.empty(),
  });
}

abstract class School {
  String get id;
}

class Student {}

class Address {}

class ParentData<L, R> {
  final ModelRepository<L> schools;
  final ModelRepository<R> students;
  final Filter Function(L) on;

}

void t(
  ModelRepository<School> schools,
  ModelRepository<Student> students,
  ModelRepository<Address> addresses,
) {
  schools
      .merge1toN<Student>(
        students,
        on: (school) => Filter.value(key: 'school-id', value: school.id),
      )
      .merge1to1<Address>(
        addresses,
        on: (student) => join.right.first.addressId,
      );

  // ParentData(
  //   left: `Instance of SchoolRepository`,
  //   right: `Instance of StudentRepository`,
  //   on: `Instance of Filter Function(School)`,
  //   child: ChildData(
  //    right: `Instance of AddressRepository`,
  //    on: `Instance of `
  //   ),
  // )
}

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
/// final Repository<SchoolData, School> schoolRepo = ...;
/// final Repository<PrincipalData, Principal> principalRepo = ...;
///
/// final Stream<Join<School, Principal?>> joint = Join1to1(
///   left: schoolRepo,
///   right: principalRepo,
///   on: (school) => school.principalId,
///   where: Filter.value(key: 'active', value: true),
/// );
/// ```
class Join1to1<Parent, Child> implements Mergeable<Join<Parent, Child?>> {
  final ModelRepository<Parent> left;
  final ModelRepository<Child> right;
  final String Function(Parent) on;
  final Filter where;

  const Join1to1({
    required this.left,
    required this.right,
    required this.on,
    this.where = const Filter.empty(),
  });

  @override
  Mergeable<Join<Join<Parent, Child?>, RightModel?>> merge1to1<RightModel>(
    ModelRepository<RightModel> right, {
    required String Function(Join<Parent, Child?> p1) on,
    Filter where = const Filter.empty(),
  }) {
    return Join1to1(left: left, right: right, on: on, where: where);
  }

  @override
  Mergeable<Join<Join<Parent, Child?>, List<RightModel>>> merge1toN<RightModel>(
    ModelRepository<RightModel> right, {
    required Filter Function(Join<Parent, Child?> p1) on,
    Filter where = const Filter.empty(),
  }) {
    throw 1;
  }
}

class OneToMany<Parent, Child> {
  final ModelRepository<Parent> left;
  final ModelRepository<Child> right;
  final String Function(Parent) on;
  final Filter where;

  const OneToMany({
    required this.left,
    required this.right,
    required this.on,
    this.where = const Filter.empty(),
  });

  // Join<Parent, List<Join<Child, RightModel?>>>
  @override
  Mergeable<Join<Parent, List<Join<Child, RightModel?>>>> merge1to1<RightModel>(
    ModelRepository<RightModel> right, {
    required String Function(Join<Parent, List<Child>> p1) on,
    Filter where = const Filter.empty(),
  }) {}

  // Join<Parent, List<Join<Child, List<RightModel>>>>
  @override
  Mergeable<Join<Join<Parent, List<Child>>, List<RightModel>>>
      merge1toN<RightModel>(
    ModelRepository<RightModel> right, {
    required Filter Function(Join<Parent, List<Child>> p1) on,
    Filter where = const Filter.empty(),
  }) {
    // TODO: implement merge1toN
    throw UnimplementedError();
  }
}

class JJ<A, B, C> implements Mergeable<Join<Join<A, B>, C>> {
  @override
  Mergeable<Join<Join<Join<A, B>, C>, RightModel?>> merge1to1<RightModel>(
    ModelRepository<RightModel> right, {
    required String Function(Join<Join<A, B>, C> p1) on,
    Filter where = const Filter.empty(),
  }) {}

  @override
  Mergeable<Join<Join<Join<A, B>, C>, List<RightModel>>> merge1toN<RightModel>(
    ModelRepository<RightModel> right, {
    required Filter Function(Join<Join<A, B>, C> p1) on,
    Filter where = const Filter.empty(),
  }) {}
}

abstract class Join1toN<LeftModel, RightModel> {
  final ModelRepository<LeftModel> left;
  final ModelRepository<RightModel> right;
  final Filter Function(LeftModel) on;
  final Filter where;

  Join1toN({
    required this.left,
    required this.right,
    required this.on,
    this.where = const Filter.empty(),
  });
}

Multiple1to1Stream<LeftModel, RightModel> merge1to1<LeftModel, RightModel>({
  required ModelRepository<LeftModel> left,
  required ModelRepository<RightModel> right,
  required String Function(LeftModel) on,
  Filter query = const Filter.empty(),
}) {
  return left //
      .pullAll(query)
      .flatMap((leftModels) => CombineLatestStream.list(leftModels //
          .map((leftModel) => right //
              .pull(on(leftModel))
              .map((rightModel) => Join(left: leftModel, right: rightModel)))));
}

Multiple1toNStream<LeftModel, RightModel> merge1toN<LeftModel, RightModel>({
  required ModelRepository<LeftModel> left,
  required ModelRepository<RightModel> right,
  required Filter Function(LeftModel) on,
  Filter query = const Filter.empty(),
}) {
  return left.pullAll(query).flatMap((leftModels) {
    if (leftModels.isEmpty) return Stream.value([]);
    return CombineLatestStream.list(leftModels.map((leftModel) {
      return right.pullAll(on(leftModel)).map((rightModels) {
        return Join(left: leftModel, right: rightModels);
      });
    }));
  });
}

MtoNStream<LeftModel, MiddleModel, RightModel>
    mergeMtoN<LeftModel, MiddleModel, RightModel>({
  required ModelRepository<LeftModel> left,
  required ModelRepository<MiddleModel> middle,
  required ModelRepository<RightModel> right,
  required Filter Function(LeftModel) onMiddle,
  required String Function(MiddleModel) onRight,
  Filter query = const Filter.empty(),
}) {
  return left.pullAll(query).flatMap((leftModels) {
    if (leftModels.isEmpty) return Stream.value([]);
    return CombineLatestStream.list(leftModels.map((leftModel) {
      return middle
          .pullAll(onMiddle(leftModel))
          .flatMap<List<Join<MiddleModel, RightModel?>>>((middleModels) {
        if (middleModels.isEmpty) return Stream.value([]);
        return CombineLatestStream.list(middleModels.map((middleModel) {
          return right
              .pull(onRight(middleModel))
              .map((rightModel) => Join(left: middleModel, right: rightModel));
        }));
      }).map((children) => Join(left: leftModel, right: children));
    }));
  });
}
