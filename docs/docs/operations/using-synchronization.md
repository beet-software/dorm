# Using synchronization

Synchronization means keeping the same application data in more than one
place.

For example, an application can write to a server database and also keep a
local copy. If the server is temporarily unavailable, the application can read
the local copy when that is safe.

The `dorm_sync` package provides this composition while keeping the generated
dORM API unchanged. You still use `Dorm`, `DatabaseEntity` and `Repository` in the
same way.

## The three parts

The feature uses three roles:

- The **primary** is the storage that receives application writes first. Its
  result is the result returned to the application.
- A **replica** is another storage that receives a copy of a successful primary
  write. It can be slightly behind the primary.
- The **outbox** is a list of changes waiting to reach replicas. It allows a
  failed delivery to be inspected and tried again.

The application writes to the primary storage first. dORM records a pending
delivery in the outbox, then sends the same result to each replica.

The primary and replicas can use different dORM engines, but they must agree
on the entities and identities that they share.

## When to use it

Synchronization is a good fit when:

- the primary should remain the place where writes are decided;
- another engine should receive the same writes later;
- a local copy can help with finite reads (reads that come from `peek` or `peekAll`);
- the application accepts that a replica may be briefly out of date.

Common examples are a server database with a local SQLite copy, a server
database with an in-memory cache, or a copy sent to a second storage service.

Use a normal engine instead when:

- all data must be saved together by one database transaction;
- the application needs one database's native stream behavior without wrapping it;
- multiple storages can be written independently and need conflict resolution.

The package does not turn several databases into one transaction.

## Add the package

Add `dorm_sync` with the framework and the concrete engines used by the
application:

~~~shell
dart pub add dorm_sync
~~~

Import the public package barrels where the engines are created:

~~~dart
import 'package:dorm_framework/dorm_framework.dart';
import 'package:dorm_memory_database/dorm_memory_database.dart';
import 'package:dorm_sync/dorm_sync.dart';
~~~

Your generated models and repositories do not need to change.

## Create a primary and a replica

In this example both storages use the memory engine. The same structure can
wrap other dORM engines.

First create the two concrete engines:

~~~dart
final Engine primaryEngine = Engine();
final Engine replicaEngine = Engine();
~~~

The primary needs to report exactly what each write changed. An engine with
this ability is called a `ChangeTrackedEngine` by the framework. Wrap it with
`EngineSyncTarget`:

~~~dart
final EngineSyncTarget<Query<Object>, OffsetPageRequest> primaryTarget = EngineSyncTarget(
  primaryEngine,
  id: 'primary',
);
~~~

The other storage only needs to accept normal dORM operations and applied
copies. Wrap it with `EngineReplicaTarget`:

~~~dart
final EngineReplicaTarget<Query<Object>, OffsetPageRequest> replicaTarget = EngineReplicaTarget(
  replicaEngine,
  id: 'local-copy',
);
~~~

The `id` is the name used to track that storage. It must be unique and
should not change after the application starts storing pending deliveries.

The two engines must describe shared entities in a compatible way:

- the table or collection name must match;
- the primary-key fields must have the same order and meaning;
- the identity type and the function that converts it to stored key fields must
  be compatible;
- stored field names and values must be readable by both engines.

The replica uses the identity chosen by the primary. It does not create a
second identity for the same model.

## Create the synchronized engine

Now combine the targets:

~~~dart
final MemorySyncOutbox outbox = MemorySyncOutbox();

final SynchronizedEngine<Query<Object>, OffsetPageRequest> engine = SynchronizedEngine(
  primary: primaryTarget,
  replicas: [replicaTarget],
  outbox: outbox,
);

final Dorm<Query<Object>, OffsetPageRequest> dorm = Dorm(engine);
~~~

By default, dORM falls back only for a portable `DormDatabaseException` whose
kind is unavailable or `timeout`. It does not hide permission, validation,
conflict, unknown, or programming errors. You can provide a `fallback` callback
when your application needs a different policy. See [Portable database errors](../reference/errors.md)
for the categories and provider details available to the callback.

## What happens when the application writes

Suppose the application runs:

