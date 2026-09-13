# Run the store with SQLite

`dorm_sqlite_database` connects dORM repositories to a local SQLite database
through [`sqlite_async`](https://pub.dev/packages/sqlite_async). The engine uses
the asynchronous driver API and keeps the database object owned by your
application.

## Add the engine package

From your pure Dart project, run:

```shell
dart pub add dorm_sqlite_database
```

Add the SQLite driver because the application creates and owns the
`SqliteDatabase`:

```shell
dart pub add sqlite_async
```

The second dependency is needed because your application creates and closes the
`SqliteDatabase` passed to the dORM engine.

## Create the database and schema

Create the database before constructing `Engine`. Use SQL or the migration
helpers provided by `sqlite_async` to prepare the tables. The dORM package does
not generate SQLite DDL.

```dart
import 'package:dorm_sqlite_database/dorm_sqlite_database.dart';
import 'package:sqlite_async/sqlite_async.dart';

final SqliteDatabase database = SqliteDatabase(path: 'store.db');

await database.execute('''
  CREATE TABLE users (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    active BOOLEAN NOT NULL
  )
''');

final Engine engine = Engine(database);
final Dorm dorm = Dorm(engine);
```

Close `database` after repository work and stream subscriptions have ended:

```dart
await database.close();
```

## Use repositories

Generated repositories use SQLite for the same dORM operations used by the
other engines. Filters, offset pages, simple and composite identities,
relationships, and model serialization are mapped to SQL statements with bound
parameters.

## Use a database-generated identity

For an SQLite `INTEGER PRIMARY KEY` column, declare a single key with
`DatabaseGeneratedIdSpec(type: int)` and omit that key from the `Data` input.
`Creation.auto` inserts the remaining fields, reads SQLite's last inserted row
ID on the same write context, and returns a model with that identity.

```dart
@Model(
  name: 'products',
  primaryKey: [
    DatabaseGeneratedIdSpec(as: #id, name: 'id', type: int),
  ],
)
abstract class Product {
  String get name;
}
```

This path applies to a single numeric database-generated key. Composite keys
still require `Creation.explicit`.

## Use transactions and streams

SQLite supports the portable dORM transaction callback through
`TransactionalDorm`:

```dart
final TransactionalDorm txDorm = TransactionalDorm(engine);

await txDorm.transaction((tx) async {
  await tx.users.repository.push(user);
  await tx.carts.repository.push(cart);
});
```

`pull` and `pullAll` use `sqlite_async` table-change notifications and emit the
initial read followed by later query results. Streams cannot be created from a
transaction context.

## Runtime and storage details

`sqlite_async` provides asynchronous SQLite access for Dart and Flutter. Its
web support requires SQLite WASM and worker assets. Declare Boolean columns as
`BOOLEAN` so the engine can restore SQLite integer values as Dart `bool` values.

The optional `SqliteMigrationAdapter` exposes the portable migration contract through `dorm_migrations`. It handles explicit SQL DDL/DML and records history in a reserved table. Use the supplied `SqliteDatabase` directly for indexes, connection management, or SQLite features outside that contract.
