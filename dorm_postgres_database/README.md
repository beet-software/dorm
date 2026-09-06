# dorm_postgres_database

PostgreSQL database engine for dORM.

The engine implements the contracts from `dorm_framework` and accepts a
`SessionExecutor` from the `postgres` package. Both an opened `Connection` and
an opened `Pool` can be passed to `Engine`.

```dart
final Connection connection = await Connection.open(endpoint);
final Engine engine = Engine(connection);
final Dorm dorm = Dorm(engine);
```

The package executes parameterized PostgreSQL statements, supports CRUD,
filters, ordering, limits, and generated relationship paths. `push` and
`pushAll` use PostgreSQL upsert statements. `pull` and `pullAll` emit the
initial read result only.

The package does not create schemas or migrations. Create the tables with the
SQL used by the application or its deployment tooling.

See [`example/`](example/) for a pure Dart application using generated models.
