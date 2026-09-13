# Engine and platform support

This page is the canonical comparison of the official engines. It records
behavior verified by the packages and tests; it is not a promise about
unlisted provider versions, server configurations, permissions, or future
implementations.

## Capability matrix

| Capability | Memory | BLoC | Firebase | Firestore | MySQL | PostgreSQL | MongoDB | HTTP | SQLite |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Storage | Dart maps | In-process state | Realtime Database | Cloud Firestore | MySQL | PostgreSQL | MongoDB | REST/JSON API | SQLite |
| Runtime | Dart | Dart/Flutter | Flutter/Firebase | Flutter/Firebase | Dart | Dart | Dart with dart:io-compatible runtime | Dart | Dart/Flutter |
| Automatic identity | UUID String | UUID String | Firebase String key | String document ID | UUID String | UUID String | UUID String | UUID String or API response | UUID String |
| Composite identities | Explicit creation | Explicit creation | Unsupported | Unsupported | Explicit creation | Explicit creation | Explicit creation | Explicit creation | Explicit creation |
| Database-generated identity | No | No | No | No | Numeric single-key models | Numeric single-key models | No | Configured response mapping | Numeric single-key models |
| Filters | In-memory | In-memory | Basic backend filters | Firestore-supported filters | SQL | SQL | MongoDB selectors | Configured query mapping | SQL |
| Pagination | Offset | Offset | Offset with client-side skipping | Offset with client-side skipping | Offset | Offset | Offset | Offset | Offset |
| Streams | State-backed | State-backed | Realtime value events | Document/query snapshots | Initial read | Initial read | Initial read | Initial read | Table watches |
| Public transactions | Yes | Yes | No | No | Yes | Yes | No | No | Yes |
| Persistent migrations | No | No | Document adapter | Document adapter | SQL adapter | SQL adapter | No | No | SQL adapter |
| Migration paging/checkpoints | No | No | Stable pages | Stable pages | Set-based SQL | Set-based SQL | Not applicable | Not applicable | Set-based SQL |
| Migration schema inspection | No | No | No | No | Tables and fields | Tables and fields | No | No | Tables and fields |
| Migration transaction | Not applicable | Not applicable | None | None | Operation | Migration | Not applicable | Not applicable | Migration |
| Migration lock | Not applicable | Not applicable | Persistent lease | Persistent lease | Backend advisory lock | Backend advisory lock | Not applicable | Not applicable | Local lock |
| Migration history compaction | Not applicable | Not applicable | Adapter support | Adapter support | Adapter support | Adapter support | Not applicable | Not applicable | Adapter support |
| Migration indexes | Not applicable | Not applicable | Unsupported | Unsupported | Explicit | Explicit | Not applicable | Not applicable | Explicit |
| Unique constraints | Not applicable | Not applicable | Unsupported | Unsupported | Explicit | Explicit | Not applicable | Not applicable | Unsupported |
| Foreign keys | Not applicable | Not applicable | Unsupported | Unsupported | Explicit | Explicit | Not applicable | Not applicable | Unsupported |
| Check constraints | Not applicable | Not applicable | Unsupported | Unsupported | Explicit | Explicit | Not applicable | Not applicable | Unsupported |
| Views | Not applicable | Not applicable | Unsupported | Unsupported | Explicit | Explicit | Not applicable | Not applicable | Explicit |
| Triggers | Not applicable | Not applicable | Unsupported | Unsupported | Explicit | Explicit | Not applicable | Not applicable | Explicit |
| Sequences | Not applicable | Not applicable | Unsupported | Unsupported | Unsupported | Explicit | Not applicable | Not applicable | Unsupported |
| Provider-specific schema | Not applicable | Not applicable | Unsupported | Unsupported | Explicit SQL | Explicit SQL | Not applicable | Not applicable | Explicit SQL |
| Relationship execution | Portable | Portable | Readable operations | Readable operations | Plans plus readable fallback | Plans plus readable fallback | Plans plus readable fallback | Readable operations | Readable operations |
| Portable provider errors | No capability | No capability | Firebase mapper | Firebase mapper | MySQL mapper | PostgreSQL mapper | MongoDB mapper | HTTP mapper | SQLite mapper |

