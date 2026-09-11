# Using sorting

Sorting belongs to the read options passed alongside a filter. Keep the filter
responsible for which records match and use `QueryOptions` for the order of the
returned records.

## Sort a collection read

Pass `QueryOptions` as the optional second argument to `peekAll`:

```dart
final List<Product> products = await dorm.products.repository.peekAll(
  Filter.empty(),
  QueryOptions(
    orderBy: [OrderBy(ProductEntity.fields.name)],
  ),
);
```

Use `SortDirection.descending` for descending order:

```dart
final List<Product> products = await dorm.products.repository.peekAll(
  Filter.empty(),
  QueryOptions(
    orderBy: [
      OrderBy(
        ProductEntity.fields.price,
        direction: SortDirection.descending,
      ),
    ],
  ),
);
```

`OrderBy` receives the `FieldSchema` for the persisted field. Generated values
such as `ProductEntity.fields.name` keep the storage name in the model
metadata instead of repeating it in the query.

## Combine sorting with a filter and a limit

`QueryOptions` can carry both ordering and a maximum result count:

```dart
final List<Product> firstProducts = await dorm.products.repository.peekAll(
  Filter.numericRange(
    const FilterRange<double>(from: 10, to: 50),
    field: ProductEntity.fields.price,
  ),
  QueryOptions(
    orderBy: [OrderBy(ProductEntity.fields.name)],
    limit: 10,
  ),
);
```

The filter narrows the matching products. The order is applied to that result
set, and `limit` caps the list returned by `peekAll`.

## Sort an offset page

Offset pagination carries its ordering on the page request itself:

```dart
final Page<Product> page = await dorm.products.repository.peekPage(
  Filter.empty(),
  OffsetPageRequest(
    size: 10,
    offset: 20,
    orderBy: [OrderBy(ProductEntity.fields.name)],
  ),
);
```

Use the same ordering when fetching adjacent pages so that records do not move
between pages because of an unspecified order. Continue with [Using pagination](using-pagination.md)
for the page request and `hasNext` behavior.
