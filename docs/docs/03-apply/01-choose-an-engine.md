# Choose a dORM engine

The generated `Dorm` and repository API are shared across engines. The engine supplies the runtime implementation that reads, writes, filters, and streams those models.

Use the engine that matches the runtime and storage service required by your application:

| Engine | Storage/runtime | Main setup boundary |
| --- | --- | --- |
| `dorm_memory_database` | Pure Dart in-process memory | Construct `Engine()` and reuse it while the application runs |
| `dorm_bloc_database` | In-memory state managed by BLoC | Construct `Engine()` and reuse it while the application runs |
| `dorm_firebase_database` | Firebase Realtime Database | Initialize Firebase, create `FirebaseInstance`, and configure Firebase access |
| `dorm_mysql_database` | MySQL server through `mysql_client` | Open a `MySQLConnection` and pass it to `Engine` |
| `dorm_postgres_database` | PostgreSQL server through `postgres` | Open a `Connection` or `Pool` and pass it to `Engine` |
| `dorm_mongo_database` | MongoDB server through `mongo_dart` | Create and open a `Db`, then pass it to `Engine` |
| `dorm_http_database` | REST-shaped HTTP/JSON API through `package:http` | Create an owned `http.Client`, configure resources, and pass them to `Engine` |

The framework does not select an engine automatically. The generated `Dorm` receives the concrete engine through its constructor.

## Keep the shared application surface

The application code keeps the same shape after changing engines:

```dart
final Dorm dorm = Dorm(engine);

final User created = await dorm.users.repository.put(
  Creation.auto(
    dependency: const UserDependency(),
    data: userData,
  ),
);

final List<Product> products = await dorm.products.repository.peekAll(
  Filter.text('note', key: '_q-name'),
);
```

`Dorm`, generated entity accessors, repositories, filters, and relation paths are generated or framework-level APIs. The concrete engine changes how those operations reach storage.

The `Data`/`Model`/`Dependency` split remains the same. `UserData` is input, `User` carries its identity, and `UserDependency` supplies the values required to construct it.

## Use the memory engine for a pure Dart local store

Use `dorm_memory_database` when the application needs an in-process store
without a database server, Flutter, BLoC, or RxDart.

Add the package:

```shell
dart pub add dorm_memory_database
```

Construct the engine and reuse the same instance for the lifetime of the
in-process store:

```dart
import 'package:dorm_memory_database/dorm_memory_database.dart';

final Engine engine = Engine();
final Dorm dorm = Dorm(engine);
```

The engine generates UUID string identities for simple generated keys and
emits the current value followed by later changes through `pull` and
`pullAll`. Its records are lost when the process stops.

## Use the BLoC engine for local in-memory state

Add the package to a Dart application:

```shell
dart pub add dorm_bloc_database
```

Construct the engine directly:

```dart
final Engine engine = Engine();
final Dorm dorm = Dorm(engine);
```

This engine keeps records in process memory. It does not require a database server or network configuration. Its state belongs to the engine instance, so create one instance and pass the same generated `Dorm` through the application code that needs the shared store.

Continue with [Run the store with the BLoC engine](02-use-bloc.md) for the complete setup.

## Use Firebase Realtime Database for a Firebase-backed runtime

The Firebase engine depends on Flutter Firebase packages. It is therefore a Flutter/Firebase integration rather than a backend-neutral Dart engine.

Its setup has three separate values:

1. the initialized Firebase app;
2. a `FirebaseInstance` that provides Firebase Core, Database, and Authentication dependencies;
3. an `Engine` with an optional database root path.

The engine requires String identities. Its Firebase-specific query and offline behavior also depends on the Firebase Realtime Database SDK.

Continue with [Run the store with Firebase Realtime Database](03-use-firebase.md) for initialization and emulator setup.

## Use MySQL for a SQL-backed runtime

Add the MySQL engine and the packages imported by the connection setup:

```shell
dart pub add dorm_mysql_database
dart pub add mysql_client dotenv
```

Create a `MySQLConnection`, connect it, and pass it to `Engine`:

```dart
final MySQLConnection connection = await MySQLConnection.createConnection(
  host: host,
  port: port,
  userName: username,
  password: password,
);

await connection.connect();
final Dorm dorm = Dorm(Engine(connection));
```

The MySQL engine executes SQL against the connection. Tables must exist before CRUD operations succeed. The package includes a separate schema-generation command for the subset of model declarations it understands.

Continue with [Run the store with MySQL](04-use-mysql.md) and [Generate MySQL table definitions](07-generate-mysql-schema.md).

## Use PostgreSQL for a SQL-backed runtime

