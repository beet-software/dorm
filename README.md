# dORM

<p>
  <a href="https://github.com/beet-software/dorm"><img src="https://img.shields.io/github/stars/beet-software/dorm?style=flat" alt="GitHub stars"></a>
  <a href="https://github.com/beet-software/dorm"><img src="https://img.shields.io/github/license/beet-software/dorm?style=flat" alt="License"></a>
  <a href="https://ezgrs.github.io/dorm/"><img src="https://img.shields.io/badge/documentation-dORM-4c8bf5?style=flat" alt="dORM documentation"></a>
  <a href="https://github.com/beet-software/dorm/actions/workflows/dart.yml"><img src="https://github.com/beet-software/dorm/actions/workflows/dart.yml/badge.svg" alt="Dart CI"></a>
</p>

<p>
  <a href="https://pub.dev/packages/dorm_framework"><img src="https://img.shields.io/pub/v/dorm_framework.svg?label=dorm_framework" alt="dorm_framework on pub.dev"></a>
  <a href="https://pub.dev/packages/dorm_annotations"><img src="https://img.shields.io/pub/v/dorm_annotations.svg?label=dorm_annotations" alt="dorm_annotations on pub.dev"></a>
  <a href="https://pub.dev/packages/dorm_generator"><img src="https://img.shields.io/pub/v/dorm_generator.svg?label=dorm_generator" alt="dorm_generator on pub.dev"></a>
  <a href="https://pub.dev/packages/dorm_example"><img src="https://img.shields.io/pub/v/dorm_example.svg?label=dorm_example" alt="dorm_example on pub.dev"></a>
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

dORM is a code-generated data-access layer for Dart. It keeps model
declarations and repository operations consistent while allowing the storage
backend to change underneath them.

It is useful when an application already has a database connection, Firebase
instance, HTTP client, or in-memory store and needs a consistent way to work
with models. dORM receives that object through the selected engine; it does not
require the application to replace its connection layer or adopt a second
database client.

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
  and transactions.
- A dorm_*_database package adapts those contracts to a backend.

The application creates the backend object and passes it to the engine:

~~~dart
final Engine engine = Engine(databaseOrClient);
final dorm = Dorm(engine);

final User user = await dorm.users.repository.peek(userId);
~~~

The generated Dorm facade and model declarations can stay the same while an
application evaluates another engine. Backend-specific capabilities still
matter: streams, transactions, identity generation, query operators, and
schema management are not identical across every backend.

## Choose an engine

| Engine | Backend object | Runtime | Notable behavior |
| --- | --- | --- | --- |
| [Memory](https://pub.dev/packages/dorm_memory_database) | None | Dart | In-process state, UUID identities, reactive streams, transactions |
| [BLoC](https://pub.dev/packages/dorm_bloc_database) | None | Dart/Flutter | BLoC-backed in-memory state and reactive streams |
| [Firebase](https://pub.dev/packages/dorm_firebase_database) | FirebaseInstance | Flutter | Realtime Database queries, push keys, live streams |
| [Firestore](https://pub.dev/packages/dorm_firestore_database) | FirebaseFirestore | Flutter | Document IDs, snapshots, batches, internal patch transactions |
| [HTTP](https://pub.dev/packages/dorm_http_database) | http.Client and HttpMapping | Dart/Flutter | Configurable REST/JSON endpoints |
| [MongoDB](https://pub.dev/packages/dorm_mongo_database) | mongo_dart.Db | Dart | BSON documents, replacement upserts, initial-read streams |
| [MySQL](https://pub.dev/packages/dorm_mysql_database) | MySQLConnection | Dart | Parameterized SQL, schema command, database-generated numeric IDs |
| [PostgreSQL](https://pub.dev/packages/dorm_postgres_database) | SessionExecutor | Dart | Parameterized SQL, Connection/Pool, upserts |
| [SQLite](https://pub.dev/packages/dorm_sqlite_database) | SqliteDatabase | Dart/Flutter | Local SQL storage, transactions, reactive table watches |

The [engine capability reference](https://ezgrs.github.io/dorm/reference/engine-capabilities/)
lists the current differences. Start with Memory when the goal is to learn
the generated API without configuring a server. Choose a backend engine when
the application already uses that backend or needs its storage semantics.

## What dORM manages

dORM manages the mapping between annotated Dart models, generated entities,
repositories, and backend operations. It gives the application a consistent
vocabulary for creating, reading, updating, deleting, filtering, sorting,
paginating, and traversing relationships.

The selected engine still owns backend-specific concerns. The application
configures the connection, Firebase SDK, HTTP client, schema, migrations,
credentials, and security rules according to the backend. dORM does not turn
different databases into one identical database, and it does not provide a
universal migration language.

## Learn more

- [dORM documentation](https://ezgrs.github.io/dorm/)
- [Quickstart](https://ezgrs.github.io/dorm/quickstart/)
- [Choose an engine](https://ezgrs.github.io/dorm/apply/choose-an-engine/)
- [Annotations](https://ezgrs.github.io/dorm/annotations/)
- [Framework contracts](https://ezgrs.github.io/dorm/reference/framework-contracts/)
- [Implement a custom engine](https://ezgrs.github.io/dorm/development/custom-engine/)
- [GitHub repository](https://github.com/beet-software/dorm)
