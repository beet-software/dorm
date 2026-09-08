# dorm_annotations

[![pub package](https://img.shields.io/pub/v/dorm_annotations.svg?label=dorm_annotations)](https://pub.dev/packages/dorm_annotations)
[![pub popularity](https://img.shields.io/pub/popularity/dorm_annotations?logo=dart)](https://pub.dev/packages/dorm_annotations)
[![pub likes](https://img.shields.io/pub/likes/dorm_annotations?logo=dart)](https://pub.dev/packages/dorm_annotations)
[![pub points](https://img.shields.io/pub/points/dorm_annotations?logo=dart)](https://pub.dev/packages/dorm_annotations)

Provides annotations related with dORM code generation.

## Getting started

Run the following commands inside your project:

```shell
dart pub add dorm_annotations
dart pub get
```

Take a look at the [`dorm_generator` package](https://pub.dev/packages/dorm_generator) to learn how
to generate code for these annotations.

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

- `name`: Optional name of the column in the underlying database. When omitted,
  the generator uses the annotated getter name.
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

The return type of the getters can be any of the specified on the
[`json_serializable` package](https://pub.dev/packages/json_serializable#supported-types):

> `BigInt`, `bool`, `DateTime`, `double`, `Duration`, `Enum`, `int`, `Iterable`, `List`, `Map`,
> `num`, `Object`, `Record`, `Set`, `String` and `Uri`.
>
> The collection types - `Iterable`, `List`, `Map`, `Record`, `Set` - can contain values of all the
> above types.
>
> For `Map`, the key value must be one of `BigInt`, `DateTime`, `Enum`, `int`, `Object`, `String`
> and `Uri`.
>
> If you own/control the desired type, add a `fromJson` constructor and a `toJson` function to the
> type.

### Foreign fields

The `ForeignField` annotation is used to link a database foreign key to a Dart field within a model
class.

In a relational database, a foreign key is a column in a table that establishes a relationship or
association with the primary key column of another table. The foreign column helps enforce 
referential integrity, which ensures that the referenced data exists and remains consistent.

It accepts the following parameters:

- `name`: Optional name of the foreign key column in the underlying database.
  When omitted, the generator uses the annotated getter name.
- `referTo`: Specifies the model class that the foreign key references.
- `unique`: Indicates that the foreign key is unique in the source model. A
  non-unique foreign key is many-to-one; a unique foreign key can be
  one-to-one.
- `as`: Optional name of the generated forward relationship accessor.
- `inverseAs`: Optional explicit name of the generated inverse relationship accessor.

```dart
import 'package:dorm_annotations/dorm_annotations.dart';

@Model(name: 'post', as: #posts)
abstract class _Post {
  @Field(name: 'contents')
  String get contents;

  @Field(name: 'creation-date')
  DateTime get creationDate;

  @ForeignField(name: 'user-id', referTo: _User, inverseAs: #posts)
  String get userId;
}
```

### Derived fields

The `DerivedField` annotation defines a persisted `String` value built from other Dart fields within a
model class. It does not create a database index. A SQL engine stores a simple name as a scalar
column and a `root/child` name inside a backend-specific JSON value.

It accepts the following parameters:

- `name`: Optional name of the column in the underlying database. When omitted,
  the generator uses the annotated getter name.
- `referTo`: Specifies the derived tokens that the field refers to.
- `joinBy`: Specifies the separator used between token values.

#### Single derived value

```dart
import 'package:dorm_annotations/dorm_annotations.dart';

@Model(name: 'school', as: #schools)
abstract class _School {
  @Field(name: 'name')
  String get name;

  @Field(name: 'active', defaultValue: true)
  bool get active;

  @DerivedField(name: '_query_active', referTo: [DerivedToken(#active)])
  String get _qActive;
}
```

Applying `Filter.value(true, key: '_query_active')` (described in the
[`dorm_framework` package](https://pub.dev/packages/dorm_framework)) compares the persisted derived
value.

#### Combining multiple fields

A derived field can combine two or more source fields into one persisted value. For example, a
combined value can be compared with `Filter.value`:

```dart
import 'package:dorm_annotations/dorm_annotations.dart';

@Model(name: 'school-address', as: #schoolAddresses)
abstract class _SchoolAddress {
  @Field(name: 'zip-code')
  String get zipCode;

  @Field(name: 'number')
  int get number;

  @DerivedField(
    name: '_query_address',
    referTo: [DerivedToken(#zipCode), DerivedToken(#number)],
    joinBy: '_',
  )
  String get _qAddress;
}
```

Applying `Filter.value('99950_13', key: '_query_address')` compares the materialized value for an
address with zip code 99950 and number 13.

#### Text normalization

A token can use `DerivedTransform.text` before it is joined into the persisted value. The resulting
value can be used with a text filter:

```dart
import 'package:dorm_annotations/dorm_annotations.dart';

@Model(name: 'student', as: #students)
abstract class _Student {
  @Field(name: 'name')
  String get name;

  @ForeignField(name: 'id-school', referTo: _School)
  String get schoolId;

  @DerivedField(
    name: '_query_sbn',
    referTo: [DerivedToken(#schoolId), DerivedToken(#name, DerivedTransform.text)],
    joinBy: '#',
  )
  String get _qSchoolByName;
}
```

Applying `Filter.text('school7319004#Paul', key: '_query_sbn')` compares the materialized value for
the selected school and name prefix.

`DerivedTransform.date` normalizes a `DateTime` token as `YYYYMMDD`, and
`DerivedTransform.datetime` normalizes it as `YYYYMMDDHHmmssSSS`. Both values
use the local date and time components and can be joined with other tokens in
a derived field.

### Composite fields

The `ModelField` annotation is used to link a database composite column to a Dart field within a
model class.

In a non-relational database, a composite column refers to a field that can hold a collection of
values or sub-attributes within a single column. Unlike a simple column that holds a single value, a
composite column allows for the grouping or nesting of multiple values or sub-attributes together.
This can be useful for representing complex or structured data within a single field in a
non-relational database model.

It accepts the following parameters:

- `name`: Optional name of the column in the underlying database. When omitted,
  the generator uses the annotated getter name.
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

### Plain models

The `Data` annotation is used to simply serialize a class.

It accepts no arguments.

```dart
import 'package:dorm_annotations/dorm_annotations.dart';

@Data()
abstract class _SchoolAddress {
  @Field(name: 'zip-code')
  String get zipCode;

  @Field(name: 'district')
  String get district;

  @Field(name: 'house-number')
  int get number;
}
```

You can also use a class annotated with `Data` as an argument to `referTo` of a `ModelField`
annotation.

### Polymorphism

The `PolymorphicField` annotation is used to link a database composite column and a pivot column
to a Dart field within a model class.

In a non-relational database, polymorphism refers to the ability to store different types of objects
in a single table. It allows for flexible data modeling, where objects of various types can be
stored together, and the specific type of each object is determined by a pivot column. A composite
column stores the specific contents of each sub-table, while the remaining columns store the common
attributes of the base table.

- The pivot column, represented as a string, is used to identify the specific type or sub-table
  to which each object belongs. It acts as a discriminator, indicating the type of the object stored
  in the composite column.
- The composite column holds the contents or attributes specific to each sub-table or object type.
  Depending on the value of the pivot column, the composite column stores the corresponding data
  structure or format for that specific object type.
- The remaining columns in the table represent the common attributes shared by all object types.
  These columns store the general or shared properties that are applicable to all objects,
  regardless of their specific type.

It accepts the following parameters:

- `name`: Optional name of the composite column in the underlying database.
  When omitted, the generator uses the annotated getter name.
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
  @Field(name: 'resistance')
  int get resistance;
}

@PolymorphicData(name: 'healing')
abstract class _Healing implements _Action {
  @Field(name: 'health')
  int get health;
}
```

### Unique identification

The default identifier type is `String`. A custom primary-key generator receives the generated
model and the default `String` id, and returns the id that should be persisted:

```dart
import 'package:dorm_annotations/dorm_annotations.dart';

@Model(name: 'country', as: #countries)
abstract class _Country {}

@Model(name: 'capital', as: #capitals, primaryKeyGenerator: _Capital.generateId)
abstract class _Capital {
  static String generateId(_Capital model, String id) => model.countryId;

  @ForeignField(name: 'country-id', referTo: _Country)
  String get countryId;
}
```

The generator validates the callback signature when it compiles the generated source. A custom
generated key type can be declared through `GeneratedIdSpec(type: ...)`. A
database-assigned key can be declared through
`DatabaseGeneratedIdSpec(type: ...)`; each database engine
decides which ID types it supports.