~~~dart
final User user = await dorm.users.repository.put(
  Creation.auto(
    dependency: const UserDependency(),
    data: const UserData(name: 'Ada'),
  ),
);
~~~

The operation happens in this order:

1. The primary stores the `User`.
2. dORM prepares the primary result: the stored `User`, with its final identity
   and data, is now ready to be returned to the application.
3. dORM creates a **change set**: a small
   record describing the completed write (which entity changed, which
   identities were affected, and what the final data is).
4. The change set is added to the outbox for each replica.
5. dORM immediately returns the prepared `User` to the application; it does
   not wait for the replicas to finish receiving the change.
6. After the `User` has been returned, dORM tries to apply the same result to
   each replica in the background.

A replica can fail after the primary succeeds. In that case the application
still has a successful primary write, and the failed delivery remains
available for inspection and retry.

This design means that a replica can receive the same change more than once.
Applying the same final model or deletion again must be safe.

### What each operation records

The primary records the result, not the original callback or filter:

| Application operation | Information sent to the replica |
| --- | --- |
| `put` | The final model and identity created by the primary. |
| `putAll` | Every final model and identity. |
| `push` | The identified model supplied by the application. |
| `pushAll` | The identified models supplied by the application. |
| `patch` | The final model, or a deletion when the callback removes it. |
| `pop` | The identity removed by the primary. |
| `popKeys` | The identities removed by the primary. |
| `popAll` | The exact identities found and removed by the primary. |
| `purge` | An instruction to remove every model of that entity. |

For example, when the application calls `popAll`, the replica does not run the
filter again. It receives the exact identities that the primary removed.

## Wait for the current deliveries

Writes are sent to replicas in the background after the primary and outbox
steps complete. Most application code should not wait for every replica:

~~~dart
await dorm.users.repository.push(user);
~~~

Use `flush` when a specific part of the application must wait for the deliveries
already scheduled by this engine:

~~~dart
await dorm.users.repository.push(user);
await engine.flush();
~~~

It waits for the current delivery attempts. It does not make the write
one indivisible operation across all databases, and it does not retry a
delivery that continues to fail.

## Read when the primary is unavailable

For a normal finite read, dORM asks the primary first:

~~~dart
final User? user = await dorm.users.repository.peek(userId);

final List<User> users = await dorm.users.repository.peekAll(
  Filter.empty(),
);
~~~

If the primary throws, the callback passed as fallback decides whether a
replica may be tried. Replicas are tried in the order given to
`SynchronizedEngine`.

Fallback is only available for finite read operations (`peek`, `peekAll`, `peekPage` and `peekAllKeys`), since a `pull` or `pullAll` call stays connected to the primary. Automatically changing
to another stream could lose events, repeat the same snapshot, or change the
order in which events arrive. If the application needs stream recovery, it
must define that behavior outside this wrapper.

## Start with the in-memory outbox

`MemorySyncOutbox` is the simplest outbox:

~~~dart
final MemorySyncOutbox outbox = MemorySyncOutbox();
~~~

It keeps pending deliveries in the current process. If the process stops, its
pending list is lost.

It is useful for tests, prototypes, and cases where replica delivery can be
recreated by another application process. It is not enough for offline work
that must survive an application restart.

This feature can retry a write after the primary has accepted it. It does
not accept a new write while the primary is unavailable. In other words, it
helps finish a delivery that was interrupted; it is not a local database that
can accept new changes without the primary.

## Use a durable outbox for offline recovery

For pending changes to survive a restart, the application must implement
`SyncOutbox` with its own storage. This is called a durable outbox because the
pending list survives a restart. Its storage can be a local database, a file,
or another durable service.

A durable outbox should save:

- the change description and its operation id, a unique name for one write;
- the target replica `id`;
- whether the delivery is still pending or already confirmed;
- how many attempts have been made;
- the last error and stack trace, if available;
- deliveries moved to the dead-letter list.

A **dead letter** is a delivery that the application has stopped retrying
automatically because it failed too many times. It is kept for inspection or
manual recovery.

The outbox should treat adding a change (enqueue) and confirming a delivery
(acknowledge) as safe to repeat. This is important because the process can
stop between applying a change and recording that it was confirmed.

