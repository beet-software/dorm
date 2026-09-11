# Public surface

This page identifies the supported import and extension boundaries of dORM. It
does not reproduce every public member; the generated API reference on pub.dev
is the appropriate source for complete signatures and member documentation.

## Supported package entry points

Application code should import these package barrels:

| Package | Supported entry point | Responsibility |
| --- | --- | --- |
| dorm_annotations | package:dorm_annotations/dorm_annotations.dart | Model and field annotations. |
| dorm_generator | package:dorm_generator/dorm_generator.dart | build_runner builder integration. |
| dorm_framework | package:dorm_framework/dorm_framework.dart | Engine-neutral contracts and generated runtime types. |
| dorm_memory_database | package:dorm_memory_database/dorm_memory_database.dart | Pure Dart in-memory storage. |
| dorm_bloc_database | package:dorm_bloc_database/dorm_bloc_database.dart | In-process BLoC-backed storage. |
| dorm_firebase_database | package:dorm_firebase_database/dorm_firebase_database.dart | Firebase Realtime Database engine. |
| dorm_firestore_database | package:dorm_firestore_database/dorm_firestore_database.dart | Cloud Firestore engine. |
| dorm_mysql_database | package:dorm_mysql_database/dorm_mysql_database.dart | MySQL engine. |
| dorm_postgres_database | package:dorm_postgres_database/dorm_postgres_database.dart | PostgreSQL engine. |
| dorm_mongo_database | package:dorm_mongo_database/dorm_mongo_database.dart | MongoDB engine. |
| dorm_http_database | package:dorm_http_database/dorm_http_database.dart | REST-shaped HTTP/JSON engine. |
| dorm_sqlite_database | package:dorm_sqlite_database/dorm_sqlite_database.dart | SQLite engine. |
| dorm_sync | package:dorm_sync/dorm_sync.dart | Optional primary-to-replica synchronization. |
| dorm_example | package:dorm_example/dorm_example.dart and the dorm_example executable | Showcase project generator. |

The generated application imports the annotations, framework, generator, and
selected engine packages in its own project. dorm_test is an internal
conformance package and is not an application dependency.

## Supported extension points

The supported extension boundaries are:

- implement BaseEngine<Q, P> for a custom storage adapter;
- implement BaseReference<Q, P>, BaseQuery<Q>, and BaseRelationship<Q> behind
  that engine;
- implement optional capabilities such as TransactionalEngine,
  ChangeTrackedEngine, or ErrorAwareEngine when the backend can satisfy their
  contracts;
- use RelationSource and relation plans to provide portable or optimized
  relationship reads;
- use generated EntitySchema and PrimaryKeyCodec metadata instead of
  re-declaring model storage names.

See [Framework contracts](framework-contracts.md) for the normative behavior
and [Implement a custom engine](../development/custom-engine.md) for the
implementation sequence.

## Internal paths are not public API

Classes under a package's lib/src/ directory are implementation details unless
the package barrel explicitly exports them. Importing an internal path may
compile today and still break without a public API migration.

The same rule applies to generated identifiers that are not documented as
supported names. Generated files are application outputs, not a stable
replacement for the package barrel.

## Stability expectations

Treat changes to the following as public API changes:

- exported barrel symbols;
- framework contracts and generic bounds;
- generated type names and generated accessors;
- identity and creation types;
- filter and relationship result shapes;
- optional capability interfaces;
- portable error categories and fields.

Use the package changelog and migration guide for changes requiring user
action. The repository is currently in an alpha/dev release line; no general
deprecation period or compatibility window is promised.

For complete member-level API documentation, use the package's pub.dev API
reference. For dORM-specific behavior and compatibility, use this repository's
[framework contracts](framework-contracts.md), [engine support](engine-support.md),
and [release status](release-status.md).