# Handling errors

Database operations can fail for different reasons: the service may be
temporarily unavailable, the current user may not have permission, or the
application may have sent an invalid query. Handling these cases separately
makes the behavior clearer and avoids retrying operations that cannot succeed
without a code or data change.

## First distinguish absence from failure

Not finding a record is normally a valid result, not an exception:

```dart
final User? user = await dorm.users.repository.peek(userId);
final List<User> users = await dorm.users.repository.peekAll();
```

`peek` returns `null` when the record does not exist. A collection read returns
an empty list when no records match. Use an error handler for failures reported
by the database or service, not for these normal results.

## Catch portable database errors

Official dORM engines translate recognized provider failures into
`DormDatabaseException`. It gives the application one API that works with
HTTP, SQL, Firebase, Firestore, and MongoDB:

```dart
try {
  final User user = await dorm.users.repository.put(creation);

  showUser(user);
} on DormDatabaseException catch (error, stackTrace) {
  if (error.isAvailabilityFailure) {
    showTemporaryFailure();
  } else if (error.kind == DormErrorKind.authentication) {
    await refreshSession();
  } else if (error.kind == DormErrorKind.authorization) {
    showPermissionError();
  } else if (error.kind == DormErrorKind.conflict ||
      error.kind == DormErrorKind.constraint) {
    showConflictError();
  } else {
    reportDatabaseFailure(error, stackTrace);
  }
}
```

Use `kind` for decisions that should remain independent of the selected
engine. The complete list of categories and their meanings is in
[Portable database errors](../reference/errors.md).

## Decide when to retry

`unavailable` and `timeout` often indicate a temporary problem, but they do
not automatically make every write safe to repeat. A failed write may have
reached the provider even when the client did not receive its response.

Check `retryability` before retrying automatically:

```dart
on DormDatabaseException catch (error, stackTrace) {
  if (error.isRetryable) {
    await retryWithBackoff();
  } else {
    reportDatabaseFailure(error, stackTrace);
  }
}
```

If retryability is `unknown`, let the application decide. For writes, prefer
an idempotent operation or an application-level way to identify a repeated
attempt before adding automatic retries.

## Keep provider details when diagnosing a failure

The portable category is intended for normal application behavior. When a
diagnostic or a provider-specific recovery needs more information, the
exception still exposes:

- `engine`: the dORM engine that reported the failure;
- `operation`: the operation being attempted, when known;
- `providerCode`: the original HTTP status, SQLSTATE, SQLite result code, or
  another provider code;
- `cause`: the original provider exception;
- `stackTrace`: the original stack trace.

For example:

```dart
on DormDatabaseException catch (error, stackTrace) {
  log(
    'Database failure in ${error.engine}: ${error.operation}',
    error: error.cause,
    stackTrace: error.stackTrace ?? stackTrace,
  );
}
```

Do not depend on `cause` or `providerCode` for behavior that must work with
another engine. Use `DormErrorKind` and `DormRetryability` for that behavior.

## Handle validation and custom-engine errors

Errors raised by dORM before it calls a provider remain ordinary Dart errors.
For example, an invalid argument, an unsupported local operation, or malformed
data can be reported as `ArgumentError`, `UnsupportedError`, `StateError`, or
`FormatException`.

Engines that do not implement the optional `ErrorAwareEngine` capability also
keep their native errors. If your application supports custom engines, keep a
final handler for errors that are not `DormDatabaseException`:

```dart
try {
  await runOperation();
} on DormDatabaseException catch (error, stackTrace) {
  handlePortableFailure(error, stackTrace);
} catch (error, stackTrace) {
  reportUnexpectedFailure(error, stackTrace);
}
```

## Handle errors from streams

`try`/`catch` around `pull` or `pullAll` only covers errors thrown while the
stream is being created. Errors that happen later arrive through the stream's
error channel:

```dart
final subscription = dorm.users.repository.pullAll().listen(
  renderUsers,
  onError: (Object error, StackTrace stackTrace) {
    if (error is DormDatabaseException) {
      handlePortableFailure(error, stackTrace);
    } else {
      reportUnexpectedFailure(error, stackTrace);
    }
  },
);
```

Do not silently replace a failed stream with another source unless the
application explicitly accepts repeated or missing snapshots. dORM keeps
streams attached to their selected engine so that an automatic switch cannot
lose events or emit duplicated state.

## Errors with synchronized engines

When using `SynchronizedEngine`, finite reads try the primary engine first.
Its default fallback policy only treats `unavailable` and `timeout` as
temporary availability failures. It does not use a fallback for an empty
result, authorization failure, invalid query, conflict, or an unknown error.

Writes still go to the primary first. A replica failure is kept for retry by
the synchronization outbox and is not reported as a failed primary write.
Streams remain connected to the primary and do not switch automatically.

You can provide a custom fallback policy when your application has a more
specific definition of temporary failure. Keep that policy narrow: falling
back for validation or permission errors would hide the actual problem.

## Quick decision guide

| Situation | Recommended response |
| --- | --- |
| `peek` returns `null` | Treat the record as absent. |
| A read returns `[]` | Treat the query as having no matches. |
| `unavailable` or `timeout` | Show temporary-failure UI; retry only when safe. |
| `authentication` | Refresh credentials or ask the user to sign in. |
| `authorization` | Explain that the operation is not permitted. |
| `conflict` or `constraint` | Resolve the conflicting state or input. |
| `invalidQuery` or `invalidData` | Fix the query, model, or data before retrying. |
| `unknown` or a native error | Preserve diagnostics and investigate the cause. |
