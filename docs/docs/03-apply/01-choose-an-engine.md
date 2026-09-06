# Choose a dORM engine

The generated `Dorm` and repository API are shared across engines. The engine supplies the runtime implementation that reads, writes, filters, and streams those models.

Use the engine that matches the runtime and storage service required by your application:

| Engine | Storage/runtime | Main setup boundary |
| --- | --- | --- |
| `dorm_bloc_database` | In-memory state managed by BLoC | Construct `Engine()` and reuse it while the application runs |
| `dorm_firebase_database` | Firebase Realtime Database | Initialize Firebase, create `FirebaseInstance`, and configure Firebase access |
| `dorm_mysql_database` | MySQL server through `mysql_client` | Open a `MySQLConnection` and pass it to `Engine` |

The framework does not select an engine automatically. The generated `Dorm` receives the concrete engine through its constructor.

## Keep the shared application surface

The application code keeps the same shape after changing engines:

```dart
final Dorm dorm = Dorm(engine);

final User created = await dorm.users.repository.put(
  const UserDependency(),
  userData,
);

final List<Product> products = await dorm.products.repository.peekAll(
  Filter.text('note', key: '_q-name'),
);
```

`Dorm`, generated entity accessors, repositories, filters, and relation paths are generated or framework-level APIs. The concrete engine changes how those operations reach storage.

The `Data`/`Model`/`Dependency` split remains the same. `UserData` is input, `User` carries its identity, and `UserDependency` supplies the values required to construct it.

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

## Compare current capability boundaries

The common repository API does not imply identical runtime behavior in every engine:

| Capability | BLoC | Firebase | MySQL |
| --- | --- | --- | --- |
| External server required | No | Firebase project or emulator | Yes |
| Generated identity from `put` | UUID in memory | Firebase push key | UUID in SQL |
| Composite identity with `put` | `UnsupportedError` | Firebase IDs must be `String` | `UnsupportedError` from `put` |
| Single-record streams | State-backed | Firebase value events | Initial read only in current implementation |
| Filter/query execution | In-memory query implementation | Firebase Realtime Database query | SQL query |
| Transactions exposed by the public framework API | No documented transaction API | `patch` uses a Firebase transaction internally | Some batch and patch operations use MySQL transactions internally |

The matrix describes current implementation behavior. It is not a compatibility promise for a future release.

## Select the next setup step

For a local Dart process, start with BLoC. For Firebase Realtime Database, continue with the Flutter/Firebase initialization page. For a SQL-backed application, prepare the MySQL connection and schema before issuing repository operations.
