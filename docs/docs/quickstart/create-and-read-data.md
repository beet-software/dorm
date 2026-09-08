# Create and read a user

Use the generated repository to create one user and read it back. Replace the
contents of `bin/dorm_store.dart` with this complete application:

```dart title="bin/dorm_store.dart"
import 'package:dorm_memory_database/dorm_memory_database.dart';

import 'package:dorm_store/models.dart';

Future<void> main() async {
  final dorm = Dorm(Engine());
  final User created = await dorm.users.repository.put(
    Creation.auto(
      dependency: UserDependency(),
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

  print(loaded?.email ?? 'User not found');
}
```

`put` receives a `Creation` object. `Creation.auto` follows the identity
strategy declared by the model and carries the dependency and data used to
construct it.
The returned `User` is already identified, so its `id` can be passed to
`peek`. `peek` returns `null` when that identity is not present.

## Run the application

Run the generation command again after changing `models.dart`, then start the
application:

```shell title="Generate the model API and run the application"
dart run build_runner build
dart run
```

The program prints the email read from the repository. The records live only
for the lifetime of this process because the memory engine is in-process.

Continue the example with [carts and cart items](relations-and-cart.md),
then use [Operations](../build-the-store/overview.md) for the reusable create,
read, update, delete, filter, sorting, and pagination tasks.
