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
contract is centralized in the [Annotations reference](../annotations/index.md);
the declaration below shows only the part needed for this search task:

```dart title="lib/models.dart"
@DerivedField(name: '_q-username')
static String $dorm$derived$qUsername(
  _User model,
  DerivedTransformations transformations,
) => transformations.text(model.username) ?? '';

@DerivedField(name: '_q-name')
static String $dorm$derived$qName(
  _Product model,
  DerivedTransformations transformations,
) => transformations.text(model.name) ?? '';
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
query implementation. The callback determines which model fields contribute to
the searchable value and how those values are normalized.

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

## Compare values and test membership

Use comparison filters when equality is not enough. The comparison names state
whether the boundary is included:

```dart
final List<Product> products = await dorm.products.repository.peekAll(
  Filter.greaterThanOrEqual<Query>(
    10,
    field: ProductEntity.fields.price,
  ),
);
```

`lessThan` and `greaterThan` are open comparisons. `lessThanOrEqual` and
`greaterThanOrEqual` include the supplied value. `notEqual` excludes it.

Use set filters when a field may match one of several values:

```dart
final List<Product> products = await dorm.products.repository.peekAll(
  Filter.inValues<Query>(
    ['Notebook', 'Mouse'],
    field: ProductEntity.fields.name,
  ),
);
```

`notInValues` excludes the supplied values. The order of the values passed to
the filter does not define the order of the returned models; use
[`OrderBy`](using-sorting.md) when result order matters.

Use `isNull` and `isNotNull` for nullable fields. They are separate from
`Filter.value(null, ...)` because database engines do not interpret null
comparisons uniformly.

These operators are capability-based. The concrete `Query` type must implement
the corresponding framework capability. Write the type argument explicitly when
Dart cannot infer it from the repository, as in the examples above.

The engine and platform support table shows which engines expose comparison and set
filters.

## Combine conditions

Use `allOf` for a conjunction and `anyOf` for a disjunction. These names accept
lists of filters and make the grouping visible in the code:

```dart
final BaseFilter<Query> availableNotebook = Filter.allOf<Query>([
  Filter.greaterThanOrEqual<Query>(
    10,
    field: ProductEntity.fields.price,
  ),
  Filter.text('Notebook', field: ProductEntity.fields.name),
]);

final List<Product> products = await dorm.products.repository.peekAll(
  availableNotebook,
);
```

```dart
final BaseFilter<Query> featuredOrAffordable = Filter.anyOf<Query>([
  Filter.lessThan<Query>(
    25,
    field: ProductEntity.fields.price,
  ),
  Filter.text('Notebook', field: ProductEntity.fields.name),
]);
```

`allOf([])` is an empty filter. `anyOf([])` throws `ArgumentError` because an
empty disjunction has no matching condition. Use `Filter.not(filter)` to negate
one condition when the selected engine supports negation.

The framework does not silently download all records and filter them in Dart
when a backend cannot express a condition. This preserves the backend's
pagination, security rules, ordering, and request behavior. For a backend with
limited query composition, use a supported single condition or make any local
second-stage filtering explicit in application code.

## Filter collection fields

`contains` and `containsAny` apply to fields whose stored representation is a
collection:

```dart
final List<Product> products = await dorm.products.repository.peekAll(
  Filter.contains<Query>(
    'wireless',
    field: [PLACEHOLDER: a generated collection field],
  ),
);
```

`contains` matches one member and `containsAny` matches at least one member of
the supplied values. These operators do not perform substring search or
full-text search. Use `Filter.text` for a persisted prefix-search field.

Collection filters are not part of the minimum portable filter set. Check the
engine and platform support table before using them in code that may switch engines.

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
