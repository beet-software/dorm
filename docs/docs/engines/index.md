# Choose an engine

dORM is a portable ORM: it gives recurring application operations a shared,
generated surface while allowing the storage system to remain explicit. Choose
an engine when you want that common surface around a backend your application
already uses, or when you want to start with a local engine and move to a
server-backed one later.

The trade-off is deliberate. dORM is more portable than a backend-specific
ORM, but less expressive than the native API of each backend. The generated
`Dorm` and repository API are shared across engines; the engine turns those
operations into reads, writes, filters, relationships, and streams for a
specific storage system.

## Compare the setup boundary

| `Engine` | Storage or runtime | What the application supplies |
| --- | --- | --- |
| In-memory | Pure Dart in-process memory | A reusable `Engine()` instance |
| BLoC | In-memory BLoC state | A reusable `Engine()` instance |
| Firebase | Firebase Realtime Database | Initialized Firebase services and database configuration; the showcase generator also provides a local emulator profile |
| Firestore | Cloud Firestore | Initialized Firebase services and `FirebaseFirestore`; the showcase generator also provides a local emulator profile |
| MySQL | MySQL through `mysql_client` | An opened `MySQLConnection` |
| PostgreSQL | PostgreSQL through `postgres` | An opened `Connection` or `Pool` |
| MongoDB | MongoDB through `mongo_dart` | An opened `Db` |
| HTTP/JSON | A REST-shaped service | An owned `http.Client`, base URI, and resource mapping; the showcase generator can provide a local demo server |
| SQLite | SQLite through `sqlite_async` | An application-owned `SqliteDatabase` |

The application owns the lifecycle of the backend object when the engine
accepts one. The engine does not automatically open or close an application-
owned database connection, `Db`, or HTTP client.

!!! warning
    The repository API is portable, but it does not expose every feature of
    every backend. Check the engine page before relying on transactions,
    reactive streams, schema generation, or backend-specific query features.

The framework does not select an engine automatically. The generated `Dorm`
receives the concrete engine through its constructor.

## Choose by backend and capability

Choose the engine that matches the backend boundary and the capabilities your
application needs. Do not choose an engine expecting it to reproduce every
feature of another backend. Check the capability table before relying on
transactions, reactive streams, advanced filters, generated identities, or
schema behavior.

Use the common repository API for recurring operations. Keep native SQL,
Firebase calls, MongoDB selectors, or HTTP-specific behavior beside dORM when
the backend needs more expressiveness than the portable surface provides.

To create a complete project with the selected setup, use the
[showcase project generator](../quickstart/generate-a-showcase.md). Its
profiles follow the platform and capability boundaries listed on this page:
Flutter profiles are generated for in-memory, BLoC, Firebase, Firestore, and
HTTP; pure Dart profiles are generated for PostgreSQL, MySQL, MongoDB, and
SQLite.

## Select by runtime need

Use the [in-memory engine](memory.md) for a pure Dart application that
needs an in-process store without a database server. Use [BLoC](bloc.md)
when local state must use the BLoC integration. Use [Firebase](firebase.md)
for a Flutter/Firebase Realtime Database application. Use
[Cloud Firestore](firestore.md) for a Flutter application that stores
documents in Firestore and needs its queries, listeners, batches, or internal
transactions.

Use [MySQL](mysql.md) or [PostgreSQL](postgres.md) when the
database is relational and SQL is part of the application's storage boundary.
Use [MongoDB](mongo.md) for document storage. Use [HTTP/JSON](http.md)
when the application talks to a REST-shaped API rather than directly to a
database. Use [SQLite](sqlite.md) for local relational storage through the
asynchronous `sqlite_async` API.

## Keep the application surface stable

The generated facade receives the engine and exposes the same entity accessors:

```dart
final Dorm<Query, OffsetPageRequest> dorm = Dorm(engine);

final User created = await dorm.users.repository.put(
  Creation.auto(
    dependency: const UserDependency(),
    data: userData,
  ),
);

final List<Product> products = await dorm.products.repository.peekAll(
  Filter.value('Notebook', field: ProductEntity.fields.name),
);
```

The concrete engine changes how these operations reach storage. The generated
`Data`, `Model`, `Dependency`, entity, filter, and relationship types keep the
same application role.

## Compare the current capability boundaries

| Capability | In-memory | BLoC | Firebase | Firestore | MySQL | PostgreSQL | MongoDB | HTTP | SQLite |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| External server required | No | No | Firebase project or emulator | Firebase project or emulator | Yes | Yes | Yes | HTTP API | No |
| Streams | State-backed | State-backed | Firebase value events | Firestore snapshots | Initial read only | Initial read only | Initial read only | Initial read only | SQLite table watches |
| `Filter` execution | In-memory evaluation | In-memory evaluation | Firebase query | Firestore query | SQL query | PostgreSQL SQL query | MongoDB selector | URL parameters | SQLite SQL query |
| Comparisons and set membership | Yes | Yes | Basic filters only | Where supported by Firestore | Yes | Yes | Yes | Not declared | Yes |
| `allOf` / `anyOf` | Yes | Yes | No | Where supported by Firestore | Yes | Yes | Yes | Not declared | Yes |
| `not` | Yes | Yes | No | No general support | Yes | Yes | Yes | Not declared | Yes |
| Collection membership | Yes | Yes | No | Where supported by Firestore | No | No | Yes | Not declared | No |
| Public transaction API | Yes | Yes | No | No | Yes | Yes | No | No | Yes |
| Pagination | Offset pages | Offset pages | Offset pages with client-side skipping | Offset pages with client-side skipping | Offset pages | Offset pages | Offset pages | Offset pages | Offset pages |
| Composite creation | Explicit identity required | Explicit identity required | Unsupported | Unsupported | Explicit identity required | Explicit identity required | Explicit identity required | Explicit identity required | Explicit identity required |

This table describes current engine behavior. It does not promise that future
versions will preserve every backend capability or limitation.

The additional filter rows describe typed query capabilities, not client-side
fallbacks. A `No` entry means the engine does not advertise that capability;
the repository will not download a larger result set to imitate it.

## Continue with the engine page

After choosing a backend, follow its setup page. The pages include the package
commands, lifecycle boundary, schema or mapping requirements, and behavior that
differs from the common repository API.
