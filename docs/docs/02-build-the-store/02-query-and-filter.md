# Search and filter the store

Repositories accept structured filters for one-shot reads, stream reads, and filtered removals. The store model already defines derived fields for user names and product names, so text search can use those generated values instead of reading every record in application code.

This guide assumes that the generated `User` and `Product` types are available and that `Dorm` is initialized as shown in [Create, read, update, and remove store records](01-crud.md).

## Read a collection

Use `peekAll` for one collection result:

```dart
final List<Product> products = await dorm.products.repository.peekAll();
```

Use `pullAll` when the application needs a stream of collection results:

```dart
final subscription = dorm.products.repository.pullAll().listen((products) {
  print('${products.length} products are available');
});

await subscription.cancel();
```

An empty result is an empty list. Add a `Filter` to restrict the records returned by either operation.

## Match a stored value

Create a value filter with the persisted field name:

```dart
final List<User> users = await dorm.users.repository.peekAll(
  Filter.value('ada@example.com', key: 'email'),
);
```

For generated fields, use `FieldSchema` metadata when it is available:

```dart
final List<Product> products = await dorm.products.repository.peekAll(
  Filter.value(
    'Notebook',
    field: ProductEntity.fields.name,
  ),
);
```

`key` and `field` identify the same persisted field in two forms. A value filter compares the field with the supplied value. The `key` form is useful for a dynamic field name; the generated `field` form keeps the model's column name in the generated metadata.

## Search text with a generated derived field

The `User` model declares `_q-username` as a derived field built from `username`. Use that stored value with `Filter.text`:

```dart
final List<User> matches = await dorm.users.repository.peekAll(
  Filter.text('ada', key: '_q-username'),
);
```

The `Product` model exposes the equivalent `_q-name` derived field:

```dart
final List<Product> matches = await dorm.products.repository.peekAll(
  Filter.text('note', key: '_q-name'),
);
```

`Filter.text` matches values that start with the supplied text according to the query implementation. The derived-field declaration determines which model fields contribute to the searchable value and how those values are normalized.

To add text search to another model, declare a `@DerivedField` in the annotated source and regenerate the model before querying that field.

## Filter dates and ranges

Use a date filter when the comparison is made at a specific date unit:

```dart
final List<Review> reviews = await dorm.reviews.repository.peekAll(
  Filter.date(
    DateTime(2025, 1, 1),
    key: 'timestamp',
    unit: DateFilterUnit.year,
  ),
);
```

Use a range filter when the lower or upper bound matters:

```dart
final List<Product> products = await dorm.products.repository.peekAll(
  Filter.numericRange(
    const FilterRange<double>(from: 10, to: 50),
    key: 'price',
  ),
);
```

The range classes correspond to the value being compared:

- `Filter.textRange` uses lexicographic string bounds;
- `Filter.numericRange` uses numeric bounds;
- `Filter.dateRange` uses `DateFilterRange`, including its date unit.

The `from` and `to` values are nullable. A supplied bound limits that side of the range.

## Limit and sort a result

Apply `limit` and `sort` to a filter before passing it to the repository:

```dart
final List<Product> firstProducts = await dorm.products.repository.peekAll(
  Filter.empty()
      .sort(key: 'name')
      .limit(10),
);
```

`sort` supplies the field used for ordering. `limit` restricts the number of records returned by the operation. Both modifiers are part of the filter passed to the engine.

## Filter a relation source

The same value-filter API applies when reading related records directly. For example, read the items belonging to one cart by filtering `cart-id`:

```dart
final List<CartItem> items = await dorm.cartItems.repository.peekAll(
  Filter.value(cartId, field: CartItemEntity.fields.cartId),
);
```

Generated relationship paths construct equivalent field filters from the relationship metadata. Use a relation path when the result should retain the root model together with the related value; use a repository filter when the related entity list is enough.
