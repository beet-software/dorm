# Migration protocol

This page defines the runtime contract of `dorm_migrations`. It is the canonical
reference for guarantees, adapter capabilities, and failure behavior. For the
beginner workflow, see [Use migrations](../operations/using-migrations.md).

## Migration model

A `Migration` is a named, versioned list of `MigrationOperation` values. The
source migration files are the history of intended changes. The backend stores
which versions completed and a checksum for each completed version.

The runner requires:

- a positive, unique integer version;
- a stable migration name;
- an operation order;
- a matching checksum when a version is already recorded.

Optional `id` and `dependsOn` values describe a dependency graph. The runner
uses a deterministic topological order and rejects unknown dependencies, cycles,
duplicate graph identities, and dependencies that point to a newer version.
Numeric versions remain unique. The graph can order branches and merge points;
it does not resolve conflicting operations.

## Operations

Structural operations describe stored entities and fields:

- `CreateEntityOperation`;
- `DropEntityOperation`;
- `AddFieldOperation`;
- `RemoveFieldOperation`;
- `RenameFieldOperation`;
- `AlterFieldOperation`.

Data operations change existing records:

- `BackfillFieldOperation`;
- `CopyFieldOperation`;
- `RemoveFieldValueOperation`;
- `TransformFieldOperation`.

`CopyFieldOperation` and `RemoveFieldValueOperation` are migration operations,
not *dorm.yaml* settings. The generator rejects the former
`migrations.copyFields` and `migrations.removeValues` settings so that these
decisions remain in the versioned Dart migration source.

`TransformFieldOperation` supports field copying, text trimming and case
changes, and conversion to a logical `MigrationValueType`. It accepts a
structured `FilterExpression`. Arbitrary Dart callbacks are not portable and
are outside the contract.

Provider-specific schema operations are explicit, not inferred from models.
The current contract includes indexes, unique constraints, foreign keys, check
constraints, views, triggers, sequences, and `ProviderMigrationOperation`.
An adapter must reject an unsupported operation with
`MigrationUnsupportedException`; it must not silently reinterpret it.

## Data safety

Adding a required field should normally be split into:

1. add it as nullable;
2. fill existing records;
3. validate the stored data;
4. make it non-nullable.

`@Field(defaultValue: ...)` is a model deserialization default. It is not a
database default and is not automatically a backfill.

When `onlyMissing` is enabled, backfills, copies, and typed transformations
preserve an existing non-null target value. This is the preferred retry mode.
Overwriting data is classified as destructive.

The runner rejects destructive operations by default. The CLI enables them only
with `apply --allow-destructive`, and direct callers must construct the runner
with `MigrationDestructivePolicy.allow`. Opt-in does not create a backup,
rollback, or data-loss protection.

## Execution and history

`MigrationRunner.run`:

1. validates versions and dependencies;
2. obtains the adapter lock or persistent lease;
3. reads the stored history;
4. skips applied migrations after validating their checksums;
5. applies pending operations in order;
6. records a migration only after its operations complete;
7. releases the lock or lease.

An edited migration with an applied version and a different checksum fails.
Legacy history without a checksum is not silently trusted. A failed migration is
not recorded as complete, although operations before the failure may remain
committed when the adapter lacks a transaction boundary.

The runner exposes `status` and `validate` without applying operations.
`status` classifies pending, applied, unknown, legacy, and checksum-inconsistent
history. `validate` performs the same checks and may additionally call the
project's live-schema validation callback.

## Project CLI

The project-owned entrypoint calls `runMigrationCommand` with an opened
`MigrationRuntime` and an explicit list of migrations.

The available commands are:

| Command | Contract |
| --- | --- |
| `apply` | Applies pending migrations. |
| `status` | Reads and classifies migration history. |
| `validate` | Validates history and an optional live schema. |
| `baseline --through <version> --confirm` | Records an existing state without running operations. |
| `resolve --version <version> --confirm` | Records one externally completed migration. |

The helper returns `0` on success, `64` for invalid arguments, and `1` for
opening, validation, execution, or cleanup failures. It does not discover Dart
files or create provider connections.

The generated *migrations/index.dart* is a convenience index and is ignored.
The versioned migration files must be imported explicitly or through a
regenerated index.

## Locks and transactions

Locks and transactions solve different problems:

- a lock prevents concurrent runners from starting the same migration work;
- a transaction controls which completed operations can be rolled back.

Adapters declare their strongest transaction boundary with
`TransactionalMigrationAdapter`:

| Mode | Guarantee |
| --- | --- |
| `migration` | Operations and the history record share one transaction when the provider honors it. |
| `operation` | Each operation has its own transaction boundary; earlier operations may remain after a later failure. |
| `none` | No migration transaction is available; completed work may remain. |

