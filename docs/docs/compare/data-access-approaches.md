# When to use dORM?

Choosing a data-access library is a trade-off between control, convenience,
and portability. The right choice depends on whether your application needs
the full vocabulary of one backend or a shared way to perform recurring work
across different storage systems.

## Start with the access pattern

Most applications combine three kinds of data-access work:

- calling a backend directly when a feature needs its native behavior;
- using a specialized data layer for one database family;
- repeating ordinary operations such as mapping, CRUD, filtering, relations,
  and pagination across several features or backends.

dORM is designed for the third case. It generates a common repository surface
from annotated models while keeping the selected client, connection, service,
or in-process store explicit.

## Compare the main approaches

| Approach | Best fit | Main benefit | Main cost |
| --- | --- | --- | --- |
| Native client or SDK | Backend-specific features | Maximum backend control | Repeated mapping and application boilerplate |
| Backend-specific ORM | One database family | Rich queries, schema tools, migrations, and transactions | Strong coupling to that backend |
| Query builder or SQL toolkit | SQL-first applications | Precise queries and compile-time assistance | Limited portability outside its database model |
| dORM | Shared application operations across different storage systems | Generated repositories and gradual adoption | Less native expressiveness |

These approaches solve different problems. A native client is often the best
choice when the backend itself is the application boundary. A specialized ORM
is often the best choice when one database model, its schema, and its query
language define the application. dORM is useful when the application wants a
shared surface for recurring operations without taking ownership of a
universal database language.

## Native clients and SDKs

