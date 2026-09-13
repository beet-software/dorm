# dorm_mysql_database

<p>
  <a href="https://pub.dev/packages/dorm_mysql_database"><img src="https://img.shields.io/pub/v/dorm_mysql_database.svg?label=dorm_mysql_database" alt="dorm_mysql_database on pub.dev"></a>
  <a href="https://pub.dev/packages/dorm_mysql_database"><img src="https://img.shields.io/pub/points/dorm_mysql_database?logo=dart" alt="dorm_mysql_database pub points"></a>
  <a href="https://pub.dev/packages/dorm_mysql_database"><img src="https://img.shields.io/pub/popularity/dorm_mysql_database?logo=dart" alt="dorm_mysql_database popularity"></a>
  <a href="https://pub.dev/packages/dorm_mysql_database"><img src="https://img.shields.io/pub/likes/dorm_mysql_database?logo=dart" alt="dorm_mysql_database likes"></a>
  <a href="https://ezgrs.github.io/dorm/apply/use-mysql/"><img src="https://img.shields.io/badge/documentation-dORM-4c8bf5?style=flat" alt="dorm_mysql_database documentation"></a>
  <a href="https://github.com/ezgrs/dorm"><img src="https://img.shields.io/badge/repository-GitHub-181717?logo=github&style=flat" alt="dORM repository"></a>
  <a href="https://github.com/ezgrs/dorm"><img src="https://img.shields.io/github/license/ezgrs/dorm?style=flat" alt="License"></a>
  <a href="https://github.com/ezgrs/dorm/actions/workflows/dart.yml"><img src="https://github.com/ezgrs/dorm/actions/workflows/dart.yml/badge.svg" alt="Dart CI"></a>
</p>

dorm_mysql_database connects generated dORM repositories to an
application-owned MySQLConnection from mysql_client.

The engine supports CRUD, framework filters, ordering, offset pagination,
relationships, database-generated numeric identities, and the portable dORM
transaction callback.

## Backend and runtime

The backend is MySQL through `mysql_client`. The application owns the opened
connection and selects the database before constructing the engine.

## Install

~~~shell
dart pub add dorm_framework
dart pub add dorm_mysql_database
dart pub add mysql_client
dart pub add dorm_annotations
dart pub add --dev dorm_generator
dart pub add --dev build_runner
~~~

dotenv is optional and is useful only when the application loads connection
settings from a local environment file.

## Create the engine and Dorm facade

~~~dart
import 'package:dorm_framework/dorm_framework.dart';
import 'package:dorm_mysql_database/dorm_mysql_database.dart';
import 'package:mysql_client/mysql_client.dart';

final MySQLConnection connection =
    await MySQLConnection.createConnection(
  host: '127.0.0.1',
  port: 3306,
  userName: '[PLACEHOLDER: MySQL username]',
  password: '[PLACEHOLDER: MySQL password]',
);

await connection.connect();
await connection.execute('USE [PLACEHOLDER: database name];');

try {
  final engine = Engine(connection);
  final dorm = Dorm(engine);
  // Use generated repositories here.
} finally {
  await connection.close();
}
~~~

The application opens, selects, and closes the connection. Engine does not
perform those lifecycle operations.

## Generate the schema

The package command reads supported Model declarations and prints MySQL table
definitions:

~~~shell
dart run dorm_mysql_database:generate lib/models.dart > schema.sql
~~~

Apply the generated SQL with the database tooling used by the application. The
command creates definitions; it does not compare a live schema, track
migrations, create indexes, or update an existing database. For ordered migration history, use `MySqlMigrationAdapter` from `dorm_migrations`. It applies explicit SQL operations, uses a backend advisory lock, and isolates migration operations because DDL may commit implicitly. See the [migration guide](https://ezgrs.github.io/dorm/operations/using-migrations/) for generation, review, and recovery.

The normal model generation command remains separate:

~~~shell
dart run build_runner build
~~~

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

For a MySQL AUTO_INCREMENT key, declare one DatabaseGeneratedIdSpec with a
numeric type. Creation.auto omits that field from the insert and returns the
model with the ID returned by MySQL. Composite identities require
Creation.explicit.

## Relationships

Direct relationships can use grouped SQL reads; other relationship sources use
readable-operation fallbacks. Both forms expose the same generated relationship
API.

## Transactions

MySQL implements TransactionalDorm. patch, putAll, and pushAll also use
connection transactions internally:

~~~dart
final txDorm = TransactionalDorm(engine);

await txDorm.transaction((tx) async {
  final User? user = await tx.users.repository.peek(userId);
  if (user != null) {
    await tx.users.repository.push(user.copyWith(active: false));
  }
});
~~~

## Streams

`pull` and `pullAll` currently emit the initial read result only. They do not
subscribe to later MySQL changes.

## Schema, errors, and limitations

Model and filter values are passed as driver parameters. Table and column
identifiers come from generated schema metadata. Provider failures are exposed
through the portable `DormDatabaseException` contract; inspect `cause` and
`providerCode` when MySQL-specific details are needed.

## Run an example

Generate a project with the showcase CLI. The generated project includes the
MySQL service configuration and the commands needed to run it:

~~~shell
dart pub global activate dorm_example
dorm_example -e mysql
~~~

## Links

- [Run with MySQL](https://ezgrs.github.io/dorm/apply/use-mysql/)
- [mysql_client](https://pub.dev/packages/mysql_client)
- [dorm_framework](https://pub.dev/packages/dorm_framework)
- [GitHub repository](https://github.com/ezgrs/dorm)
