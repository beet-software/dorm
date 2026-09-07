# Run the store with the BLoC engine

The BLoC engine stores dORM records in memory and exposes them through the framework repository API. It is useful when the application process owns the data for its lifetime and no external database connection is required.

This page uses a pure Dart application and the generated store models from [Generate the model](../01-start-here/03-generate-the-model.md).

## Add the engine package

From the directory containing your application's `pubspec.yaml`, run:

```shell
dart pub add dorm_bloc_database
dart pub get
```

The model source still needs the dORM annotations, framework, generator, JSON annotation, and build tools installed in the [quickstart](../01-start-here/01-quickstart.md). The engine package supplies the concrete `Engine` and `Filter` used by the application code.

## Construct one engine and one generated `Dorm`

Create the engine before creating the generated database object:

```dart
import 'package:decimal/decimal.dart';
import 'package:dorm_bloc_database/dorm_bloc_database.dart';

import 'models.dart';

final Engine engine = Engine();
final Dorm<Query, OffsetPageRequest> dorm = Dorm(engine);
```

`Engine()` creates the in-memory reference used by the generated `Dorm`. Reuse this `Dorm` instance when different parts of the application need to observe the same records. A separate `Engine()` creates a separate in-memory store.

## Run the User and Product flow

The repository calls do not change for the BLoC engine:

```dart
Future<void> createAndRead(Dorm dorm) async {
  final User user = await dorm.users.repository.put(
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

  await dorm.products.repository.put(
    Creation.auto(
      dependency: const ProductDependency(),
      data: ProductData(
        name: 'Notebook',
        description: 'A lined notebook',
        price: Decimal.fromInt(12),
      ),
    ),
  );

  final User? loaded = await dorm.users.repository.peek(user.id);
  print(loaded?.username);
}
```

The engine creates a UUID identity for `put` on entities with a simple generated identity. The returned model contains that identity and can be used in later reads or dependencies.

## Observe changes through streams

The BLoC reference emits changes from its in-memory state. Subscribe to a model or collection through the repository:

```dart
final subscription = dorm.users.repository.pullAll().listen((users) {
  print('Users: ${users.length}');
});

await dorm.users.repository.put(
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

await subscription.cancel();
```

Use the same repository instance for the write and the stream. The subscription receives collection updates produced by repository operations on that reference.

## Understand state lifetime

The BLoC engine has no persistence outside the running process. Restarting the process creates a new empty `Engine` state unless the application loads data from another source.

The engine does not expose a database-server connection or a migration step. The generated schema metadata is still used by repositories, filters, and relationships, but the records remain in memory.

## Handle composite identities

For a composite primary key, pass the final identity explicitly through `Creation.explicit`:

```dart
final CompositeKey key = CompositeKey(['tenant-1', 'user-1']);
final [PLACEHOLDER: composite model] model =
    await [PLACEHOLDER: composite repository].put(
  Creation.explicit(
    dependency: [PLACEHOLDER: composite dependency],
    data: [PLACEHOLDER: composite data],
    identity: key,
  ),
);
```

`Creation.auto` is rejected by the generated composite repository at compile
time because dORM does not generate multiple key components implicitly.
`Creation.explicit` uses the supplied identity as the model's final identity.

## Run the application

For a Dart console application, regenerate the model and run the program from the application directory:

```shell
dart run build_runner build
dart run
```

The generated files must be present before the application imports the generated `Dorm`, data classes, or repositories.