The official adapters currently expose these boundaries:

| Adapter | Transaction mode | Lock mode |
| --- | --- | --- |
| MySQL | `operation` | backend advisory lock |
| PostgreSQL | `migration` | backend advisory lock |
| SQLite | `migration` | local adapter lock |
| Firebase Realtime Database | `none` | persistent lease |
| Cloud Firestore | `none` | persistent lease |

A local lock protects only one process. A persistent lease has an owner,
expiration, and fencing value; losing it fails the migration instead of
reporting success. A lease does not remove provider outages, clock, permission,
or deployment risks.

There is no distributed transaction between engines, and the contract provides
no universal rollback.

## Large document operations

Document adapters use `DocumentMigrationPagingBackend` when available. They
read stable pages, write each page, and persist a checkpoint after the page
finishes. Firebase Realtime Database and Cloud Firestore provide this paging
path.

`DocumentMigrationPerformanceOptions` controls the default page size, an
optional pause between pages, and an optional maximum number of pages in one
invocation. Data operations may override the page size with `batchSize`.

When the maximum is reached, the adapter stores the cursor and reports
`DocumentMigrationBatchLimitException`. Running the same migration again
continues from that checkpoint. Processing is at-least-once, not exactly-once:
a page may be attempted again, so operations must be idempotent.

A custom document backend without stable paging retains the full-read path and
cannot resume inside that read. Large document changes are not one global
transaction.

## SQL preview and schema inspection

`SqlMigrationAdapter.preview` creates a `SqlMigrationScript` without opening
or calling a provider connection:

```dart
final script = await adapter.preview(migrations);
print(script.sql);
```

Each statement retains its migration version, operation index, placeholders,
and parameters. The preview does not inspect the live schema or include the
history record. It is a review aid, not a live dry-run guarantee.

SQL adapters implement `MigrationSchemaInspector`. They can compare a normalized
expected snapshot with tables, fields, logical types, nullability, defaults,
and primary keys. The inspector does not validate every provider object,
permission, security rule, trigger body, index option, or external schema tool.

Document adapters do not claim complete schema inspection: an absent field may
simply be absent from one document.

## Baseline, resolve, and compaction

`baseline` records all migrations through a selected version without executing
them. `resolve` records one migration after an external tool or operator has
completed it. Both require explicit confirmation and checksum validation, but
neither proves that the external change really matches the migration.

`MigrationRunner.compact` can replace completed history through a selected
version with an externally prepared replacement migration. It records the
replacement without executing its operations and requires
`MigrationHistoryCompactionAdapter`. The replacement operations remain
available for a new database starting from empty.

Compaction is forward-only. It does not restore removed history, provide
rollback, or make a non-transactional adapter atomic.

## Generated schema and diff

The generator compares the current analyzed models with
*migrations/schema.json*. It does not compare directly with the live database.
The snapshot stores logical types, names, nullability, primary keys,
relationships, model defaults as metadata, and optional SQL type overrides.

The generator can create structural operations and explicit data-operation
candidates. It does not safely infer:

- whether a removed field was renamed;
- whether a new required field has a valid backfill;
- indexes, constraints, security rules, or provider objects;
- a physical SQL type from a Dart type alone.

Review and edit the generated migration before applying it. The decision becomes
part of the versioned Dart migration and its checksum.

## Adapter contract

A backend integrates migrations by implementing `MigrationAdapter` and storing
history in a backend-owned location. The adapter must:

- apply operations in the requested order;
- provide a lock covering the runner operation;
- record the checksum only after successful completion;
- make retryable data operations idempotent;
- reject operations it cannot represent safely.

Optional capabilities include `TransactionalMigrationAdapter`,
`MigrationLeaseAdapter`, `MigrationSchemaInspector`,
`MigrationHistoryCompactionAdapter`, and document paging/context adapters.
Capabilities are additive; `BaseEngine` does not require migration support.

Provider-specific code stays in the engine package. Custom adapters must not
claim stronger atomicity, lock, schema, or retry guarantees than their backend
can prove.

## Compatibility boundaries

Migrations are explicit and forward-only. They do not provide:

- universal rollback;
- automatic branch conflict resolution;
- distributed transactions;
- complete document-store schema introspection;
- automatic runtime discovery or application;
- a universal physical SQL type;
- persistent migration history for MongoDB, HTTP, memory, or BLoC;
- automatic identity conversion between backends.

For provider, server, permission, rule, or deployment compatibility not
established by the repository, consult the selected engine guide and provider
documentation. Verify the deployment environment before relying on a
provider-specific migration feature.

See [Engine and platform support](engine-support.md) for the canonical backend
matrix and [Use migrations](../operations/using-migrations.md) for the safe
user workflow.
