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

final Student current = Student(
  // Simple primary key
  id: uniqueId,
  
  // Composite primary key
  id: dependency.key(uniqueId),
  // If `dependency.schoolId` is 'school-key', the above call will return `school-key&primary-key` 
  
  // Foreign primary key
  id: dependency.schoolId,
);
```

If you're using Firebase, `uniqueId` here is commonly replaced by Firebase's push ID.

> Push IDs are string identifiers that are generated client-side. They are a 
> combination of a timestamp and some random bits. The timestamp ensures they are
> ordered chronologically, and the random bits ensure that each ID is unique, even
> if thousands of people are creating push IDs at the same time.
>
> *Source:* [The 2^120 Ways to Ensure Unique Identifiers](https://firebase.blog/posts/2015/02/the-2120-ways-to-ensure-unique_68https://firebase.blog/posts/2015/02/the-2120-ways-to-ensure-unique_68), The Firebase Blog

If you're using pure Dart code, you can use `const Uuid().v4()` from 
[`uuid`](https://pub.dev/packages/uuid) library.


### Entity

To join a model, its data and its dependency to a single, robust model, there is an
`Entity` class, which acts as a bridge that can be used to manipulate the database.
This is an abstract class, so implement it for each schema created:

```dart
// Naming convention for schema entity: schema name + Entity
class SchoolEntity implements Entity<SchoolData, School> {
  const SchoolEntity();

  // The name of this table in the database, equivalent
  // to `CREATE TABLE schools` from SQL
  @override
  String get tableName => 'schools';
  
  @override
  School fromJson(String id, Map data) => School.fromJson(id, data);
  
  @override
  Map<String, Object?> toJson(SchoolData data) => data.toJson();
  
  // This represents an UPDATE transformation, see the previous section
  @override
  School convert(School model, SchoolData data) => School(
      id: model.id,
      name: data.name,
      phoneNumber: data.phoneNumber,
      address: data.address,
    );
    
  // This represents a CREATE transformation, see the previous section
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

// Read all and listen for changes
final Stream<List<School>> schoolsStream = schoolRepository.pullAll();

// Read single
final School? hogwarts = await schoolRepository.peek('hogwarts');
if (hogwarts == null) {
  throw StateError('The id `hogwarts` was not found in the database');
}

// Create with an ID defined by the framework
final School school0 = await schoolRepository.put(
  const SchoolDependency(), 
  SchoolData(
    name: 'School 1',
    phoneNumber: '5511111111111',
    address: 'Sao Paulo, BR',
  ),
);

// Create with an ID defined by yourself
// If the given ID already exists, the old model will be overwritten
final School school1 = await schoolRepository.push(School(
  id: '12345678',
  name: 'School 2',
  phoneNumber: '5522222222222',
  address: 'Sao Paulo, BR',
));

// Update
await schoolRepository.push(School(
  id: school0.id,
  name: 'School 3',
  phoneNumber: '5533333333333', 
  address: 'Sao Paulo, BR',
));

// Delete
await schoolRepository.pop(school1.id);
```

### Filtering

Batch-read methods of repositories, such as `peekAll` (which returns a Future)
and `pullAll` (which returns a Stream), receives an optional filter parameter.
This parameter is, by default, equals to `Filter.empty()`, which downloads all 
models from this repository. If you want to limit how many data is downloaded,
you can pass to these methods custom filters:

```dart
// Peek all schools
await schoolRepository.peekAll(const Filter.empty());

// Peek all schools with name equal to ABC
await schoolRepository.peekAll(const Filter.value(key: 'name', value: 'ABC'));

// Peek all schools with name *prefixed* with DEF
await schoolRepository.peekAll(const Filter.text(key: 'name', text: 'DEF'));
```

You can also combine filters, if available on their constructor:

```dart
// Peek first 10 schools with name equal to ABC
await schoolRepository.peekAll(const Filter.limit(
  query: Filter.value(key: 'name', value: 'ABC'), 
  limit: 10,
));

// Peek last 20 schools with name equal to DEF
await schoolRepository.peekAll(const Filter.limit(
  query: Filter.value(key: 'name', value: 'DEF'), 
  limit: -20,
));
```

Note that filters containing `key` as parameters receive a String, which should be 
the same as their serialization fields. In the beginning of this document, we 
serialized the name of a school as `'name'`, so that's what we should use as `key`
parameter in a filter when filtering by a school name.

### Relationships

With a repository ready to be used, we want to ask the database questions related to
relationships between schemas, such as "What are the students of a given school?". These
questions can be asked through the `Relationship` subclasses: `OneToOneRelationship` and 
`OneToManyRelationship`. Given we have a school repository and a student repository, that
question can be answered in the following way:

```dart
final Repository<School, SchoolData> schoolRepository = ...;
final Repository<Student, StudentData> studentRepository = ...;

// Creating a new school
final School hogwarts = await schoolRepository.put(
  const SchoolDependency(), 
  SchoolData(
    name: 'Hogwarts School of Witchcraft and Wizardry',
    phoneNumber: '605-475-6961',
    address: 'Hogwarts Castle, Highlands, Scotland',
  ),
);

// Creating students
await studentRepository.put(
  StudentDependency(schoolId: hogwarts.id),
  StudentData(
    name: 'Harry Potter',
    birthDate: DateTime(1980, 7, 31),
    grade: '1',
    email: 'harrypotter@gmail.co.uk',
  ),
);

await studentRepository.put(
  StudentDependency(schoolId: hogwarts.id),
  StudentData(
    name: 'Rony Weasley',
    birthDate: DateTime(1980, 3, 1),
    grade: '1',
    email: 'ronyweasley@gmail.co.uk',
  ),
);

// Creating a relationship between schools and students
final OneToManyRelationship<School, Student> relationship = OneToManyRelationship(
  left: schoolRepository,
  right: studentRepository,

  // For a given `school` of this relationship, 
  // filter students where `school-id` equals to `school`'s ID 
  on: (school) => Filter.value(key: 'school-id', value: school.id),
);

// What are the students of Hogwarts?
final Join<School, List<Student>>? join = await relationship.peek(hogwarts.id);

if (join == null) {
  // If `hogwarts.id` does not exist or was deleted in this interval of time
} else {
  final School school = join.left;
  final List<Student> students = join.right;
  print(school.name);        // Hogwarts School of Witchcraft and Wizardry
  print(students.length);    // 2
}
```

This way, you can create complex relationship queries.

Another example showing how you can combine relationships:

``` dart
class Country {
  final String id;
}

abstract class State {
  final String id;

  // A country has multiple states (Country 1-to-N State)
  final String countryId;
}

abstract class Capital {
  // A state has a single capital (State 1-to-1 Capital)
  // Since a capital depends exclusively on a state, they 
  // must have the same ID. This ID sharing is the only
  // way to guarantee that one row in a table may be linked
  // with ONLY one row in another table.
  final String id;
}

final OneToOneRelationship<State, Capital> r0 = OneToOneRelationship(
  left: stateRepository,
  right: capitalRepository,
  on: (state) => state.id,
);

final OneToManyRelationship<Country, Join<State, Capital?>> r1 = OneToManyRelationship(
  left: countryRepository,
  right: r0,    // You can use another relationship here!
  on: (country) => Filter.value(key: 'country-id', value: country.id),
);

// Peek all countries whose name starts with AB and their 
// respective states with their respective capitals
final List<Join<Country, List<Join<State, Capital?>>>> joins = 
    await r1.peekAll(Filter.value(key: 'name', value: 'AB'));
```

## Automatizing the setup

Found all too much? You can run all these steps using code generation provided 
by `dorm_generator`.