Native packages expose the behavior of the backend directly. Examples used by
dORM engines include [`firebase_database`](https://pub.dev/packages/firebase_database),
[`cloud_firestore`](https://pub.dev/packages/cloud_firestore),
[`postgres`](https://pub.dev/packages/postgres),
[`mysql_client`](https://pub.dev/packages/mysql_client),
[`mongo_dart`](https://pub.dev/packages/mongo_dart),
[`sqlite_async`](https://pub.dev/packages/sqlite_async), and
[`http`](https://pub.dev/packages/http).

Use a native client when the feature depends on capabilities such as:

- a backend-specific selector or query operator;
- a CTE, window function, aggregation pipeline, or stored procedure;
- a provider-specific listener or synchronization protocol;
- security rules, indexes, or administrative commands;
- a wire format or endpoint contract that should remain visible in the
  feature.

The cost is repetition. Each feature may need to decode values, construct
models, preserve identities, write filters, handle missing records, and load
related data again. dORM can sit beside the client and take over those
repeated flows without removing the client from the application.

## Backend-specific ORMs and SQL toolkits

Specialized libraries usually provide a deeper model of one storage family.
For example, [Drift](https://pub.dev/packages/drift) combines Dart and SQL
APIs with typed queries, joins, transactions, reactive streams, and schema
migrations. Its [SQL API](https://drift.simonbinder.eu/sql_api/) validates SQL
and generates matching methods, while its
[migration tooling](https://drift.simonbinder.eu/migrations/) manages schema
versions and migration tests.

That depth is an advantage when SQLite or SQL is the center of the product.
It is also a coupling decision: the application adopts the library's database
model, query language, schema workflow, and runtime assumptions.

Another example is [Prisma Client Dart](https://pub.dev/packages/orm), which
provides generated, type-safe access around Prisma. Its documented surface
includes CRUD, relations, filtering, sorting, pagination, aggregation,
transactions, and raw database access. This is a strong fit when the
application is intentionally built around Prisma's model and backend
workflow.

dORM makes a different decision. It uses generated models and repositories,
but its common contract is deliberately smaller so that an application can
use In-memory, SQL, NoSQL, Firebase, or HTTP engines with the same recurring
operation vocabulary.

## What dORM gives you

dORM generates the repeated boundary between application code and storage.
The generated repository surface includes operations such as:

```dart
final Product? product = await dorm.products.repository.peek(productId);

final List<Product> products = await dorm.products.repository.peekAll(
  Filter.text(
    'keyboard',
    field: ProductEntity.fields.name,
  ),
  QueryOptions(
    orderBy: [OrderBy(ProductEntity.fields.name)],
  ),
);
```

The generated code also gives the application:

- model-to-storage mapping derived from annotations;
- separate `Data`, `Model`, and dependency values for creation flows;
- identity codecs for simple and composite identities where supported;
- generated field metadata for filters and ordering;
- generated relationship paths;
- common CRUD, filtering, sorting, and offset pagination operations;
- a stable repository surface across the selected engines;
- an In-memory engine for testing common flows without an external service.

The main benefit is not only fewer lines in one method. It is avoiding the
same mapping and persistence decisions in every feature, and avoiding a
second implementation of those decisions when the storage engine changes.

## What dORM deliberately does not unify

!!! warning "Trade-off"
    dORM is more portable than a backend-specific ORM, but less expressive
    than the native API of each backend.

The portable surface does not turn every backend into the same database. A
feature may still need native code for:

- CTEs, window functions, and backend-specific aggregations;
- stored procedures, raw SQL, or database-specific query hints;
- schema versioning, migrations, and index management;
- MongoDB aggregation pipelines and native selectors;
- Firebase security rules and provider-specific listener semantics;
- Firestore-specific query or transaction constraints;
- HTTP protocol features outside the configured mapping;
- geospatial, full-text, vector, or JSON-path queries;
- a transaction model that is not available through the selected engine.

Those capabilities remain available through the native client or service. The
application decides where the portable repository surface ends and where
backend-specific code begins. dORM does not silently download data and filter
it locally to imitate a query that the backend cannot execute.

## When a backend-specific ORM is the better choice

Choose a specialized ORM or SQL toolkit when:

- the application uses one database family by design;
- migrations and schema versioning are central to the release process;
- complex SQL, CTEs, aggregations, or advanced joins are common;
- stored procedures, indexes, or query plans are part of normal feature work;
- the team wants the database schema and query language to shape the model;
- backend-specific transactions and reactive queries are more important than
  switching storage systems.

For example, a SQLite application whose core value is rich SQL queries,
schema migrations, and reactive multi-table reads may gain more from a
SQL-focused library such as Drift than from a smaller portable query contract.

## When dORM is the better fit

Choose dORM when:

- features repeat mapping, CRUD, filters, identities, or relationship reads;
- the same domain may use local storage during development and a remote
  backend in another environment;
- the application needs one common surface across SQL, NoSQL, Firebase, HTTP,
  or In-memory storage;
- an existing client or connection should remain owned by the application;
- the team wants to migrate one model or feature at a time;
- common operations matter more than exposing every backend-specific operator;
- tests should exercise generated repositories without requiring a service.

The selected engine still matters. Read [Choose an engine](../apply/choose-an-engine.md)
and the [engine and platform support table](../reference/engine-support.md) before
depending on streams, transactions, advanced filters, identity generation, or
relationship behavior.

## Use a hybrid approach

dORM does not require an all-or-nothing migration. A feature can use dORM for
recurring operations and the native API for one operation that needs more
expressiveness:

```dart
final Product? product = await dorm.products.repository.peek(productId);

// Keep a native call beside dORM when the feature needs a backend-specific
// operation that is not part of the portable repository surface.
final nativeResult = await nativeClient.runSpecializedOperation(productId);
```

Both layers can use the same configured client, connection, project, or
database. Keep the boundary visible in application code instead of adding a
portable-looking method whose behavior only works on one backend.

For an existing application, this is usually the lowest-risk path: move one
repetitive read or write to a generated repository, leave specialized
operations in their native form, and expand only where the shared contract
continues to provide value.

## Decision guide

| If the application needs... | Prefer |
| --- | --- |
| Full access to one backend's query language | Native client or backend-specific ORM |
| SQLite with rich SQL, migrations, joins, and reactive queries | Drift or another SQL-focused solution |
| Generated Prisma-style access around a Prisma backend | Prisma Client Dart |
| Common CRUD and relationships across different storage systems | dORM |
| Existing clients or connections kept under application control | dORM |
| Backend-specific features as the main product requirement | Native API or specialized ORM |
| Common operations plus occasional native features | dORM plus native APIs |

## Evaluate dORM incrementally

Use this sequence when an existing application already has working data
access:

1. Choose an entity with repeated mapping or repository boilerplate.
2. Declare the model and generate its API.
3. Pass the client or connection already owned by the application to the
   matching engine.
4. Replace one repeated read or write with the generated repository.
5. Compare the application code before and after the change.
6. Check the selected engine's capabilities for the operations you need.
7. Keep native calls for features that require backend-specific
   expressiveness.
8. Expand the dORM boundary only while the common surface remains useful.

Continue with [Build a small store](../quickstart/index.md) to create a
project, [Operations](../build-the-store/overview.md) to learn the repository
operations, or [Choose an engine](../apply/choose-an-engine.md) to compare
backend setup and capabilities.
