# Public API reference

Use this page to locate exported APIs. The tutorial pages explain how to use
the common operations; this page groups the same surface by package.

## Import from package barrels

Use these package entry points for application code:

| Package | Barrel |
| --- | --- |
| Annotations | `package:dorm_annotations/dorm_annotations.dart` |
| Framework | `package:dorm_framework/dorm_framework.dart` |
| Generator | `package:dorm_generator/dorm_generator.dart` |
| Memory engine | `package:dorm_memory_database/dorm_memory_database.dart` |
| BLoC engine | `package:dorm_bloc_database/dorm_bloc_database.dart` |
| Firebase engine | `package:dorm_firebase_database/dorm_firebase_database.dart` |
| Firestore engine | `package:dorm_firestore_database/dorm_firestore_database.dart` |
| MySQL engine | `package:dorm_mysql_database/dorm_mysql_database.dart` |
| PostgreSQL engine | `package:dorm_postgres_database/dorm_postgres_database.dart` |
| HTTP engine | `package:dorm_http_database/dorm_http_database.dart` |
| SQLite engine | `package:dorm_sqlite_database/dorm_sqlite_database.dart` |

Concrete classes below `lib/src/` are not automatically part of the barrel
surface. A class being importable by an internal package path does not by
itself establish a supported application API.

## Annotations and generated-facing APIs

Use the dedicated [Annotations](../annotations/index.md) reference for
annotation parameters, identity specifications, derived values, and
polymorphic values. Use [Generated API](generated-api.md) for the concrete
types emitted from those declarations.

The annotations barrel also re-exports selected APIs from
copy_with_extension and json_annotation. Their behavior is defined by those
packages.

## Generator entry point

The generator package exports:

~~~dart
Builder generateOrm(BuilderOptions options)
~~~

The builder writes a .dorm.dart part file and is configured for dependent
packages through build_runner. Application code normally invokes build_runner;
it does not call generateOrm directly.

## Framework operation surface

Generated repositories expose these operation families:

| Method | Signature shape | Result |
| --- | --- | --- |
| `peek` | `Future<Model?> peek(I id)` | One model or `null`. |
| `peekAll` | `Future<List<Model>> peekAll([BaseFilter<Q> filter, QueryOptions options])` | Matching models with optional ordering and read window options. |
| `peekPage` | `Future<Page<Model>> peekPage(BaseFilter<Q>, PageRequest)` | One offset page with `items` and `hasNext`. |
| `pull` | `Stream<Model?> pull(I id)` | A stream of one model or `null`. |
| `pullAll` | `Stream<List<Model>> pullAll([BaseFilter<Q> filter, QueryOptions options])` | A stream of matching lists with optional read options. |
| `peekAllKeys` | `Future<List<I>> peekAllKeys()` | Stored identities. |
| `put` | `Future<Model> put(C creation)` | Constructs and persists one model from a creation request accepted by the entity. |
| `putAll` | `Future<List<Model>> putAll(List<C> creations)` | Constructs and persists one model per creation request accepted by the entity. |
| `push` | `Future<void> push(Model model)` | Persists an identified model. |
| `pushAll` | `Future<void> pushAll(List<Model>)` | Persists identified models. |
| `patch` | `Future<void> patch(I id, Model? Function(Model?) update)` | Updates, creates, or removes according to the callback result. |
| `pop` | `Future<void> pop(I id)` | Removes one identity. |
| `popKeys` | `Future<void> popKeys(Iterable<I>)` | Removes selected identities. |
| `popAll` | `Future<void> popAll(BaseFilter<Q>)` | Removes matching models. |
| `purge` | `Future<void> purge()` | Removes all models for the entity. |

`Repository` combines the data and model operation interfaces. The generated
entry point is normally `dorm.<model>.repository`.

See [Operations in a generated repository](../build-the-store/overview.md) for
operation sequences and [Framework contracts](framework-contracts.md) for
contract details.

### Creation requests

`Creation<Data, I>` is the common base for requests that group the data,
dependency, and identity strategy for one new model. `Creation.auto(...)`
follows the identity strategy declared by the model's `IdSpec`, while
`Creation.explicit(...)` returns
`ExplicitCreation<Data, I>`:

~~~dart
Creation.auto(
  dependency: dependency,
  data: data,
);

Creation.explicit(
  dependency: dependency,
  data: data,
  identity: id,
);
~~~

`SimpleCreation<Data, I>` is the accepted creation type for generated
single-key entities, so it accepts both factory results. `Creation.auto` can
use a dORM-generated identity or a backend-generated identity when the model
declares `DatabaseGeneratedIdSpec` and the engine supports it. Generated
composite-key entities accept `ExplicitCreation<Data, CompositeKey>` only;
passing `Creation.auto(...)` to their generated `put` or `putAll` is a
compile-time error. `AutoCreation<Data, I>` follows the automatic identity
strategy, while `ExplicitCreation<Data, I>` contains the final identity.
`ResolvedCreation<Data, I>` is the context passed to
`Entity.fromData`; it contains `dependency`, `data`, `id`, and
`identitySource`, which identifies whether the engine, database, or caller
supplied the final identity.

