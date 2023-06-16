# dorm_annotations

Provides annotations related with dORM code generation.

## Getting started

Run the following commands inside your project:

```shell
dart pub add dorm_annotations
dart pub get
```

## Usage

> This document only explains the annotations exported by this package. 
> Refer to the `dorm_generator` package to read more about how to generate code for these annotations.

### Models

The `Model` annotation is used to define a model class. It accepts two parameters:

- `name`: Specifies the name of the table in the underlying database.
- `as`: Provides a name for the repository accessor of the model. 

```dart
import 'package:dorm_annotations/dorm_annotations.dart';

@Model(name: 'user', as: #users)
abstract class _User {}
```

### Fields

The `Field` annotation is used to define a field within a model class.
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

The `ForeignField` annotation is used to define a foreign key relationship between two models. 
It accepts the following parameters:

- `name`: Specifies the name of the foreign key field in the underlying database.
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

The `QueryField` annotation is used to define a field that can optimize queries and filters on the database.
It accepts the following parameters:

- `name`: Specifies the name of the column in the underlying database.
- `referTo`: Specifies the query tokens that the field refers to

```dart
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

Applying `Filter.value(true, key: '_query_active')`, described in the `dorm` package should optimize the reading of all active schools.

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
@Model(name: 'country', as: #countries, uidType: UidType.simple())
abstract class _Country {}

@Model(name: 'state', as: #states, uidType: UidType.composite())
abstract class _State {}

@Model(name: 'capital', as: #capitals, uidType: UidType.sameAs(_Country))
abstract class _Capital {}

CustomUidValue _identifyCitizen(Object obj) {
  final _Citizen data = obj as _Citizen; 
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

### Polymorphism

If you have a model that may contain different fields for different types, you can use 
`PolymorphicData` together with `PolymorphicField` to represent it on the database. 

For example, you have a RPG database with a abstract schema named `Operation` and wants
to derive `Attack`, `Defense` and `Healing` from it. You can use the following:

```dart
abstract class _Action {}

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

@Model(name: 'operation', as: #operations)
abstract class _Operation {
  @Field(name: 'name')
  String get name;

  @PolymorphicField(name: 'action', pivotName: 'type')
  _Action get action;
}
```
