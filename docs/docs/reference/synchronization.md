# Synchronization protocol

This page defines the technical protocol implemented by `dorm_sync`. Use
[Using synchronization](../operations/using-synchronization.md) for the
application setup and beginner-friendly explanation.

## Composition boundary

`dorm_sync` composes existing engines:

- one primary is the source of truth for reads and application writes;
- zero or more replicas receive materialized write results;
- finite reads may fall back to replicas when the configured policy allows it;
- streams remain attached to the primary;
- the composition does not implement distributed transactions.

The primary must be adapted from `ChangeTrackedEngine` with `EngineSyncTarget`.
A normal `BaseEngine` can be adapted as a replica with `EngineReplicaTarget`. The
public query and page types of `SynchronizedEngine` are the primary types.

## Write protocol

For an application write:

1. the primary executes the operation and chooses the final identity;
2. the primary returns the normal operation result and an exact change set;
3. the change set is stored in the `SyncOutbox` for each replica;
4. the application receives the primary result;
5. replica delivery is scheduled asynchronously and follows sequence order.

A replica failure does not roll back a successful primary write. The delivery
remains pending for retry. The generic engine does not claim atomicity between
the primary write and outbox insertion.

The delivery guarantee is at-least-once. Replica application must therefore be
idempotent.

## Materialized change sets

A `MutationChangeSet` contains:

| Field | Meaning |
| --- | --- |
| operationId | Stable identifier for one logical operation. |
| sequence | Source order used for per-replica ordering. |
| tableName | `Entity` schema table or collection name. |
| kind | Mutation family. |
| records | Exact affected identities and final serialized data where applicable. |

| Mutation | Recorded result |
| --- | --- |
| `put` | Final model and final identity from the primary. |
| `putAll` | All final models and identities from the primary. |
| `push` | Supplied identified model. |
| `pushAll` | Supplied identified models. |
| `patch` | Final model, or a removal record. |
| `pop` | Removed identity. |
| `popKeys` | Removed identities. |
| `popAll` | Exact identities selected and removed by the primary. |
| `purge` | `Entity`-wide purge marker. |

A replica never re-executes a `patch` callback and never evaluates the original
`popAll` filter against its own data.

`MutationChangeSet` and `SyncOperation` expose JSON-compatible serialization for a
durable outbox. The model data must be supported by the entity codec.

## Reads and fallback

Finite reads call the primary first:

1. call the primary;
2. classify its error with the fallback policy;
3. if the policy rejects the error, rethrow it;
4. otherwise try replicas in configured order;
5. rethrow the last read error if every replica fails.

Fallback applies to `peek`, `peekAll`, `peekPage`, and `peekAllKeys`. A null result or
empty list is a successful result and does not trigger fallback.

Fallback does not apply to `pull`, `pullAll`, or writes. Switching a stream after a
failure could lose events, duplicate snapshots, or change ordering.

Filters and page requests are adapted structurally. The wrapper does not parse
SQL, Firebase paths, MongoDB selectors, or arbitrary query strings. An adapter
must reject unsupported filter capabilities rather than broaden them silently.

## Outbox durability

`MemorySyncOutbox` is process-local and is appropriate when pending deliveries
may be lost at process shutdown. It is not an offline durable queue.

A durable `SyncOutbox` is application-owned. It should persist:

- the `SyncOperation` payload;
- target replica IDs;
- pending and acknowledged state;
- attempt counts;
- failure diagnostics;
- dead-letter state when terminal retries are enabled.

enqueue and acknowledge must be idempotent. A process can crash after a
replica applies a change and before the acknowledgement is persisted.

After restart, a saved `SyncOperation` may not contain its in-process callback.
`SyncOperationResolver` is an explicit registry that maps the saved entity key to
a typed applier. The saved entity key is the table or collection name recorded
in `EntitySchema`.tableName; it is not automatic reflection over Dart types.

The application should load pending deliveries before normal work resumes and
call `SynchronizedEngine`.retry. The generic engine does not choose a retry
interval or start a background worker.

## Delivery lifecycle

Use flush when the caller must wait for deliveries already scheduled by the
current process. Use retry to replay pending deliveries, optionally selecting
operation IDs or replica IDs.

`SyncOutbox`.failures reports the delivery, error, stack trace, and whether a
failure became terminal. maxAttempts can move repeated failures to dead
letters. The application owns dead-letter recovery.

Call close when the composed engine and its outbox are no longer needed. It
waits for scheduled deliveries before closing the outbox stream.

## Identity and schema compatibility

The primary and every replica must agree on:

- logical identity type;
- primary-key count and order;
- entity table or collection name;
- primary-key codec;
- serialized field names and compatible value representations.

The primary's final identity is delivered to the replica. The replica does not
generate a replacement identity. There is no automatic mapping between a
Firebase String key and a PostgreSQL integer key.

## Relationships and transactions

`SynchronizedEngine` uses portable `RelationSource` operations so relationship reads
follow the same primary/fallback boundary. A synchronized relationship may
perform more reads than a native SQL relationship plan.

`SynchronizedEngine` is not a `TransactionalEngine`. A primary local transaction
does not make replica delivery atomic. The package also does not provide
multi-master synchronization, conflict resolution, external replica-change
detection, automatic retry scheduling, or a built-in durable outbox.

See [Framework contracts](framework-contracts.md) for the capability boundary.
