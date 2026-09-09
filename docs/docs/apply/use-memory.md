# Run the store with the memory engine

The memory engine is a pure Dart implementation of the dORM framework. It
stores records in the process, so it is useful for a local workflow, an
example application, or tests that should not require a database server.

## Add the engine package

From the Dart application directory, run:

```shell title="Add the memory engine"
dart pub add dorm_memory_database
```

The model and generated API packages are still required. If you are starting
from an empty application, follow the [quickstart](../quickstart/installation.md)
for the complete package and generation sequence.

## Create one reusable engine

Construct the engine once and pass it to the generated `Dorm`:

```dart
import 'package:dorm_memory_database/dorm_memory_database.dart';

final Engine engine = Engine();
final Dorm<Query, OffsetPageRequest> dorm = Dorm(engine);
```

The engine instance owns the in-process records. Reusing the same instance
keeps the records available to all repositories and generated accessors that
use it. Creating a second instance creates a separate in-memory store.

## Use the normal repository operations

The repository surface is the same as the other engines:

```dart
final User created = await dorm.users.repository.put(
  Creation.auto(
    dependency: const UserDependency(),
    data: UserData(
      username: 'ada',
      email: 'ada@example.com',
      profile: Profile(
        name: 'Ada Lovelace',
        birthDate: DateTime(1815, 12, 10),
        bio: null,
      ),
    ),
  ),
);

final User? loaded = await dorm.users.repository.peek(created.id);
```

Simple generated identities use UUID strings. Explicit identities and composite
identities follow the framework creation contracts described in [Create records](../build-the-store/creating.md).

## Observe in-process changes

The memory engine emits the current value and later changes through `pull` and
`pullAll`:

```dart
final subscription = dorm.users.repository.pull(created.id).listen((user) {
  print(user?.email ?? 'User removed');
});

await dorm.users.repository.patch(created.id, (current) {
  if (current == null) return null;

  return User(
    id: current.id,
    username: current.username,
    email: 'ada@example.org',
    profile: current.profile,
  );
});

await subscription.cancel();
```

The first stream event is the current stored value. Keep the subscription alive
for as long as the consuming feature needs updates and cancel it during that
feature's cleanup.

## Understand the lifetime

The records are lost when the process stops. The memory engine does not create
tables, persist data to a file, or connect to an external service. Move to a
server-backed engine when the application needs storage outside the process;
the generated repository calls remain the same while the engine setup changes.

## Apply application access control

The memory engine has no external authorization boundary. Records live in the
process that owns the engine, so access control must be applied by the
application code that exposes or withholds the generated repository.

## Observe performance characteristics

The memory engine keeps entity records in process memory. Reads materialize
models and result lists from that state, while relationship paths create their
join structures when they are read. No database round trip is involved and no
dORM-owned result cache is exposed.
