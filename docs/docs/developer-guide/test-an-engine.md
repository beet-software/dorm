# Test an engine

Validate an engine in the same order in which its code is built:

1. regenerate generated inputs when needed;
2. analyze the affected package and examples;
3. run tests that do not require an external service;
4. run opt-in integration tests with the backend configured.

## Use the shared compliance suite

`dorm_test` contains the canonical portable engine suite. An engine-specific
test package supplies an adapter that opens the engine, resets its data, and
closes it after the tests.

The shared suite covers portable repository behavior such as:

- simple identity creation and explicit identity creation;
- reads, filters, ordering, pagination, and empty results;
- updates, patches, removals, and purges;
- serialization and deserialization;
- all four relationship forms;
- initial stream reads.

Keep engine-package tests for behavior that is specific to the driver, query
language, connection lifecycle, schema setup, or backend error handling. Do
not duplicate portable CRUD tests in every engine package when the compliance
adapter already covers them.

## Regenerate before analysis

Run generation from the package or example directory that owns the annotated
source:

```shell
dart pub get
dart run build_runner build --delete-conflicting-outputs
dart analyze
```

For a test suite whose generated files are test inputs, the workspace workflow
may use:

```shell
dart run build_runner build test
```

Edit the source annotations or generator inputs rather than generated output.

## Run local and workspace tests

For a package that does not need an external backend:

```shell
dart test
```

For the whole workspace, run from the repository root:

```shell
melos run analyze
melos run test --no-select
```

The in-memory and BLoC engines can run their compliance tests without a database
server. Database and service-backed engines skip their integration groups when
the required environment is not configured.

## Configure backend integration tests

Run an engine's live tests only after preparing the service and environment
variables documented on that engine's page. The current integration suites use
opt-in configuration for PostgreSQL, MySQL, MongoDB, and Firebase. The HTTP
engine uses mocked clients for unit tests and requires an API contract for live
integration coverage.

For MongoDB, for example, set `MONGO_URI` from the package directory before
running its tests:

```shell
set MONGO_URI=[PLACEHOLDER: MongoDB connection URI]
dart test
```

On PowerShell, use `$env:MONGO_URI = '[PLACEHOLDER: MongoDB connection URI]'`
instead of `set`. Tests without the required variable do not establish live
backend compliance.

## Interpret a failing step

The first failing command usually identifies the layer to inspect:

| Failure | Inspect first |
| --- | --- |
| Generation fails | Annotated source, parts, or generator validation. |
| Analysis fails | Dart types, imports, or stale generated output. |
| Shared compliance test fails | The framework contract or the adapter lifecycle. |
| `Engine`-specific unit test fails | Query translation, serialization, or driver behavior. |
| Integration test fails | Connection, credentials, schema, service, or backend state. |

Keep the original exception and stack trace. An official external engine maps
recognized provider failures to `DormDatabaseException`; a custom engine may
keep its native provider errors.
