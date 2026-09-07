# Run the store with MySQL

`dorm_mysql_database` connects generated dORM repositories to a live MySQL server through `mysql_client`.

This setup has three resources that must be available before a repository call can succeed:

1. a MySQL server;
2. a database containing the generated tables;
3. an open `MySQLConnection` passed to the dORM `Engine`.

## Add the packages

From the Dart application's directory, run:

```shell
dart pub add dorm_mysql_database
dart pub add mysql_client
dart pub add dotenv
dart pub get
```

`dorm_mysql_database` supplies the dORM engine. `mysql_client` supplies the connection type used by application code. `dotenv` loads connection values from a local `.env` file in the command-line example.

## Define the connection settings

Create `.env` beside the application's `pubspec.yaml`:

```dotenv
MYSQL_HOST=127.0.0.1
MYSQL_PORT=3306
MYSQL_USERNAME=[PLACEHOLDER: MySQL username]
MYSQL_PASSWORD=[PLACEHOLDER: MySQL password]
```

The connection code reads these names as strings and parses `MYSQL_PORT` as an integer. Keep the actual password in the local environment value instead of replacing the placeholder in documentation or source control.

## Open MySQL and create `Dorm`

Use `try`/`finally` so the connection is closed after the application finishes:

```dart
import 'package:dotenv/dotenv.dart';
import 'package:dorm_mysql_database/dorm_mysql_database.dart';
import 'package:mysql_client/mysql_client.dart';

import 'models.dart';

Future<void> main() async {
  final DotEnv env = DotEnv()..load();

  final MySQLConnection connection =
      await MySQLConnection.createConnection(
    host: env['MYSQL_HOST']!,
    port: int.parse(env['MYSQL_PORT']!),
    userName: env['MYSQL_USERNAME']!,
    password: env['MYSQL_PASSWORD']!,
  );

  await connection.connect();
  try {
    final Dorm<Query, OffsetPageRequest> dorm = Dorm(Engine(connection));
    await runStoreFlow(dorm);
  } finally {
    await connection.close();
  }
}
```

The dORM `Engine` does not open or close the MySQL connection itself. The application owns the connection lifecycle and passes the open connection to `Engine`.

## Select the database

The command-line flow selects a database explicitly before constructing the dORM engine:

```dart
await connection.execute('USE test;');
```

Create the `test` database and its tables before running this statement. Replace `test` with the database name used by the application and update the connection setup accordingly.

## Run CRUD and filters

Once the connection and tables exist, the generated repository calls are the same as with other engines:

```dart
final User user = await dorm.users.repository.put(
  Creation.auto(
    dependency: const UserDependency(),
    data: userData,
  ),
);

final List<User> users = await dorm.users.repository.peekAll(
  Filter.text('ada', key: '_q-username'),
);

await dorm.users.repository.push(
  User(
    id: user.id,
    username: user.username,
    email: 'ada@example.org',
    profile: user.profile,
  ),
);
```

The MySQL query implementation maps value and text filters to SQL predicates with parameters. Sort and limit are appended to the generated query. Table and column identifiers come from generated schema metadata.

## Read relationships

The MySQL engine implements direct relationship associations and generated relation paths. Use the same generated relation API as the common store workflow:

```dart
final List<Join<Cart, CartItem>> rows = await dorm
    .relations
    .carts
    .items
    .peekAll(Filter.value(cart.id, key: 'id'));
```

For direct table sources, the engine can use relation plan metadata. Relationship sources that do not expose a direct table plan use readable repository operations.

## Understand stream behavior

The current MySQL reference implements `pull` and `pullAll` by performing an initial read and adding that result to a stream. The source marks realtime behavior as a TODO. A MySQL repository stream should therefore be treated as an initial result, not as a documented live subscription to database changes.

## Observe transaction use inside operations

The current MySQL implementation uses a connection transaction internally for `patch`, `putAll`, and `pushAll`. The public framework does not expose a general transaction object or transaction callback API.

This internal behavior does not change the repository method signatures. Handle connection and database errors around the repository call:

```dart
try {
  await dorm.products.repository.put(
    Creation.auto(
      dependency: const ProductDependency(),
      data: productData,
    ),
  );
} catch (error, stackTrace) {
  print('MySQL operation failed: $error');
  print(stackTrace);
}
```
