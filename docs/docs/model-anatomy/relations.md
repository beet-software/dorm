# Generated relationship paths

When models contain `ForeignField` declarations, the generator creates
relationship roots and path getters in `DormRelations`.

```dart
final List<Join<CartItem, Product?>> rows = await dorm
    .relations
    .cartItems
    .productOrNull
    .peekAll();
```

The path is assembled before the first backend read. Calling `peekAll` or
`pullAll` loads the root source and resolves each relationship step.

Generated path names describe both cardinality and missing-target behavior:

| Path form | Result behavior |
| --- | --- |
| `product` or `user` | Required target; parents without a target are omitted. |
| `productOrNull` or `userOrNull` | Optional target; parents remain with `null`. |
| `items` or `cartItems` | To-many target; matching rows are flattened. |
| `itemsOrEmpty` or `cartItemsOrEmpty` | To-many target grouped in a list, including empty lists. |

The path stores relationship specifications containing cardinality, source
fields, and target fields. An engine can use a structured relation plan or
resolve the path through ordinary readable repository operations.

The relation names come from `ForeignField.as` and
`ForeignField.inverseAs`. See [ForeignField](../annotations/foreign-field.md)
and [Add carts and cart items](../quickstart/relations-and-cart.md)
for the declarations behind these generated paths.
