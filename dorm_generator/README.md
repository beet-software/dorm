# dorm_generator

[![pub package](https://img.shields.io/pub/v/dorm_generator.svg?label=dorm_generator)](https://pub.dev/packages/dorm_generator)
[![pub popularity](https://img.shields.io/pub/popularity/dorm_generator?logo=dart)](https://pub.dev/packages/dorm_generator)
[![pub likes](https://img.shields.io/pub/likes/dorm_generator?logo=dart)](https://pub.dev/packages/dorm_generator)
[![pub points](https://img.shields.io/pub/points/dorm_generator?logo=dart)](https://pub.dev/packages/dorm_generator)

Provides code adapted to work with the dORM framework.

## Getting started

Run the following commands inside your project:

```shell
dart pub add dev:dorm_generator
dart pub add dev:build_runner
dart pub add dev:json_serializable
dart pub get
```

## Usage

> **Note**: This document assumes that you have already seen the
> [`dorm_annotations` documentation](https://pub.dev/packages/dorm_annotations).

### Generating

Create a file inside the *lib* folder of your Dart project. In this example, it will be
*lib/models.dart*.

Write the classes, their getters and their annotations to this file. Add the following directives to
top of this file:

```dart
import 'package:dorm_annotations/dorm_annotations.dart';
import 'package:dorm_framework/dorm_framework.dart';

part 'models.g.dart';

part 'models.dorm.dart';
```

Run the following line in your command prompt:

```shell
dart run build_runner build
```

This will generate all the files based on the annotated classes.

### Models

Any class `_Class` annotated with [`Model`](https://pub.dev/documentation/dorm_annotations/latest/dorm_annotations/Model-class.html) will create four new classes: `ClassData`, `Class`,
`ClassDependency` and `ClassEntity`.

```dart
@Model(name: 'class', as: #classes)
abstract class _Class {
  @Field(name: 'name')
  String? get name;

  @Field(name: 'timestamp')
  DateTime get timestamp;

  @ForeignField(name: 'school-id', referTo: _School)
  String get schoolId;
}
```

#### Data

A `ClassData` will contain only the getters annotated with 
[`Field`](https://pub.dev/documentation/dorm_annotations/latest/dorm_annotations/Field-class.html),
[`PolymorphicField`](https://pub.dev/documentation/dorm_annotations/latest/dorm_annotations/PolymorphicField-class.html)
and
[`ModelField`](https://pub.dev/documentation/dorm_annotations/latest/dorm_annotations/ModelField-class.html).
In the above example is defined as:

```dart
@JsonSerializable(anyMap: true, explicitToJson: true)
class ClassData {
  @JsonKey(name: 'name')
  final String? name;

  @JsonKey(name: 'timestamp', required: true, disallowNullValue: true)
  final DateTime timestamp;

  factory ClassData.fromJson(Map json) => _$ClassDataFromJson(json);

  const ClassData({
    required this.name,
    required this.timestamp,
  });

  Map<String, Object?> toJson() => _$ClassDataToJson(this);
}
```

#### Model

A `Class` extends `ClassData`, implements `_Class`, has an additional `id` field and will
contain only the getters annotated with 
[`ForeignField`](https://pub.dev/documentation/dorm_annotations/latest/dorm_annotations/ForeignField-class.html)
and
[`QueryField`](https://pub.dev/documentation/dorm_annotations/latest/dorm_annotations/QueryField-class.html).
In the above example is defined as:

```dart
@JsonSerializable(anyMap: true, explicitToJson: true)
class Class extends ClassData implements _Class {
  @JsonKey(name: '_id', required: true, disallowNullValue: true)
  final String id;

  @JsonKey(name: 'school-id', required: true, disallowNullValue: true)
  final String schoolId;

  factory Class.fromJson(String id, Map json) =>
      _$ClassFromJson({...json, '_id': id});

  const Class({
    required this.id,
    required this.schoolId,
    required super.name,
    required super.timestamp,
  });

  Map<String, Object?> toJson() =>
      _$ClassToJson(this)
        ..remove('_id');
}
```

#### dORM components

A `ClassDependency` and a `ClassEntity` extends respectively `Dependency<ClassData>`
and `Entity<ClassData, Class>`, exported by the
[`dorm_framework` package](https://pub.dev/packages/dorm_framework).

#### Accessors

The code generation will also create a new class named `Dorm`, which will contain the
repository accessors. In the above example, it is defined as:

```dart
class Dorm {
  final BaseEngine _engine;

  const Dorm(this._engine);

  DatabaseEntity<ClassData, Class> get classes =>
      DatabaseEntity(const ClassEntity(), engine: _engine);
}
```

Refer to the `dorm_*_database` packages to read more about how to obtain a `Engine`.
With a `Dorm` instance, you can operate on classes using a `Repository`, also exported by
`dorm_framework`:

```dart
void main() async {
  final Dorm dorm /* =  ... */;

  // Create
  final Class c = await dorm.classes.repository.put(
    ClassDependency(schoolId: 'school-0'),
    ClassData(name: 'A class.', timestamp: DateTime.now()),
  );

  // Read
  final Future<Class> fc = await dorm.classes.repository.peek('class-1');
  final Future<List<Class>> fcs = await dorm.classes.repository.peekAll();
  final Stream<Class> sc = dorm.classes.repository.pull('class-1');
  final Stream<List<Class>> scs = dorm.classes.repository.pullAll();

  // Update
  final Class uc = await dorm.classes.repository.push(Class(
    id: 'class-1',
    schoolId: 'school-1',
    name: 'A new class.',
    timestamp: DateTime.now(),
  ));

  // Delete
  await dorm.classes.repository.pop('class-1');
}
```

### Polymorphism

Consider the following annotated code:

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

@PolymorphicData(name: 'healing', as: #heal)
abstract class _Healing implements _Action {
  @Field(name: 'health')
  int get health;
}

@Model(name: 'operation', as: #operations)
abstract class _Operation {
  @Field(name: 'name')
  String get name;

  @PolymorphicField(name: 'action', pivotName: 'type', pivotAs: #type)
  _Action get action;
}
```

The generated code will contain an abstract class named `Action` with three subclasses:
`Attack`, `Defense` and `Healing`. It'll also contain an enum named `ActionType` with three
values: `attack`, `defense` and `heal` (not `healing`; see its `PolymorphicData`'s `as` argument).

The `_Operation` model will be generated as described previously, except that will contain an
additional field named `type` of type `ActionType`, which will allow the user to check the runtime
type of the `action` field.

The following code explains how to manipulate generated code for a `Model` with a field annotated
with `PolymorphicField`:

```dart
void main() async {
  final Operation o1 = await dorm.operations.repository.put(
    const OperationDependency(),
    OperationData(name: 'AoT', action: Attack(strength: 42), type: ActionType.attack),
  );

  final Operation o2 = await dorm.operations.repository.peek('543f2f8da023');

  final int value;
  switch (operation.type) {
    case ActionType.attack:
      final Attack attack = operation.action as Attack;
      value = attack.strength;
      break;
    case ActionType.defense:
      final Defense defense = operation.action as Defense;
      value = defense.resistence;
      break;
    case ActionType.heal:
      final Healing healing = operation.action as Healing;
      value = healing.health;
      break;
  }
}
```

### Unique identification

#### Simple

If

```dart
@Model(name: 'country', as: #countries, uidType: UidType.simple())
abstract class _Country {
  @Field(name: 'name')
  String get name;
}
```

then

```dart
void main() async {
  final Country country = await dorm.countries.repository.put(
    CountryDependency(),
    CountryData(name: 'Brazil'),
  );
  // uuid
  assert(country.id == '27f04af67a1f');
}
```

#### Composite

If

```dart
@Model(name: 'state', as: #states, uidType: UidType.composite())
abstract class _State {
  @Field(name: 'name')
  String get name;

  @ForeignField(name: 'country-id', referTo: _Country)
  String get countryId;
}
```

then

```dart
void main() async {
  final State state = await dorm.states.repository.put(
    StateDependency(countryId: '27f04af67a1f'),
    StateData(name: 'Rio de Janeiro'),
  );
  // ${countryId}_uuid
  assert(country.id == '27f04af67a1f_367f1672f637');
}
```

#### Same-as

If

```dart
@Model(name: 'capital', as: #capitals, uidType: UidType.sameAs(_Country))
abstract class _Capital {
  @Field(name: 'name')
  String get name;

  @ForeignField(name: 'country-id', referTo: _Country)
  String get countryId;
}
```

then

```dart
void main() async {
  final Capital capital = await dorm.capitals.repository.put(
    CapitalDependency(countryId: '27f04af67a1f'),
    CapitalData(name: 'Brasilia'),
  );
  // countryId
  assert(capital.id == '27f04af67a1f');
}
```

#### Custom

If

```dart
CustomUidValue _identifyCitizen(Object data) {
  data as _Citizen;
  if (data.isForeigner) {
    return CustomUidValue.value(data.visaCode!);
  }
  if (data.socialSecurity != null) {
    return CustomUidValue.value(data.socialSecurity);
  }
  return const CustomUidValue.simple();
}

@Model(name: 'citizen', as: #citizens, uidType: UidType.custom(_identifyCitizen))
abstract class _Citizen {
  @Field(name: 'name')
  String get name;

  @Field(name: 'is-foreigner', defaultValue: false)
  bool get isForeigner;

  @Field(name: 'visa-code')
  String? get visaCode;

  @Field(name: 'ssn')
  String? get socialSecurity;

  @ForeignField(name: 'country-id', referTo: _Country)
  String get countryId;
}
```

then

```dart
void main() async {
  final Citizen c1 = await dorm.citizens.repository.put(
    CitizenDependency(countryId: '27f04af67a1f'),
    CitizenData(
      name: 'Rodrigo Maia',
      isForeigner: true,
      visaCode: '4bb6',
      socialSecurity: '11111111111',
    ),
  );
  // visaCode
  assert(c1.id == '4bb6');

  final Citizen c2 = await dorm.citizens.repository.put(
    CitizenDependency(countryId: '27f04af67a1f'),
    CitizenData(
      name: 'Arthur Lira',
      isForeigner: false,
      visaCode: null,
      socialSecurity: '22222222222',
    ),
  );
  // socialSecurity
  assert(c2.id == '22222222222');

  final Citizen c3 = await dorm.citizens.repository.put(
    CitizenDependency(countryId: '27f04af67a1f'),
    CitizenData(name: 'Capivara Filó', isForeigner: false, visaCode: null, socialSecurity: null),
  );
  // uuid
  assert(c3.id == 'b2a6304807a0');
}
```
