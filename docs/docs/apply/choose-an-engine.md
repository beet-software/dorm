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
| MySQL | MySQL through `mysql_client` | An opened `MySQLConnection` |
| PostgreSQL | PostgreSQL through `postgres` | An opened `Connection` or `Pool` |
| MongoDB | MongoDB through `mongo_dart` | An opened `Db` |
| HTTP/JSON | A REST-shaped service | An owned `http.Client`, base URI, and resource mapping |

The application owns the lifecycle of the backend object when the engine
accepts one. The engine does not automatically open or close an application-
owned database connection, `Db`, or HTTP client.

!!! warning "Engine capability is not identical to backend capability"
    The repository API is portable, but it does not expose every feature of
    every backend. Check the engine page before relying on transactions,
    reactive streams, schema generation, or backend-specific query features.

The framework does not select an engine automatically. The generated `Dorm`
receives the concrete engine through its constructor.

## Select by runtime need

Use the [memory engine](use-memory.md) for a pure Dart application that
needs an in-process store without a database server. Use [BLoC](use-bloc.md)
when local state must use the BLoC integration. Use [Firebase](use-firebase.md)
for a Flutter/Firebase application.

Use [MySQL](use-mysql.md) or [PostgreSQL](use-postgres.md) when the
database is relational and SQL is part of the application's storage boundary.
Use [MongoDB](use-mongo.md) for document storage. Use [HTTP/JSON](use-http.md)
when the application talks to a REST-shaped API rather than directly to a
database.

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
  Filter.value('Notebook', key: 'name'),
);
```

The concrete engine changes how these operations reach storage. The generated
`Data`, `Model`, `Dependency`, entity, filter, and relationship types keep the
same application role.

## Compare the current capability boundaries

| Capability | Memory | BLoC | Firebase | MySQL | PostgreSQL | MongoDB | HTTP |
| --- | --- | --- | --- | --- | --- | --- | --- |
| External server required | No | No | Firebase project or emulator | Yes | Yes | Yes | HTTP API |
| Streams | State-backed | State-backed | Firebase value events | Initial read only | Initial read only | Initial read only | Initial read only |
| Filter execution | In memory | In memory | Firebase query | SQL query | PostgreSQL SQL query | MongoDB selector | URL parameters |
| Public transaction API | No | No | No | No | No | No | No |
| Pagination | Offset pages | Offset pages | Offset pages with client-side skipping | Offset pages | Offset pages | Offset pages | Offset pages |
| Composite creation | Explicit identity | Explicit identity | Unsupported | Explicit identity | Explicit identity | Explicit identity | Explicit identity |

This table describes current engine behavior. It does not promise that future
versions will preserve every backend capability or limitation.

## Continue with the engine page

After choosing a backend, follow its setup page. The pages include the package
commands, lifecycle boundary, schema or mapping requirements, and behavior that
differs from the common repository API.
