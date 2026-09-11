# Add carts and cart items

Extend the store with carts and the items inside them:

- one `User` owns a `Cart`;
- a `Cart` has many `CartItem` records;
- each `CartItem` points to one `Product`;
- a `Product` can appear in many cart items.

The generated relation paths follow these foreign fields. Add the following
declarations to the same <i>lib/models.dart</i> file used in the earlier Quickstart
pages, after the `User` and `Product` declarations:

```dart title="lib/models.dart"
@Model(name: 'Carts', as: #carts)
abstract class _Cart {
  static String $dorm$generateId(_Cart cart, String id) => cart.userId;

  @Field(name: 'timestamp')
  DateTime get timestamp;

  @ForeignField(name: 'user-id', referTo: _User, inverseAs: #carts)
  String get userId;
}

@Model(name: 'CartItems', as: #cartItems)
abstract class _CartItem {
  @Field(name: 'amount')
  int get amount;

  @ForeignField(name: 'product-id', referTo: _Product, inverseAs: #cartItems)
  String get productId;

  @ForeignField(name: 'cart-id', referTo: _Cart, inverseAs: #items)
  String get cartId;
}
```

The `Cart` declaration uses the owning user's identity as its generated
identity. `CartItem` keeps its own generated identity and receives the cart and
product identities through its generated dependency type. Regenerate the model
parts after adding these declarations:

```shell
dart run build_runner build
```

The generated names used below are `dorm.carts`, `dorm.cartItems`,
`dorm.relations.carts`, and `dorm.relations.cartItems`.

## Create records with foreign dependencies

Create the cart with the user's identity in `CartDependency`:

```dart
final Cart cart = await dorm.carts.repository.put(
  Creation.auto(
    dependency: CartDependency(userId: user.id),
    data: CartData(timestamp: DateTime.now()),
  ),
);
```

The `Cart` model declares a `$dorm$generateId` method based on `userId`. For this model, the generated cart identity is the user identity, so `cart.id == user.id` after creation.

Create an item with both foreign identities in `CartItemDependency`:

```dart
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

The foreign fields are not part of `CartItemData`. They are supplied through the dependency because they identify the records related to the new item.

## Read the product for one cart item

The generated `DormRelations` object provides relation roots. The `cartItems.productOrNull` path starts at `CartItem` and reads its product:

```dart
final List<Join<CartItem, Product?>> rows = await dorm
    .relations
    .cartItems
    .productOrNull
    .peekAll(
      Filter.value(cart.id, field: CartItemEntity.fields.cartId),
    );

for (final Join<CartItem, Product?> row in rows) {
  print('${row.left.amount}: ${row.right?.name ?? 'product missing'}');
}
```

`Join.left` is the root model and `Join.right` is the terminal value in the path. `productOrNull` preserves a cart item when its product is absent and returns `null` on the right side.

The `product` path is the required form. It removes a cart item when no product can be read:

```dart
final List<Join<CartItem, Product>> existingProducts = await dorm
    .relations
    .cartItems
    .product
    .peekAll();
```

## Read all items for a cart

Use the cart root and its generated to-many path:

```dart
final List<Join<Cart, CartItem>> rows = await dorm
    .relations
    .carts
    .items
    .peekAll(Filter.value(cart.id, field: CartItemEntity.fields.id));
```

`items` flattens the matching cart items. A cart with no matching items produces no row in this path. Use `itemsOrEmpty` when the cart must remain in the result:

```dart
final List<Join<Cart, List<CartItem>>> grouped = await dorm
    .relations
    .carts
    .itemsOrEmpty
    .peekAll(Filter.value(cart.id, field: CartItemEntity.fields.id));

final List<CartItem> cartItems = grouped.single.right;
```

The `OrEmpty` form groups the related values and keeps an empty list for a cart with no items.

## Traverse a nested path

A path can continue through multiple relationships. To read a user's cart items and their products in one result shape, use:

```dart
final List<Join<User, Product?>> rows = await dorm
    .relations
    .users
    .carts
    .items
    .productOrNull
    .peekAll(Filter.value(user.id, field: UserEntity.fields.id));
```

The path is built by its getters. The first database read occurs when `peekAll` or `pullAll` is called. The intermediate `Cart` and `CartItem` values are used to resolve the path and are not exposed as nested `Join` objects in the final result.

## Choose relation names by their cardinality

The generated paths distinguish both the relationship direction and the result shape:

| Path form | Result behavior |
| --- | --- |
| `product` or `user` | one required target; parents without a target are removed |
| `productOrNull` or `userOrNull` | one optional target; parents remain with `null` |
| `items` or `cartItems` | many targets; parents without targets are removed |
| `itemsOrEmpty` or `cartItemsOrEmpty` | many targets grouped in a list; parents remain with an empty list |

`ForeignField.as` supplies the forward relation name. `ForeignField.inverseAs` supplies the name exposed on the related model. The generated names in this store are `Cart.user`, `Cart.items`, `CartItem.product`, and `Product.cartItems`.

## Keep relationship constraints in mind

The generated path is tied to the foreign fields declared in the annotated model. Its source and target fields must use compatible identities, and each path step is resolved through the corresponding repository. The same `Data`, dependency, and identity split used for direct writes applies when creating related records.

Continue with [reviews and polymorphic content](reviews-and-polymorphism.md)
to add a second relationship-backed part of the store.
