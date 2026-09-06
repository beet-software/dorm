# What dORM supports today

The common model and repository APIs are shared across the available engines, but the current implementation does not provide identical capabilities everywhere. Treat the following as the current behavior of the published package source, not as a promise about future versions.

## Publicly documented capability boundaries

The root package documentation explicitly states that these common features are not handled by the framework:

| Capability | Current status |
| --- | --- |
| Application-controlled transactions | No public transaction API |
| Portable pagination | No pagination abstraction |

Some engine methods use internal transaction primitives. That does not create a public transaction boundary for application code.

## Engine-specific boundaries

| Area | BLoC | Firebase | MySQL | PostgreSQL | MongoDB |
| --- | --- | --- | --- | --- | --- |
| Runtime | In-process memory | Firebase Realtime Database | MySQL through `mysql_client` | PostgreSQL through `postgres` | MongoDB through `mongo_dart` |
| Automatic identity | UUID-backed current implementation | String push keys | UUID-backed current implementation | UUID-backed current implementation | UUID-backed String identity |
| Identity restriction | Composite-key `put`/`putAll` throw `UnsupportedError` | IDs must be `String`; non-String IDs throw `ArgumentError` | Composite-key `put` throws `UnsupportedError` | Composite-key `put` throws `UnsupportedError` | Composite-key `put`/`putAll` throw `UnsupportedError` |
| `pull`/`pullAll` | State-backed change events | Firebase value events and offline adapter | Initial read only in current reference | Initial read only | Initial read only |
| `popAll` atomicity | In-memory state update | Current implementation reads matching models then removes keys | SQL delete operation | SQL delete operation | Direct delete or read-then-delete when modifiers are used |
| External service | None | Firebase app, rules, and connectivity | MySQL server and schema | PostgreSQL server and schema | MongoDB server |

The common method names therefore do not imply identical storage, event, or transaction behavior.

## Current compatibility status

The package manifests declare Dart SDK ranges. The non-Firebase packages use Dart package tooling; `dorm_firebase_database` declares a Flutter dependency and Firebase packages.

The package manifests currently use alpha package versions, and the changelog contains version history that does not exactly match every manifest version. No formal compatibility window, deprecation period, or supported backend-version matrix is defined.

The following are current observations rather than future guarantees:

- generated `*.dorm.dart` and `*.g.dart` files depend on the generator and serializer versions used to produce them;
- package barrel files are the confirmed import surface for the framework and engines;
- direct imports from `lib/src` are not a confirmed compatibility contract;
- MySQL server-version, SQL-mode, authentication, collation, and platform matrices are not specified;
- MongoDB server-version, feature-compatibility, authentication, and platform matrices are not specified;
- Firebase server, emulator, rules, and platform-plugin compatibility beyond package dependencies and demonstrated setup are not specified.

## Separate current behavior from intended status

The current design records several behaviors that are not equivalent to permanent support boundaries:

| Behavior | Current classification |
| --- | --- |
| Composite-key generator and generated-relationship restrictions | Accidental behavior |
| Scalar `EntitySchema.primaryKey` compatibility shape | Accidental behavior; ordered `primaryKeys` is the stated canonical direction |
| Batch atomicity across all engines | Limitation; desired behavior is incomplete |
| Public transactions | Limitation; intended but currently blocked |
| Filter portability | Intended semantic direction; current API may need improvement |
| `DerivedField` | Generated persisted value with engine-specific storage mapping |
| Polymorphic serialization | Existing Firebase-origin representation requiring review for non-JSON engines |
| Pagination | Limitation; intended portable capability currently absent |

These classifications prevent an implementation gap or historical artifact from being presented as a permanent design principle.

## Treat generated APIs as compatibility surfaces

The author-confirmed public generated names include model data classes, model classes, dependencies, entity classes, field metadata, properties, relation accessors, and generated `Dorm` accessors.

Changing an annotation can therefore change generated public names or relation paths. Regenerate output after source changes and review the generated API used by application code.

The current construction boundary is `Dorm(engine)`, where `engine` implements `BaseEngine`. Earlier documentation that constructs `Dorm` from a direct `BaseReference` describes an older API shape and does not match current generated code.

## Use tests as scoped compatibility evidence

Implemented tests provide evidence for the cases they exercise:

- primary-key codecs and schema key fields in framework tests;
- direct and nested relation paths in framework tests;
- BLoC reference operations such as filtered removal;
- MySQL CRUD/filter operations when configured with a live connection;
- MySQL callback relationship forms without a live database;
- MongoDB selector construction and callback relationship forms without a live database. Integration evidence depends on `MONGO_URI`.

The test suites are not a complete cross-engine compatibility matrix. A passing test run establishes current behavior for covered cases, not a promise for untested combinations.
