# Run the store with SQLite

`dorm_sqlite_database` connects dORM repositories to a local SQLite database
through [`sqlite_async`](https://pub.dev/packages/sqlite_async). The engine uses
the asynchronous driver API and keeps the database object owned by your
application.

## Add the engine package

From your pure Dart project, run:

```shell title="Add the SQLite engine"
dart pub add dorm_sqlite_database
```

Add the SQLite driver because the application creates and owns the
`SqliteDatabase`:

```shell title="Add the SQLite driver"
dart pub add sqlite_async
```

The second dependency is needed because your application creates and closes the
`SqliteDatabase` passed to the dORM engine.

## Create the database and schema

Create the database before constructing `Engine`. Use SQL or the migration
helpers provided by `sqlite_async` to prepare the tables. The dORM package does
not generate SQLite DDL.

```dart title="Create the SQLite database and schema"
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

The engine does not expose SQLite-native statements, indexes, migrations, or
connection management through the dORM API. Use the supplied `SqliteDatabase`
directly for those operations when they are part of application setup.
