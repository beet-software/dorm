# Engine and platform support

This page is the canonical comparison of the official engines. It records
current behavior verified by the packages and tests; it is not a promise about
unlisted server versions, provider configurations, or future implementations.

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
| Relationship execution | Portable | Portable | Readable operations | Readable operations | Plans plus readable fallback | Plans plus readable fallback | Plans plus readable fallback | Readable operations | Readable operations |
| Portable provider errors | No capability | No capability | Firebase mapper | Firebase mapper | MySQL mapper | PostgreSQL mapper | MongoDB mapper | HTTP mapper | SQLite mapper |

## `Engine` notes

### Memory and BLoC

Both engines keep state in the `Engine` instance and require no external
service. Their reads and relationships are evaluated in process. Memory uses
Dart maps and streams; BLoC exposes state-backed streams through its BLoC
dependencies.

See [Run in-memory](../engines/memory.md) and [Run with BLoC](../engines/bloc.md).

### Firebase Realtime Database

Reference identities are String values. Firebase initialization, authentication,
and offline mode belong to the Flutter application. Value events are provided
by Realtime Database.

The current `popAll` path is not a common all-or-nothing transaction guarantee.
See [Run with Firebase](../engines/firebase.md).

### Cloud Firestore

Document IDs are simple String identities. Firestore snapshots and internal
batches/transactions are available to the implementation, but there is no
public `TransactionalDorm` capability. Composite identities, migrations,
aggregation, and general cursor pagination are not part of the current dORM
surface.

See [Run with Cloud Firestore](../engines/firestore.md).

### MySQL and PostgreSQL

Both SQL engines translate structured metadata and filters to parameterized
SQL and require application-created tables. MySQL and PostgreSQL expose the
portable transaction facade.

Their direct relationship sources can use plans that group work, while custom
or composite sources may use readable operations. Their current `pull` and
`pullAll` implementations perform an initial read rather than subscribing to
later database changes.

See [Run with MySQL](../engines/mysql.md) and
[Run with PostgreSQL](../engines/postgres.md).

### MongoDB

MongoDB stores identities in schema-declared fields and does not replace them
with MongoDB ObjectId or the _id field. Identified writes use replacement
upserts. The current engine does not expose public transactions, change
streams, aggregation, migrations, or native selector APIs.

See [Run with MongoDB](../engines/mongo.md).

### HTTP

The application supplies an HTTP client, base URI, and resource mappings.
Mappings define routes, JSON envelopes, batch operations, and query
parameters. Missing configured batch endpoints are unsupported rather than
silently emulated.

HTTP exposes initial-read streams, readable-operation relationships, and
portable HTTP errors. It does not expose transactions, cursor pagination,
polling, or server-event streams.

See [Run with HTTP/JSON](../engines/http.md).

### SQLite

SQLite uses an application-owned `SqliteDatabase` and supports SQL filters,
offset pages, composite identities, table-watch streams, and the portable
transaction facade. The application prepares the database schema and owns its
lifecycle.

The SQLite dependency uses `dart:ffi` in its current implementation. It is not
Wasm-compatible through the default path, even when the package can be used on
other supported platforms.

See [Run with SQLite](../engines/sqlite.md).

## Synchronization composition

`dorm_sync` is a composition layer, not another storage backend. A primary must
provide `ChangeTrackedEngine` through `EngineSyncTarget`. A replica may use a normal
`BaseEngine` through `EngineReplicaTarget`.

The composed engine uses the primary query and page types publicly. Structured
filters and page requests are adapted to each target. Synchronization is
one-way, at-least-once, and eventually consistent; it does not add automatic
identity conversion or distributed transactions.

See [Synchronization protocol](synchronization.md).
