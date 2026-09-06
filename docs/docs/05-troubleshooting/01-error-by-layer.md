# Diagnose errors by layer

dORM does not convert every failure into one common exception type. The error
class and the information available to the caller depend on the phase and on
the selected engine.

Use the phase of the failure to choose the first place to inspect:

| Symptom | First layer to inspect | Next step |
| --- | --- | --- |
| The application cannot resolve a package or command | Project setup | Run the command from the directory that contains the intended `pubspec.yaml`. |
| `build_runner` stops while reading annotations | Generation | Check the annotated source and generated `part` declarations. |
| A repository call rejects an identity or operation | Framework or engine API | Check the identity type, schema, and selected operation. |
| A repository call fails after reaching storage | Backend or driver | Inspect the original Firebase or MySQL error and its connection/configuration. |
| A stream emits an error after subscription | Stream source or relationship mapping | Handle the stream error and inspect the source operation. |

The framework exposes ordinary Dart `Future`, `Stream`, nullable model, and
list results. It does not expose a shared dORM exception hierarchy or a common
error envelope.

## Check setup and configuration first

Setup errors occur before a repository operation can produce a normal result.
Confirm the boundary for the selected engine:

- BLoC requires an `Engine` instance. It does not require a server or network
  connection.
- Firebase requires Firebase initialization, a configured Firebase app, and
  access to the Realtime Database. Authentication and database rules can reject
  an operation after initialization.
- MySQL requires an open `MySQLConnection`, an existing database, and tables
  compatible with the generated entity schema.

For MySQL, open the connection before creating `Dorm` and keep the connection
available for the operations that use it. A failure from
`MySQLConnection.createConnection`, `connect`, or a later SQL call remains a
  MySQL client or server error; the framework API does not wrap it in a dORM
  error.

For Firebase, initialize Firebase before constructing `FirebaseInstance` or
the dORM `Engine`. A Firebase initialization, rules, network, or emulator
failure remains a Firebase or platform error.

Use the engine-specific setup pages for the complete initialization sequence:

- [Run with BLoC](../03-apply/02-use-bloc.md)
- [Run with Firebase](../03-apply/03-use-firebase.md)
- [Run with MySQL](../03-apply/04-use-mysql.md)

## Separate generation errors from runtime errors

Annotation and model-shape errors happen during `build_runner`. They do not
come from `Repository` or `BaseReference` calls.

From the application directory, run:

```shell
dart pub get
dart run build_runner build
```

The generator currently raises `StateError` for several invalid declarations,
including unsupported primary-key shapes, invalid identity fields, unsupported
foreign-field targets, duplicate generated relationship path names, and
invalid query-field references. The message commonly includes the model,
field, or generated name involved in the failure.

Start with [Diagnose annotation and generated-code problems](02-code-generation-problems.md)
when the failure occurs before generated files are available.

## Check framework and API preconditions

Some failures are produced before an engine reaches its storage backend.

### Missing values are usually results, not exceptions

Read methods represent an absent record with their declared result shape:

```dart
final User? user = await dorm.users.repository.peek(userId);
final List<Product> products = await dorm.products.repository.peekAll();
```

`peek` returns `null` for an absent identity. Collection reads return an empty
list when no records match. A `pull` stream can emit `null` when the watched
record is absent or removed.

### Identity and operation errors use ordinary Dart errors

The current implementations expose these observed classes:

| Error | Observed condition |
| --- | --- |
| `ArgumentError` | The Firebase adapter receives a non-`String` identity or cannot convert a Firebase key to the requested identity type. |
| `UnsupportedError` | BLoC and MySQL reject the automatic `put` path for a composite primary key. |
| `StateError` | A primary-key codec returns a number of values that does not match the schema or single-key contract. |
| Dart type error | A backend value, serialized field, identity, or custom entity does not match the declared generic type. |

The exact operation and engine still matter. For example, an explicitly
identified model may use `push` where automatic identity creation through
`put` is rejected for a composite key. Check
[Identity and dependencies](../03-understand/02-identity-and-dependencies.md)
before changing an operation.

## Inspect backend and driver errors without replacing them

Firebase SDK calls and MySQL connection calls are delegated through the
engine. The adapters do not add a standard entity name, operation name,
backend code, or dORM error code to every failure.

Catch at the application boundary when the operation needs to be reported:

```dart
try {
  await dorm.products.repository.push(product);
} catch (error, stackTrace) {
  print('Product write failed: $error');
  print(stackTrace);
}
```

Keep both `error` and `stackTrace` when forwarding the failure. The original
exception is normally the only backend-specific context available to the
caller.

MySQL failures can occur while dORM builds SQL or while the driver executes
it. A schema/codec mismatch can fail before `connection.execute`; SQL syntax,
constraint, connection, and server errors come from the MySQL client or
server. Firebase failures can occur during SDK reads, writes, removals,
transactions, or listener setup.

## Handle stream errors through the stream API

Errors from a relationship source, child stream, mapping callback, or backend
stream are forwarded through the stream error channel. They are not
necessarily thrown by the call that creates the stream.

```dart
final subscription = dorm.users.repository.pullAll().listen(
  (users) {
    print('Loaded ${users.length} users');
  },
  onError: (Object error, StackTrace stackTrace) {
    print('User stream failed: $error');
    print(stackTrace);
  },
);
```

The forwarded error can remain backend-specific. The relationship layer does
not add a universal relationship path, entity, or operation field.

## Treat propagation details as engine-specific

The framework does not establish one error behavior for all engines. In
particular, a callback error passed to `patch` is handled differently:

- Firebase catches the callback failure and aborts the Firebase transaction.
  The original callback error is not rethrown by that callback path.
- MySQL does not catch the callback failure in the adapter. The error follows
  the transaction future supplied by `mysql_client`.

When the required behavior depends on the exception type, verify it against
the selected engine rather than assuming that two repository calls propagate
the same way.

## Keep the uncertainty visible

The current public contracts do not guarantee a uniform exception class,
uniform message, or uniform error metadata across engines. A behavior marked
`UNKNOWN` or `UNCONFIRMED` in the API and compatibility material must not be
treated as a cross-engine error contract.

For the distinction between framework errors, backend errors, and mapping
errors, read [Serialization and mapping](../03-understand/03-serialization-and-mapping.md).
