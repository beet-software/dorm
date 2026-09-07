# Identity, primary keys, and dependencies

Every generated model has an identity. dORM keeps identity handling separate from ordinary field data and uses dependency objects when creating models whose identity or relationships rely on other records.

## Simple generated identity

When a model uses the default `GeneratedIdSpec`, the generated model receives an `id` field. The default Dart identity type is `String`:

```dart
@Model(name: 'Users', as: #users)
abstract class _User {
  @Field(name: 'username')
  String get username;
}
```

The generated `User` has a String identity, and `UserEntity.identify(user)` returns `user.id`. The entity's default `SinglePrimaryKeyCodec` encodes one identity value for the schema and decodes one stored key value back into the identity.

The selected engine creates the identity during `put`:

- BLoC generates a UUID in memory;
- MySQL generates a UUID before the insert;
- Firebase creates a push key and requires it to be a `String`.

The generic identity parameter in framework types does not make every identity type valid for every engine. Firebase's reference explicitly rejects non-String IDs.

## Use an existing identity field

`ExistingIdSpec` describes a primary-key field already declared in the annotated source:

```dart
@Model(
  name: 'Users',
  as: #users,
  primaryKey: [ExistingIdSpec(referTo: #externalId)],
)
abstract class _User {
  @Field(name: 'external-id')
  String get externalId;
}
```

The generator resolves the Dart type and storage name from the referenced field. The model's identity then comes from that declared field instead of a generated `id` field.

## Use strong and weak dependencies

`Dependency.strong()` has an empty `ids` list. It represents a model that can be created without the identity of another model:

```dart
class UserDependency extends Dependency<UserData> {
  const UserDependency() : super.strong();
}
```

`Dependency.weak(ids)` carries the identities of strong models that the new model depends on:

```dart
final Cart cart = await dorm.carts.repository.put(
  Creation.auto(
    dependency: CartDependency(userId: user.id),
    data: CartData(timestamp: DateTime.now()),
  ),
);

final CartItem item = await dorm.cartItems.repository.put(
  Creation.auto(
    dependency: CartItemDependency(productId: product.id, cartId: cart.id),
    data: const CartItemData(amount: 2),
  ),
);
```

The generated `CartDependency` and `CartItemDependency` retain the typed foreign IDs in addition to the base dependency ID list. `Entity.fromData` receives a `ResolvedCreation` and uses its dependency and data to construct the relationship-bearing model.

In the store model, `Cart` uses a primary-key generator that returns `cart.userId`, so the cart identity is the user identity. `CartItem` receives both the product and cart IDs as foreign dependencies.

## Separate `put` from `push`

`put` receives a `Creation` and creates an identified `Model`. `push` receives an already identified `Model`:

```dart
final User created = await dorm.users.repository.put(
  Creation.auto(
    dependency: const UserDependency(),
    data: userData,
  ),
);

await dorm.users.repository.push(
  User(
    id: created.id,
    username: created.username,
    email: 'ada@example.org',
    profile: created.profile,
  ),
);
```

This is an API distinction, not a guarantee that every engine has identical conflict behavior. The framework comments describe `put` and `push` as overwriting an existing model with the same identity, while the exact storage operation is implemented by each engine.

## Represent a composite identity

The framework provides `CompositeKey` and `CompositePrimaryKeyCodec` for ordered multi-field identities:

```dart
final CompositeKey key = CompositeKey(['tenant-1', 'user-1']);
final CompositePrimaryKeyCodec codec = CompositePrimaryKeyCodec();

final List<Object?> values = codec.encode(key);
final CompositeKey decoded = codec.decode(values);
```

`EntitySchema.keyFields` preserves the ordered fields that make up the identity. `primaryKey` remains the first key field for the current compatibility shape, while `primaryKeys` and `keyFields` represent the complete ordered key.

The generator accepts one generated identity or existing identity fields for composite declarations. Composite generated keys are not supported by the annotation contract. Current restrictions involving composite-key generators and generated relationships are classified as accidental behavior rather than as a confirmed permanent design rule.

## Check engine-specific identity restrictions

Identity behavior depends on the engine:

| Situation | Current behavior |
| --- | --- |
| `put` with a composite primary key | Use `Creation.explicit` with a `CompositeKey`; the generated repository accepts only explicit creation |
| `put` with `Creation.auto` and a composite primary key | Compile-time error through generated types; `UnsupportedError` if the static type is bypassed |
| Firebase non-String identity | Throws `ArgumentError` |
| Simple generated identity in BLoC/MySQL | UUID-backed String behavior in current implementations |

The common identity abstractions therefore describe the model identity independently from each engine's automatic creation path.
