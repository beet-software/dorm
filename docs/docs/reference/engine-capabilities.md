# Engine capability reference

The generated model and repository surface is shared. The engine determines
storage, query translation, identity creation, stream source, and backend
requirements.

## Capability matrix

| Capability | Memory | BLoC | Firebase | Firestore | MySQL | PostgreSQL | MongoDB | HTTP |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Storage | Dart maps | In-process state | Firebase Realtime Database | Cloud Firestore | MySQL through mysql_client | PostgreSQL through postgres | MongoDB through mongo_dart | REST-shaped HTTP/JSON API |
| Public engine constructor | Engine() | Engine() | Engine(FirebaseInstance, {String? path}) | Engine(FirebaseFirestore, {String? parentPath}) | Engine(MySQLConnection) | Engine(SessionExecutor) | Engine(Db) | Engine({client, baseUri, mapping, headers}) |
| External service | None | None | Firebase app/database or emulator | Firebase app/Firestore or emulator | MySQL server and schema | PostgreSQL server and schema | MongoDB server | Configured HTTP API |
| Runtime dependencies | dorm_framework, uuid | bloc, rxdart, uuid | Firebase packages | cloud_firestore, rxdart | mysql_client, uuid | postgres, uuid | mongo_dart, uuid | http, uuid |
| Automatic identity | UUID-backed in-memory identity | UUID-backed in-memory identity | Firebase push key | Firestore document ID | UUID-backed SQL identity | UUID-backed SQL identity | UUID-backed String identity | UUID-backed String identity |
| Identity restriction | Composite creation requires `Creation.explicit` | Composite creation requires `Creation.explicit` | Reference identities must be String; composite identities are unsupported | Reference identities must be String; composite identities are unsupported | Composite creation requires `Creation.explicit` | Composite creation requires `Creation.explicit` | Composite creation requires `Creation.explicit` | Composite creation requires `Creation.explicit` |
| Collection filtering | In-memory query evaluation | In-memory query evaluation | Realtime Database query | Firestore query | SQL query | PostgreSQL SQL query | MongoDB selectors | Configured URL parameters |
| Single reads | In-memory map lookup | In-memory map lookup | Firebase SDK read | Firestore document read | SQL read | PostgreSQL SQL read | MongoDB collection read | HTTP request |
| Streams | State-backed | State-backed | Firebase value events, with offline behavior | Firestore document/query snapshots | Initial read only in current implementation | Initial read only | Initial read only | Initial read only |
| Relationships | Framework relationship implementation | Framework relationship implementation | Framework relationship implementation | Readable-operation fallback | Direct relation plans plus readable fallbacks | Direct relation plans plus readable fallbacks | Direct relation plans plus readable fallbacks | Readable-operation fallback |
| Public transaction API | `TransactionalDorm` | `TransactionalDorm` | None; patch uses a Firebase transaction internally | None; patch uses a Firestore transaction internally | `TransactionalDorm` | `TransactionalDorm` | None | None |
| Pagination | Offset pages | Offset pages | Offset pages with client-side skipping | Offset pages with client-side skipping | Offset pages | Offset pages | Offset pages | Offset pages |

The matrix records current behavior. It does not create a future compatibility
promise.

## Memory engine

Import:

~~~dart
import 'package:dorm_memory_database/dorm_memory_database.dart';
~~~

Construct it without a server or connection:

~~~dart
final Engine engine = Engine();
final Dorm dorm = Dorm(engine);
~~~

The engine stores models in Dart maps owned by the `Engine` instance. It uses
Dart streams to emit the current value when a subscription starts and later
values after writes. It generates UUID string identities for simple generated
keys and requires explicit identities for composite keys.

The package has no runtime dependency on BLoC or RxDart. Its runtime
dependencies are `dorm_framework` and `uuid`.

See [Choose a dORM engine](../apply/choose-an-engine.md).

## BLoC engine

Import:

~~~dart
import 'package:dorm_bloc_database/dorm_bloc_database.dart';
~~~

Public entry points include:

~~~dart
final Engine engine = Engine();
final Dorm dorm = Dorm(engine);
~~~

The engine stores models in process memory. State belongs to the Engine
instance; a separate engine instance has separate state.

Filter and Query evaluate serialized in-memory values. BLoC streams react to
state changes. The current implementation copies table state for mutation
paths and reconstructs collection reads through serialization.

Generated composite-key repositories accept only `Creation.explicit` with a
`CompositeKey` for creation. A `Creation.auto` call is rejected by the static
type system; engines retain `UnsupportedError` as a runtime safeguard when
that type restriction is bypassed.

See [Run with BLoC](../apply/use-bloc.md).

## Firebase engine

Import:

~~~dart
import 'package:dorm_firebase_database/dorm_firebase_database.dart';
~~~

The public setup types are:

~~~dart
FirebaseInstance()
FirebaseInstance.custom(...)
Engine(FirebaseInstance instance, {String? path})
OfflineMode.include
OfflineMode.exclude
~~~

Firebase initialization is owned by the Flutter application. The engine uses
Firebase Core, Realtime Database, and Authentication dependencies supplied by
FirebaseInstance.

