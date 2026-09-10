# Synchronize database engines

The optional dorm_sync package composes existing dORM engines into one
unidirectional synchronization boundary:

- one primary target is the source of truth;
- zero or more replicas receive application writes;
- finite reads use the primary and may fall back to replicas;
- streams remain attached to the primary;
- writes are delivered to replicas with at-least-once semantics.

This is useful when an application needs a local cache, a read replica, a
secondary database, or a process-local offline target. It is not a distributed
transaction coordinator and it does not reconcile changes made directly to a
replica.

For the task-oriented setup, see [Using synchronization](../build-the-store/using-synchronization.md).

## Package and imports

Add dorm_sync together with the engine packages used by the application:

~~~yaml
dependencies:
  dorm_framework: ^2.0.0-dev.2
  dorm_memory_database: ^2.0.0-dev.2
  dorm_sync: ^2.0.0-dev.2
~~~

Import the public barrel:

~~~dart
import 'package:dorm_sync/dorm_sync.dart';
~~~

The synchronization package depends only on dorm_framework at runtime. Its tests
use dorm_memory_database, but applications can adapt any engine that satisfies
the required capability contracts.

## The composition boundary

The normal generated Dorm API does not change. The composed engine is passed to
the same generated facade as any other BaseEngine:

~~~dart
final primaryTarget = EngineSyncTarget<Query<Object>, OffsetPageRequest>(
  primaryEngine,
  id: 'primary',
);

final replicaTarget = EngineReplicaTarget<Query<Object>, OffsetPageRequest>(
  replicaEngine,
  id: 'replica',
);

final synchronizedEngine =
    SynchronizedEngine<Query<Object>, OffsetPageRequest>(
      primary: primaryTarget,
      replicas: [replicaTarget],
      outbox: MemorySyncOutbox(),
      fallback: (error, stackTrace) {
        return error is DatabaseUnavailableException;
      },
    );

final dorm = Dorm(synchronizedEngine);
~~~

DatabaseUnavailableException above is an application-defined example. dORM
does not provide one common availability exception. The fallback callback must
classify errors using the concrete backend's error types.

The primary target must be a SyncMutationTarget. EngineSyncTarget is the
standard adapter for a ChangeTrackedEngine, which can report the exact result
of each mutation.

A replica target must be a SyncReadApplyTarget. EngineReplicaTarget adapts a
normal BaseEngine: it can read for finite-read fallback and can apply
materialized change sets, but it does not need to generate or report changes.
A replica can also use a custom SyncReadApplyTarget when the application owns
the adapter.

Every target needs a unique stable id. The id is persisted in outbox delivery
records, so it must not change between process runs.

## What happens during a write

A write through the generated repository follows this sequence:

1. The synchronized reference executes the mutation on the primary.
2. The primary returns its normal result and an exact MutationChangeSet.
3. The change set is inserted into the configured SyncOutbox, once for each
   replica.
4. The application receives the primary result. Replica delivery is scheduled
   asynchronously.
5. The coordinator delivers the materialized change set to each replica in
   sequence order.

The primary write is not rolled back when a replica is unavailable. A failed
delivery remains pending, and the application can inspect or retry it.

This means the visible guarantees are:

- primary-first writes;
- ordered delivery per replica;
- at-least-once delivery;
- idempotent replay required from the replica operation;
- no atomicity between primary and replicas.

There is one important boundary: the framework cannot guarantee atomicity
between the primary write and the outbox insertion. A backend-specific
implementation may provide that guarantee, but the generic SynchronizedEngine
does not claim it.

## Change sets

Change sets are backend-neutral and contain:

| Field | Meaning |
| --- | --- |
| operationId | Stable id used to deduplicate a logical operation. |
| sequence | Monotonic source order used to preserve per-replica ordering. |
| tableName | Entity schema table or collection name. |
| kind | The original mutation family. |
| records | Exact affected identities and final serialized data. |

The records are materialized before replica delivery. A replica does not
re-execute application callbacks or recalculate filters.

| Mutation | Recorded information |
| --- | --- |
| put | Final model and final identity returned by the primary. |
| putAll | All final models and identities returned by the primary. |
| push | The supplied identified model. |
| pushAll | The supplied identified models. |
| patch | The final model, or a null data record when the callback removes it. |
| pop | The removed identity. |
| popKeys | The removed identities. |
| popAll | The exact identities selected and removed by the primary. |
| purge | An entity-wide purge marker. |

For example, a popAll change set contains the identities found by the primary
before deletion. The replica never evaluates the original filter against its
own state, which prevents divergent filters from deleting the wrong records.

MutationChangeSet, MutationRecord, and SyncOperation expose toJson and
fromJson-compatible data for durable outboxes. The model data must itself be
JSON-compatible according to the entity codec.

## Reads and fallback

The composed reference performs finite reads in this order:

1. call the primary;
2. if the primary throws, call fallback with the error and stack trace;
3. if fallback returns false, rethrow the original primary error;
4. if fallback returns true, try replicas in their configured order;
5. rethrow the last read error if every eligible replica fails.

An empty list or null result is a valid result. It does not trigger fallback.

Fallback applies to:

- peek;
- peekAll;
- peekPage;
- peekAllKeys.

Fallback does not apply to:

- pull;
- pullAll;
- writes.

Streams stay on the primary because changing sources after a stream error could
lose events, duplicate snapshots, or change ordering. If an application needs
stream recovery, it must define that policy above the dORM stream.

The composed engine uses the primary query and page types in its public API.
Each target converts the structured FilterExpression and PageRequest to its own
backend representation. It never parses SQL, Firebase paths, MongoDB selectors,
or arbitrary query strings.

