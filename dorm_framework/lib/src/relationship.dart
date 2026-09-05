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

class Join<LeftModel, RightModel> {
  final LeftModel left;
  final RightModel right;

  const Join({required this.left, required this.right});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Join &&
          runtimeType == other.runtimeType &&
          left == other.left &&
          right == other.right;

  @override
  int get hashCode => left.hashCode ^ right.hashCode;
}

/// A type that can evaluate [SingleReadModel] given a [String] and a list of
/// [BatchReadModel]s given a [Filter].
abstract class Readable2<SingleReadModel, I extends Object, BatchReadModel,
        Q extends BaseQuery<Q>>
    implements
        SingleReadOperation<SingleReadModel, I>,
        BatchReadOperation<BatchReadModel, Q> {}

/// A type that can evaluate [Model] given a [String] and a list of [Model]s
/// given a [Filter].
///
/// This is a special case of [Readable2].
typedef Readable<Model, I extends Object, Q extends BaseQuery<Q>> = Readable2<Model, I, Model, Q>;

/// A readable model source with a backend-neutral relationship plan.
///
/// A table-backed source exposes its [TableRelationPlan]. A composed
/// relationship exposes a [CompositeRelationPlan]. Engines may use the plan
/// to optimize execution, while sources that cannot be optimized still use
/// the regular [Readable] operations.
abstract interface class RelationSource<
        Model, I extends Object, Q extends BaseQuery<Q>>
    implements Readable<Model, I, Q> {
  RelationPlan<Model, I> get plan;

  /// The schema of a direct table source, or `null` for a composed source.
  EntitySchema? get schema => plan.schema;
}

/// Describes how a [RelationSource] can be executed by an engine.
abstract class RelationPlan<Model, I extends Object> {
  const RelationPlan();

  /// The table schema when this plan represents a direct table.
  EntitySchema? get schema => null;
}

/// Non-generic view of a table plan for engine implementations.
abstract interface class TableRelationPlanBase {
  EntitySchema get schema;

  Object? decode(Map<String, Object?> data);
}

/// A plan for a source backed directly by an [EntitySchema].
class TableRelationPlan<Model, I extends Object>
    extends RelationPlan<Model, I> implements TableRelationPlanBase {
  final Model Function(I id, Map data) fromJson;

  @override
  final EntitySchema schema;

  const TableRelationPlan({
    required this.schema,
    required this.fromJson,
  });

  @override
  Object? decode(Map<String, Object?> data) {
    final I id = data[schema.primaryKey.columnName] as I;
    return fromJson(id, data);
  }
}

/// A plan for a source produced by another relationship.
class CompositeRelationPlan<Model, I extends Object>
    extends RelationPlan<Model, I> {
  const CompositeRelationPlan();
}

/// A type that can evaluate a [Join] between [L] and [SingleR] given a
/// [String] and a list of [Join]s between [L] and [BatchR] given a [Filter].
typedef Association2<L, I extends Object, SingleR, BatchR, Q extends BaseQuery<Q>>
    = Readable2<Join<L, SingleR>, I, Join<L, BatchR>, Q>;

/// A type that can evaluate *V* given a [String] and to a list of *V* given a
/// [Filter], where *V* is a [Join] between [L] and [R].
///
/// This is a special case of [Association2].
typedef Association<L, I extends Object, R, Q extends BaseQuery<Q>> = Association2<L, I, R, R, Q>;

/// An association that evaluates joins between [L] to [R]?.
typedef OneToOneAssociation<L, I extends Object, R, Q extends BaseQuery<Q>> = Association<L, I, R?, Q>;

/// An association that evaluates joins between [L] and a list of [R]s.
typedef OneToManyAssociation<L, I extends Object, R, Q extends BaseQuery<Q>> = Association<L, I, List<R>, Q>;

/// An association that evaluates a join between [R] and [L] given a [String]
/// and joins between [R] and a list of [L] given a [Filter].
typedef ManyToOneAssociation<L, I extends Object, R, J extends Object, Q extends BaseQuery<Q>> = Association2<R, I, L, List<L>, Q>;

/// An association that evaluates joins between [M] and a tuple of [L] and [R].
typedef ManyToManyAssociation<M, I extends Object, L, R, Q extends BaseQuery<Q>> = Association<M, I, (L?, R?), Q>;

