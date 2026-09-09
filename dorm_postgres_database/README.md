# dorm_postgres_database

<p>
  <a href="https://pub.dev/packages/dorm_postgres_database"><img src="https://img.shields.io/pub/v/dorm_postgres_database.svg?label=dorm_postgres_database" alt="dorm_postgres_database on pub.dev"></a>
  <a href="https://pub.dev/packages/dorm_postgres_database"><img src="https://img.shields.io/pub/points/dorm_postgres_database?logo=dart" alt="dorm_postgres_database pub points"></a>
  <a href="https://pub.dev/packages/dorm_postgres_database"><img src="https://img.shields.io/pub/popularity/dorm_postgres_database?logo=dart" alt="dorm_postgres_database popularity"></a>
  <a href="https://pub.dev/packages/dorm_postgres_database"><img src="https://img.shields.io/pub/likes/dorm_postgres_database?logo=dart" alt="dorm_postgres_database likes"></a>
  <a href="https://ezgrs.github.io/dorm/apply/use-postgres/"><img src="https://img.shields.io/badge/documentation-dORM-4c8bf5?style=flat" alt="dorm_postgres_database documentation"></a>
  <a href="https://github.com/ezgrs/dorm"><img src="https://img.shields.io/badge/repository-GitHub-181717?logo=github&style=flat" alt="dORM repository"></a>
  <a href="https://github.com/ezgrs/dorm"><img src="https://img.shields.io/github/license/ezgrs/dorm?style=flat" alt="License"></a>
  <a href="https://github.com/ezgrs/dorm/actions/workflows/dart.yml"><img src="https://github.com/ezgrs/dorm/actions/workflows/dart.yml/badge.svg" alt="Dart CI"></a>
</p>

dorm_postgres_database adapts dORM repositories to PostgreSQL through the
postgres package. Engine accepts an opened SessionExecutor, including
Connection and Pool.

## Backend and runtime

The backend is PostgreSQL through `postgres`. The application opens and owns a
`Connection` or `Pool` before constructing the engine.

## Install

~~~shell
dart pub add dorm_framework
dart pub add dorm_postgres_database
dart pub add postgres
dart pub add dorm_annotations
dart pub add --dev dorm_generator
dart pub add --dev build_runner
~~~

## Create the engine and Dorm facade

~~~dart
import 'package:postgres/postgres.dart';
import 'package:dorm_postgres_database/dorm_postgres_database.dart';

final Connection connection = await Connection.open(
  Endpoint(
    host: '[PLACEHOLDER: host]',
    database: '[PLACEHOLDER: database]',
    username: '[PLACEHOLDER: username]',
    password: '[PLACEHOLDER: password]',
  ),
);

try {
  final engine = Engine(connection);
  final dorm = Dorm(engine);
  // Use generated repositories here.
} finally {
  await connection.close();
}
~~~

The application opens and closes the SessionExecutor. Pool can be passed in
the same way when the application manages pooling.

## Identities, filters, pages, and relationships

~~~dart
final User user = await dorm.users.repository.put(
  Creation.auto(
    dependency: const UserDependency(),
    data: UserData(name: 'Ada'),
  ),
);

await dorm.users.repository.push(user.copyWith(name: 'Ada Lovelace'));
~~~

The engine sends values as PostgreSQL parameters. Identified writes use
PostgreSQL upsert statements. DatabaseGeneratedIdSpec uses a returned identity
for supported simple-key schemas; composite identities require
Creation.explicit.

## Relationships

Generated relationships use grouped reads when possible and readable-operation
fallbacks otherwise.

## Transactions

PostgreSQL implements TransactionalDorm and runs the callback through the
SessionExecutor transaction API:

~~~dart
final txDorm = TransactionalDorm(engine);

await txDorm.transaction((tx) async {
  final User? user = await tx.users.repository.peek(userId);
  if (user != null) {
    await tx.users.repository.push(user.copyWith(active: false));
  }
});
~~~

The callback context is temporary and streams are unavailable inside it.

## Streams

`pull` and `pullAll` emit the initial read only. They do not subscribe to later
PostgreSQL changes.

## Schema, errors, and limitations

dorm_postgres_database does not generate schemas or migrations. Create and
migrate tables through the SQL and deployment workflow used by the application.
Driver and PostgreSQL errors are propagated without a new dORM error hierarchy.

## Run the example

See the [package example](example/README.md) for PostgreSQL environment
variables, schema setup, generation, and Dart commands.

## Links

- [Run with PostgreSQL](https://ezgrs.github.io/dorm/apply/use-postgres/)
- [postgres](https://pub.dev/packages/postgres)
- [dorm_framework](https://pub.dev/packages/dorm_framework)
- [GitHub repository](https://github.com/ezgrs/dorm)
