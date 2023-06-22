# dorm_annotations

Provides annotations related with dORM code generation.

## Getting started

Run the following commands inside your project:

```shell
dart pub add dorm_annotations
dart pub get
```

## Usage

### Models

The `Model` annotation is used to link a database table to a Dart class. 

It accepts two parameters:

- `name`: Specifies the name of the table in the underlying database.
- `as`: Provides a name for the repository accessor of the model.

```dart
import 'package:dorm_annotations/dorm_annotations.dart';

@Model(name: 'user', as: #users)
abstract class _User {}
```

### Fields

The `Field` annotation is used to link a database column to a Dart field within a model class.

It accepts the following parameters:

- `name`: Specifies the name of the column in the underlying database.
- `defaultValue`: Provides an optional default value for the field. If not explicitly set and
  the return type of the getter is nullable, the field will default to null.

```dart
import 'package:dorm_annotations/dorm_annotations.dart';

@Model(name: 'user', as: #users)
abstract class _User {
  @Field(name: 'name')
  String? get name;

  @Field(name: 'birth-date')
  DateTime get birthDate;

  @Field(name: 'emails', defaultValue: [])
  List<String> get emails;

  @Field(name: 'picture-url')
  Uri get pictureUrl;
}
```

The return type of the getters can be [any of the specified](https://pub.dev/packages/json_serializable#supported-types) on the `json_serializable` package:

> `BigInt`, `bool`, `DateTime`, `double`, `Duration`, `Enum`, `int`, `Iterable`, `List`, `Map`, `num`, `Object`, `Record`, `Set`, `String`, `Uri`.
>
> The collection types - `Iterable`, `List`, `Map`, `Record`, `Set` - can contain values of all the above types.
>
> For `Map`, the key value must be one of `BigInt`, `DateTime`, `Enum`, `int`, `Object`, `String`, `Uri`.
>
> If you own/control the desired type, add a `fromJson` constructor and a `toJson` function to the type.

### Foreign fields

The `ForeignField` annotation is used to link a database foreign key to a Dart field within a model class. 

In a relational database, a foreign key is a column in a table that establishes a relationship or association
with the primary key column of another table. The foreign column helps enforce referential integrity, which 
ensures that the referenced data exists and remains consistent.

It accepts the following parameters:

- `name`: Specifies the name of the foreign key column in the underlying database.
- `referTo`: Specifies the model class that the foreign key references.

```dart
import 'package:dorm_annotations/dorm_annotations.dart';

@Model(name: 'post', as: #posts)
abstract class _Post {
  @Field(name: 'contents')
  String get contents;

  @Field(name: 'creation-date')
  DateTime get creationDate;

  @ForeignField(name: 'user-id', referTo: _User)
  String get userId;
}
```

### Query fields

The `QueryField` annotation is used to link a database index to a Dart field within a model class.

An index is a data structure that improves the speed and efficiency of data retrieval operations on
database tables. It provides a way to quickly locate and access specific data within a table based on
the values stored in one or more columns. When a query includes a condition on indexed columns, the 
database engine can use the index to quickly identify the relevant rows, rather than scanning the entire table.

It accepts the following parameters:

- `name`: Specifies the name of the column in the underlying database.
- `referTo`: Specifies the query tokens that the field refers to.

#### Single-column indexing

```dart
import 'package:dorm_annotations/dorm_annotations.dart';

@Model(name: 'school', as: #schools)
abstract class _School {
  @Field(name: 'name')
  String get name;

  @Field(name: 'active', defaultValue: true)
  bool get active;

  @QueryField(name: '_query_active', referTo: [QueryToken(#active)])
  String get _qActive;
}
```

Applying `Filter.value(true, key: '_query_active')` (described in the `dorm` package) should optimize the reading of all active schools.

#### Multiple-column indexing

Combining two or more columns in a query involves searching for data based on the values present in
two or more different columns simultaneously. This type of query allows you to perform logical operations
on the values of two or more columns, such as concatenation, comparison, or matching patterns.
Examples of combining two columns include searching for records where the values in column A and column B are equal:

```dart
import 'package:dorm_annotations/dorm_annotations.dart';

@Model(name: 'school-address', as: #schoolAddresses)
abstract class _SchoolAddress {
  @Field(name: 'zip-code')
  String get zipCode;

  @Field(name: 'number')
  int get number;

  @QueryField(
    name: '_query_address',
    referTo: [QueryToken(#zipCode), QueryToken(#number)],
    joinBy: '_',
  )
  String get _qAddress;
}
```

Applying `Filter.value('99950_13', key: '_query_address')` (described in the `dorm` package) 
should optimize the reading of all addresses with zip code 99950 and number 13.

#### Text indexing

Searching by prefix involves finding records that match a specific prefix or initial set of 
characters in a given column. This type of query is particularly useful when you want to retrieve data
based on partial matches or when you only have partial information about the desired data. Examples of
searching by prefix include searching for names starting with "John" in a column containing full names:

```dart
import 'package:dorm_annotations/dorm_annotations.dart';

@Model(name: 'student', as: #students)
abstract class _Student {
  @Field(name: 'name')
  String get name;

  @ForeignField(name: 'id-school', referTo: _School)
  String get schoolId;

  @QueryField(
    name: '_query_sbn',
    referTo: [QueryToken(#schoolId), QueryToken(#name, QueryType.text)],
    joinBy: '#',
  )
  String get _qSchoolByName;
}
```

Applying `Filter.text('school7319004#Paul', key: '_query_sbn')` (described in the `dorm` package) 
should optimize the reading of all Pauls studying at the school with ID `school7319004`.

### Composite fields

The `ModelField` annotation is used to link a database composite column to a Dart field within a model class.

In a non-relational database, a composite column refers to a field that can hold a collection of values or
sub-attributes within a single column. Unlike a simple column that holds a single value, a composite column
allows for the grouping or nesting of multiple values or sub-attributes together. This can be useful for
representing complex or structured data within a single field in a non-relational database model.

It accepts the following parameters:

- `name`: Specifies the name of the column in the underlying database.
- `referTo`: Specifies the model class that should be represented within this field.

```dart
import 'package:dorm_annotations/dorm_annotations.dart';

@Model(name: 'school-address', as: #schoolAddresses)
abstract class _SchoolAddress {
  @Field(name: 'zip-code')
  String get zipCode;
}

@Model(name: 'school', as: #schools)
abstract class _School {
  @Field(name: 'name')
  String get name;

  @ModelField(name: 'address', referTo: _SchoolAddress)
  get address;
}
```

### Polymorphism

The `PolymorphicField` annotation is used to link a database composite column and a pivot column 
to a Dart field within a model class.

In a non-relational database, polymorphism refers to the ability to store different types of objects
in a single table. It allows for flexible data modeling, where objects of various types can be stored 
together, and the specific type of each object is determined by a pivot column. A composite column
stores the specific contents of each subtable, while the remaining columns store the common attributes 
of the base table.

- The pivot column, represented as a string, is used to identify the specific type or subtable
  to which each object belongs. It acts as a discriminator, indicating the type of the object stored
  in the composite column.
- The composite column holds the contents or attributes specific to each subtable or object type.
  Depending on the value of the pivot column, the composite column stores the corresponding data
  structure or format for that specific object type.
- The remaining columns in the table represent the common attributes shared by all object types.
  These columns store the general or shared properties that are applicable to all objects,
  regardless of their specific type.

It accepts the following parameters:

- `name`: Specifies the name of the composite column in the underlying database.
- `pivotName`: Specifies the name of the pivot column in the underlying database.
- `pivotAs`: Specifies the name of the pivot field in the Dart class.

```dart
import 'package:dorm_annotations/dorm_annotations.dart';

abstract class _Action {}

@Model(name: 'operation', as: #operations)
abstract class _Operation {
  @Field(name: 'name')
  String get name;

  @PolymorphicField(name: 'action', pivotName: 'type', pivotAs: #type)
  _Action get action;
}
```

The `PolymorphicData` is used to create a composite object of a polymorphic field:

```dart
import 'package:dorm_annotations/dorm_annotations.dart';

@PolymorphicData(name: 'attack')
abstract class _Attack implements _Action {
  @Field(name: 'strength')
  int get strength;
}

@PolymorphicData(name: 'defence')
abstract class _Defense implements _Action {
  @Field(name: 'resistence')
  int get resistence;
}

@PolymorphicData(name: 'healing')
abstract class _Healing implements _Action {
  @Field(name: 'health')
  int get health;
}
```

### Unique identification

In the context of unique identification types for models, there are four types: simple, composite, same-as, and custom.
These types determine how the unique identifier (id) of a model is defined and generated:

- Simple *(default)*: generates a universally unique identifier as the id for the model. They are highly likely to be unique across
  different systems. This type of UID is suitable when a globally unique identifier is required for each instance of the model.
- Composite: creates a string by joining all foreign keys of the model with a given separator and appending a universally unique
  identifier to it. This type is particularly useful when users frequently query models by their ids and want to include related
  foreign keys in the id for easier referencing. The resulting id can be used to identify a specific instance of the model and
  maintain a relationship with its associated foreign keys.
- Same-as: receives a model class type and creates the same id as the referenced model. This type is ideal for establishing
  one-to-one relationships between models where both models share the same unique identifier. When two models have a same-as,
  it means they are linked by the same id, allowing for efficient retrieval and synchronization of related data.
- Custom: is a function that receives a model class and returns a string as the id. This type allows users to customize the
  generation of the model's id based on their specific requirements. The function can incorporate any logic or algorithm to
  generate a unique identifier based on the model's attributes or external factors. This type is useful when users need fine-grained
  control over how the id is generated, allowing for unique identification according to their own criteria.

You can specify the unique identification of a model through `UidType`:

```dart
import 'package:dorm_annotations/dorm_annotations.dart';

@Model(name: 'country', as: #countries, uidType: UidType.simple())
abstract class _Country {}

@Model(name: 'state', as: #states, uidType: UidType.composite())
abstract class _State {}

@Model(name: 'capital', as: #capitals, uidType: UidType.sameAs(_Country))
abstract class _Capital {}

CustomUidValue _identifyCitizen(Object data) {
  data as _Citizen; 
  if (data.isForeigner) {
    return CustomUidValue.value(data.visaCode);
  }
  if (data.socialSecurity != null) {
    return CustomUidValue.value(data.socialSecurity);
  }
  return const CustomUidValue.simple(); // or const CustomUidValue.composite();
}
@Model(name: 'citizen', as: #citizens, uidType: UidType.custom(_identifyCitizen))
abstract class _Citizen {}
```
