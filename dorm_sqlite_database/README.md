# dorm_sqlite_database

`dorm_sqlite_database` is the SQLite engine for dORM. It uses the asynchronous
`sqlite_async` API and accepts an application-owned `SqliteDatabase`.

```shell
dart pub add dorm_sqlite_database
dart pub add sqlite_async
```

Open the database, create the schema with SQL or the migration facilities of
`sqlite_async`, and pass the same database instance to `Engine`:

```dart
final database = SqliteDatabase(path: 'app.db');
await database.execute(
  'CREATE TABLE users (id TEXT PRIMARY KEY, name TEXT NOT NULL)',
);

final engine = Engine(database);
final dorm = Dorm(engine);
// Use dorm.users.repository here.

await database.close();
```

The engine supports SQL filters, offset pagination, relationships, reactive
`pull` streams, composite identities, batches, and the portable dORM
transaction API. The application owns the database lifecycle.

`sqlite_async` supports native Dart and Flutter targets and has beta web
support that requires SQLite WASM and worker assets. The dORM engine does not
generate schema or migrations.