### Restore typed operations after a restart

While the application is running, dORM keeps an internal function that
knows how to apply that change set to the correct generated entity. This
function is created when a write is accepted by the primary. It is not the
callback from your application code, such as the function used to calculate a
`patch`; dORM does not save or run that application callback again. The internal
function is simply the step that calls `target.apply` for the entity involved in
the write.

A Dart function cannot be restored from the JSON-like data saved by a durable
outbox. After a restart, dORM therefore needs a `SyncOperationResolver`. The
resolver is one callback that dORM calls with the name of the entity from the
saved operation. Inside that callback, a `switch` explicitly maps each
supported name to its generated entity:

~~~dart
// UserEntity is generated in models.dorm.dart and imported by this file.
final SyncOperationResolver resolver = (String entityKey) {
  switch (entityKey) {
    case 'Users':
      return (target, changeSet) =>
          target.apply(const UserEntity(), changeSet);
    default:
      throw StateError('Unknown entity: $entityKey');
  }
};

final SynchronizedEngine<Query<Object>, OffsetPageRequest> engine = SynchronizedEngine(
  primary: primaryTarget,
  replicas: [replicaTarget],
  outbox: durableOutbox,
  resolver: resolver,
);
~~~

In this example, `Users` is the value of `UserEntity`'s
`schema.tableName`. The generated entity gets this value from the model
configuration, and dORM saves it as `entityKey` when it creates the operation.
It is the stable name that lets a later retry find the correct generated entity;
it is not the Dart class name and it is not inferred by reflection. If your
schema uses another table or collection name, use that exact value in the
`switch`.

The `switch` is the explicit mapping maintained by the application. The
resolver itself is still a callback, not a list: dORM calls it once for each
saved operation that needs to be rebuilt. If the application has several
entities, add one `case` for each supported entity and return the corresponding
class generated in the `.dorm.dart` file.

After creating the engine, the application decides when to load and retry
pending deliveries:

~~~dart
await engine.retry();
~~~

During this call, dORM reads pending deliveries from the outbox, calls the
resolver for operations that no longer have their in-memory function, and then
tries to apply each change to its replica. dORM does not start a background
retry timer for the application.

## Inspect failures and retry

Listen to the outbox when the application needs logs, metrics, or alerts:

~~~dart
await for (final SyncFailure failure in outbox.failures) {
  logFailure(
    failure.error,
    failure.stackTrace,
    terminal: failure.terminal,
  );
}
~~~

Retry all pending deliveries:

~~~dart
await engine.retry();
~~~

Retry only selected operations or storages:

~~~dart
await engine.retry(
  operationIds: ['operation-123'],
  replicaIds: ['local-copy'],
);
~~~

Set `maxAttempts` when a permanently failing storage should eventually stop
receiving automatic retries:

~~~dart
final SynchronizedEngine<Query<Object>, OffsetPageRequest> engine = SynchronizedEngine(
  primary: primaryTarget,
  replicas: [replicaTarget],
  outbox: durableOutbox,
  maxAttempts: 5,
);
~~~

A delivery moved to the dead-letter list is no longer returned by pending.
The application must decide how to repair the storage and safely retry that
delivery.

## Close the engine

When the application no longer needs the generated repositories and streams,
close the composed engine:

~~~dart
await engine.close();
~~~

It waits for deliveries already scheduled by the coordinator and then
closes the outbox. A durable outbox can also release its own file or database
resources in its `close` implementation.

## What this feature does not do

Synchronization in dORM does not:

- save a write locally when the primary rejected it;
- copy changes made directly to a replica back to the primary;
- decide which value wins when two storages were changed independently;
- convert a `String` identity into an integer identity automatically;
- make transactions span all storages;
- provide a durable outbox implementation;
- automatically retry forever;
- guarantee that writing the primary and outbox is one indivisible step.

Relationships still work through the normal generated API. The synchronized
engine uses the portable relationship implementation, so a relationship can
perform more reads than an SQL join optimized for one database.

For the detailed API contracts and exact rules, see
[Synchronize database engines](../reference/synchronization.md).
