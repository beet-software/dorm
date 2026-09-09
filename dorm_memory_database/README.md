# dorm_memory_database

`dorm_memory_database` is the pure Dart in-memory engine for dORM. It stores
records in the process and does not require a database server or connection
configuration.

Add it to a Dart application with:

```shell
dart pub add dorm_memory_database
```

Create one engine and pass it to the generated `Dorm` object:

```dart
final Engine engine = Engine();
final Dorm dorm = Dorm(engine);
```

The engine keeps its state in the `Engine` instance. Reuse that instance when
different parts of the application must access the same records. A new engine
starts with an independent empty store.

The public barrel exports `Engine`, `Filter`, and `Query`. CRUD operations,
filters, relationships, and reactive reads use the contracts from
`dorm_framework`. Automatic simple identities are UUID strings. Composite
identities must be supplied explicitly through `Creation.explicit`.

The package uses Dart streams for `pull` and `pullAll`; each subscription first
receives the current value and then receives updates caused by writes.
