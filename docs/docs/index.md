# dORM: A portable ORM for Dart

dORM is a generated, portable ORM for Dart. It reduces repeated data-access
boilerplate while keeping the database, service, or client that your
application already uses.

## When data access starts repeating

Applications often repeat the same work around every feature:

- convert Firebase snapshots, database rows, or JSON into models;
- serialize models before writing them;
- build identity lookups and filters;
- load related records;
- keep create, read, update, and delete operations consistent;
- write a second version of the same code for tests or another backend.

The result is usually not one difficult query. It is a large amount of
plumbing repeated around ordinary operations.

For example, without a shared data-access layer, a Firebase read may include storage access,
existence checks, casts, and model construction in the application feature:

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

With an annotated model and the generated repository API, the feature can ask
for the same record through the dORM operation vocabulary:

```dart
final Product? product = await dorm.products.repository.peek(productId);
```

The Firebase engine still performs the Firebase work. dORM generates the
mapping, identity, and repository boundary so that this application code does
not need to repeat them in every feature.

This is dORM's main purpose: reduce repeated data-access boilerplate, not
replace the backend client or hide every backend detail.

## A different perspective on data access

The application keeps its configured client or connection and places dORM
around it:

```text
your database client, service client, or in-memory store
    -> selected dORM engine
    -> generated Dorm facade
    -> generated repositories
    -> application features
```

The same generated model and repository surface can be used with Memory,
PostgreSQL, MySQL, SQLite, MongoDB, Firebase, Firestore, or HTTP. The setup
and capabilities change with the engine, but ordinary operations do not need
to be rewritten just because the storage boundary changes.

Keep native SQL, Firebase calls, MongoDB operations, or HTTP calls beside dORM
when a backend-specific feature is a better fit. dORM is designed for gradual
adoption: start with one model or one repeated operation and expand from
there.

## The central trade-off

!!! warning
    dORM is more portable than a backend-specific ORM, but less expressive
    than the native API of each backend.

The common surface covers recurring application work such as:

- creating and reading models;
- updating and deleting records;
- filtering and sorting;
- offset pagination;
- generated relationships;
- selected streams and transactions, when the engine supports them.

CTEs, database-specific aggregations, migrations, indexes, security rules,
native selectors, and other backend features remain owned by the selected
database, service, or client. dORM does not turn different backends into one
identical database, and it does not silently emulate unsupported features by
downloading and filtering data locally.

## What the engine changes

| Data source | What the application gives the engine |
| --- | --- |
| In-memory data | A Memory or BLoC engine instance |
| Firebase Realtime Database | Configured Firebase services and database objects |
| Cloud Firestore | An initialized `FirebaseFirestore` |
| MySQL | An opened `MySQLConnection` |
| PostgreSQL | An opened `Connection` or `Pool` |
| MongoDB | An opened `mongo_dart` `Db` |
| REST-shaped API | An `http.Client`, base URI, and HTTP mapping |
| SQLite | An application-owned `sqlite_async` `SqliteDatabase` |

The engine adapts the common repository operations to that source. The
application still owns credentials, connection lifecycle, schema, migrations,
Firebase rules, HTTP authentication, and backend-specific configuration.

Read [Choose an engine](apply/choose-an-engine.md) before relying on a
capability that is not part of the common repository surface.

## What dORM provides

Generated repositories use a small set of operations for the work most
applications need:

| Operation | Use it to |
| --- | --- |
| `put` | Create a model from data and related identities. |
| `peek` | Read one model by its identity. |
| `peekAll` | Read a collection with filters and read options. |
| `peekPage` | Read an offset-based page. |
| `push` | Save a model that already has its identity. |
| `patch` | Read, change, and save or remove a model conditionally. |
| `pop` | Remove one model by its identity. |
| `pull` | Observe a model according to the selected engine's stream behavior. |

The operation names stay stable across engines. The selected engine decides
how those operations reach storage and which additional capabilities are
available.

## Start with a working project

Use [`dorm_example`](quickstart/generate-a-showcase.md) when you want a
complete project with models, generated code, and an engine-specific setup.
Use the Memory profile to learn the generated API without configuring a
server:

```shell
dart pub global activate dorm_example
dorm_example --engine memory
```

When the application already has a backend, choose the matching engine and
keep that backend's client or connection. The [Quickstart](quickstart/index.md)
builds the same store domain progressively, and [Operations](build-the-store/overview.md)
shows the repository tasks independently.

## Important boundaries

dORM does not provide a universal migration language. Schema creation,
migrations, indexes, credentials, authorization, and security rules remain
backend-specific.

The public transaction callback is available only for engines that implement
the transactional capability. Streams, advanced filters, identity generation,
and relationship execution also vary by engine. See the
[engine capability reference](reference/engine-capabilities.md) before making
backend-specific behavior part of an application contract.

## Continue from here

- [Generate a showcase project](quickstart/generate-a-showcase.md) for a
  complete starting point.
- [Choose an engine](apply/choose-an-engine.md) based on the backend and
  capabilities your application needs.
- [Build a small store](quickstart/index.md) from an empty Dart project.
- [Learn the annotations](annotations/index.md) when you are ready to define
  models.
- [Inspect model anatomy](model-anatomy/index.md) to understand generated
  types.
- [Read the public API](reference/public-api.md) for signatures and return
  values.
