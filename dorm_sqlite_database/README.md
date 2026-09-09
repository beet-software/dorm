# dorm_sqlite_database

<p>
  <a href="https://pub.dev/packages/dorm_sqlite_database"><img src="https://img.shields.io/pub/v/dorm_sqlite_database.svg?label=dorm_sqlite_database" alt="dorm_sqlite_database on pub.dev"></a>
  <a href="https://pub.dev/packages/dorm_sqlite_database"><img src="https://img.shields.io/pub/points/dorm_sqlite_database?logo=dart" alt="dorm_sqlite_database pub points"></a>
  <a href="https://pub.dev/packages/dorm_sqlite_database"><img src="https://img.shields.io/pub/popularity/dorm_sqlite_database?logo=dart" alt="dorm_sqlite_database popularity"></a>
  <a href="https://pub.dev/packages/dorm_sqlite_database"><img src="https://img.shields.io/pub/likes/dorm_sqlite_database?logo=dart" alt="dorm_sqlite_database likes"></a>
  <a href="https://ezgrs.github.io/dorm/apply/use-sqlite/"><img src="https://img.shields.io/badge/documentation-dORM-4c8bf5?style=flat" alt="dorm_sqlite_database documentation"></a>
  <a href="https://github.com/beet-software/dorm"><img src="https://img.shields.io/badge/repository-GitHub-181717?logo=github&style=flat" alt="dORM repository"></a>
  <a href="https://github.com/beet-software/dorm"><img src="https://img.shields.io/github/license/beet-software/dorm?style=flat" alt="License"></a>
  <a href="https://github.com/beet-software/dorm/actions/workflows/dart.yml"><img src="https://github.com/beet-software/dorm/actions/workflows/dart.yml/badge.svg" alt="Dart CI"></a>
</p>

dorm_sqlite_database adapts dORM repositories to SQLite through the
asynchronous sqlite_async API. It accepts an application-owned
SqliteDatabase.

## Backend and runtime

The backend is a local SQLite file through `sqlite_async` and `sqlite3`. Web
applications require the WASM and worker setup documented by `sqlite_async`.

## Install

~~~shell
dart pub add dorm_framework
dart pub add dorm_sqlite_database
dart pub add sqlite_async
dart pub add dorm_annotations
dart pub add --dev dorm_generator
dart pub add --dev build_runner
~~~

sqlite_async uses sqlite3 underneath. Native Dart and Flutter targets are
supported; web usage requires the WASM and worker setup documented by
sqlite_async.

## Create the engine and Dorm facade

~~~dart
import 'package:dorm_sqlite_database/dorm_sqlite_database.dart';
import 'package:sqlite_async/sqlite_async.dart';

final database = SqliteDatabase(path: '[PLACEHOLDER: database path]');
await database.execute(
  'CREATE TABLE users (id TEXT PRIMARY KEY, name TEXT NOT NULL)',
);

try {
  final engine = Engine(database);
  final dorm = Dorm(engine);
  // Use generated repositories here.
} finally {
  await database.close();
}
~~~

The application owns the database and decides when schema or migration SQL is
executed. The engine does not create a schema automatically.

## Identities, filters, pages, and relationships

SQLite supports framework filters, ordering, offset pagination, relationships,
simple and composite identities, and batches.

## Transactions

~~~dart
final User user = await dorm.users.repository.put(
  Creation.auto(
    dependency: const UserDependency(),
    data: UserData(name: 'Ada'),
  ),
);

final txDorm = TransactionalDorm(engine);
await txDorm.transaction((tx) async {
  await tx.users.repository.push(user.copyWith(name: 'Ada Lovelace'));
});
~~~

## Streams

`pull` and `pullAll` use sqlite_async table watches and can emit later changes.

## Relationships

The generated relationship API is the same as other engines; the number of SQL
reads depends on the relation plan and fallback path.

## Schema, errors, and limitations

Use SQL or sqlite_async migration facilities from the application. This package
does not generate schema or migration history. SQLite and sqlite_async errors
are propagated without a dORM-specific error hierarchy.

## Run an example

Generate a local project with the showcase CLI. It includes a schema file and
the commands needed to run SQLite without a server:

~~~shell
dart pub global activate dorm_example
dorm_example -e sqlite
~~~

## Links

- [Run with SQLite](https://ezgrs.github.io/dorm/apply/use-sqlite/)
- [sqlite_async](https://pub.dev/packages/sqlite_async)
- [sqlite3](https://pub.dev/packages/sqlite3)
- [dorm_framework](https://pub.dev/packages/dorm_framework)
- [GitHub repository](https://github.com/beet-software/dorm)
