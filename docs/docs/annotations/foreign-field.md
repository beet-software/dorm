# `@ForeignField`

Use `@ForeignField` for a field containing the identity of another `@Model`.

```dart title="lib/models.dart"
@ForeignField(
  name: 'owner-id',
  referTo: _User,
  as: #owner,
  inverseAs: #carts,
)
String get ownerId;
```

The annotation constructor is:

```dart
const ForeignField({
  String? name,
  required Type referTo,
  bool unique = false,
  Symbol? as,
  Symbol? inverseAs,
})
```

- `name` is the stored foreign-key field name. If omitted, the getter name is
  used.
- `referTo` identifies the target model.
- `unique` records whether the relationship points to one or many records. It
  is metadata for generated relationships, not a physical database uniqueness
  constraint.
- `as` names the generated forward relationship accessor on the class that
  declares the field.
- `inverseAs` requests an inverse accessor on the model named by `referTo`.

If `as` is omitted, the generator derives a forward relationship name from
the foreign field name and can remove a trailing `Id`. For example, a
`productId` field can produce a `product` relation.

The two names control generated Dart relationship paths, not stored column
names. For example:

```dart
@Model(name: 'carts', as: #carts)
abstract class _Cart {
  @ForeignField(
    name: 'user-id',
    referTo: _User,
    as: #owner,
    inverseAs: #carts,
  )
  String get ownerId;
}
```

This declaration makes the source-to-target path available as
`cart.owner`, and the inverse path available as `user.carts`. The stored field
is still `user-id`, and the target model is still `_User`.

For the cart item example, the declarations use inferred forward names and
explicit inverse names:

```dart
@ForeignField(name: 'product-id', referTo: _Product, inverseAs: #cartItems)
String get productId;

@ForeignField(name: 'cart-id', referTo: _Cart, inverseAs: #items)
String get cartId;
```

They produce `cartItem.product`, `product.cartItems`, `cartItem.cart`, and
`cart.items`. If `inverseAs` is omitted, the forward relation can still be
generated, but no inverse accessor is requested on the target model.

The generated dependency type carries foreign identities during creation. A
foreign identity is distinct from the new model's own primary identity. The
generated relation paths use the names supplied by `as` and `inverseAs`.

See [Add carts and cart items](../quickstart/relations-and-cart.md)
for a complete `Cart` and `CartItem` declaration using forward and inverse
foreign fields.
