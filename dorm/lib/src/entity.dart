import 'dependency.dart';

abstract class Entity<Data, Model extends Data> {
  /// The name of the database table of this entity.
  ///
  /// ```dart
  /// final Entity<SchoolData, School> entity = ...;
  ///
  /// // Firebase example
  /// final DataSnapshot snapshot = await FirebaseDatabase
  ///     .instance
  ///     .ref(entity.tableName)
  ///     .get();
  ///
  /// print(snapshot.children.length);    // The number of schools on the database
  /// ```
  String get tableName;

  /// Converts an [id] and its [data] as JSON on the database to a [Model].
  ///
  /// ```dart
  /// final Entity<SchoolData, School> entity = ...;
  ///
  /// // Firebase example
  /// final DataSnapshot snapshot = await FirebaseDatabase
  ///     .instance
  ///     .ref('schools/1')
  ///     .get();
  ///
  /// final String id = snapshot.key;            // '1'
  /// final Map data = snapshot.value as Map;    // {name: "S1", active: false}
  ///
  /// final School school = entity.fromJson(id, data);
  /// print(school.id);        // '1'
  /// print(school.name);      // 'S1'
  /// print(school.active);    // false
  /// ```
  Model fromJson(String id, Map data);

  /// Converts [data] to a JSON representation.
  ///
  /// ```dart
  /// final Entity<SchoolData, School> entity = ...;
  ///
  /// final School school = School(id: '1', name: 'S1', active: false);
  /// final Map<String, Object?> json = entity.toJson(school);
  /// print(json);    // {name: "S1", active: false}
  /// ```
  Map<String, Object?> toJson(Data data);

  /// Assign all the fields of [data] to an existing [model] preserving
  /// additional fields.
  ///
  /// ```dart
  /// final Entity<SchoolData, School> entity = ...;
  /// final SchoolData data = SchoolData(name: 'S1', active: true);
  /// final School school = School(id: '1', name: 'S2', active: false);
  ///
  /// final School updatedSchool = entity.convert(school, data);
  /// print(updatedSchool.id);        // '1'
  /// print(updatedSchool.name);      // 'S1'
  /// print(updatedSchool.active);    // true
  /// ```
  ///
  /// Act as a `copyWith` method and is useful when editing existing data
  /// through a form.
  Model convert(Model model, Data data);

  /// Builds a [Model] using its [dependency], an unique [id] and its [data].
  ///
  /// ```dart
  /// final School school = School(id: '1', name: 'S1', active: true);
  /// final Dependency<StudentData> dependency = StudentDependency(schoolId: school.id);
  /// final String id = ...;   // Can be Uuid().v4() from `uuid` package
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

  /// Provides a way to uniquely identify this model.
  ///
  /// ```dart
  /// final Entity<SchoolData, School> entity = ...;
  /// final School school = School(id: '1', name: 'S2', active: false);
  /// print(entity.identify(school));    // '1'
  /// ```
  ///
  /// Most of the cases, this method implementation is
  ///
  /// ```
  /// String identify(Model model) => model.id;
  /// ```
  String identify(Model model);
}
