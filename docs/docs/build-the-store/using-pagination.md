# Using pagination

Use `peekPage` when a collection read needs a bounded result together with
continuation metadata. The current engines expose offset pagination through
`OffsetPageRequest`.

## Read an offset page

```dart title="Read the third page of products"
final Page<Product> page = await dorm.products.repository.peekPage(
  Filter.empty(),
  OffsetPageRequest(
    size: 10,
    offset: 20,
    orderBy: [OrderBy(ProductEntity.fields.name)],
  ),
);

final List<Product> products = page.items;
final bool hasMore = page.hasNext;
```

`size` is the maximum number of items in the page. `offset` skips that many
matching records before the page starts. The engine reads one extra item when
needed to calculate `hasNext`; that item is not included in `items`.

## Combine pagination with filters

Pass the same filter used by a normal collection read:

```dart
final Page<Product> page = await dorm.products.repository.peekPage(
  Filter.numericRange(
    const FilterRange<double>(from: 10, to: 50),
    field: ProductEntity.fields.price,
  ),
  OffsetPageRequest(
    size: 20,
    offset: 0,
    orderBy: [OrderBy(ProductEntity.fields.name)],
  ),
);
```

The offset applies after the engine evaluates the filter. Keep the ordering
stable while requesting successive pages; [Using sorting](using-sorting.md)
shows how to define it.

## Keep the page type compatible with the engine

The generated `Dorm<Q, P>` and repository types use the page-request type
declared by the engine. Current engines expose `OffsetPageRequest`, so passing
`CursorPageRequest` is rejected by the analyzer when that type is preserved.

This restriction is visible at compile time in generated code. Calls through
`dynamic`, casts, or an intentionally widened generic type do not retain that
static guarantee.
