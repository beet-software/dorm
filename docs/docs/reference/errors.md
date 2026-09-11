# Portable errors

This page defines the error contract shared by official external engines. Use
[Handling errors](../build-the-store/handling-errors.md) for application
decisions such as retrying, showing a message, or handling a stream error.

## The portable exception

Recognized provider failures are exposed as DormDatabaseException. It preserves:

- kind: the portable category;
- retryability: whether automatic retry is safe;
- message: a human-readable description;
- engine: the dORM engine that reported the failure;
- operation: the operation being attempted, when known;
- providerCode: the original provider status or code;
- cause: the original provider exception;
- stackTrace: the provider stack trace.

The original provider error is not discarded. Application code can use kind and
retryability for portable behavior and inspect cause or providerCode for
provider-specific diagnostics.

## Error categories

| Kind | Contract |
| --- | --- |
| unavailable | The service or connection is temporarily unreachable. |
| timeout | The provider exceeded a time limit. |
| authentication | Credentials are missing or rejected. |
| authorization | The credentials do not have permission. |
| notFound | The provider explicitly reports a missing resource as a failure. |
| conflict | The operation conflicts with the current resource state. |
| constraint | A database constraint rejected the operation. |
| invalidQuery | The provider rejected the query. |
| invalidData | Provider data could not be decoded or validated. |
| transaction | A transaction was aborted or could not complete. |
| cancelled | The operation was cancelled. |
| unsupported | The provider does not support the requested operation. |
| unknown | dORM cannot classify the provider failure. |

Absence is not an error category in normal repository reads. peek returns null
and collection reads return empty lists when nothing exists.

## Retryability is separate

DormRetryability has three values:

| Value | Meaning |
| --- | --- |
| never | Do not automatically retry. |
| safe | The provider indicates that retrying is safe. |
| unknown | The application must decide. |

An unavailable or timeout error may still have unknown retryability. In
particular, repeating a write after a lost response can create a duplicate
effect unless the operation is idempotent.

## Provider mapping boundary

Each official external engine maps errors at its provider boundary:

| Engine family | Preserved provider detail |
| --- | --- |
| HTTP | Status code and response context. |
| PostgreSQL | SQLSTATE and driver exception. |
| MySQL | Server/client error code and exception. |
| SQLite | Result and extended result codes. |
| Firebase and Firestore | Firebase error code and exception. |
| MongoDB | Driver code/name and exception. |

Memory and BLoC do not currently implement ErrorAwareEngine because they do not
have an external provider taxonomy to normalize.

An engine without ErrorAwareEngine may propagate its native errors. Validation
errors raised before a provider call, including ArgumentError, StateError,
UnsupportedError, and FormatException, remain ordinary Dart errors.

## Streams and relationships

The same mapping applies to errors emitted by supported provider-backed
relationships and streams. A stream reports a later failure through its error
channel; wrapping the code that creates the stream does not catch that later
event.

A backend may expose a provider-native error when the failure occurs outside
its mapped provider boundary. The application should retain a final handler
for errors that are not DormDatabaseException.

## Synchronization interaction

SynchronizedEngine uses the portable classification as its default finite-read
fallback policy. Only unavailable and timeout are considered availability
failures by that default policy. Unknown, authorization, validation, conflict,
and programming errors do not trigger fallback.

Replica delivery failures remain observable through the synchronization outbox.
They are not converted into a failed primary operation.

See [Framework contracts](framework-contracts.md) for ErrorAwareEngine and
[Engine and platform support](engine-support.md) for engine coverage.