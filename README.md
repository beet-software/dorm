# dORM: A portable ORM for Dart

<p>
  <a href="https://ezgrs.github.io/dorm/"><img src="https://img.shields.io/badge/documentation-readthedocs-4c8bf5?style=flat" alt="dORM documentation"></a>
  <a href="https://github.com/ezgrs/dorm"><img src="https://img.shields.io/github/stars/ezgrs/dorm?style=flat" alt="GitHub stars"></a>
  <a href="https://github.com/ezgrs/dorm"><img src="https://img.shields.io/github/license/ezgrs/dorm?style=flat" alt="License"></a>
  <a href="https://github.com/ezgrs/dorm/actions/workflows/dart.yml"><img src="https://github.com/ezgrs/dorm/actions/workflows/dart.yml/badge.svg" alt="Dart CI"></a>
</p>

<p>
  <a href="https://pub.dev/packages/dorm_framework"><img src="https://img.shields.io/pub/v/dorm_framework.svg?label=dorm_framework" alt="dorm_framework on pub.dev"></a>
  <a href="https://pub.dev/packages/dorm_annotations"><img src="https://img.shields.io/pub/v/dorm_annotations.svg?label=dorm_annotations" alt="dorm_annotations on pub.dev"></a>
  <a href="https://pub.dev/packages/dorm_generator"><img src="https://img.shields.io/pub/v/dorm_generator.svg?label=dorm_generator" alt="dorm_generator on pub.dev"></a>
  <a href="https://pub.dev/packages/dorm_example"><img src="https://img.shields.io/pub/v/dorm_example.svg?label=dorm_example" alt="dorm_example on pub.dev"></a>
  <a href="https://pub.dev/packages/dorm_sync"><img src="https://img.shields.io/pub/v/dorm_sync.svg?label=dorm_sync" alt="dorm_sync on pub.dev"></a>
</p>

<p>
  <a href="https://pub.dev/packages/dorm_memory_database"><img src="https://img.shields.io/pub/v/dorm_memory_database.svg?label=dorm_memory_database" alt="dorm_memory_database on pub.dev"></a>
  <a href="https://pub.dev/packages/dorm_bloc_database"><img src="https://img.shields.io/pub/v/dorm_bloc_database.svg?label=dorm_bloc_database" alt="dorm_bloc_database on pub.dev"></a>
  <a href="https://pub.dev/packages/dorm_firebase_database"><img src="https://img.shields.io/pub/v/dorm_firebase_database.svg?label=dorm_firebase_database" alt="dorm_firebase_database on pub.dev"></a>
  <a href="https://pub.dev/packages/dorm_firestore_database"><img src="https://img.shields.io/pub/v/dorm_firestore_database.svg?label=dorm_firestore_database" alt="dorm_firestore_database on pub.dev"></a>
  <a href="https://pub.dev/packages/dorm_http_database"><img src="https://img.shields.io/pub/v/dorm_http_database.svg?label=dorm_http_database" alt="dorm_http_database on pub.dev"></a>
  <a href="https://pub.dev/packages/dorm_mongo_database"><img src="https://img.shields.io/pub/v/dorm_mongo_database.svg?label=dorm_mongo_database" alt="dorm_mongo_database on pub.dev"></a>
  <a href="https://pub.dev/packages/dorm_mysql_database"><img src="https://img.shields.io/pub/v/dorm_mysql_database.svg?label=dorm_mysql_database" alt="dorm_mysql_database on pub.dev"></a>
  <a href="https://pub.dev/packages/dorm_postgres_database"><img src="https://img.shields.io/pub/v/dorm_postgres_database.svg?label=dorm_postgres_database" alt="dorm_postgres_database on pub.dev"></a>
  <a href="https://pub.dev/packages/dorm_sqlite_database"><img src="https://img.shields.io/pub/v/dorm_sqlite_database.svg?label=dorm_sqlite_database" alt="dorm_sqlite_database on pub.dev"></a>
</p>

dORM is a generated, portable ORM for Dart. It reduces the repeated code
around model conversion, identity handling, filters, relationships, and CRUD
operations without hiding the backend that your application already uses.

When an application talks directly to Firebase, a database driver, or an HTTP
API, the same plumbing is often repeated in every feature: read raw data,
construct a model, serialize writes, build filters, resolve related records,
and keep the operations consistent. dORM generates that application-facing
surface once and lets the selected engine adapt it to the backend.

The result is a different perspective on data access: keep your existing
client or connection, add dORM around it, and adopt generated repositories one
model or one operation at a time.

## See the boilerplate disappear

This is the kind of code an application may otherwise repeat around a Firebase
read:

```dart
final snapshot = await FirebaseDatabase.instance
    .ref('products/$productId')
    .get();

if (!snapshot.exists) return null;

final raw = Map<String, Object?>.from(snapshot.value as Map);
return Product(
  id: productId,
  name: raw['name']! as String,
  price: (raw['price']! as num).toDouble(),
);
```

With an annotated model and generated API, the application code becomes an
operation on the repository:

```dart
final Product? product = await dorm.products.repository.peek(productId);
```

The engine still uses Firebase. The generated code handles the mapping,
identity, and repository boundary so that the same application operation can
also be backed by an in-memory engine, PostgreSQL, MongoDB, Firestore, HTTP,
or SQLite.

This does not require replacing the Firebase client. Native Firebase calls can
remain beside dORM whenever a Firebase-specific feature is the right choice.

## Start with a working project

