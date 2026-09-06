# Implement a custom dORM engine

A custom engine connects the framework contracts to another storage system. The generated model source and repository calls remain the application-facing layer; the engine supplies the query, reference, and relationship implementations.

This guide assumes that the model and repository flow is already understood. It uses a package named `dorm_example_database` as a placeholder for the engine package you are creating.

## Create the engine package

Create a Dart package and add the framework:

```shell
dart create -t package dorm_example_database
cd dorm_example_database
dart pub add dorm_framework
dart pub add dev:lints
```

The package name is not part of the framework contract. The current engine packages use the `dorm_<backend>_database` naming convention.

Create the implementation under `lib/src/` and expose the public entry point from `lib/dorm_example_database.dart`.

## Implement the supported engine boundary

The official extension boundary is the set of framework contracts:

```text
BaseQuery<Q>
BaseReference<Q>
BaseRelationship<Q>
BaseEngine<Q>
```

The same query type `Q` is used by the engine's filters, reference, and relationship implementations.

The engine entry point supplies the latter two implementations to generated `Dorm` code:

```dart
class Engine implements BaseEngine<Query> {
  final BackendConnection connection;

  const Engine(this.connection);

  @override
  BaseReference<Query> createReference() {
    return Reference(connection);
  }

  @override
  BaseRelationship<Query> createRelationship() {
    return Relationship(connection);
  }
}
```

`DatabaseEntity` calls `createReference` and `createRelationship` when it is constructed. Repository calls then delegate to those created objects.

## Implement the backend query value

Implement every method required by `BaseQuery<Q>`:

```dart
class Query implements BaseQuery<Query> {
  final BackendQuery value;

  const Query(this.value);

  @override
  Query whereValue(String key, Object? value) {
    return Query(this.value.whereEqual(key, value));
  }

  @override
  Query whereText(String key, String prefix) {
    return Query(this.value.whereStartsWith(key, prefix));
  }

  @override
  Query whereDate(String key, DateTime date, DateFilterUnit unit) {
    return Query(this.value.whereDate(key, date, unit));
  }

  @override
  Query whereRange<R>(String key, FilterRange<R> range) {
    return Query(this.value.whereRange(key, range));
  }

  @override
  Query limit(int count) {
    return Query(this.value.limit(count));
  }

  @override
  Query sorted(String key) {
    return Query(this.value.sorted(key));
  }
}
```

The `BackendQuery` calls above are placeholders for the operations supplied by the storage driver. `BaseQuery` does not define a portable serialized query language; `Query` is the backend-specific representation consumed by the engine.

Existing engine query types wrap different values:

- BLoC stores a table operation representation;
- Firebase wraps a Firebase Database query;
- MySQL stores SQL text and parameter maps.

The current implementations return a new query value when applying an operation. The interface requires a `Q` result for each method, but it does not independently enforce immutability.

## Implement the reference

Implement `BaseReference<Query>` for the backend's direct entity operations:

```dart
class Reference implements BaseReference<Query> {
  final BackendConnection connection;

  const Reference(this.connection);

  @override
  Future<Model?> peek<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I> entity,
    I id,
  ) async {
    // Read one backend record and return entity.fromJson(id, data).
    throw UnimplementedError();
  }

  // Implement pull, peekAll, pullAll, peekAllKeys, pop, popKeys,
  // popAll, patch, put, putAll, push, pushAll, and purge.
}
```

Each reference method receives an `Entity`. Use that entity for the model-specific operations instead of depending on generated model classes:

| Entity operation | Use at the backend boundary |
| --- | --- |
| `schema` | Table/storage name, field names, and foreign-key metadata |
| `primaryKeyCodec` | Encode and decode simple or composite identities |
| `fromData` | Construct a model from `Dependency`, generated identity, and `Data` |
| `identify` | Obtain the identity of a model being written |
| `toJson` | Convert a data/model value into backend field values |
| `fromJson` | Convert a backend map/row into a generated model |
| `convert` | Apply `Data` to an existing model while preserving its identity and other model fields |

The reference must preserve the framework operation semantics: `peek` returns a nullable single model, collection reads return lists, `put` returns a created model, and write/delete methods complete with `Future<void>` where specified.

`pull` and `pullAll` return streams. The framework exposes these methods as a common vocabulary, but it does not require every engine to provide continuous realtime events. The MySQL implementation currently emits an initial read only; a custom engine must document the stream behavior it actually provides.

## Implement relationships

Implement `BaseRelationship<Query>` for the four association forms:

```text
oneToOne
oneToMany
manyToOne
manyToMany
```

Each method receives readable sources and a callback that supplies a target ID or filter. Return the corresponding framework association type and `Join` result shape.

The relationship implementation must preserve the framework cardinality semantics:

- required to-one paths omit parents without a target;
- nullable to-one paths preserve parents with `null`;
- to-many paths flatten related values;
- empty-preserving to-many paths retain parents with an empty list;
- many-to-many paths return the framework's nullable pair shape.

A source can expose a `TableRelationPlan`, `CompositeRelationPlan`, or another `RelationPlan`. Use a plan when the backend can execute a relationship structurally, such as a grouped SQL read. Keep readable operations as the fallback for sources that cannot be optimized.

The relation plan is an optimization hook, not a performance guarantee. The framework still expects the readable source operations and the documented result semantics.

## Publish the engine entry point

Expose the engine-facing types from the package barrel:

```dart
library dorm_example_database;

export 'src/engine.dart' show Engine;
export 'src/filter.dart' show Filter;
export 'src/query.dart' show Query;
```

The current engine packages guarantee `Engine`, `Filter`, and `Query` through their barrel files. Concrete `Reference` and `Relationship` classes under `lib/src` are not the confirmed application-facing construction API. A custom package may keep those classes internal to its engine implementation.

## Validate the engine

Add tests for the framework contract and run them from the custom engine package:

```shell
dart pub get
dart analyze
dart test
```

Test at least the operations implemented by the backend:

- simple and composite identity encoding where supported;
- `put`, `putAll`, `peek`, `peekAll`, `push`, `pushAll`, `patch`, and deletion;
- empty and filtered reads;
- `pull` and `pullAll` stream behavior;
- all relationship cardinalities used by the engine;
- serialization and deserialization of generated fields;
- backend errors and invalid identity handling.

Framework relationship-path tests and MySQL relationship tests demonstrate the kinds of contract cases that can be exercised without a full application. Live database tests require the external service and schema used by the engine.

## Separate supported extension from incidental access

| Extension mechanism | Status |
| --- | --- |
| Implement `BaseEngine`, `BaseQuery`, `BaseReference`, and `BaseRelationship` | Officially supported |
| Implement `Entity`, `PrimaryKeyCodec`, `RelationSource`, or relation plans through their public framework contracts | Officially supported at the framework contract level |
| Use concrete engine constructors or types that are exported by a package barrel | Possible, subject to that package's public API |
| Import another package's `lib/src` classes or rely on generated normalization helper names | Incidental implementation use; not guaranteed |
| Depend on a backend's private transaction, cache, or driver behavior through an internal class | Incidental and backend-specific |

The current common framework has no public transaction or pagination contract. A custom engine can have internal backend mechanisms for those features, but those mechanisms do not become common dORM APIs automatically.