## Filters and queries

The framework exposes `BaseFilter<Q>` factories and a `BaseQuery<Q>`
contract. Engine packages expose a concrete `Filter` type and `Query` type.

Common filter factories include:

| Factory | Input |
| --- | --- |
| `Filter.empty()` | No condition. |
| `Filter.value(...)` | Exact value, using a key or generated field schema. |
| `Filter.text(...)` | Text-prefix condition. |
| `Filter.textRange(...)` | Text bounds. |
| `Filter.numericRange(...)` | Numeric bounds. |
| `Filter.date(...)` | Date comparison at a `DateFilterUnit`. |
| `Filter.dateRange(...)` | Date bounds. |

`QueryOptions`, `OrderBy`, `OffsetPageRequest`, and `Page` provide
ordering, read windows, and offset-page metadata. See [Using filters](../build-the-store/using-filters.md),
[Using sorting](../build-the-store/using-sorting.md), and
[Using pagination](../build-the-store/using-pagination.md).

## Relationship APIs

The framework exposes:

- `BaseRelationship<Q>` for one-to-one, one-to-many, many-to-one, and
  many-to-many associations;
- `RelationPath<Context, Root, Current, Q>` for chained generated paths;
- `Join<LeftModel, RightModel>` for relationship results;
- `RelationSource`, `RelationPlan`, and `RelationSpec` for relationship
  sources and generated path metadata;
- `ModelRelationship` and `RelationshipDefinedAssociation` for generated
  and explicit relationship access.

Relationship path reads return `Future<List<Join<...>>>` or corresponding
streams. See [Add carts and cart items](../quickstart/relations-and-cart.md)
and [Framework contracts](framework-contracts.md).

## Engine entry points

| Package | Public entry points |
| --- | --- |
| BLoC | `Engine()`, `Filter`, `Query`, and the exported BLoC API. |
| Firebase | `Engine(FirebaseInstance, {String? path})`, `FirebaseInstance`, `OfflineMode`, `Filter`, `Query`, and selected Firebase types. |
| MySQL | `Engine(MySQLConnection)`, `Filter`, and `Query`. |
| PostgreSQL | `Engine(SessionExecutor)`, `Filter`, and `Query`. PostgreSQL driver types are imported from `package:postgres/postgres.dart`. |
| HTTP | `Engine({client, baseUri, mapping, headers})`, `Filter`, `Query`, `HttpMapping`, `HttpResourceMapping`, `HttpEndpoint`, `HttpJsonCodec`, `HttpQueryCodec`, and `HttpDatabaseException`. |
| SQLite | `Engine(SqliteDatabase)`, `Filter`, and `Query`; import `SqliteDatabase` from `package:sqlite_async/sqlite_async.dart`. |

The generated `Dorm` receives one concrete engine and exposes generated
`DatabaseEntity` accessors. See [Engine capability reference](engine-capabilities.md)
for current backend differences.

### Transactions

Generated model libraries also expose `TransactionalDorm<Q, P>` when a
transaction-capable engine is used. Its constructor requires
`TransactionalEngine<Q, P>` and its callback receives a temporary
`Dorm<Q, P>`:

~~~dart
final TransactionalDorm<Query, OffsetPageRequest> dorm =
    TransactionalDorm(engine);

final result = await dorm.transaction((tx) async {
  final User? user = await tx.users.repository.peek(userId);
  await tx.carts.repository.push(cart);
  return user;
});
~~~

The callback result is returned and callback or backend errors are propagated.
Supported engines roll back the transaction when the callback fails. Streams
are rejected inside the callback, and nested transactions are not supported.
The capability is currently implemented by Memory, BLoC, MySQL, PostgreSQL,
and SQLite.

## Errors and status

Public methods return ordinary Dart futures and streams. Current failures can
include `ArgumentError`, `StateError`, `UnsupportedError`, Dart runtime
type errors, Firebase SDK errors, and MySQL client/server errors. There is no
single exported dORM exception base class.

`HttpDatabaseException` preserves the HTTP status code, method, URI, and response body for non-success responses. Transport errors from the injected HTTP client are propagated. `HttpIdentityLocation.none` and `HttpCreationCodec` configure HTTP creation responses for `DatabaseGeneratedIdSpec` entities; the response can provide a scalar identity or complete JSON data.

See [Diagnose errors by layer](../troubleshooting/error-by-layer.md) for
error handling and [Compatibility and release status](compatibility-and-release-status.md)
for current compatibility qualifications.
