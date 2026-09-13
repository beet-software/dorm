# dorm_migrations

`dorm_migrations` runs explicit, ordered migrations through the optional
contracts from `dorm_framework`. It separates the description of a change from
the provider-specific code that applies it.

Use the adapter supplied by an engine that supports `MigrationCapableEngine`, or
implement `MigrationAdapter` for a custom backend. The runner records a
checksum only after a migration completes and rejects edits to an already
recorded version.

Supported official adapters currently cover MySQL, PostgreSQL, SQLite, Firebase
Realtime Database, and Cloud Firestore. MongoDB, HTTP, memory, and BLoC do not
provide persistent migration history.

## Runtime behavior

`MigrationRunner` validates versions and dependencies, obtains the adapter lock
or lease, skips verified history entries, applies pending operations, and
records completed migrations. A failed migration is not marked complete, but a
backend without a transaction can leave earlier operations committed.

Destructive operations are rejected by default. Enable them only after review
with `MigrationDestructivePolicy.allow` or the CLI option
`apply --allow-destructive`. This opt-in does not provide rollback or backups.

Operations include structural changes, data backfills and copies, typed data
transformations, and explicit provider-specific schema operations. Unsupported
operations fail with `MigrationUnsupportedException`.

## Project commands

Create an entrypoint such as *tool/migrations.dart* that opens the connection,
obtains `engine.migrationAdapter`, imports the migration list, and closes the
connection. Then run:

```shell
dart run tool/migrations.dart status
dart run tool/migrations.dart validate
dart run tool/migrations.dart apply
```

The helper also supports `baseline` and `resolve` for explicitly recording
state completed outside the runner. It does not discover Dart files or create
provider connections.

See [Use migrations](https://ezgrs.github.io/dorm/operations/using-migrations/)
for the complete beginner workflow and recovery guidance.

## SQL preview

`SqlMigrationAdapter.preview` creates a `SqlMigrationScript` without calling
the provider. Statements retain migration and operation metadata, placeholders,
and parameters:

```dart
final script = await adapter.preview(migrations);
print(script.sql);
```

This is a dialect-specific review aid. It does not inspect the live schema or
include the history record.

## Large document operations

`DocumentMigrationAdapter` supports stable paging when the backend implements
`DocumentMigrationPagingBackend`. It stores a checkpoint after each completed
page and can continue after a failure. `DocumentMigrationPerformanceOptions`
controls page size, pauses, and an optional page limit.

Processing is at-least-once, so backfills, copies, and transformations must be
idempotent. Firebase Realtime Database and Cloud Firestore provide persistent
leases; a local lock protects only one process.

## History and branches

`MigrationRunner.compact` can replace completed history with an externally
prepared migration when the adapter implements
`MigrationHistoryCompactionAdapter`. It records the replacement without
executing its operations and is not a rollback mechanism.

`Migration.id` and `Migration.dependsOn` can describe branches and merge
points. Versions remain unique, and the graph does not resolve conflicting
operations automatically.

## Limits

The package does not provide universal rollback, distributed transactions,
automatic rename inference, complete document schema inspection, or a
universal physical SQL type. See [Migration protocol](https://ezgrs.github.io/dorm/reference/migrations/)
and [Engine and platform support](https://ezgrs.github.io/dorm/reference/engine-support/)
for the normative contracts and backend differences.
