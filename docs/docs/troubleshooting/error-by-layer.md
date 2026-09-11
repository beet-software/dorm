# Find the failing layer

Recognized provider failures are exposed as `DormDatabaseException`. Validation
and unsupported-operation errors can still be ordinary Dart or provider errors. The
first useful step is to identify when the failure occurs.

| Symptom | Inspect first |
| --- | --- |
| A package or command cannot be resolved | The directory containing the intended <i>pubspec.yaml</i>. |
| `build_runner` stops while reading annotations | The annotated source and generated `part` declarations. |
| The analyzer rejects a repository call | Generated types, identity types, or stale generated output. |
| A repository call fails after reaching storage | The selected engine, driver, credentials, schema, or backend rules. |
| A stream emits an error after subscription | The stream source, relationship mapping, or backend listener. |

## Check project setup first

Run commands from the directory that owns the application or package:

```shell
dart pub get
dart analyze
```

For a pure Dart application, use `dart run` and `dart test`. A Flutter/Firebase
application uses the Flutter toolchain and must initialize Firebase before
constructing its dORM engine. The engine pages contain the backend-specific
startup sequence:

- [Run in-memory](../engines/memory.md)
- [Run with BLoC](../engines/bloc.md)
- [Run with Firebase](../engines/firebase.md)
- [Run with MySQL](../engines/mysql.md)
- [Run with PostgreSQL](../engines/postgres.md)
- [Run with MongoDB](../engines/mongo.md)
- [Run with HTTP/JSON](../engines/http.md)
- [Run with SQLite](../engines/sqlite.md)

## Separate generation from runtime

If the failure occurs during `build_runner`, follow
[Fix code generation problems](code-generation-problems.md). A generator
failure happens before a repository call and cannot be fixed by changing the
engine connection.

If generated files exist but the analyzer reports missing or incompatible
types, regenerate before changing application code:

```shell
dart run build_runner build --delete-conflicting-outputs
dart analyze
```

## Check the repository precondition

Missing records are represented by the result type rather than a shared error:

```dart
final User? user = await dorm.users.repository.peek(userId);
final List<Product> products = await dorm.products.repository.peekAll();
```

`peek` returns `null` for an absent identity. Collection reads return an empty
list when nothing matches. A `pull` stream can emit `null` when its watched
record is absent or removed.

Validation failures that happen before a provider call remain ordinary Dart errors:

| Error | Observed condition |
| --- | --- |
| `ArgumentError` | An identity or key value cannot be converted or does not match the declared schema. |
| `UnsupportedError` | An engine cannot perform the requested operation, including automatic creation reached through a bypassed composite-key type. |
| `StateError` | A primary-key codec returns values that do not match the schema or key contract. |
| Dart type error | A backend value, serialized field, identity, or custom entity violates its declared type. |

For creation and identity rules, use [Create records](../operations/creating.md)
and [`@Model`](../annotations/model.md). Composite-key repositories accept
explicit creation; `Creation.auto` is rejected by the generated type before a
repository call is made.

## Inspect the original backend error

Supported external engines expose database, driver, Firebase, and HTTP failures
as `DormDatabaseException`. The exception keeps the original provider error
and stack trace at the application boundary:

```dart
try {
  await dorm.products.repository.push(product);
} on DormDatabaseException catch (error, stackTrace) {
  print('Product write failed: ${error.kind}');
  print(error.cause);
  print(stackTrace);
}
```

A failure can occur while dORM builds a query, while the driver executes it,
or while the backend applies its own schema, permission, or constraint rules.
The selected engine page identifies the connection and configuration values
that must exist before the operation can succeed.
## Handle stream errors through the stream API

Errors from a source, relationship callback, mapping step, or backend listener
are delivered through the stream error channel:

```dart
final subscription = dorm.users.repository.pullAll().listen(
  (users) => print('Loaded ${users.length} users'),
  onError: (Object error, StackTrace stackTrace) {
    print('User stream failed: $error');
    print(stackTrace);
  },
);
```

Supported external engines use `DormDatabaseException` for provider failures
from relationships and streams. Engines without `ErrorAwareEngine` and dORM
validation errors remain native Dart or provider errors. See
[Portable database errors](../reference/errors.md).
## Check engine-specific callback behavior

`patch` combines a read, a callback, and a write or removal. Error propagation
is implemented by each engine. For example, Firebase handles callback failure
inside its transaction path, while the SQL adapters follow their driver
transaction futures. Do not assume that the same callback error has identical
propagation behavior across engines.

For the framework-level signatures and return values, see
[Framework contracts](../reference/framework-contracts.md).
