# dORM

An Object Relational Mapper framework for Dart.

## Installing

Run the following commands in your Dart or Flutter project:

```bash
dart pub add dorm \
  --git-url https://github.com/enzo-santos/dorm.git \
  --git-ref main \
  --git-path dorm
```

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

> **Why don't keep all the fields in a single model class?** Because of separation of concerns. A
form should only be concerned about real world information of a schema, not their primary or 
foreign keys. So when using a form, use the schema data. When reading from database, use the 
schema model.

It's highly recommended to add serialization methods to each class, commonly implemented using `fromJson`
and `toJson`:

```dart
class SchoolData {
  // ...

  factory SchoolData.fromJson(Map<String, Object?> json) {
    return SchoolData(
      name: json['name'] as String,
      phoneNumber: json['phone-number'] as String,
      address: json['address'] as String,
    );
  }
  
  // ...
  
  Map<String, Object?> toJson() {
    return {'name': name, 'phone-number': phoneNumber, 'address': address};
  }
}

class School extends SchoolData {
  // ...
  
  // Since this is a schema model, you must pass an `id` parameter
  factory School.fromJson(String id, Map<String, Object?> json) {
    final SchoolData data = SchoolData.fromJson(json);
    return School(
      id: id,
      name: data.name,
      phoneNumber: data.phoneNumber,
      address: data.address,
    );
  }
  
  // ...
  
  // There is no need to serialize `id`
  @override
  Map<String, Object?> toJson() {
    return super.toJson();
  }
}

class StudentData {
  // ...
  
  factory StudentData.fromJson(Map<String, Object?> json) {
    return StudentData({
      name: json['name'],
      birthDate: DateTime.parse(json['birth-date']),
      grade: json['grade'],
      email: json['email'],
    });
  }
  
  // ...
  
  Map<String, Object?> toJson() {
    return {
      'name': name,
      'birth-date': birthDate.toISOString(),
      'grade': grade,
      'email': email,
    };
  }
}

class Student extends StudentData {
  // ...
  
  factory Student.fromJson(String id, Map<String, Object?> json) {
    final StudentData data = StudentData.fromJson(json);
    return Student(
      id: id,
      schoolId: json['school-id'],
      name: data.name,
      birthDate: data.birthDate,
      grade: data.grade,
      email: data.email,
    );
  }

  // ...
  
  Map<String, Object?> toJson() {
    return {'school-id': schoolId, ...super.toJson()};
  }
}
```

Don't be afraid to also use a serialization library, such as [`json_serializable`](https://pub.dev/packages/json_serializable).

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
// The existing model you want to update
final Student existing = Student(...);

// The new data you want to overwrite
final StudentData data = StudentData(...);

// The updated model
final Student updated = Student(
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
// The data you want to transform into a model
final StudentData data = StudentData(...);

// The dependency you want to inject into the new model
final StudentDependency dependency = StudentDependency(...);

// The created model
final Student current = Student(
  // id: ???,
  schoolId: dependency.schoolId,
  name: data.name,
  birthDate: data.birthDate,
  grade: data.grade,
  email: data.email,
);
```

Since we didn't declare a primary key while creating a dependency, what can we use as
primary key here? You can either use

- an unique ID (a simple primary key)
- another ID together with an unique ID (a composite primary key)
- another ID (a foreign primary key), mostly used in one-to-one relationships

Here's the implementations of each methods:

```dart
final String uniqueId = 'primary-key';

final StudentModel current = StudentModel(
  // Simple primary key
  // id: uniqueId,
  
  // Composite primary key
  // id: dependency.key(uniqueId),
  // If `dependency.schoolId` is 'school-key', the above call will return `school-key&primary-key` 
  
  // Foreign primary key
  // id: dependency.schoolId,
);
```

If you're using Firebase, `uniqueId` here is commonly replaced by Firebase's push ID.

> Push IDs are string identifiers that are generated client-side. They are a 
> combination of a timestamp and some random bits. The timestamp ensures they are
> ordered chronologically, and the random bits ensure that each ID is unique, even
> if thousands of people are creating push IDs at the same time.
>
> *Source:* [The 2^120 Ways to Ensure Unique Identifiers](https://firebase.blog/posts/2015/02/the-2120-ways-to-ensure-unique_68https://firebase.blog/posts/2015/02/the-2120-ways-to-ensure-unique_68), The Firebase Blog

If you're using pure Dart code, you can use `const Uuid().v4()` from [`uuid`](https://pub.dev/packages/uuid) library.


### Entity

To join a model, its data and its dependency to a single, robust model, there is an
`Entity` class, which acts as a bridge that can be used to manipulate the database.
This is an abstract class, so implement it for each schema created:

```dart
// Naming convention for schema entity: schema name + Entity
class SchoolEntity implements Entity<SchoolData, School> {
  const SchoolEntity();

  @override
  String get tableName => 'schools';
  
  @override
  School fromJson(String id, Map data) => School.fromJson(id, data);
  
  @override
  Map<String, Object?> toJson(SchoolData data) => data.toJson();
  
  @override
  School convert(School model, SchoolData data) => School(
      id: model.id,
      name: data.name,
      phoneNumber: data.phoneNumber,
      address: data.address,
    );
    
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
  
  @override
  String identify(School model) => model.id;
}

class StudentEntity implements Entity<StudentData, Student> {
  const StudentEntity();

  @override
  String get tableName => 'students';
  
  @override
  Student fromJson(String id, Map data) => Student.fromJson(id, data);
  
  @override
  Map<String, Object?> toJson(StudentData data) => data.toJson();
  
  @override
  Student convert(Student model, StudentData data) => Student(
      id: model.id,
      schoolId: model.schoolId,
      name: data.name,
      birthDate: data.birthDate,
      grade: data.grade,
      email: data.email,
    );
    
  @override
  Student fromData(StudentDependency dependency, String id, StudentData data) {
    return Student(
      id: dependency.key(id),
      schoolId: dependency.schoolId,
      name: data.name,
      birthDate: data.birthDate,
      grade: data.grade,
      email: data.email,
    );
  }
  
  @override
  String identify(Student model) => model.id;
}
```

### Reference

The database access is done using a `Reference`, an abstract class. This library
provides some out-of-the-box implementations of `Reference` you can integrate into
your code, but if you want to implement it for a database language not available 
yet, implement this class.

### Repository

Database operations should be separated from the model, so it relies on an external
class called repository. This is a concrete class, so there is not need to implement
it. Since this class provides all the database operations we need, this is the end of
our setup journey: with a `Reference` and an `Entity`, you can instantiate a `Repository`.

```dart
final Reference reference = ...;
final SchoolEntity entity = const SchoolEntity();
final Repository<School, SchoolData> schoolRepository = Repository(root: reference, entity: entity);

// Read all
final List<School> schools = await schoolRepository.peekAll();

// Listen all
final Stream<School> schoolsStream = schoolRepository.pullAll();

// Read single
final School hogwarts = await schoolRepository.pull('hogwarts');

// Create
final School school = await schoolRepository.put(
  const SchoolDependency(), 
  SchoolData(name: 'School 1', phoneNumber: '5511111111111', address: 'Sao Paulo, BR'),
);

// Update
await schoolRepository.push(School(
  id: school.id,
  name: 'School 2',
  phoneNumber: '5522222222222', 
  address: 'Sao Paulo, BR'
));

// Delete
await schoolRepository.pop(school.id);
```

## Automatizing the setup

Found all too much? You can run all these steps using code generation provided 
by `dorm_generator`.


