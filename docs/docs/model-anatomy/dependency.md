# Generated `Dependency`

`Dependency` carries identities of related models while a new model is being
constructed. It keeps foreign identities separate from the ordinary fields in
the generated `Data` value.

For the store's cart models:

```dart
final Cart cart = await dorm.carts.repository.put(
  Creation.auto(
    dependency: CartDependency(userId: user.id),
    data: CartData(timestamp: DateTime.now()),
  ),
);

final CartItem item = await dorm.cartItems.repository.put(
  Creation.auto(
    dependency: CartItemDependency(
      productId: product.id,
      cartId: cart.id,
    ),
    data: const CartItemData(amount: 2),
  ),
);
```

The generated dependency type contains typed properties such as `userId`,
`productId`, and `cartId`. The base dependency also carries the related IDs
used by the framework during model construction.

A strong dependency has no related IDs. A weak dependency carries IDs of other
models required by the new model. The generated entity receives the dependency
through `ResolvedCreation` and uses it to construct the identified model.

See [`ForeignField`](../annotations/foreign-field.md) for the declarations that
produce dependency properties, [`@Model`](../annotations/model.md) for identity
specifications, and [Create records](../operations/creating.md) for
creation rules.
