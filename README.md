# dORM

An Object Relational Mapper framework for Dart.

## Modules

- `dorm_annotations`: provides annotations to be used in Dart code (start here)

- `dorm_generator`: provides the code generator to be ran with `run build_runner build`

## The framework

A database schema in this framework is split into two classes: its data and its model. The
schema data contains all the data used by the real world to represent it, while the schema
model also contains the relationship between other schema models.

For example, consider a database system containing two schemas: student and school.

- A school schema has a data class (`SchoolData`) and a model class (`School`).
  A school has a name, phone number and address.

```dart
// Naming convention for schema data: schema name + `Data`
class SchoolData {
  final String name;
  final String phoneNumber;
  final String address;
  
  const SchoolData({
    required this.name,
    required this.phoneNumber,
    required this.address,
  });
}

// Naming convention for schema model: schema name
class School extends SchoolData {
  final String id;
  
  const School({
    required this.id,
    required super.name,
    required super.phoneNumber,
    required super.address,
  });
}
```

- A student schema has a data model (`StudentData`) and a model class (`Student`).
  A student has a name, birth date, school grade and email. It also contains a reference
  to its school.
  
```dart
class StudentData {
  final String name;
  final DateTime birthDate;
  final String grade;
  final String email;
  
  const StudentData({
    required this.name,
    required this.birthDate,
    required this.grade,
    required this.email,
  });
}

class Student extends StudentData {
  final String id;
  final String schoolId;

  const School({
    required this.id,
    required this.schoolId,
    required super.name,
    required super.birthDate,
    required super.grade,
    required super.email,
  });
}
```

**Why don't keep all the fields in a single model class?** Because of separation of concerns. A
form should only be concerned about real world information of a schema, not their primary or 
foreign keys. So when using a form, use the schema data. When reading from database, use the 
schema model.

### Dependency

To implement a dependency for a given schema data, you should ask yourself: what does this 
schema depends on to exist?

- A school can exist without any student. Since there are no more models in this system,
  we can say that `School` does not depend on any model to exist, so its entity type is
  strong.
  
- A student cannot exist without a school, since they study there. Since there are no
  more models in this system, we can say that `Student` depends on `School` to exist,
  so its entity type is weak.
  
This reasoning is important to implement a dependency for a schema data, which is used
when you want to create a new model (an INSERT operation) in the database.

Let's implement a dependency for both schemas above:

```dart
class SchoolDependency extends Dependency<SchoolData> {
  const SchoolDependency() : super.strong();
}

class StudentDependency extends Dependency<StudentData> {
  final String schoolId;
  
  StudentDependency({required this.schoolId}) : super.weak([schoolId]);
}
```

Note that subclasses of `Dependency<Data>` must include as fields the primary keys of
all the dependencies of `Data`. 

#### What to use as primary key?

To transform a schema data into a schema model, you can use two methods: create or 
update. 

The following represents an update transformation:

```dart
final StudentData data = StudentData(...);
final StudentModel existing = StudentModel(...);

final StudentModel current = StudentModel(
  id: existing.id,
  schoolId: existing.schoolId,
  name: data.name,
  birthDate: data.birthDate,
  grade: data.grade,
  email: data.email,
);
```

Note that, for an update transformation, you need an existing schema model to inherit from.

In a create transformation, this existing schema model is replaced by a `Dependency`:

```dart
final StudentData data = StudentData(...);
final StudentDependency dependency = StudentDependency(...);

final StudentModel current = StudentModel(
  // id: ???,
  schoolId: dependency.schoolId,
  name: data.name,
  birthDate: data.birthDate,
  grade: data.grade,
  email: data.email,
);
```

What to use as primary key here? You can either use

- an unique ID (a simple primary key)
- another ID together with an unique ID (a composite primary key)
- another ID (a foreign primary key), mostly used in one-to-one relationships

Here's the implementations of each methods:

```dart
final StudentModel current = StudentModel(
  // Simple primary key
  // id: 'primary-key',
  
  // Composite primary key
  // id: dependency.key('primary-key'),
  // If `dependency.schoolId` is 'school-key', the above call will return `school-key&primary-key` 
  
  // Foreign primary key
  // id: dependency.schoolId,
);
```

In the common use case, `'primary-key'` here is replaced by Firebase's push ID.

> Push IDs are string identifiers that are generated client-side. They are a 
> combination of a timestamp and some random bits. The timestamp ensures they are
> ordered chronologically, and the random bits ensure that each ID is unique, even
> if thousands of people are creating push IDs at the same time.
>
> *Source:* [The 2^120 Ways to Ensure Unique Identifiers](https://firebase.blog/posts/2015/02/the-2120-ways-to-ensure-unique_68https://firebase.blog/posts/2015/02/the-2120-ways-to-ensure-unique_68), The Firebase Blog
