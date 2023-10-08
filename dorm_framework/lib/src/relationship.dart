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

import 'filter.dart';
import 'repository.dart';

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
abstract class Readable2<SingleReadModel, BatchReadModel>
    implements
        SingleReadOperation<SingleReadModel>,
        BatchReadOperation<BatchReadModel> {}

/// A type that can evaluate [Model] given a [String] and a list of [Model]s
/// given a [Filter].
///
/// This is a special case of [Readable2].
typedef Readable<Model> = Readable2<Model, Model>;

/// A type that can evaluate a [Join] between [L] and [SingleR] given a
/// [String] and a list of [Join]s between [L] and [BatchR] given a [Filter].
typedef Association2<L, SingleR, BatchR>
    = Readable2<Join<L, SingleR>, Join<L, BatchR>>;

/// A type that can evaluate *V* given a [String] and to a list of *V* given a
/// [Filter], where *V* is a [Join] between [L] and [R].
///
/// This is a special case of [Association2].
typedef Association<L, R> = Association2<L, R, R>;

/// An association that evaluates joins between [L] to [R]?.
typedef OneToOneAssociation<L, R> = Association<L, R?>;

/// An association that evaluates joins between [L] and a list of [R]s.
typedef OneToManyAssociation<L, R> = Association<L, List<R>>;

/// An association that evaluates a join between [R] and [L] given a [String]
/// and joins between [R] and a list of [L] given a [Filter].
typedef ManyToOneAssociation<L, R> = Association2<R, L, List<L>>;

/// An association that evaluates joins between [M] and a tuple of [L] and [R].
typedef ManyToManyAssociation<M, L, R> = Association<M, (L?, R?)>;

/// Declares associations between any two models.
abstract class BaseRelationship {
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
  OneToOneAssociation<L, R> oneToOne<L, R>(
    Readable<L> left,
    Readable<R> right,
    String Function(L) on,
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
  ///   on: (school) => Filter.value(school.id, key: 'school-id'),
  /// );
  /// final Stream<List<Join<School, List<Student>>>> result = association
  ///     .pullAll(const Filter.value(true, key: 'active'));
  /// ```
  OneToManyAssociation<L, R> oneToMany<L, R>(
    Readable<L> left,
    Readable<R> right,
    Filter Function(L) on,
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
  ManyToOneAssociation<L, R> manyToOne<L, R>(
    Readable<L> left,
    Readable<R> right,
    String Function(L) on,
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
  ManyToManyAssociation<M, L, R> manyToMany<M, L, R>(
    Readable<M> middle,
    Readable<L> left,
    String Function(M) onLeft,
    Readable<R> right,
    String Function(M) onRight,
  );
}

/// Declares join-oriented reading and relationship assignment.
class RelationshipDefinedAssociation<L, R> implements Association<L, R> {
  final BaseRelationship _relationship;
  final Association<L, R> _association;

  /// Creates a [RelationshipDefinedAssociation] by its attributes.
  const RelationshipDefinedAssociation(
    this._relationship, {
    required Association<L, R> association,
  }) : _association = association;

  /// Evaluates the underlying association's [SingleReadOperation.peek] method.
  @override
  Future<Join<L, R>?> peek(String id) {
    return _association.peek(id);
  }

  /// Evaluates the underlying association's [BatchReadOperation.peekAll] method.
  @override
  Future<List<Join<L, R>>> peekAll([
    Filter filter = const Filter.empty(),
  ]) {
    return _association.peekAll(filter);
  }

  /// Evaluates the underlying association's [SingleReadOperation.pull] method.
  @override
  Stream<Join<L, R>?> pull(String id) {
    return _association.pull(id);
  }

  /// Evaluates the underlying association's [BatchReadOperation.pullAll] method.
  @override
  Stream<List<Join<L, R>>> pullAll([
    Filter filter = const Filter.empty(),
  ]) {
    return _association.pullAll(filter);
  }

  /// Associates the underlying association with a [readable] using a 1:1
  /// relationship given by [on].
  RelationshipDefinedAssociation<Join<L, R>, T?> oneToOne<T>(
    Readable<T> readable, {
    required String Function(Join<L, R>) on,
  }) {
    return RelationshipDefinedAssociation(
      _relationship,
      association: _relationship.oneToOne(this, readable, on),
    );
  }

  /// Associates the underlying association with a [readable] using a 1:N
  /// relationship given by [on].
  RelationshipDefinedAssociation<Join<L, R>, List<T>> oneToMany<T>(
    Readable<T> readable, {
    required Filter Function(Join<L, R>) on,
  }) {
    return RelationshipDefinedAssociation(
      _relationship,
      association: _relationship.oneToMany(this, readable, on),
    );
  }

  /// Associates the underlying association with a [readable] using a N:1
  /// relationship given by [on].
  ManyToOneAssociation<Join<L, R>, T> manyToOne<T>(
    Readable<T> readable, {
    required String Function(Join<L, R>) on,
  }) {
    return _relationship.manyToOne(this, readable, on);
  }

  /// Associates the underlying association with a [readable] through [middle]
  /// using a M:N relationship given by [onJoin] and [on].
  RelationshipDefinedAssociation<M, (Join<L, R>?, T?)> manyToMany<M, T>({
    required Readable<M> middle,
    required String Function(M p1) onJoin,
    required Readable<T> readable,
    required String Function(M p1) on,
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
class ModelRelationship<L> {
  final BaseRelationship relationship;
  final Readable<L> left;

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
  RelationshipDefinedAssociation<L, R?> oneToOne<R>(
    Readable<R> right, {
    required String Function(L) on,
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
  ///   on: (school) => Filter.value(school.id, key: 'school-id'),
  /// );
  /// final Stream<List<Join<School, List<Student>>>> result = association
  ///     .pullAll(const Filter.value(true, key: 'active'));
  /// ```
  RelationshipDefinedAssociation<L, List<R>> oneToMany<R>(
    Readable<R> right, {
    required Filter Function(L) on,
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
  ManyToOneAssociation<L, R> manyToOne<R>(
    Readable<R> right, {
    required String Function(L) on,
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
  RelationshipDefinedAssociation<L, (RL?, RR?)> manyToMany<RL, RR>({
    required Readable<RL> left,
    required String Function(L) onLeft,
    required Readable<RR> right,
    required String Function(L) onRight,
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