Add the PostgreSQL engine:

```shell
dart pub add dorm_postgres_database
```

Open a `Connection` or `Pool` from the `postgres` package and pass the opened
object to `Engine`. Both implement the `SessionExecutor` accepted by the
engine:

```dart
final Connection connection = await Connection.open(endpoint);
final Dorm dorm = Dorm(Engine(connection));
```

The PostgreSQL engine executes parameterized SQL, supports generated CRUD,
filters, ordering, limits, and relationship paths, and uses PostgreSQL upsert
statements for identified writes. The engine does not create tables or
migrations. Create the schema with SQL before using repository operations.

Its `pull` and `pullAll` streams emit the initial read result only; the
engine does not use PostgreSQL `LISTEN`/`NOTIFY` for these operations.

Continue with [Run the PostgreSQL example](08-use-postgres.md).

## Use MongoDB for a document-backed runtime

Add the MongoDB engine and driver:

```shell
dart pub add dorm_mongo_database
dart pub add mongo_dart
```

Create and open a `Db`, then pass it to `Engine`:

```dart
final Db database = Db(
  Platform.environment['MONGO_URI'] ??
      'mongodb://127.0.0.1:27017/dorm_example',
);
await database.open();
final Dorm dorm = Dorm(Engine(database));
```

The application owns the `Db` lifecycle. The engine stores identities in the
schema-declared document fields, not in MongoDB `_id`, and does not convert
them to `ObjectId`. It supports framework CRUD, filters, limits, relationships,
and initial-read-only streams. It does not expose public transactions,
aggregation, migrations, or change streams.

Continue with [Run the store with MongoDB](09-use-mongo.md).

## Use HTTP/JSON for a REST-shaped API

Add the HTTP engine:

```shell
dart pub add dorm_http_database
dart pub add http
```

Create an application-owned `http.Client`, configure one resource mapping per
entity, and pass the HTTP configuration to `Engine`:

```dart
final http.Client client = http.Client();
final Engine engine = Engine(
  client: client,
  baseUri: Uri.parse('https://api.example.test/'),
  mapping: HttpMapping.byTableName({
    'users': HttpResourceMapping(path: 'users'),
  }),
);
final Dorm dorm = Dorm(engine);
```

The base URI should end with `/` so relative resource paths resolve as
expected. The default query codec sends equality, prefix, range, date, sort,
and limit conditions as URL parameters. Use `HttpJsonCodec.envelope()` when
the API wraps response data in a JSON field such as `data`.

Batch operations require batch endpoints in the corresponding
`HttpResourceMapping`. The engine does not silently replace one batch request
with multiple requests. `pull` and `pullAll` emit one HTTP read only, and
relationships use readable repository operations, which can produce multiple
HTTP requests.

Close the client from the application lifecycle:

```dart
client.close();
```

Continue with [Run with HTTP/JSON](10-use-http.md).

## Compare current capability boundaries

The common repository API does not imply identical runtime behavior in every engine:

| Capability | Memory | BLoC | Firebase | MySQL | PostgreSQL | MongoDB | HTTP |
| --- | --- | --- | --- | --- | --- | --- | --- |
| External server required | No | No | Firebase project or emulator | Yes | Yes | Yes | HTTP API |
| Generated identity from `put` | UUID in memory | UUID in memory | Firebase push key | UUID in SQL | UUID in SQL | UUID in a document field | UUID in HTTP request body |
| Streams | State-backed | State-backed | Firebase value events | Initial read only | Initial read only | Initial read only | Initial read only |
| Filter/query execution | In-memory query | In-memory query | Firebase query | SQL query | PostgreSQL SQL query | MongoDB selector | URL parameters |
| Public transaction API | No | No | No | No | No | No | No |
| Pagination | Not supported | Not supported | Not supported | Not supported | Not supported | Not supported | Not supported |
| Composite identity with `put` | `Creation.explicit`; automatic generation is rejected | `Creation.explicit`; automatic generation is rejected | Composite identities unsupported | `Creation.explicit`; automatic generation is rejected | `Creation.explicit`; automatic generation is rejected | `Creation.explicit`; automatic generation is rejected | `Creation.explicit`; automatic generation is rejected |

The matrix describes current implementation behavior. It is not a compatibility promise for a future release.

## Select the next setup step

For a local Dart process, start with the memory engine. Use BLoC when the
application specifically needs its BLoC integration. For Firebase Realtime
Database, continue with the Flutter/Firebase initialization page. For a
SQL-backed application, prepare the MySQL or PostgreSQL connection and schema
before issuing repository operations. For MongoDB, prepare the URI and open
the `Db` before constructing the engine.
