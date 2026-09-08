# Using filters

Repositories accept structured filters for one-shot reads, stream reads, and
filtered removals. Pass the generated `FieldSchema` for the field being
queried. This keeps the Dart field name and its persisted name together.

This guide assumes that the generated `User` and `Product` types are available
and that `Dorm` is initialized as shown in [Operations in a generated repository](overview.md).

## Match a stored value

Create a value filter with generated field metadata:

```dart
final List<User> users = await dorm.users.repository.peekAll(
  Filter.value('ada@example.com', field: UserEntity.fields.email),
);
```

```dart
final List<Product> products = await dorm.products.repository.peekAll(
  Filter.value(
    'Notebook',
    field: ProductEntity.fields.name,
  ),
);
```

A value filter compares the selected field with the supplied value. The
generated metadata contains both the Dart field name and the name used by the
selected storage engine.

## Add a derived field for text search

Add a derived field to the annotated source when the application needs text
search through a generated, normalized value. The complete `@DerivedField`
and `DerivedTransform` contract is centralized in the
[Annotations reference](../annotations/index.md); the declaration below shows
only the part needed for this search task:

```dart title="lib/models.dart"
@DerivedField(
  name: '_q-username',
  referTo: [DerivedToken(#username, DerivedTransform.text)],
)
// ignore: unused_element
String get _qUsername;

@DerivedField(
  name: '_q-name',
  referTo: [DerivedToken(#name, DerivedTransform.text)],
)
// ignore: unused_element
String get _qName;
```

Regenerate the model after changing the annotated source. The `User` model can
then be searched through `_q-username`:

```dart
final List<User> matches = await dorm.users.repository.peekAll(
  Filter.text('ada', field: UserEntity.fields.qUsername),
);
```

The `Product` model can use the corresponding `_q-name` field:

```dart
final List<Product> matches = await dorm.products.repository.peekAll(
  Filter.text('note', field: ProductEntity.fields.qName),
);
```

`Filter.text` matches values that start with the supplied text according to the
query implementation. The derived-field declaration determines which model
fields contribute to the searchable value and how those values are normalized.

## Filter dates and ranges

Use a date filter when the comparison is made at a specific date unit:

```dart
final List<Review> reviews = await dorm.reviews.repository.peekAll(
  Filter.date(
    DateTime(2025, 1, 1),
    field: ReviewEntity.fields.timestamp,
    unit: DateFilterUnit.year,
  ),
);
```

Use a range filter when the lower or upper bound matters:

```dart
final List<Product> products = await dorm.products.repository.peekAll(
  Filter.numericRange(
    const FilterRange<double>(from: 10, to: 50),
    field: ProductEntity.fields.price,
  ),
);
```

The range classes correspond to the value being compared:

- `Filter.textRange` uses lexicographic string bounds;
- `Filter.numericRange` uses numeric bounds;
- `Filter.dateRange` uses `DateFilterRange`, including its date unit.

The `from` and `to` values are nullable. A supplied bound limits that side of
the range.

## Filter a relation source

The same value-filter API applies when reading related records directly. For
example, read the items belonging to one cart by filtering `cart-id`:

```dart
final List<CartItem> items = await dorm.cartItems.repository.peekAll(
  Filter.value(cartId, field: CartItemEntity.fields.cartId),
);
```

Generated relationship paths construct equivalent field filters from the
relationship metadata. Use a relation path when the result should retain the
root model together with the related value; use a repository filter when the
related entity list is enough.

For ordering, use [Using sorting](using-sorting.md). For bounded result sets,
use [Using pagination](using-pagination.md).
