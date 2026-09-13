# Use migrations

This guide explains how to change a database safely as your models change. A
migration is a small, named description of one change. It is reviewed as code,
then applied to the database by a command owned by your project.

The process has two separate parts:

- the generator compares your current models with a saved snapshot and writes a
  Dart migration;
- the migration runner opens your configured database connection and applies
  pending migrations in order.

Generating a migration never connects to a database and never changes stored
data.

## Before you start

Migrations are available only through an engine that exposes a
`MigrationCapableEngine`. MySQL, PostgreSQL, SQLite, Firebase Realtime Database,
and Cloud Firestore provide adapters in the current repository. MongoDB, HTTP,
memory, and BLoC do not provide persistent migration history.

The database connection, credentials, permissions, backups, and deployment
environment remain the responsibility of your project. Test a migration on a
copy or staging database before using it on production data.

## Create the first baseline

After defining your first models, save the model schema:

```shell
dart run dorm_generator:migrate initialize --input lib/models.dart
```

This creates *migrations/schema.json*. It records the schema known by the
project; it does not create tables or collections and does not write migration
history to a backend.

If the database is empty and must be created by migrations, generate the first
migration instead:

```shell
dart run dorm_generator:migrate diff \
  --input lib/models.dart \
  --from-empty \
  --name initial
```

Do not use `initialize` as a replacement for that initial migration when the
database still needs its schema.

`initialize` refuses to replace an existing snapshot. Use `--force` only when
you intentionally want to establish a new baseline and have checked its
effect on the migration history.

## Generate a migration

Change the annotated model, then compare it with the previous snapshot:

```shell
dart run dorm_generator:migrate diff \
  --input lib/models.dart \
  --name add-active
```