/// Declares associations between any two models.
abstract class BaseRelationship<Q extends BaseQuery<Q>> {
  /// Represents an one-to-one operation.
  ///
  /// Let's suppose you have two models: `School` and `Principal`. Since a
  /// `School` has only one `Principal`, this is a 1-to-1 relationship:
  ///
  /// ```dart
  /// final Relationship relationship /* = ... */;
  /// final Repository<SchoolData, School> schools /* = ... */;
  /// final Repository<PrincipalData, Principal> principals /* = ... */;
  ///
  /// final OneToOneAssociation<School, Principal> association = relationship.oneToOne(
  ///   left: schools,
  ///   right: principals,
  ///   on: (school) => school.principalId,
  /// );
  /// final Stream<List<Join<School, Principal?>>> result = association
  ///     .pullAll(const Filter.value(true, key: 'active'));
  /// ```
  OneToOneAssociation<L, I, R, Q> oneToOne<L, I extends Object, R, J extends Object>(
    RelationSource<L, I, Q> left,
    RelationSource<R, J, Q> right,
    J Function(L) on,
  );

  /// Represents an one-to-many operation.
  ///
  /// Let's suppose you have two models: `School` and `Student`. Since a
  /// `School` can have more than one `Student`, this is a 1-to-N relationship:
  ///
  /// ```dart
  /// final Relationship relationship /* = ... */;
  /// final Repository<SchoolData, School> schools = ...;
  /// final Repository<StudentData, Student> students = ...;
  ///
  /// final OneToManyAssociation<School, Student> association = relationship.oneToMany(
  ///   left: schools,
  ///   right: students,
  ///   on: (school) => Filter.value(school.id, field: StudentEntity.fields.schoolId),
  /// );
  /// final Stream<List<Join<School, List<Student>>>> result = association
  ///     .pullAll(const Filter.value(true, key: 'active'));
  /// ```
  OneToManyAssociation<L, I, R, Q> oneToMany<L, I extends Object, R, J extends Object>(
    RelationSource<L, I, Q> left,
    RelationSource<R, J, Q> right,
    BaseFilter<Q> Function(L) on,
  );

  /// Represents a many-to-one operation.
  ///
  /// Let's suppose you have two models: `School` and `Student`. Since a
  /// `School` can have more than one `Student`, this is a 1-to-N relationship.
  /// If you want to fetch all schools and their respective students, you can use
  /// [oneToMany]. However, not all schools have students. Using this operation
  /// can omit the schools without students (a right-join):
  ///
  /// ```dart
  /// final Relationship relationship /* = ... */;
  /// final Repository<SchoolData, School> schools /* = ... */;
  /// final Repository<StudentData, Student> students /* = ... */;
  ///
  /// final ManyToOneAssociation<School, Student> association = relationship.manyToOne(
  ///   left: students,
  ///   right: schools,
  ///   on: (student) => student.schoolId,
  /// );
  /// final Stream<List<Join<School, List<Student>>>> result = association
  ///     .pullAll(Filter.date(DateTime(2018), key: 'birth-date', unit: DateFilterUnit.year));
  /// ```
  ManyToOneAssociation<L, I, R, J, Q> manyToOne<L, I extends Object, R, J extends Object>(
    RelationSource<L, I, Q> left,
    RelationSource<R, J, Q> right,
    J Function(L) on,
  );

  /// Represents a many-to-many operation.
  ///
  /// Let's suppose you have two models: `School`, `Professor` and `Teaching`.
  /// Since a `Professor` can teach on more than one `School`, this is a M-to-N
  /// relationship through `Teaching`:
  ///
  /// ```dart
  /// final Relationship relationship /* = ... */;
  /// final Repository<TeachingData, Teaching> teachings /* = ... */;
  /// final Repository<SchoolData, School> schools /* = ... */;
  /// final Repository<StudentData, Student> students /* = ... */;
  ///
  /// final ManyToManyAssociation<Teaching, School, Student> association = relationship.manyToMany(
  ///   middle: teachings,
  ///   left: students,
  ///   onLeft: (teaching) => teaching.studentId,
  ///   right: schools,
  ///   onRight: (teaching) => teaching.schoolId,
  /// );
  /// final Stream<List<Join<Teaching, (School?, Student?)>>> result = association
  ///     .pullAll(Filter.value(true, key: 'active'));
  /// ```
  ManyToManyAssociation<M, I, L, R, Q> manyToMany<M, I extends Object, L, J extends Object, R, K extends Object>(
    RelationSource<M, I, Q> middle,
    RelationSource<L, J, Q> left,
    J Function(M) onLeft,
    RelationSource<R, K, Q> right,
    K Function(M) onRight,
  );
}

