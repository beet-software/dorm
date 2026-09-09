# Choose an engine

The generated `Dorm` and repository API are shared across engines. The engine
is the runtime boundary that turns those operations into reads, writes,
filters, relationships, and streams for a specific storage system.

## Compare the setup boundary

| Engine | Storage or runtime | What the application supplies |
| --- | --- | --- |
| Memory | Pure Dart in-process memory | A reusable `Engine()` instance |
| BLoC | In-memory BLoC state | A reusable `Engine()` instance |
| Firebase | Firebase Realtime Database | Initialized Firebase services and database configuration |
| Firestore | Cloud Firestore | Initialized Firebase services and `FirebaseFirestore` |
| MySQL | MySQL through `mysql_client` | An opened `MySQLConnection` |
| PostgreSQL | PostgreSQL through `postgres` | An opened `Connection` or `Pool` |
| MongoDB | MongoDB through `mongo_dart` | An opened `Db` |
| HTTP/JSON | A REST-shaped service | An owned `http.Client`, base URI, and resource mapping |
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

## Select by runtime need

Use the [memory engine](use-memory.md) for a pure Dart application that
needs an in-process store without a database server. Use [BLoC](use-bloc.md)
when local state must use the BLoC integration. Use [Firebase](use-firebase.md)
for a Flutter/Firebase Realtime Database application. Use
[Cloud Firestore](use-firestore.md) for a Flutter application that stores
documents in Firestore and needs its queries, listeners, batches, or internal
transactions.

Use [MySQL](use-mysql.md) or [PostgreSQL](use-postgres.md) when the
database is relational and SQL is part of the application's storage boundary.
Use [MongoDB](use-mongo.md) for document storage. Use [HTTP/JSON](use-http.md)
when the application talks to a REST-shaped API rather than directly to a
database. Use [SQLite](use-sqlite.md) for local relational storage through the
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

| Capability | Memory | BLoC | Firebase | Firestore | MySQL | PostgreSQL | MongoDB | HTTP | SQLite |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| External server required | No | No | Firebase project or emulator | Firebase project or emulator | Yes | Yes | Yes | HTTP API | No |
| Streams | State-backed | State-backed | Firebase value events | Firestore snapshots | Initial read only | Initial read only | Initial read only | Initial read only | SQLite table watches |
| Filter execution | In memory | In memory | Firebase query | Firestore query | SQL query | PostgreSQL SQL query | MongoDB selector | URL parameters | SQLite SQL query |
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
