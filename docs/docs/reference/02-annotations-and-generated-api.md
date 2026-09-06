# Annotations and generated API reference

This page indexes annotation parameters and the generated types that appear
after running dORM code generation.

## Model and data annotations

| Annotation/type | Constructor shape | Meaning |
| --- | --- | --- |
| `Data` | `const Data()` | Marks a class as serializable data input. |
| `Model` | `const Model({String? name, List<IdSpec> primaryKey, Symbol? as, Function? primaryKeyGenerator})` | Declares a stored model, primary-key parts, table name, generated accessor name, and optional identity function. |
| `Field` | `const Field({String? name, Object? defaultValue})` | Maps a getter to a stored field. |
| `ForeignField` | `const ForeignField({required String name, required Type referTo, bool unique = false, Symbol? as, Symbol? inverseAs})` | Maps a foreign key and declares relationship metadata. |
| `ModelField` | `const ModelField({required String name, required Type referTo, ModelFieldTemplate<Object?> template})` | Maps an embedded model/data value. |

`Model.name` and field `name` values are storage names. `Model.as` is the
generated Dart accessor name for the database entity.

## Primary-key annotations

| Type | Constructor | Fields |
| --- | --- | --- |
| `GeneratedIdSpec` | `const GeneratedIdSpec({Symbol as = #id, String name = 'id', Type type = String})` | Generated Dart property, stored name, and Dart identity type. |
| `ExistingIdSpec` | `const ExistingIdSpec({required Symbol referTo})` | Existing getter that supplies one primary-key field. |
| `IdSpec` | `const IdSpec()` | Base type for primary-key specifications. |

The default `Model.primaryKey` contains one `GeneratedIdSpec`. One generated
identity or one or more existing identity fields are supported by the
annotation model; composite generated keys are not supported by the current
generator.

## Query annotations

| Type | Constructor | Meaning |
| --- | --- | --- |
| `QueryType` | `text`, `enumeration` | Transformation category for a query token. |
| `QueryField` | `const QueryField({required String name, required List<QueryToken> referTo, String joinBy = '_'})` | Creates a stored/query value from other fields. |
| `QueryToken` | `const QueryToken(Symbol field, [QueryType? type])` | Selects one annotated field and optional normalization. |

`QueryType.text` applies text normalization; `QueryType.enumeration` applies
enum-style normalization. Query-field behavior is engine-specific after the
generated field is passed to a filter.

## Polymorphism annotations

| Type | Constructor | Meaning |
| --- | --- | --- |
| `PolymorphicField` | `const PolymorphicField({required String name, required String pivotName, Symbol? pivotAs})` | Maps a payload field and discriminator/pivot field. |
| `PolymorphicData` | `const PolymorphicData({required String name, Symbol? as})` | Associates a discriminator value with a data class. |

The generated serialized representation includes discriminator and payload
information. Its stability as a universal wire format across every engine is
not established.

## Generated types for each model

For an annotated model such as `User`, generation produces the following
types:

| Generated type | Role |
| --- | --- |
| `UserData` | Field values used as create/update input. |
| `User` | Identified model extending `UserData`. |
| `UserDependency` | Values required to construct `User`. |
| `UserFields` | Generated field metadata for filters and relationships. |
| `UserEntity` | `Entity<UserData, User, I>` implementation. |
| `Dorm` | Generated engine-bound accessors such as `users`. |

The exact generated class names are derived from the annotated class name and
are part of the current generated output shape.

## Generated entity and database access

The generated entity implements the engine-neutral mapping contract:

```dart
Entity<UserData, User, String>
```

It supplies:

- `schema`;
- `primaryKeyCodec`;
- `fromData(dependency, id, data)`;
- `identify(model)`;
- `fromJson(id, data)`;
- `toJson(data)`;
- `convert(model, data)`.

The generated `Dorm` receives a `BaseEngine<Query>` and exposes a
`DatabaseEntity` for each annotated model. Application code normally reaches
the operations through `dorm.users.repository`, not through the generated
entity conversion methods directly.

## Generated relationship API

`ForeignField.as` names the forward relationship accessor. When
`inverseAs` is present, the generator creates the inverse accessor on the
target model. If `as` is omitted, the generator derives a name from the
foreign-field name and may remove a trailing `Id`.

Generated relationship paths use `RelationPath` and expose variants for
required, nullable, and empty-preserving relationship results, including
forms corresponding to `toOne`, `toOneOrNull`, `toMany`, and
`toManyOrEmpty`.

Duplicate generated path names fail generation with a `StateError`. See
[Add a cart and read related products](../02-build-the-store/03-relations-and-cart.md)
for path usage.

## Generated files and generation boundary

| File | Producer | Role |
| --- | --- | --- |
| `*.dorm.dart` | `dorm_generator` | dORM models, entities, schema, `Dorm`, and relationship paths. |
| `*.g.dart` | `json_serializable` | JSON serialization helpers. |

The annotated source must declare both parts when both outputs are required:

```dart
part 'models.dorm.dart';
part 'models.g.dart';
```

Run `dart run build_runner build` from the directory containing the
application `pubspec.yaml`. See [Diagnose annotation and generated-code problems](../05-troubleshooting/02-code-generation-problems.md)
for generation failures and [Compatibility and release status](06-compatibility-and-release-status.md)
for current stability qualifications.

