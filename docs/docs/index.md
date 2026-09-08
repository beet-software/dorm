# dORM documentation

dORM is a Dart library for applications that already read and write data but
have too much repeated code around that data.

It generates models and repositories from annotated Dart classes. Those
repositories provide common create, read, update, delete, filtering, and
relationship operations across in-memory data, Firebase, SQL databases,
MongoDB, REST-shaped HTTP APIs, and SQLite.

## A helper around the code you already have

Applications often repeat the same work in several places:

- convert database rows or JSON into model objects;
- turn model objects back into data for writes;
- build identity lookups and filters;
- load related records;
- keep create, update, and delete code consistent.

dORM generates much of this connection between your Dart models and your data
source. It does not take ownership of the database client, connection, pool,
or HTTP client that your application already uses.

!!! tip "Start with a model you already have"
    Keep your current database or API code. Pass its client or connection to
    the matching dORM engine, and move one model or one operation to the
    generated repository first.

This makes gradual adoption possible. Keep native SQL, Firebase calls,
MongoDB operations, or HTTP calls beside dORM when a backend-specific feature
is a better fit there.

## It is more than a database-specific ORM

The same framework can work with very different kinds of data sources:

| Data source | What your application gives the engine |
| --- | --- |
| In-memory data | The memory or BLoC engine. |
| Firebase Realtime Database | Firebase configuration and database objects. |
| MySQL | An opened `MySQLConnection`. |
| PostgreSQL | An opened `Connection` or `Pool`. |
| MongoDB | An opened `mongo_dart` `Db`. |
| REST-shaped API | An `http.Client`, base URI, and HTTP mapping. |
| SQLite | An application-owned `sqlite_async` `SqliteDatabase`. |

The engine adapts the common dORM operations to that data source:

```text
your Dart application
    -> generated Dorm and repositories
    -> selected dORM engine
    -> your database, client, or in-memory state
```

The database, driver, and connection lifecycle remain visible in your
application. dORM gives you generated mapping and repository code without
pretending that a relational database, a document database, Firebase, and an
HTTP API behave identically.

## The main operations stay familiar

Generated repositories expose a small set of operations for the work most
applications need:

| Operation | Use it to |
| --- | --- |
| `put` | Create a model from data and related identities. |
| `peek` | Read one model by its identity. |
| `peekAll` | Read a collection, optionally with filters and read options. |
| `push` | Save a model that already has its identity. |
| `patch` | Read a model, change it in a callback, then save or remove it. |
| `pop` | Remove one model by its identity. |
| `pull` | Subscribe to reads whose later events depend on the selected engine. |

The names stay the same across engines, while the work underneath them is
adapted to the selected data source.

## What is shared and what can differ

dORM gives engines a common model and repository surface. It does not make
every backend behave identically.

| Topic | Current behavior |
| --- | --- |
| Create, read, update, delete, and common filters | Available through the common repository API. |
| Pagination | Current engines accept offset pagination. Cursor requests are not accepted by their typed APIs. |
| Streams | Memory, BLoC, Firebase, Firestore, and SQLite can provide later changes. PostgreSQL, MongoDB, and HTTP currently emit the initial read only; MySQL streams are not fully implemented. |
| Authorization | Configured by the application and the selected backend. |
| Backend-specific features | Continue to belong to the native database, driver, or HTTP client when dORM does not model them. |

Choose the engine whose data source matches your application. Then read its
setup and behavior before relying on stream updates, batch operations, or
relationship reads.

## What dORM does not replace

dORM does not provide built-in database migrations. Database schema creation
and schema changes remain part of your database workflow. The MySQL package
can generate schema SQL, but that is different from a migration system.
PostgreSQL, MongoDB, Firebase, and HTTP setup also remain application- or
backend-specific.

dORM provides a public transaction callback through `TransactionalDorm` for
the Memory, BLoC, MySQL, PostgreSQL, and SQLite engines. The callback can compose
repository reads and writes across entities and rolls back when it fails.
Streams are not available inside the callback. Firestore, Firebase Realtime
Database, MongoDB, and HTTP do not expose this common capability; their
individual internal transactions, where present, remain separate from it.

If your project expects one abstraction to hide all backend details, this may
not be a good fit. Engine differences remain visible, and advanced SQL,
MongoDB, Firebase, or HTTP features may still require native code.

## Choose a starting point

- Start a new pure Dart application with [Quickstart](quickstart/index.md).
- Connect an existing backend through [Choose an engine](apply/choose-an-engine.md).
- Learn repository tasks in [Operations](build-the-store/overview.md).
- Learn the source declarations in [Annotations](annotations/index.md).
- See generated types and their roles in [Model anatomy](model-anatomy/index.md).
- Find signatures and return values in [Public API](reference/public-api.md).
- Start with [Troubleshooting](troubleshooting/index.md) when a command or
  repository call fails.
