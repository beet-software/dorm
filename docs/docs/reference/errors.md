# Portable database errors

The framework exposes one error type for failures reported by the supported
external engines: `DormDatabaseException`. It keeps the original provider
error in `cause`, the original `StackTrace` in `stackTrace`, and provider
metadata in `engine`, `operation`, and `providerCode`.

This does not change normal absence results. `peek` still returns `null` when a
record is absent, and collection reads still return an empty list. A
`notFound` error is reserved for a provider operation that explicitly reports a
missing resource as a failure.

## Classify the portable category

Use `kind` for application behavior that should work with more than one
engine:

| Kind | Meaning |
| --- | --- |
| `unavailable` | The service or connection is temporarily unreachable. |
| `timeout` | The provider exceeded a time limit. |
| `authentication` | Credentials are missing or rejected. |
| `authorization` | The credentials do not have permission. |
| `notFound` | The provider reports a missing resource as an error. |
| `conflict` | The operation conflicts with the current resource state. |
| `constraint` | A database constraint rejected the operation. |
| `invalidQuery` | The query is invalid for the provider. |
| `invalidData` | Provider data could not be decoded or validated. |
| `transaction` | A transaction was aborted or could not complete. |
| `cancelled` | The operation was explicitly cancelled. |
| `unsupported` | The provider does not support the requested operation. |
| `unknown` | dORM could not classify the provider failure. |

`retryability` is separate from `kind`. `safe` means the provider indicates
that retrying is safe; `never` means it should not be retried automatically;
`unknown` means the application must decide. An unknown error is never used by
the default synchronization fallback.

## Catch an error from a repository operation

```dart
try {
  await dorm.users.repository.put(creation);
} on DormDatabaseException catch (error, stackTrace) {
  switch (error.kind) {
    case DormErrorKind.unavailable:
    case DormErrorKind.timeout:
      scheduleRetry();
    case DormErrorKind.authentication:
      await refreshSession();
    case DormErrorKind.authorization:
      showPermissionError();
    case DormErrorKind.conflict:
    case DormErrorKind.constraint:
      showConflictError();
    default:
      report(error, stackTrace);
  }
}
```

Use `cause` only when a provider-specific detail is required. Portable code
should prefer `kind` and `retryability`, because the class of the native error
can differ between HTTP, SQL, Firebase, and MongoDB.

## Stream errors

The same conversion is applied to errors emitted by finite relationship reads
and by `pull`/`pullAll` streams. A stream reports the exception through its
error channel:

```dart
final subscription = dorm.users.repository.pullAll().listen(
  renderUsers,
  onError: (Object error, StackTrace stackTrace) {
    if (error case DormDatabaseException(:final kind)) {
      logDatabaseFailure(kind, stackTrace);
    }
  },
);
```

Validation errors raised by dORM before a provider call, such as
`ArgumentError`, `StateError`, `UnsupportedError`, and `FormatException`, are
left as their original Dart errors. Engines that do not implement
`ErrorAwareEngine` also keep their native errors unchanged.

## Engine-specific details

The official adapters normalize recognized errors at their provider boundary:
HTTP status codes, SQLSTATE/error codes, SQLite result codes, Firebase error
codes, and MongoDB error codes are retained in `providerCode`. The original
exception remains available through `cause`; no provider detail is discarded.

When a provider introduces a code that dORM does not know, the result is
`DormErrorKind.unknown` with `DormRetryability.unknown`. That conservative
classification prevents an accidental retry or fallback.