The migration rows describe the optional adapter, not the regular repository
engine. A backend marked `Unsupported` rejects that operation through the
portable migration contract. See [Migration protocol](migrations.md) for the
operation and failure rules.

## Engine notes

### Memory and BLoC

Both engines keep state in the `Engine` instance and require no external
service. Their reads and relationships are evaluated in process. They do not
have persistent schema migration history. Use them to exercise application
behavior without a database deployment.

See [Run in-memory](../engines/memory.md) and [Run with BLoC](../engines/bloc.md).

### Firebase Realtime Database

Reference identities are String values. Firebase initialization,
authentication, offline mode, and rules belong to the Flutter application.

The `FirebaseDatabaseMigrationAdapter` treats structural field declarations as
no-ops and scans records for data changes. It uses stable paging, checkpoints,
and a persistent lease in a reserved path. It does not provide one transaction
for an entire migration; data operations must be safe to retry.

See [Run with Firebase](../engines/firebase.md).

### Cloud Firestore

Document IDs are simple String identities. Firestore snapshots and internal
batches are available to the implementation, but there is no public
`TransactionalDorm` capability.

The `FirestoreMigrationAdapter` treats structural field declarations as no-ops
and changes existing documents in pages. It uses checkpoints and a persistent
lease in a reserved document. Large operations are not one global transaction.

See [Run with Cloud Firestore](../engines/firestore.md).

### MySQL and PostgreSQL

Both SQL engines translate structured metadata and filters to parameterized
SQL and require application-created tables. Their migration adapters use SQL
DDL/DML and keep history in a reserved table.

`MySqlMigrationAdapter` uses a backend advisory lock and isolates each migration
operation because DDL may implicitly commit. `PostgresMigrationAdapter` uses a
backend advisory lock and groups a migration with its history record in one
transaction when the provider honors it.

Both adapters inspect SQL tables and fields through `MigrationSchemaInspector`.
Indexes, constraints, views, triggers, sequences, and provider-specific
statements remain explicit operations with provider-specific support.

See [Run with MySQL](../engines/mysql.md) and
[Run with PostgreSQL](../engines/postgres.md).

### MongoDB

MongoDB stores identities in schema-declared fields and does not replace them
with MongoDB ObjectId or the `_id` field. The current engine does not expose
persistent migrations, public transactions, or a migration adapter.

Create collections and indexes with MongoDB tools or application code when
needed.

See [Run with MongoDB](../engines/mongo.md).

### HTTP

The application supplies an HTTP client, base URI, and resource mappings.
HTTP does not provide persistent migration history. Schema changes and
deployment state remain server concerns.

See [Run with HTTP/JSON](../engines/http.md).

### SQLite

SQLite uses an application-owned `SqliteDatabase` and supports SQL filters,
offset pages, composite identities, table-watch streams, and the portable
transaction facade.

`SqliteMigrationAdapter` groups each migration with its history record in the
database transaction when the provider honors it. It can inspect tables and
fields, but provider-specific constraints and unsupported alterations remain
explicit. The SQLite dependency uses `dart:ffi` in its default path and is not
Wasm-compatible through that path.

See [Run with SQLite](../engines/sqlite.md).

## Synchronization composition

`dorm_sync` is a composition layer, not another storage backend. A primary must
provide `ChangeTrackedEngine` through `EngineSyncTarget`; a replica may use a
normal `BaseEngine` through `EngineReplicaTarget`.

The composed engine uses the primary query and page types publicly. Structured
filters and page requests are adapted to each target. Synchronization is
one-way, at-least-once, and eventually consistent; it does not add automatic
identity conversion or distributed transactions.

See [Synchronization protocol](synchronization.md).