Use the example generator when you want a complete starting point:

~~~shell
dart pub global activate dorm_example
dorm_example --engine memory
~~~

For a database-backed Dart project, choose an engine and an output directory:

~~~shell
dorm_example --engine postgres --output store_example
cd store_example
docker compose up -d
dart pub get
dart run build_runner build
dart analyze
dart run
~~~

The generated project contains the annotated models and the commands needed
to generate the .dorm.dart and .g.dart files. The CLI does not install
dependencies, start Docker, or overwrite a non-empty directory.

## How the pieces fit

The public packages have separate responsibilities:

- [dorm_annotations](https://pub.dev/packages/dorm_annotations) describes
  models, fields, identities, and relationships.
- [dorm_generator](https://pub.dev/packages/dorm_generator) turns those
  declarations into the model and repository API used by the application.
- [dorm_framework](https://pub.dev/packages/dorm_framework) defines the
  common types for creation, reading, filtering, relationships, pagination,
  synchronization contracts, and transactions.
- [dorm_sync](https://pub.dev/packages/dorm_sync) composes a primary with
  replicas with finite-read fallback and at-least-once write delivery.
- A dorm_*_database package adapts those contracts to a backend.

The application creates the backend object and passes it to the engine:

~~~dart
final Engine engine = Engine(databaseOrClient);
final dorm = Dorm(engine);

final User user = await dorm.users.repository.peek(userId);
~~~

For a unidirectional primary-to-replica setup, wrap adapted change-tracking
targets in `SynchronizedEngine` from `dorm_sync`. Reads remain on the primary
unless a finite-read fallback policy classifies its error as available for a
replica; streams and distributed transactions are intentionally not switched. See [Synchronize database engines](docs/docs/reference/synchronization.md) for the delivery, outbox, fallback, and identity rules.

The generated `Dorm` facade and model declarations can stay the same while an
application evaluates another engine. This is the main portability boundary:
common repository operations remain stable, while backend-specific setup and
capabilities remain explicit.

Application code calls the generated repositories through `Dorm`. The selected
engine adapts those calls to the client, connection, service, or in-process
store supplied by the application.

## The central trade-off

> dORM is more portable than a backend-specific ORM, but less expressive than the native API of each backend.

CRUD, common filters, relationships, sorting, pagination, and selected
transaction operations can use a shared API. CTEs, database-specific
aggregations, migrations, indexes, security rules, native selectors, and
other backend features remain the responsibility of the database, service, or
native client.

This boundary is intentional: dORM does not turn different backends into one
identical database. It gives recurring application operations a common home
while allowing native code to remain available when the backend needs more
expressiveness.

## Choose an engine

| Engine | Backend object | Runtime | Notable behavior |
| --- | --- | --- | --- |
| [In-memory](https://pub.dev/packages/dorm_memory_database) | None | Dart | In-process state, UUID identities, reactive streams, transactions |
| [BLoC](https://pub.dev/packages/dorm_bloc_database) | None | Dart/Flutter | BLoC-backed in-memory state and reactive streams |
| [Firebase](https://pub.dev/packages/dorm_firebase_database) | FirebaseInstance | Flutter | Realtime Database queries, push keys, live streams |
| [Firestore](https://pub.dev/packages/dorm_firestore_database) | FirebaseFirestore | Flutter | Document IDs, snapshots, batches, internal patch transactions |
| [HTTP](https://pub.dev/packages/dorm_http_database) | http.Client and HttpMapping | Dart/Flutter | Configurable REST/JSON endpoints |
| [MongoDB](https://pub.dev/packages/dorm_mongo_database) | mongo_dart.Db | Dart | BSON documents, replacement upserts, initial-read streams |
| [MySQL](https://pub.dev/packages/dorm_mysql_database) | MySQLConnection | Dart | Parameterized SQL, schema command, database-generated numeric IDs |
| [PostgreSQL](https://pub.dev/packages/dorm_postgres_database) | SessionExecutor | Dart | Parameterized SQL, Connection/Pool, upserts |
| [SQLite](https://pub.dev/packages/dorm_sqlite_database) | SqliteDatabase | Dart/Flutter | Local SQL storage, transactions, reactive table watches |

The [engine capability reference](https://ezgrs.github.io/dorm/reference/engine-capabilities/)
lists the current differences. Start in-memory when the goal is to learn the
generated API without configuring a server. Choose a backend engine when
the application already uses that backend or needs its storage semantics.

## What dORM manages

dORM manages the mapping between annotated Dart models, generated entities,
repositories, and backend operations. It gives the application a consistent
vocabulary for creating, reading, updating, deleting, filtering, sorting,
paginating, and traversing relationships.

The selected engine still owns backend-specific concerns. The application
configures the connection, Firebase SDK, HTTP client, schema, migrations,
credentials, and security rules according to the backend. dORM does not
provide a universal migration language or replace the native client.

## Learn more

- [dORM documentation](https://ezgrs.github.io/dorm/)
- [Quickstart](https://ezgrs.github.io/dorm/quickstart/)
- [Choose an engine](https://ezgrs.github.io/dorm/apply/choose-an-engine/)
- [Annotations](https://ezgrs.github.io/dorm/annotations/)
- [Framework contracts](https://ezgrs.github.io/dorm/reference/framework-contracts/)
- [Implement a custom engine](https://ezgrs.github.io/dorm/development/custom-engine/)
- [GitHub repository](https://github.com/ezgrs/dorm)
