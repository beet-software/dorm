# Public API reference

Use this page to locate exported APIs. The tutorial pages explain how to use
the common operations; this page groups the same surface by package.

## Import from package barrels

Use these package entry points for application code:

| Package | Barrel |
| --- | --- |
| Annotations | `package:dorm_annotations/dorm_annotations.dart` |
| Framework | `package:dorm_framework/dorm_framework.dart` |
| Generator | `package:dorm_generator/dorm_generator.dart` |
| BLoC engine | `package:dorm_bloc_database/dorm_bloc_database.dart` |
| Firebase engine | `package:dorm_firebase_database/dorm_firebase_database.dart` |
| MySQL engine | `package:dorm_mysql_database/dorm_mysql_database.dart` |

Concrete classes below `lib/src/` are not automatically part of the barrel
surface. A class being importable by an internal package path does not by
itself establish a supported application API.

## Annotations and generated-facing APIs

The annotations package contains the declarations read by code generation:

- `Data` marks a serializable data class.
- `Model` associates a class with a stored model and declares its identity
  shape and generated accessor name.
- `Field`, `ForeignField`, and `ModelField` describe stored fields and
  relationships.
- `QueryField` and `QueryToken` describe generated query values.
- `PolymorphicField` and `PolymorphicData` describe polymorphic values.
- `GeneratedIdSpec` and `ExistingIdSpec` describe primary-key parts.

See [Annotations and generated API](02-annotations-and-generated-api.md) for
parameters and generated type names.

The annotations barrel also re-exports selected APIs from
copy_with_extension and json_annotation. Their behavior is defined by those
packages.

## Generator entry point

The generator package exports:

~~~dart
Builder generateOrm(BuilderOptions options)
~~~

The builder writes a .dorm.dart part file and is configured for dependent
packages through build_runner. Application code normally invokes build_runner;
it does not call generateOrm directly.

## Framework operation surface

Generated repositories expose these operation families:

| Method | Signature shape | Result |
| --- | --- | --- |
| `peek` | `Future<Model?> peek(I id)` | One model or `null`. |
| `peekAll` | `Future<List<Model>> peekAll([BaseFilter<Q> filter])` | Matching models. |
| `pull` | `Stream<Model?> pull(I id)` | A stream of one model or `null`. |
| `pullAll` | `Stream<List<Model>> pullAll([BaseFilter<Q> filter])` | A stream of matching lists. |
| `peekAllKeys` | `Future<List<I>> peekAllKeys()` | Stored identities. |
| `put` | `Future<Model> put(Dependency<Data>, Data)` | A newly constructed/persisted model. |
| `putAll` | `Future<List<Model>> putAll(Dependency<Data>, List<Data>)` | Persisted models. |
| `push` | `Future<void> push(Model model)` | Persists an identified model. |
| `pushAll` | `Future<void> pushAll(List<Model>)` | Persists identified models. |
| `patch` | `Future<void> patch(I id, Model? Function(Model?) update)` | Updates, creates, or removes according to the callback result. |
| `pop` | `Future<void> pop(I id)` | Removes one identity. |
| `popKeys` | `Future<void> popKeys(Iterable<I>)` | Removes selected identities. |
| `popAll` | `Future<void> popAll(BaseFilter<Q>)` | Removes matching models. |
| `purge` | `Future<void> purge()` | Removes all models for the entity. |

`Repository` combines the data and model operation interfaces. The generated
entry point is normally `dorm.<model>.repository`.

See [Create, read, update, and remove](../02-build-the-store/01-crud.md) for
operation sequences and [Framework contracts](03-framework-contracts.md) for
contract details.

## Filters and queries

The framework exposes `BaseFilter<Q>` factories and a `BaseQuery<Q>`
contract. Engine packages expose a concrete `Filter` type and `Query` type.

Common filter factories include:

| Factory | Input |
| --- | --- |
| `Filter.empty()` | No condition. |
| `Filter.value(...)` | Exact value, using a key or generated field schema. |
| `Filter.text(...)` | Text-prefix condition. |
| `Filter.textRange(...)` | Text bounds. |
| `Filter.numericRange(...)` | Numeric bounds. |
| `Filter.date(...)` | Date comparison at a `DateFilterUnit`. |
| `Filter.dateRange(...)` | Date bounds. |

The `limit` and `sort` extensions add query modifiers to a filter. See
[Search and filter](../02-build-the-store/02-query-and-filter.md).

## Relationship APIs

The framework exposes:

- `BaseRelationship<Q>` for one-to-one, one-to-many, many-to-one, and
  many-to-many associations;
- `RelationPath<Context, Root, Current, Q>` for chained generated paths;
- `Join<LeftModel, RightModel>` for relationship results;
- `RelationSource`, `RelationPlan`, and `RelationSpec` for relationship
  sources and generated path metadata;
- `ModelRelationship` and `RelationshipDefinedAssociation` for generated
  and explicit relationship access.

Relationship path reads return `Future<List<Join<...>>>` or corresponding
streams. See [Add a cart and read related products](../02-build-the-store/03-relations-and-cart.md)
and [Framework contracts](03-framework-contracts.md).

## Engine entry points

| Package | Public entry points |
| --- | --- |
| BLoC | `Engine()`, `Filter`, `Query`, and the exported BLoC API. |
| Firebase | `Engine(FirebaseInstance, {String? path})`, `FirebaseInstance`, `OfflineMode`, `Filter`, `Query`, and selected Firebase types. |
| MySQL | `Engine(MySQLConnection)`, `Filter`, and `Query`. |

The generated `Dorm` receives one concrete engine and exposes generated
`DatabaseEntity` accessors. See [Engine capability reference](04-engine-capabilities.md)
for current backend differences.

## Errors and status

Public methods return ordinary Dart futures and streams. Current failures can
include `ArgumentError`, `StateError`, `UnsupportedError`, Dart runtime
type errors, Firebase SDK errors, and MySQL client/server errors. There is no
single exported dORM exception base class.

See [Diagnose errors by layer](../05-troubleshooting/01-error-by-layer.md) for
error handling and [Compatibility and release status](06-compatibility-and-release-status.md)
for current compatibility qualifications.