For a backend with a different query or page type, provide adapters when
constructing EngineSyncTarget or EngineReplicaTarget:

~~~dart
final replicaTarget = EngineReplicaTarget<ReplicaQuery, ReplicaPage>(
  replicaEngine,
  id: 'replica',
  compileFilter: (expression) {
    return ReplicaFilter.fromExpression(expression);
  },
  mapPage: (request) {
    return ReplicaPage.fromPageRequest(request);
  },
);
~~~

The adapter must reject unsupported filter capabilities explicitly. It should
not silently broaden a filter or return a different page window.

## Durable outboxes

MemorySyncOutbox is process-local. It is suitable for tests and applications
where losing pending deliveries at process shutdown is acceptable. It does not
provide offline durability.

A durable outbox is application-owned and implements SyncOutbox. It should
persist at least:

- the SyncOperation JSON payload;
- the target replica id for each delivery;
- the pending or acknowledged state;
- attempt count;
- last error and stack trace representation;
- dead-letter state, if the application uses terminal retries.

The outbox must make enqueue idempotent by operationId. It must also make
acknowledge idempotent, because a process can crash after a replica applies a
change but before the acknowledgement is persisted.

After a restart, the outbox may return a SyncOperation without its in-process
callback. Register a SyncOperationResolver on SynchronizedEngine:

~~~dart
final resolver = (String entityKey) {
  switch (entityKey) {
    case 'users':
      return (target, changeSet) => target.apply(userEntity, changeSet);
    case 'orders':
      return (target, changeSet) => target.apply(orderEntity, changeSet);
    default:
      throw StateError('Unknown synchronization entity: $entityKey');
  }
};

final engine = SynchronizedEngine<Query<Object>, OffsetPageRequest>(
  primary: primaryTarget,
  replicas: [replicaTarget],
  outbox: durableOutbox,
  fallback: (_, _) => false,
  resolver: resolver,
);
~~~

The resolver is an application registry. The table name in a change set is not
a Dart type name and should not be used as an unchecked dynamic dispatch key.

A durable outbox should load pending deliveries before the application begins
normal work, then call SynchronizedEngine.retry. The generic engine does not
start a background worker or choose a retry interval.

## Failures, retries, and lifecycle

Use flush after a write when the caller must wait until deliveries scheduled by
the current process have finished attempting:

~~~dart
await dorm.users.repository.push(user);
await synchronizedEngine.flush();
~~~

Use retry for pending deliveries. It can be restricted to selected operations
or replicas:

~~~dart
await synchronizedEngine.retry(
  operationIds: ['operation-123'],
  replicaIds: ['replica'],
);
~~~

The outbox failures stream reports:

- the delivery;
- the error;
- its stack trace;
- whether the failure is terminal.

Set maxAttempts to move a repeatedly failing delivery to the outbox's
dead-letter collection:

~~~dart
final engine = SynchronizedEngine<Query<Object>, OffsetPageRequest>(
  primary: primaryTarget,
  replicas: [replicaTarget],
  outbox: durableOutbox,
  fallback: (_, _) => false,
  maxAttempts: 5,
);

await for (final SyncFailure failure in durableOutbox.failures) {
  logSyncFailure(failure);
}
~~~

A terminal delivery is no longer returned by pending. The application must
define a recovery process for dead letters, such as fixing the target and
re-enqueuing a verified operation.

Call close when the composed engine and its outbox are no longer needed:

~~~dart
await synchronizedEngine.close();
~~~

The close operation waits for deliveries already scheduled by the coordinator
before closing the outbox stream.

## Identity and schema compatibility

The primary and each replica must agree on:

- the logical identity type;
- the number and order of primary keys;
- entity table or collection name;
- primary-key codec;
- serialized field names and compatible value representations.

The primary's final identity is always delivered to the replica. The replica
does not generate a replacement id.

There is no automatic mapping between incompatible identities such as a Firebase
String key and a PostgreSQL integer key. Add an explicit application mapping
layer before using those engines together.

A change set with a different table name or primary-key shape is rejected before
the replica operation is executed.

## Relationships

SynchronizedEngine creates portable relationship implementations based on
RelationSource. This keeps finite relationship reads inside the primary/fallback
policy instead of calling a backend-native relationship planner directly.

The consequence is intentional: a synchronized relationship can perform more
reads than a MySQL or PostgreSQL relationship plan optimized for joins. The
relationship result remains engine-neutral, but query-count and join
optimizations belong to the concrete backend.

## Transactions and unsupported assumptions

SynchronizedEngine does not implement TransactionalEngine. The following code
must not be inferred to be distributed:

~~~dart
final TransactionalDorm<Query<Object>, OffsetPageRequest> tx =
    TransactionalDorm(synchronizedEngine);
~~~

Instead, use a transaction-capable concrete engine before composing it, or
define a future synchronization strategy explicitly. A local transaction on
the primary does not automatically make replica delivery atomic.

The current package also does not provide:

- replica-to-primary synchronization;
- conflict resolution;
- external replica change detection;
- distributed transactions;
- automatic identity conversion;
- a built-in durable outbox implementation;
- automatic retry scheduling;
- a guarantee that primary and outbox writes are atomic together.

## Choosing the right setup

Use a synchronized engine when the primary remains authoritative and replicas
can tolerate eventual consistency.

Use a normal engine when the application requires one backend's native
transaction, query planner, or stream semantics without replication.

Use an application-level conflict or event system when multiple stores can be
written independently. SynchronizedEngine is intentionally one-way and should
not be presented as multi-master replication.
