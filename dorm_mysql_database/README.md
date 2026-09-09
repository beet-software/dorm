# dorm_mysql_database

MySQL database engine for dORM. It connects generated dORM repositories to an
application-owned `MySQLConnection` from [`mysql_client`](https://pub.dev/packages/mysql_client).

The engine supports CRUD operations, filters, ordering, offset pagination,
relationships, database-generated numeric identities, and the portable dORM
transaction callback.

## Installation

For a new Dart application, add the framework, annotations, MySQL engine, and
driver:

```shell
dart pub add dorm_framework
dart pub add dorm_annotations
dart pub add dorm_mysql_database
dart pub add mysql_client
dart pub add dev:dorm_generator
dart pub add dev:build_runner
```

`dotenv` is optional. The package example uses it to load local connection
settings from a `.env` file; the engine itself does not require it.

## Open MySQL and create `Dorm`

Open the connection before constructing the engine. The application owns the
connection lifecycle and must close it after the repositories are no longer
needed:

```dart
import 'package:dorm_framework/dorm_framework.dart';
import 'package:dorm_mysql_database/dorm_mysql_database.dart';
import 'package:mysql_client/mysql_client.dart';

Future<void> main() async {
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
    final Engine engine = Engine(connection);
    final dorm = Dorm(engine);

    // Use generated repositories through `dorm` here.
  } finally {
    await connection.close();
  }
}
```

`Engine` does not open the connection, select a database, or close the
connection. Those steps remain part of the application's setup.

## Generate models and the SQL schema

Keep the annotated model source and its generated parts in the application:

```shell
dart run build_runner build
```

The package also provides a command that reads supported `@Model` declarations
and prints MySQL table definitions:

```shell
dart run dorm_mysql_database:generate lib/models.dart > schema.sql
```

Apply `schema.sql` with the MySQL tooling used by the application. This command
generates table definitions; it does not compare an existing database, track
migrations, rename columns, create indexes, or update a live schema.

The generator covers model names, primary-key specifications, scalar
`@Field`/`@ForeignField` declarations, and the supported scalar Dart types.
Complex embedded and polymorphic values may require schema definitions written
by the application.

## Use repositories

The generated repositories use the same dORM operations as the other engines:

```dart
final User user = await dorm.users.repository.put(
  Creation.auto(
    dependency: const UserDependency(),
    data: UserData(
      name: 'Ada',
      active: true,
      age: 37,
    ),
  ),
);

final List<User> users = await dorm.users.repository.peekAll(
  Filter.text('Ada', field: UserEntity.fields.name),
);

await dorm.users.repository.push(
  user.copyWith(name: 'Ada Lovelace'),
);
```

Filter values are sent as MySQL parameters. Table and column names come from
the generated entity schema.

## Database-generated identities

For a MySQL `AUTO_INCREMENT` key, declare a single
`DatabaseGeneratedIdSpec`. The key is omitted from the creation data;
`Creation.auto` lets MySQL generate it and returns the model with the generated
identity:

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

This path supports a single numeric database-generated key. Composite
identities require `Creation.explicit`.

## Transactions and streams

MySQL implements the portable `TransactionalDorm` API. Operations performed
through the transaction context reuse the same MySQL transaction:

```dart
final transactionalDorm = TransactionalDorm(engine);

await transactionalDorm.transaction((tx) async {
  final User user = await tx.users.repository.peek(user.id);
  await tx.users.repository.push(user.copyWith(active: false));
});
```

`patch`, `putAll`, and `pushAll` also use connection transactions internally.
The engine does not expose the driver transaction object as part of the dORM
API.

`pull` and `pullAll` currently emit the initial read result. They do not
subscribe to later MySQL changes.

## Connection and error handling

Credentials, database permissions, TLS settings, and server access rules are
configured through `mysql_client` and the application environment. The engine
propagates errors from the MySQL driver and server without wrapping them in a
dORM-specific error hierarchy.

See the [MySQL setup guide](https://github.com/beet-software/dorm/blob/main/docs/docs/apply/use-mysql.md)
for environment configuration, relationships, schema generation, and the
engine's current behavior in more detail.