The command writes the next numbered file under *migrations/* and updates the
snapshot only after the migration and generated index have been written. If no
schema changed, it creates no migration.

The generated *migrations/index.dart* is ignored and is not the source of
truth. Rebuild it from the versioned migration files after a fresh clone or in
CI:

```shell
dart run dorm_generator:migrate index
```

The migration source files and snapshot should be reviewed and committed. The
index can be recreated at any time.

## Review before applying

Treat every generated migration as a proposal. Open the Dart file and verify:

- the entity and stored field names are the intended ones;
- a removed field is really being removed, rather than renamed;
- a new required field is added, filled, and made required in safe stages;
- a data transformation handles existing values and can be retried;
- destructive operations are intentional;
- provider-specific operations match the selected backend.

The generator does not infer renames. If an old field and a new field represent
the same data, replace the generated add/remove pair with an explicit
`RenameFieldOperation`. That decision belongs in the versioned migration file,
not in a temporary configuration entry.

The `defaultValue` in `@Field` is used while reading model data. It is not
automatically a database default and is not automatically written to existing
records. Add a `BackfillFieldOperation` when existing records need a value.

For a new required field, prefer this sequence:

1. add the field as nullable;
2. backfill existing records with an explicit value or transformation;
3. validate the stored data;
4. make the field non-nullable.

The optional `operationValidator` callback can perform project-specific checks
before an operation reaches the adapter. It does not replace a review of the
data or provide a universal query language.

## Create the project entrypoint

The generator does not know how your application opens a database. Create an
entrypoint such as *tool/migrations.dart*. It imports the generated index,
creates the engine, obtains its `MigrationAdapter`, and closes the connection.

```dart
import 'dart:io';

import 'package:dorm_migrations/dorm_migrations.dart';
import 'package:dorm_sqlite_database/dorm_sqlite_database.dart';
import 'package:sqlite_async/sqlite_async.dart';

import '../migrations/index.dart';

Future<MigrationRuntime> openRuntime() async {
  final database = SqliteDatabase(path: '[your database path]');
  final engine = Engine(database);

  return MigrationRuntime(
    adapter: engine.migrationAdapter,
    close: database.close,
  );
}

Future<void> main(List<String> arguments) async {
  final int result = await runMigrationCommand(
    arguments,
    open: openRuntime,
    migrations: migrations,
  );

  if (result != 0) exit(result);
}
```

The connection is opened only when the entrypoint is run. The migration helper
does not discover Dart files, read credentials, or create a provider connection.

## Check and apply

Before changing data, inspect the recorded history:

```shell
dart run tool/migrations.dart status
dart run tool/migrations.dart validate
```

`status` reports pending, applied, unknown, legacy, and checksum-inconsistent
entries. `validate` performs the same history checks and can also run the
project's optional live-schema validation. A pending migration is expected;
checksum differences and schema drift require investigation.

Apply pending migrations with:

```shell
dart run tool/migrations.dart apply
```

The command opens the connection, acquires the adapter's lock, applies pending
migrations in dependency order, records each completed migration, releases the
lock, and closes the connection. A migration is not recorded as complete until
all of its operations finish.

The runner rejects operations classified as destructive. If the reviewed
migration intentionally removes or overwrites data, opt in explicitly:

```shell
dart run tool/migrations.dart apply --allow-destructive
```

That flag does not create a backup or rollback plan.

## Recover from a failed run

A migration can change some records before it reports an error when the
backend cannot put the whole migration in one transaction. Prepare for that
possibility before applying anything.

### Before applying

1. Make a recent backup, or use a restored copy in staging.
2. Confirm that no other deployment or operator is running migrations for the
   same database.
3. Rebuild the generated migration index if this is a fresh clone:

   ```shell
   dart run dorm_generator:migrate index
   ```

4. Check the recorded history:

   ```shell
   dart run tool/migrations.dart status
   dart run tool/migrations.dart validate
   ```

5. Read the migration Dart file from top to bottom. Check every field removal,
   rename, backfill, transformation, index, and provider-specific operation.
6. For SQL, inspect the generated statements before connecting:

   ```dart
   final script = await sqlAdapter.preview(migrations);
   print(script.sql);
   ```

7. Confirm that the project has the required credentials and permissions.
   Check the engine guide for provider-specific rules, versions, and
   deployment requirements.
8. If the migration is destructive, apply it only when the data loss is
   intentional and the backup has been tested. The command requires:

   ```shell
   dart run tool/migrations.dart apply --allow-destructive
   ```

### If the command fails

Do not immediately run the same command again.

1. Save the command output, error message, stack trace, and migration version.
2. Stop other deployments that could start the same migration.
3. Check whether the adapter lock or lease is still held. Do not remove it
   manually unless the adapter documentation says that it is safe.
4. Inspect the database or document store to determine which operations and
   records were changed.
5. Run `status` and `validate` again. A checksum difference means that
   an applied migration was edited or the history is inconsistent; restore the
   original file instead of changing it again.
6. Decide whether the failed operations are safe to repeat. A retry is safe
   only when the operation is idempotent and the current data is consistent.

Firebase Realtime Database and Cloud Firestore save checkpoints for paged
document operations. A retry can resume from the last checkpoint, but the
last page may be attempted again. This is why backfills, copies, removals,
and transformations must be safe to repeat.

### Choose the recovery

- If the state is consistent and the remaining operations are idempotent,
  correct the cause and retry the same migration.
- If data is missing, duplicated, or inconsistent, stop and restore the backup
  or repair the data before retrying.
- If only part of the migration completed and it cannot be safely repeated,
  create a new forward migration that repairs the observed state. Do not edit
  the migration that already ran.
- Use `baseline` or `resolve` only when an external tool has completed the
  intended change and you have independently verified the result:

  ```shell
  dart run tool/migrations.dart baseline --through <version> --confirm
  dart run tool/migrations.dart resolve --version <version> --confirm
  ```

  These commands record history only. They do not execute, inspect, or repair
  the missing operation.

### Retry safely

1. Fix the connection, permission, data, or migration issue that caused the
   failure.
2. Keep the migration version and source unchanged if it was already recorded.
3. Run `status` and `validate` before retrying.
4. Use `--allow-destructive` only if the reviewed migration still intentionally
   performs a destructive operation.
5. After success, run `status` and `validate` again and keep the output with
   the deployment record.

## Data changes and backend-specific features

Use `BackfillFieldOperation`, `CopyFieldOperation`,
`RemoveFieldValueOperation`, or `TransformFieldOperation` for existing data.
Keep transformations in the supported typed vocabulary. Arbitrary Dart
callbacks cannot be reproduced safely by every adapter.

Add these operations directly to the generated Dart migration. The generator
does not accept `migrations.copyFields` or `migrations.removeValues` in
*dorm.yaml*; keeping data changes in the versioned migration file prevents a
configuration entry from being repeated by a later `diff`.

Indexes, foreign keys, checks, views, triggers, sequences, and provider SQL
are explicit operations rather than automatic consequences of a model change.
Check the [engine support reference](../reference/engine-support.md) before
using them. Unsupported operations fail explicitly; they are not silently
ignored.

For SQL, review a dialect-specific script without opening the database:

```dart
final script = await sqlAdapter.preview(migrations);
print(script.sql);
```

This is a review aid, not a live dry run: it does not inspect the current schema
or include the migration-history write.

## What migrations do not do

The current API does not provide:

- universal rollback;
- distributed transactions across engines;
- identical transaction guarantees for every backend;
- automatic rename or backfill inference;
- complete live-schema inspection for document stores;
- automatic discovery or application of migration files;
- automatic conflict resolution between migration branches;
- persistent migration history for MongoDB, HTTP, memory, or BLoC;
- a universal physical SQL type such as `VARCHAR(255)`.

These boundaries are intentional. Use provider tools, backups, staging, and
forward repair migrations when a project needs behavior outside the portable
contract. Check the engine guide and provider documentation before relying on
backend-specific behavior, especially for permissions, rules, versions, and
deployment settings.

For the exact contracts and capability boundaries, see
[Migration protocol](../reference/migrations.md).
