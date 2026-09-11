# dorm_sync

dorm_sync composes dORM engines into a unidirectional primary-to-replica
setup.

The primary handles all reads and application writes. Finite reads use a portable fallback policy for unavailable or timed-out
primaries; applications can provide a custom policy. Writes are
recorded as exact change sets and delivered to replicas through an injectable
at-least-once outbox. Streams stay connected to the primary and distributed
transactions are not provided.

Example:

    final primaryTarget = EngineSyncTarget(primaryEngine, id: 'primary');
    final replicaTarget = EngineReplicaTarget(replicaEngine, id: 'replica');

    final engine = SynchronizedEngine(
      primary: primaryTarget,
      replicas: [replicaTarget],
      outbox: MemorySyncOutbox(),
    );

    final dorm = Dorm(engine);

EngineSyncTarget requires a framework ChangeTrackedEngine, because the primary
must report the exact result of each write. EngineReplicaTarget requires only a
normal BaseEngine; replicas receive materialized change sets and do not
generate another identity.

MemorySyncOutbox is process-local and is intended for tests and small
applications. A durable outbox should persist SyncOperation.toJson(), including
the change set and replica IDs, and return operations without the in-process
callback after a restart. Pass a SyncOperationResolver to SynchronizedEngine so
those operations can resolve their typed applier from the entity table name.

Delivery is ordered per replica and at-least-once. Use flush() to wait for
scheduled deliveries and retry() to retry pending failures. Pass operationIds
or replicaIds for a selective retry. Configure maxAttempts to move repeatedly
failing deliveries to the outbox dead-letter queue. Observe outbox.failures for
errors, stack traces, and terminal failures.

## Full reference

For the complete semantics and implementation guidance, see the repository
[database synchronization reference](https://github.com/ezgrs/dorm/blob/main/docs/docs/reference/synchronization.md).