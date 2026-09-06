# Engine capability reference

The generated model and repository surface is shared. The engine determines
storage, query translation, identity creation, stream source, and backend
requirements.

## Capability matrix

| Capability | BLoC | Firebase | MySQL | PostgreSQL |
| --- | --- | --- | --- | --- |
| Storage | In-process state | Firebase Realtime Database | MySQL through mysql_client | PostgreSQL through postgres |
| Public engine constructor | Engine() | Engine(FirebaseInstance, {String? path}) | Engine(MySQLConnection) | Engine(SessionExecutor) |
| External service | None | Firebase app/database or emulator | MySQL server and schema | PostgreSQL server and schema |
| Automatic identity | UUID-backed in-memory identity | Firebase push key | UUID-backed SQL identity | UUID-backed SQL identity |
| Identity restriction | Composite-key put/putAll throw UnsupportedError | Reference identities must be String | Composite-key put throws UnsupportedError | Composite-key put throws UnsupportedError |
| Collection filtering | In-memory query evaluation | Realtime Database query | SQL query | PostgreSQL SQL query |
| Single reads | In-memory map lookup | Firebase SDK read | SQL read | SQL read |
| Streams | State-backed | Firebase value events, with offline behavior | Initial read only in current implementation | Initial read only |
| Relationships | Framework relationship implementation | Framework relationship implementation | Direct relation plans plus readable fallbacks | Direct relation plans plus readable fallbacks |
| Public transaction API | None documented | None; patch uses a Firebase transaction internally | None; selected operations use MySQL transactions internally | None; selected operations use PostgreSQL transactions internally |
| Pagination | Not supported by the common API | Not supported | Not supported | Not supported |

The matrix records current behavior. It does not create a future compatibility
promise.

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

Composite-key automatic put and putAll are rejected with UnsupportedError. An
explicitly identified model can use push when the operation and generated
entity support it.

See [Run with BLoC](../03-apply/02-use-bloc.md).

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

See [Run with Firebase](../03-apply/03-use-firebase.md).

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
do not subscribe to later database changes. Several writes use a connection
transaction internally, but the public framework does not expose a general
transaction object.

Direct table relationship plans can group reads. Other relationship sources
use readable operations. This is an implementation capability, not a
cross-engine query-count guarantee.

The package also contains a separate command for printing MySQL table
definitions from annotated Dart input. It is not a general migration API.

See [Run with MySQL](../03-apply/04-use-mysql.md) and
[Generate MySQL table definitions](../03-apply/07-generate-mysql-schema.md).

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
operations use driver transactions internally, while the common framework
does not expose a transaction object.

See [Run with PostgreSQL](../03-apply/08-use-postgres.md).

## Shared surface and engine-specific errors

Dorm, generated DatabaseEntity accessors, repositories, filters, and
relationship paths keep their common type shape after the engine changes.
Backend exceptions do not share one dORM error class.

Use [Diagnose errors by layer](../05-troubleshooting/01-error-by-layer.md) for
the observed propagation behavior and [Boundaries and compatibility](../03-understand/05-boundaries-and-compatibility.md)
for unresolved capability status.
