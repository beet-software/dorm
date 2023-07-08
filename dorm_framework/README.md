# dorm_framework

[![pub package](https://img.shields.io/pub/v/dorm_framework.svg?label=dorm_framework)](https://pub.dev/packages/dorm_framework)
[![pub popularity](https://img.shields.io/pub/popularity/dorm_framework?logo=dart)](https://pub.dev/packages/dorm_framework)
[![pub likes](https://img.shields.io/pub/likes/dorm_framework?logo=dart)](https://pub.dev/packages/dorm_framework)
[![pub points](https://img.shields.io/pub/points/dorm_framework?logo=dart)](https://pub.dev/packages/dorm_framework)

An Object Relational Mapper framework for Dart.

## Table of contents

<!-- TOC start (generated with https://github.com/derlin/bitdowntoc) -->

- [Getting started](#getting-started)
- [Model](#model)
   * [Object structure](#object-structure)
   * [Serialization](#serialization)
   * [Dependency](#dependency)
   * [Instantiation](#instantiation)
   * [Entity](#entity)
- [Engine](#engine)
- [Controller](#controller)
   * [Operations](#operations)
      + [Creating](#creating)
      + [Reading](#reading)
      + [Updating](#updating)
      + [Deleting](#deleting)
    * [Filters](#filters)
      + [By value](#by-value)
      + [By text](#by-text)
      + [By dates](#by-dates)
      + [By amount](#by-amount)
    * [Relationships](#relationships)
      + [One-to-one](#one-to-one)
      + [One-to-many](#one-to-many)
      + [Many-to-one](#many-to-one)
      + [Many-to-many](#many-to-many)

<!-- TOC end -->



## Getting started

Run the following commands in your Dart or Flutter project:

```bash
dart pub add dorm_framework
dart pub get
```

## Model

> **Note**: This is a section that explains the *theoretical* concept of dORM: it uses the ideas and
> abstract principles related to dORM rather than the practical uses of it. You can automatize all
> of the steps below using code generation, provided by
> [`dorm_annotations`](https://pub.dev/packages/dorm_annotations) and
> [`dorm_generator`](https://pub.dev/packages/dorm_generator) packages. If you are interested on how
> dORM works behind the scenes, keep reading! Otherwise, go to the next section.

### Object structure

An object in this framework is split into two views: *data* and *model*.

Its *data* view contains all the information used by the real world to represent it. Consider a
database schema containing two tables: student and school. The school's data view is composed by its
name, its phone number and its address, while the student's data view is composed by its name, its
birth date, and its email. These are fields the system user can fill in forms, for example.

You can represent the data view of an object in Dart using a simple class:

```dart
class SchoolData {
  final String name;
  final String phoneNumber;
  final String address;

  const SchoolData({required this.name, required this.phoneNumber, required this.address});
}

class StudentData {
  final String name;
  final DateTime birthDate;
  final String email;

  const StudentData({required this.name, required this.birthDate, required this.email});
}
```

In the other hand, the *model* view of an object contains all the information used by the database
logic to represent it, such as identification and relationships. Every database object must have a
unique identification, therefore this field is included in the model view. A school does not need a
student to be created, so its model view has no further attributes. However, a student needs to be
associated with a school, so its model view has to be a reference to it.

You can represent the model view of an object in Dart also using a class, that inherits from the
data view class:

```dart
class School extends SchoolData {
  final String id;

  const School({
    required this.id,
    /* required super.declarations */
  });
}

class Student extends StudentData {
  final String id;
  final String schoolId;

  const Student({
    required this.id,
    required this.schoolId,
    /* required super.declarations */
  });
}
```

These fields aren't kept in a single class because of *separation of concerns*. A form should
only be concerned about real world information of a schema, not their primary or foreign keys. So
when using a form, use the *data* view. When reading from database, use the *model* view.

### Serialization

It's highly recommended to add serialization methods to each class, commonly implemented using
`fromJson` and `toJson`:

```dart
class SchoolData {
  // ...

  factory SchoolData.fromJson(Map<String, Object?> json) {
    return SchoolData(/* decode from JSON */);
  }

  // ...

  Map<String, Object?> toJson() =>
      {
        /*  encode to JSON */
      };
}

class School extends SchoolData {
  // ...

  // Since this is a schema model, you must pass an `id` parameter
  factory School.fromJson(String id, Map<String, Object?> json) {
    final SchoolData data = SchoolData.fromJson(json);
    return School(id: id, /* decode from data */);
  }

  // ...

  @override
  Map<String, Object?> toJson() =>
      {
        ...super.toJson(),
        /* encode to JSON */
      };
}
```

### Dependency

The dependency of an object *O* contains all the references to other objects that *O* depends to be
created (a.k.a. foreign keys). A school can exist without any student. Since there are no more models in our schema, we
can say that `School` does not depend on any model to exist, so its entity type is *strong*. A
student cannot exist without a school, since they study there. Since there are no more models in
this system, we can say that `Student` depends on `School` to exist, so its entity type is *weak*.
This reasoning is important to implement a dependency for a schema data, which is used when you want
to create a new model (an INSERT operation, for example) in the database.

You can represent the dependency of an object in Dart using a class that inherits from `Dependency`,
a class that this package exports:

```dart
import 'package:dorm_framework/dorm_framework.dart';

class SchoolDependency extends Dependency<SchoolData> {
  const SchoolDependency() : super.strong();
}

class StudentDependency extends Dependency<StudentData> {
  final String schoolId;

  StudentDependency({required this.schoolId}) : super.weak([schoolId]);
}
```

### Instantiation

To create a complete object, you can use two methods: create or update.

The following represents the update method:

```dart
void main() {
  // The model view you want to update
  final Student existing = Student(/*...*/);

  // The data view you want to overwrite
  final StudentData data = StudentData(/*...*/);

  // The updated object
  final Student updated = Student(
    id: existing.id,
    schoolId: existing.schoolId,
    name: data.name,
    birthDate: data.birthDate,
    email: data.email,
  );
}
```

Note that, for an update, you need an existing object to inherit from.

In a create transformation, this existing object is replaced by a `Dependency`:

```dart
void main() {
  // The data view you want to upgrade
  final StudentData data = StudentData(/*...*/);

  // The dependency you want to inject into the model view
  final StudentDependency dependency = StudentDependency(/*...*/);

  // The created model
  final Student current = Student(
    /* id: ..., */
    schoolId: dependency.schoolId,
    name: data.name,
    birthDate: data.birthDate,
    email: data.email,
  );
}
```

What can we use as primary key here? You can use some techniques depending on how your object should be identified:

- If your object needs to be uniquely identified across the system, use an unique identifier such as
  the one provided by the [`uuid` package](https://pub.dev/packages/uuid):

  ```dart
  import 'package:uuid/uuid.dart';

  String createId() => const Uuid().v4();
  ```

- If your object depends *exclusively* on another object (an one-to-one relationship), use a foreign
  primary key. For example, since a `Grade` belongs to a single `Student`, we could define its
  primary key as being the following:

  ```dart
  String createId(GradeDependency dependency) => dependency.studentId;
  ```

- If your object depends on other attributes of your object, use a logical primary key:

  ```dart
  String createId(StudentData data) => data.schoolCode == null ? data.ssn : data.schoolCode!;
  ```

These are only some methods that can be used to identify an object. Note that our fictional function
`createId` defined above can receive any kind of arguments (nothing, a data view, a dependency).
Therefore, we need to find a way to abstract it.

### Entity

The entity of an object acts as a bridge that can be used to manipulate the database. This is a
single and robust class, exported by this package, that joins data view, model view and dependency
into a single place.

You can represent the entity of an object in Dart using a class that inherits from `Entity`,
a class that this package exports:

```dart
class SchoolEntity implements Entity<SchoolData, School> {
  const SchoolEntity();

  @override
  String identify(School model) => model.id;

  @override
  School fromJson(String id, Map data) => School.fromJson(id, data);

  @override
  Map<String, Object?> toJson(SchoolData data) => data.toJson();

  // The name of this table in the database, equivalent to `CREATE TABLE schools` from SQL
  @override
  String get tableName => 'schools';

  // This represents the UPDATE method, see the previous section
  @override
  School convert(School model, SchoolData data) =>
      School(
        id: model.id,
        name: data.name,
        phoneNumber: data.phoneNumber,
        address: data.address,
      );

  // This represents the CREATE method, see the previous section
  @override
  School fromData(SchoolDependency dependency, String id, SchoolData data) {
    return School(
      // Choose your primary key strategy here
      id: id,
      name: data.name,
      phoneNumber: data.phoneNumber,
      address: data.address,
    );
  }
}
```

## Engine

An engine is a dORM component that enables communication between the model (defined in the previous section) 
and the controller. It behaves as a *pointer* to where the serialized models should be located and as a 
*guide* to how the controller should use its syntax to execute queries.

You can represent an engine in Dart using a class that inherits from `BaseEngine`, a class that this package
exports:

```dart
class Engine implements BaseEngine {
  BaseReference createReference() {}

  BaseRelationship createRelationship() {}
} 
```

Note that every engine must provide a reference, which allows the controller to execute queries, and a
relationship, which allows the controller to associate tables and join records.

At the moment, dORM exports two database engines through Dart packages: `dorm_bloc_database` and 
`dorm_firebase_database`. These two packages exports a class named `Engine`, which extends from
`BaseEngine`. You can access it by adding one of them to your *pubspec.yaml*, importing them 
within your code and accessing the exported class:

```dart
import 'package:dorm_*_database/dorm_*_database.dart' show Engine;

void main() {
  final BaseEngine engine = Engine(/* any required arguments */);
}
```

## Controller

In the Model section, we have created four classes for each table object in our database: 
`TableData`, `Table`, `TableDependency` and `TableEntity`.
In the Engine section, we have chosen a database engine and its respective `Engine` class.

These classes now can be used to be integrated with dORM using a database entity. It contains
all the concrete methods necessary for you to use the framework.

You can represent it in Dart by instantiating `DatabaseEntity`, a class that this package
exports:

```dart
import 'package:dorm_*_database/dorm_*_database.dart' show Engine;

void main() {
  final BaseEngine engine /* = ... */;
  const SchoolEntity entity = SchoolEntity();

  final DatabaseEntity<SchoolData, School> schoolController
      = DatabaseEntity(engine: engine, entity: entity);
}
```

Since `DatabaseEntity` inherits from `Entity`, you can access all its methods:

```dart
void main() {
  School school;
  final DatabaseEntity<SchoolData, School> controller /* = ... */;

  // Access the table name
  print(controller.tableName);    // schools

  // Decode a row
  school = controller.fromJson('123456', {'name': 'School'});

  // Encode a row
  final Map<String, Object?> data = controller.toJson(school);

  // Identify a model
  print(controller.identify(school));    // 123456

  // Create a model
  school = controller.fromData(
    SchoolDependency(),
    '123456',
    SchoolData(name: 'School'),
  );

  // Update a model
  school = controller.convert(school, SchoolData(name: 'College'));
}
```

### Operations

The `DatabaseEntity` class provides a `repository` field you can use to access all the 
CRUD methods (which conveniently all start with the letter *p*).

#### Creating

There are two methods available for creating: `put` and `putAll`.

The `put` method receives a dependency of an object and its data. Its primary concept is
to create a new row on the table. It returns the created model:

```dart
void main(Repository<SchoolData, School> repository) async {
  final School school = await repository.put(
    const SchoolDependency(),
    SchoolData(
      name: 'Harmony Academy',
      phoneNumber: '(555) 123-4567',
      address: '123 Main Street, Anytown, USA',
    ),
  );
}
```

The `putAll` method receives a dependency of an object and a collection of data. If
you have more than two or more data views that share the same dependency, this method is
preferred rather than calling `put` repeatedly. It returns the created models:

```dart
void main(Repository<SchoolData, School> repository) async {
  final List<School> schools = await repository.putAll(
    const SchoolDependency(),
    [
      SchoolData(
        name: 'Oakwood High School',
        phoneNumber: '(555) 987-6543',
        address: '456 Elm Avenue, Springfield, USA',
      ),
      SchoolData(
        name: 'Maplewood Elementary',
        phoneNumber: '(555) 555-5555',
        address: '789 Oak Street, Willowbrook, USA',
      ),
    ],
  );
}
```

Note that, even though these schools share the same dependency, they will be 
created with different IDs.

#### Reading

There are five methods available for reading: `peek`, `peekAll`, `pull`, `pullAll`
and `peekAllKeys`.

The `peek` and `pull` methods receive a model ID and evaluates its respective model
in the underlying database table. If the ID does not exist, the method evaluates to null.
The difference between them is that `peek` returns a `Future` (read once and return) and 
`pull` returns a `Stream` (read once and listen for changes):

```dart
void main(Repository<SchoolData, School> repository) async {
  final School? school = await repository.peek('123456');
  final Stream<School?> streamedSchool = repository.pull('123456');
}
```

The `peekAll` and `pullAll` methods evaluate all models in the underlying database table as
a `List`. They optionally receive a `Filter` argument, but for now just assume they evaluates 
all models. If there are no models in the table, the method evaluates to an empty list. Similar
as before, the difference between then is that `peek` returns a `Future` and `pull` returns a
`Stream`:

```dart
void main(Repository<SchoolData, School> repository) async {
  final List<School> schools = await repository.peekAll();
  final Stream<List<School>> streamedSchools = repository.pullAll();
}
```

The `peekAllKeys` method makes more sense in non-relational databases: it returns all primary 
keys on the database. If you use custom IDs and want to filter them based on a condition, this 
method is preferred rather than calling `peekAll` and reading the returned IDs:

```dart
void main(Repository<SchoolData, School> repository) async {
  final List<String> ids = await repository.peekAllKeys();
}
```

#### Updating

There are three methods available for update: `push`, `pushAll` and `patch`.

The `push` method receives a model *M* and writes it to the table. If this model ID
does not exist yet, it will be created. If it exists, the previous data will be 
overwritten by *M*. It returns nothing:

```dart
void main(Repository<SchoolData, School> repository) async {
  await repository.push(School(
    id: '123456',
    name: 'Sunflower Preparatory School',
    phoneNumber: '(555) 222-3333',
    address: '321 Sunflower Lane, Sunnyville, USA',
  ));
}
```

The `pushAll` method receives a collection of models. If you have more than two
or more models you want to update at the same time, this method is preferred rather
than calling `push` repeatedly. It returns nothing:

```dart
void main(Repository<SchoolData, School> repository) async {
  await repository.pushAll([
    School(
      id: '123',
      name: 'Crestview Middle School',
      phoneNumber: '(555) 777-8888',
      address: '654 Hillcrest Road, Mountainview, USA',
    ),
    School(
      id: '456',
      name: 'Riverside Academy',
      phoneNumber: '(555) 444-9999',
      address: '987 Riverfront Drive, Riverdale, USA',
    ),
  ]);
}
```

The `patch` method receives a model ID and a callback that receives a model and returns
a model. If you want to read a model from the database given its ID, apply some 
operation to it locally and write it back to the database, this method is preferred
rather than calling `peek` and `push` sequentially. It returns nothing:

```dart
void main(Repository<SchoolData, School> repository) async {
  const String id = '789';
  await repository.patch(id, (School? school) {
    return School(
      id: school?.id ?? id,
      name: 'Willowbrook High School',
      phoneNumber: '(555) 333-1111',
      address: '246 Willow Avenue, Greenfield, USA',
    );
  });
}
```

#### Deleting

There are four methods available for deleting: `pop`, `popAll`, `popKeys` and `purge`.

The `pop` method receives a model ID and removes its respective model from the underlying database
table. If the ID does not exist, nothing is done. It returns nothing:

```dart
void main(Repository<SchoolData, School> repository) async {
  await repository.pop('123');
}
```

The `popKeys` method receives a collection of IDs. If you have more than two or more models
you want to delete at the same time, this method is preferred rather than calling `pop` repeatedly. 
It returns nothing:

```dart
void main(Repository<SchoolData, School> repository) async {
  await repository.popKeys(['123', '456', '789']);
}
```

The `popAll` method receives a `Filter` and remove all models that match this filter. You'll read
more about filtering later, but for now keep in mind that `Filter.empty()` matches all models. 
Therefore, if you use it in this method, it'll be the equivalent to removing all models from the table. 
It returns nothing:

```dart
void main(Repository<SchoolData, School> repository) async {
  await repository.popAll(const Filter.empty());
}
``` 

The `purge` method drops the underlying database table (removes all models). If you want to remove all
models from a table, this method is preferred rather than calling `popAll` passing `Filter.empty()`.
It returns nothing:

```dart
void main(Repository<SchoolData, School> repository) async {
  await repository.purge();
}
```

### Filters

Batch methods of repositories, such as `peekAll`, `pullAll` and `popAll`, can receive a `Filter` as parameter. 
In read operations, this parameter defaults to `Filter.empty()`, which matches all models from that repository.
If you want to limit how many models are matched, you can change it to your appropriate use case.

#### By value

If you want to match models whose field is equal to a certain value, you can use `Filter.value`:

```dart
void main(Repository<SchoolData, School> repository) async {
  // Peek all active schools
  await repository.peekAll(const Filter.value(true, key: 'active'));

  // Peek all schools that belongs to US
  await repository.peekAll(const Filter.value('US', key: 'country-name'));
}
```

The argument passed to `key` should match the serialization field name.

#### By text

If you want to match models whose field *starts* with a certain string, you can use `Filter.text`:

```dart
void main(Repository<SchoolData, School> repository) async {
  // Peek all active schools
  await repository.peekAll(const Filter.value(true, key: 'active'));

  // Peek all schools that belongs to US
  await repository.peekAll(const Filter.value('US', key: 'country-name'));
}
```

Note that this is a exact and case-sensitive search, so the following will not work:

```dart
void main(Repository<SchoolData, School> repository) async {
  // User wants to find the Lincoln Elementary school,
  // so they type in the search bar "lincoln el"
  final String userInput = 'lincoln el';

  // Since the stored school name is "Lincoln Elementary"
  // (note the uppercase letters and spaces), nothing will be found
  await repository.peekAll(Filter.text(userInput, key: 'name'));
}
```

If you want a case-insensitive search, you can create a new serialization field, normalize 
your field value, and applying the same normalization to your query. For this, update the 
`toJson` method of your object's model view to include this new field:

```dart
class Student {
  // ...

  @override
  Map<String, Object?> toJson() {
    return {
      'name': name,
      // ...
      '.name': name.toUpperCase().replaceAll(' ', ''),
      // It can be any key, such as `_name` or `_query/name`
    };
  }
}
```

Now, search for this new field and apply the same transformation to user's query:

```dart
void main(Repository<SchoolData, School> repository) async {
  // User wants to find the Lincoln Elementary school,
  // so they type in the search bar "lincoln el"
  final String userInput = 'lincoln el';

  // Successfully finds the desired school
  final String query = userInput.toUpperCase().replaceAll(' ', '');
  await repository.peekAll(Filter.text(query, key: '.name'));
}
```

#### By dates

To filter on dates, you must transform your date field using `DateTime`'s 
`toIso8601String` method when serializing it inside `toJson`:

```dart
class Student {
  // ...

  @override
  Map<String, Object?> toJson() {
    return {
      // ...
      'birth-date': birthDate.toIso8601String(),
    };
  }
}
```

You can now use another date to belong to your filter, using the `unit` 
parameter to control how exact do you want this matching:

```dart
void main() {
  final DateTime dt = DateTime(2021, 06, 13, 16, 05, 12, 111);
  Filter? filter;

  // Select entries occurred at 13/06/2021, 16:05:12.111
  filter = Filter.date(dt, key: 'birth-date');

  // Select entries occurred at 2021
  filter = Filter.date(dt, key: 'birth-date', unit: DateFilterUnit.year);

  // Select entries occurred at 13/06/2021
  filter = Filter.date(dt, key: 'birth-date', unit: DateFilterUnit.day);

  // Select entries occurred at 13/06/2021, from 16:00 to 16:59
  filter = Filter.date(dt, key: 'birth-date', unit: DateFilterUnit.hour);
}
```

#### By amount

For any filter, you can use its `limit` method to evaluate the only first or last *N* models: 

```dart
void main(Repository<SchoolData, School> repository) async {
  // Peek first 10 schools
  await repository.peekAll(const Filter.empty().limit(10));

  // Peek last 20 schools with name prefixed with DEF
  await repository.peekAll(Filter.text('DEF', key: 'name').limit(-20));
}
```

### Relationships

With the foreign keys defined in each model view, we can link related models through relationships.

The `DatabaseEntity` class provides a `relationships` field you can use to access all the associations
defined below. This field returns an object of type `ModelRelationship`. This class contains four methods:
`oneToOne`, `oneToMany`, `manyToOne` and `manyToMany`, all of them returning an object of type `Association`.

Every `Association` contains four methods you can use to read the query: `peek`, `pull`, `peekAll` and `pullAll`.
Those methods behave similarly as the ones defined on `Repository`, however their evaluation type is a `Join`.
Every `Join` has a `left` and `right` fields. The left field will contain the model of the first table declared 
on the association and the right field will contain the model of the second table declared on the association.
More on that later.

#### One-to-one

Consider there is a `School` and a `Principal` model. Since every school has one and only one 
principal, this is an one-to-one relationship. You can read all schools and their principals:

```dart
void main(
  DatabaseEntity<SchoolData, School> schoolController,
  DatabaseEntity<PrincipalData, Principal> principalController,
) async {
  final OneToOneAssociation<School, Principal> association = schoolController
    .relationships
    .oneToOne(
      principalController.repository,
      on: (school) => school.principalId,
    );

  // Returns all schools with their respective principals
  final List<Join<School, Principal?>> joins = await association.peekAll();
  for (Join<School, Principal?> join in joins) {
    final School school = join.left;
    final Principal? principal = join.right; 
  } 
}
```

#### One-to-many

Consider there is a `School` and a `Student` model. Since every school can have zero or more 
students, this is an one-to-many relationship. You can read all schools and their students:

```dart
void main(
  DatabaseEntity<SchoolData, School> schoolController,
  DatabaseEntity<StudentData, Student> studentController,
) async {
  final OneToManyAssociation<School, Student> association = schoolController
    .relationships
    .oneToMany(
      studentController.repository,
      // This filter will be evaluated on `studentController`
      on: (school) => Filter.value(school.id, 'school-id'),
    );

  // Returns all schools with their respective students
  final List<Join<School, List<Student>>> joins = await association.peekAll();
  for (Join<School, List<Student>> join in joins) {
    final School school = join.left;
    final List<Student> students = join.right; 
  } 
}
```

#### Many-to-one

The previous method can return schools that have no students (a left-join). To exclude these cases
and return schools that must have at least one student (a right-join), use the many-to-one association:

```dart
void main(
  DatabaseEntity<SchoolData, School> schoolController,
  DatabaseEntity<StudentData, Student> studentController,
) async {
  // Note the change in type parameters compared with `OneToManyAssociation`
  final ManyToOneAssociation<Student, School> association = studentController
    .relationships
    .manyToOne(
      schoolController.repository,
      on: (student) => student.schoolId,
    );

  // Returns all schools with their respective students
  final List<Join<School, List<Student>>> joins = await association.peekAll();
  for (Join<School, List<Student>> join in joins) {
    final School school = join.left;
    final List<Student> students = join.right;
    assert(students.isNotEmpty); 
  } 
}
```

#### Many-to-many

Consider there is a `School`, a `Teacher` and a `Teaching` model. Since every school can have zero or more 
teachers and a teacher can teach in zero or more schools, this is an many-to-many relationship. You can read
all schools and their teachers:

```dart
void main(
  DatabaseEntity<TeachingData, Teaching> teachingController,
  DatabaseEntity<SchoolData, School> schoolController,
  DatabaseEntity<TeacherData, Teacher> teacherController,
) async {
  final ManyToManyAssociation<Teaching, School, Teacher> association = teachingController
    .relationships
    .manyToMany(
      left: schoolController.repository,
      onLeft: (teaching) => teaching.schoolId,
      right: teacherController.repository,
      onRight: (teaching) => teaching.teacherId,
    );

  // Returns all teachers and their schools
  final List<Join<Teaching, (School?, Teacher?)>> joins = await association.peekAll();
  for (Join<Teaching, (School?, Teacher?)> join in joins) {
    final Teaching teaching = join.left;
    final School? school = join.right.$1;
    final Teacher? teacher = join.right.$2; 
  }
}
```