Firebase reference operations require String identities. Passing another
identity type produces ArgumentError at key/path conversion.

pull and pullAll use Realtime Database value events. OfflineMode.include
allows local cached events; OfflineMode.exclude uses the online path and the
current source notes that reads/events can wait indefinitely while offline.

popAll currently reads matching models and then removes their keys. The
operation is not a common all-or-nothing transaction contract.

See [Run with Firebase](../apply/use-firebase.md).

## Cloud Firestore engine

Import `package:dorm_firestore_database/dorm_firestore_database.dart` and pass
an initialized `FirebaseFirestore` instance to `Engine`. The application owns
Firebase initialization, emulator configuration, and SDK lifecycle.

The engine uses Firestore document IDs as simple String identities. It supports
Firestore queries, document/query snapshots, internal write batches, and an
internal transaction for `patch`. Composite identities, schema generation,
migrations, aggregation, and a public transaction API are not supported.

Offset pagination is implemented by reading enough documents and skipping the
offset in the client. Relationship reads use the framework's readable
operations and may issue multiple Firestore reads.

See [Run with Cloud Firestore](../apply/use-firestore.md).

## MySQL engine

Import:

~~~dart
import 'package:dorm_mysql_database/dorm_mysql_database.dart';
~~~

Construct it with an open connection:

~~~dart
final Engine engine = Engine(connection);
final Dorm dorm = Dorm(engine);
~~~

The engine maps filters and generated schema metadata to SQL text and named
parameters. It requires tables to exist before normal CRUD operations can
succeed.

The current MySQL pull and pullAll implementations perform an initial read and
do not subscribe to later database changes. `TransactionalDorm` can compose
reads and writes across repositories using the same connection transaction.
Selected individual operations also use a connection transaction internally.

Direct table relationship plans can group reads. Other relationship sources
use readable operations. This is an implementation capability, not a
cross-engine query-count guarantee.

The package also contains a separate command for printing MySQL table
definitions from annotated Dart input. It is not a general migration API.

See [Run with MySQL](../apply/use-mysql.md) and
[Generate MySQL table definitions](../apply/use-mysql.md#generate-a-mysql-schema).

## PostgreSQL engine

Import:

~~~dart
import 'package:dorm_postgres_database/dorm_postgres_database.dart';
import 'package:postgres/postgres.dart';
~~~

Construct it with an opened `Connection` or `Pool`:

~~~dart
final SessionExecutor executor = await Connection.open(endpoint);
final Engine engine = Engine(executor);
final Dorm dorm = Dorm(engine);
~~~

The engine maps generated schema metadata and filters to PostgreSQL SQL with
named parameters. It requires tables to exist before normal CRUD operations
can succeed. Identified writes use PostgreSQL upsert statements. The package
does not provide schema generation or migrations.

`pull` and `pullAll` perform the initial read only. Selected batch and patch
operations use driver transactions internally. `TransactionalDorm` can also
compose reads and writes across repositories using the same driver transaction.

See [Run with PostgreSQL](../apply/use-postgres.md).

## MongoDB engine

Import:

~~~dart
import 'package:dorm_mongo_database/dorm_mongo_database.dart';
import 'package:mongo_dart/mongo_dart.dart';
~~~

Construct it with an opened `Db`:

~~~dart
final Db database = Db(uri);
await database.open();
final Engine engine = Engine(database);
final Dorm dorm = Dorm(engine);
~~~

The application owns the `Db` lifecycle. The engine uses the schema-declared
identity fields in documents and does not convert identities to MongoDB
`ObjectId` or use `_id` as the dORM identity field. Identified writes use
replacement upserts. `pushAll` is sequential and has no atomicity guarantee.

MongoDB filters support equality, escaped text-prefix matching, date/range
conditions, ascending/descending sort, limits, and offsets. `pull` and `pullAll` emit one initial
read. The engine does not expose public transactions, change streams,
aggregation, migrations, or native selector APIs.

See [Run with MongoDB](../apply/use-mongo.md).

## HTTP engine

Import:

~~~dart
import 'package:dorm_http_database/dorm_http_database.dart';
import 'package:http/http.dart' as http;
~~~

Construct it with an application-owned client, a base URI, and one resource
mapping per entity. The mapping defines endpoint paths, batch operations,
query parameters, and JSON envelopes.

The engine sends JSON bodies using generated entity serialization and decodes
JSON objects/lists with generated entity deserialization. It emits an initial
read for `pull` and `pullAll`, uses readable operations for relationships, and
does not expose transactions, cursor pagination, polling, or server-event streams.

Batch operations require configured endpoints. Missing batch endpoints produce
`UnsupportedError` instead of being emulated with multiple independent
requests. Non-success HTTP responses produce `HttpDatabaseException`.

See [Run with HTTP/JSON](../apply/use-http.md).

## Shared surface and engine-specific errors

Dorm, generated DatabaseEntity accessors, repositories, filters, and
relationship paths keep their common type shape after the engine changes.
Backend exceptions do not share one dORM error class.

Use [Diagnose errors by layer](../troubleshooting/error-by-layer.md) for
the observed propagation behavior and [dORM documentation home](../index.md)
for unresolved capability status.
