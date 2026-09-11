# Run the store with the BLoC engine

The BLoC engine stores dORM records in memory and exposes them through the framework repository API. It is useful when the application process owns the data for its lifetime and no external database connection is required.

This page uses a pure Dart application and the generated store models from [Generate the store API](../quickstart/generating-models.md).

## Add the engine package

From the directory containing your application's <i>pubspec.yaml</i>, run:

```shell
dart pub add dorm_bloc_database
```

The model source still needs the dORM annotations, framework, generator, and
build tools installed in [Quickstart installation](../quickstart/installation.md).
The annotations barrel reexports the JSON annotation types used by generated
code. The engine package supplies the concrete `Engine` and `Filter` used by
the application code.

## Construct one engine and one generated `Dorm`

Create the engine before creating the generated database object:

```dart title="bin/dorm_store.dart"
import 'package:decimal/decimal.dart';
import 'package:dorm_bloc_database/dorm_bloc_database.dart';

import 'models.dart';

final Engine engine = Engine();
final Dorm<Query, OffsetPageRequest> dorm = Dorm(engine);
```

`Engine()` creates the in-memory reference used by the generated `Dorm`. Reuse this `Dorm` instance when different parts of the application need to observe the same records. A separate `Engine()` creates a separate in-memory store.

## Run the `User` and `Product` flow

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

Add this model declaration to <i>lib/models.dart</i> and regenerate the model API:

```dart
@Model(
  name: 'CartItems',
  as: #cartItems,
  primaryKey: [
    ExistingIdSpec(referTo: #cartId),
    ExistingIdSpec(referTo: #productId),
  ],
)
abstract class _CartItem {
  @Field(name: 'cart-id')
  String get cartId;

  @Field(name: 'product-id')
  String get productId;

  @Field(name: 'quantity')
  int get quantity;
}
```

The generated `CartItemData` contains the non-key fields. Create the record
with a `CompositeKey` whose values follow the same order as `primaryKey`:

```dart
final CompositeKey key = CompositeKey(['cart-1', 'product-1']);
final CartItem model = await dorm.cartItems.repository.put(
  Creation.explicit(
    dependency: CartItemDependency(),
    data: CartItemData(quantity: 1),
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

## Apply application access control

The BLoC engine has no external authorization boundary. Records remain in the
process state owned by the application, so access control must be applied by
the application code that holds or exposes the generated `Dorm` instance.

## Observe performance characteristics

The BLoC engine stores each entity table in a `Map` inside its state. A direct
identity read uses the table lookup. Collection reads serialize current model
values for filter evaluation and reconstruct the selected models.

Mutations copy the complete entity table map before applying the change. The
batch write operations prepare multiple models and emit one table-state
mutation. Filtered stream results are rematerialized when a table-state event
arrives; the engine does not expose a separate filtered-result cache.