/// Declares join-oriented reading and relationship assignment.
class RelationshipDefinedAssociation<L, I extends Object, R, Q extends BaseQuery<Q>>
    implements Association<L, I, R, Q>, RelationSource<Join<L, R>, I, Q> {
  final BaseRelationship<Q> _relationship;
  final Association<L, I, R, Q> _association;

  /// Creates a [RelationshipDefinedAssociation] by its attributes.
  const RelationshipDefinedAssociation(
    this._relationship, {
    required Association<L, I, R, Q> association,
  }) : _association = association;

  @override
  RelationPlan<Join<L, R>, I> get plan => const CompositeRelationPlan();

  @override
  EntitySchema? get schema => null;

  /// Evaluates the underlying association's [SingleReadOperation.peek] method.
  @override
  Future<Join<L, R>?> peek(I id) {
    return _association.peek(id);
  }

  /// Evaluates the underlying association's [BatchReadOperation.peekAll] method.
  @override
  Future<List<Join<L, R>>> peekAll([
    BaseFilter<Q> filter = const BaseFilter.empty(),
  ]) {
    return _association.peekAll(filter);
  }

  /// Evaluates the underlying association's [SingleReadOperation.pull] method.
  @override
  Stream<Join<L, R>?> pull(I id) {
    return _association.pull(id);
  }

  /// Evaluates the underlying association's [BatchReadOperation.pullAll] method.
  @override
  Stream<List<Join<L, R>>> pullAll([
    BaseFilter<Q> filter = const BaseFilter.empty(),
  ]) {
    return _association.pullAll(filter);
  }

  /// Associates the underlying association with a [readable] using a 1:1
  /// relationship given by [on].
  RelationshipDefinedAssociation<Join<L, R>, I, T?, Q> oneToOne<T, J extends Object>(
    RelationSource<T, J, Q> readable, {
    required J Function(Join<L, R>) on,
  }) {
    return RelationshipDefinedAssociation(
      _relationship,
      association: _relationship.oneToOne(this, readable, on),
    );
  }

  /// Associates the underlying association with a [readable] using a 1:N
  /// relationship given by [on].
  RelationshipDefinedAssociation<Join<L, R>, I, List<T>, Q> oneToMany<T, J extends Object>(
    RelationSource<T, J, Q> readable, {
    required BaseFilter<Q> Function(Join<L, R>) on,
  }) {
    return RelationshipDefinedAssociation(
      _relationship,
      association: _relationship.oneToMany(this, readable, on),
    );
  }

  /// Associates the underlying association with a [readable] using a N:1
  /// relationship given by [on].
  ManyToOneAssociation<Join<L, R>, I, T, J, Q> manyToOne<T, J extends Object>(
    RelationSource<T, J, Q> readable, {
    required J Function(Join<L, R>) on,
  }) {
    return _relationship.manyToOne(this, readable, on);
  }

  /// Associates the underlying association with a [readable] through [middle]
  /// using a M:N relationship given by [onJoin] and [on].
  RelationshipDefinedAssociation<M, J, (Join<L, R>?, T?), Q> manyToMany<M, J extends Object, T, K extends Object>({
    required RelationSource<M, J, Q> middle,
    required J Function(M p1) onJoin,
    required RelationSource<T, K, Q> readable,
    required K Function(M p1) on,
  }) {
    return RelationshipDefinedAssociation(
      _relationship,
      association: _relationship.manyToMany(
        middle,
        this,
        onJoin,
        readable,
        on,
      ),
    );
  }
}

/// Declares associations between [left] and another model.
///
/// A [Relationship] associates two models by declaring two parameters to each
/// method in the class. In the other hand, a [ModelRelationship] associates
/// two models by declaring a [left] property and a parameter to each method in
/// this class. Basically, calling
///
/// ```dart
/// final Relationship relationship /* = ... */;
/// relationship.oneToOne<L, R>(left, right, on);
/// ```
///
/// is virtually the same as calling
///
/// ```dart
/// final ModelRelationship<L> relationship = ModelRelationship(
///   left: left,
///   relationship: /* ... */,
/// );
/// relationship.oneToOne<R>(right, on);
/// ```
class ModelRelationship<L, I extends Object, Q extends BaseQuery<Q>> {
  final BaseRelationship<Q> relationship;
  final RelationSource<L, I, Q> left;

  /// Creates a [ModelRelationship] from its attributes.
  const ModelRelationship({
    required this.relationship,
    required this.left,
  });

