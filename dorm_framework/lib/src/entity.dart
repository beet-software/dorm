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

/// Represents the conversion of a [Model] into dORM's model system.
abstract class Entity<Data, Model extends Data> {
  /// The name of the table of this entity in the underlying database engine.
  String get tableName;

  /// Deserializes the [id] and the [data] of a row in the underlying database
  /// engine to a [Model].
  ///
  /// ```dart
  /// final Entity<SchoolData, School> entity = ...;
  ///
  /// const String id = 'd12207624e35';
  /// const Map<String, Object?> data = {'name': 'S1', 'active': false};
  ///
  /// final School school = entity.fromJson(id, data);
  /// print(school.id);        // 'd12207624e35'
  /// print(school.name);      // 'S1'
  /// print(school.active);    // false
  /// ```
  ///
  /// In most of the cases, this method implementation is
  ///
  /// ```dart
  /// Model fromJson(String id, Map data) => Model.fromJson(id, data);
  /// ```
  Model fromJson(String id, Map data);

  /// Serializes [data] to the underlying database engine representation.
  ///
  /// ```dart
  /// final Entity<SchoolData, School> entity = ...;
  ///
  /// final School school = School(id: 'd12207624e35', name: 'S1', active: false);
  /// final Map<String, Object?> json = entity.toJson(school);
  /// print(json);    // {'name': 'S1', 'active': false}
  /// ```
  ///
  /// In most of the cases, this method implementation is
  ///
  /// ```dart
  /// Map<String, Object?> toJson(Data data) => data.toJson();
  /// ```
  Map<String, Object?> toJson(Data data);

  /// Assign all the fields of [data] to an existing [model] preserving
  /// additional fields.
  ///
  /// ```dart
  /// final Entity<SchoolData, School> entity = ...;
  /// final School school = School(id: 'd12207624e35', name: 'S1', active: false);
  /// final SchoolData data = SchoolData(name: 'S2', active: true);
  ///
  /// final School updatedSchool = entity.convert(school, data);
  /// print(updatedSchool.id);        // 'd12207624e35'
  /// print(updatedSchool.name);      // 'S2'
  /// print(updatedSchool.active);    // false
  /// ```
  ///
  /// Act as a `copyWith` method and is useful when editing existing data
  /// through a form.
  Model convert(Model model, Data data);

  /// Creates a [Model] using its [dependency], an unique [id] and its [data].
  ///
  /// ```dart
  /// final School school = School(id: 'd12207624e35', name: 'S1', active: true);
  /// final Dependency<StudentData> dependency = StudentDependency(schoolId: school.id);
  /// final String id = 'cc03334e70a9';
  /// final StudentData data = StudentData(name: 'John', birthDate: DateTime(1942, 6, 13));
  ///
  /// final Entity<StudentData, Student> entity = ...;
  /// final Student student = entity.fromData(dependency, id, data);
  /// print(student.id);            // This value depends on the identification
  ///                               // strategy used by the implementation of
  ///                               // this method. Usually, the default is to
  ///                               // just duplicate the `id` variable passed as
  ///                               // argument to `fromData`, but it is also
  ///                               // common to implement custom logic.
  ///
  /// print(student.name);          // 'John'
  /// print(student.birthDate);     // 13/06/1942
  /// ```
  ///
  /// Its useful when modeling *new* data received from a form.
  Model fromData(covariant Dependency<Data> dependency, String id, Data data);

  /// Uniquely identify a [model].
  ///
  /// ```dart
  /// final Entity<SchoolData, School> entity = ...;
  /// final School school = School(id: 'd12207624e35', name: 'S2', active: false);
  /// print(entity.identify(school));    // 'd12207624e35'
  /// ```
  ///
  /// In most of the cases, this method implementation is
  ///
  /// ```
  /// String identify(Model model) => model.id;
  /// ```
  String identify(Model model);
}

/// Represents the bridge between a database engine and a controller.
class DatabaseEntity<Data, Model extends Data, Q extends BaseQuery<Q>>
    implements Entity<Data, Model> {
  final Entity<Data, Model> _entity;
  final BaseReference<Q> _reference;
  final BaseRelationship<Q> _relationship;

  DatabaseEntity(
    Entity<Data, Model> entity, {
    required BaseEngine<Q> engine,
  })  : _entity = entity,
        _reference = engine.createReference(),
        _relationship = engine.createRelationship();

  ModelRelationship<Model, Q> get relationships {
    return ModelRelationship(left: repository, relationship: _relationship);
  }

  /// The controller of this entity.
  Repository<Data, Model, Q> get repository {
    return Repository(
      entity: _entity,
      reference: _reference,
      relationship: _relationship,
    );
  }

  @override
  Model convert(Model model, Data data) => _entity.convert(model, data);

  @override
  Model fromData(covariant Dependency<Data> dependency, String id, Data data) =>
      _entity.fromData(dependency, id, data);

  @override
  Model fromJson(String id, Map data) => _entity.fromJson(id, data);

  @override
  String identify(Model model) => _entity.identify(model);

  @override
  String get tableName => _entity.tableName;

  @override
  Map<String, Object?> toJson(Data data) => _entity.toJson(data);
}