  /// Represents an one-to-one .
  ///
  /// Let's suppose you have two models: `School` and `Principal`. Since a
  /// `School` has only one `Principal`, this is a 1-to-1 relationship:
  ///
  /// ```dart
  /// final ModelRelationship<School> relationship /* = ... */;
  /// final Repository<PrincipalData, Principal> principals /* = ... */;
  ///
  /// final Association<School, Principal?> association;
  /// association = relationship.oneToOne(
  ///   principals,
  ///   on: (school) => school.principalId,
  /// );
  /// final Stream<List<Join<School, Principal?>>> result = association
  ///     .pullAll(const Filter.value(true, key: 'active'));
  /// ```
  RelationshipDefinedAssociation<L, I, R?, Q> oneToOne<R, J extends Object>(
    RelationSource<R, J, Q> right, {
    required J Function(L) on,
  }) {
    return RelationshipDefinedAssociation(
      relationship,
      association: relationship.oneToOne(left, right, on),
    );
  }

  /// Represents an one-to-many association.
  ///
  /// Let's suppose you have two models: `School` and `Student`. Since a
  /// `School` can have more than one `Student`, this is a 1-to-N relationship:
  ///
  /// ```dart
  /// final ModelRelationship<School> relationship /* = ... */;
  /// final Repository<StudentData, Student> students = ...;
  ///
  /// final Association<School, List<Student>> association;
  /// association = relationship.oneToMany(
  ///   students,
  ///   on: (school) => Filter.value(school.id, field: StudentEntity.fields.schoolId),
  /// );
  /// final Stream<List<Join<School, List<Student>>>> result = association
  ///     .pullAll(const Filter.value(true, key: 'active'));
  /// ```
  RelationshipDefinedAssociation<L, I, List<R>, Q> oneToMany<R, J extends Object>(
    RelationSource<R, J, Q> right, {
    required BaseFilter<Q> Function(L) on,
  }) {
    return RelationshipDefinedAssociation(
      relationship,
      association: relationship.oneToMany(left, right, on),
    );
  }

  /// Represents a many-to-one association.
  ///
  /// Let's suppose you have two models: `School` and `Student`. Since a
  /// `School` can have more than one `Student`, this is a 1-to-N relationship.
  /// If you want to fetch all schools and their respective students, you can use
  /// [oneToMany]. However, not all schools have students. Using this operation
  /// can omit the schools without students (a right-join):
  ///
  /// ```dart
  /// final Relationship<School> relationship /* = ... */;
  /// final Repository<StudentData, Student> students /* = ... */;
  ///
  /// final ManyToOneAssociation<School, Student> association;
  /// association = relationship.manyToOne(
  ///   schools,
  ///   on: (student) => student.schoolId,
  /// );
  /// final Stream<List<Join<School, List<Student>>>> result = association
  ///     .pullAll(Filter.date(DateTime(2018), key: 'birth-date', unit: DateFilterUnit.year));
  /// ```
  ManyToOneAssociation<L, I, R, J, Q> manyToOne<R, J extends Object>(
    RelationSource<R, J, Q> right, {
    required J Function(L) on,
  }) {
    return relationship.manyToOne(left, right, on);
  }

  /// Represents a many-to-many association.
  ///
  /// Let's suppose you have two models: `School`, `Professor` and `Teaching`.
  /// Since a `Professor` can teach on more than one `School`, this is a M-to-N
  /// relationship through `Teaching`:
  ///
  /// ```dart
  /// final Relationship<Teaching> relationship /* = ... */;
  /// final Repository<SchoolData, School> schools /* = ... */;
  /// final Repository<StudentData, Student> students /* = ... */;
  ///
  /// final Association<Teaching, (School?, Student?)> association;
  /// association = relationship.manyToMany(
  ///   left: students,
  ///   onLeft: (teaching) => teaching.studentId,
  ///   right: schools,
  ///   onRight: (teaching) => teaching.schoolId,
  /// );
  /// final Stream<List<Join<Teaching, (School?, Student?)>>> result = association
  ///     .pullAll(Filter.value(true, key: 'active'));
  /// ```
  RelationshipDefinedAssociation<L, I, (RL?, RR?), Q> manyToMany<RL, J extends Object, RR, K extends Object>({
    required RelationSource<RL, J, Q> left,
    required J Function(L) onLeft,
    required RelationSource<RR, K, Q> right,
    required K Function(L) onRight,
  }) {
    return RelationshipDefinedAssociation(
      relationship,
      association: relationship.manyToMany(
        this.left,
        left,
        onLeft,
        right,
        onRight,
      ),
    );
  }
}
