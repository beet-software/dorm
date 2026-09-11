# Recipes

These recipes focus on application situations where the dORM API is useful
but not always obvious. The code uses `Product`, `Cart`, and `CartItem` as
concrete stand-ins for generated models. Apply the same patterns to any model
in your application.

The snippets assume a configured generated facade:

```dart
final dorm = Dorm(engine);
```

The selected engine supplies the concrete `Filter` type and determines which
backend capabilities are available. The repository calls remain the same.

## Turn navigation data into an update

A Flutter form often returns values through route arguments or another screen
boundary. Keep those values separate from the persisted model. Convert them to
the generated `Data` type, then use `updateWith` to retain the model's
identity.

The form itself is not part of this recipe. Assume the previous screen passed
an input object through navigation:

```dart
class EditProductInput {
  const EditProductInput({
    required this.name,
    required this.description,
    required this.price,
  });

  final String name;
  final String description;
  final String price;
}
```

Read the input in the destination screen, create `ProductData`, and persist an
identified model:

```dart
Future<void> saveProductFromRoute(
  Dorm dorm,
  Product current,
  EditProductInput input,
) async {
  final ProductData data = ProductData(
    name: input.name.trim(),
    description: input.description.trim(),
    price: Decimal.parse(input.price),
  );

  final Product updated = current.updateWith(data);
  await dorm.products.repository.push(updated);
}
```

The important boundary is `ProductData`: it contains the values being edited,
while `Product` contains the identity required by `push`. Parse and validate
the input before constructing `ProductData`; the repository should receive a
valid application value rather than raw form strings.

## Update from the latest stored value

Use `patch` when the new value depends on what is currently stored. This avoids
the non-atomic read, application callback, and write sequence that would occur
if the calls were assembled manually:

```dart
Future<void> renameProduct(Dorm dorm, String productId) {
  return dorm.products.repository.patch(productId, (current) {
    if (current == null) {
      return null;
    }

    return current.copyWith(
      name: '${current.name} (updated)',
    );
  });
}
```

Returning a model replaces the stored record. Returning `null` removes an
existing record. When the identity does not exist, the callback receives
`null`; returning `null` leaves the repository unchanged.

Use `copyWith` when only selected model fields change. Use `updateWith` when a
complete `Data` value came from a form, route, command, or another application
boundary. See [Update records](../../operations/updating.md) for the
complete update contract.

## Refresh a list without creating a stream

Use `peekAll` when the feature needs a completed result and controls when the
read happens. This is useful after a navigation result, a successful write, or
an explicit refresh action:

```dart
Future<List<Product>> loadProducts(Dorm dorm) {
  return dorm.products.repository.peekAll(
    const Filter.empty(),
    QueryOptions(
      orderBy: [OrderBy(ProductEntity.fields.name)],
    ),
  );
}

Future<List<Product>> saveAndRefresh(
  Dorm dorm,
  Product product,
) async {
  await dorm.products.repository.push(product);
  return loadProducts(dorm);
}
```

Calling `loadProducts` again starts a new read and returns a new list. No
subscription remains active between calls. This is different from `pullAll`,
which is a stream API intended for consumers that need later events.

## Turn screen state into a searchable query

Keep the state of a search field separate from the query object. Resolve every
field through generated metadata so the query uses the persisted name selected
by the model declaration:

```dart
Future<List<Product>> searchProducts(
  Dorm dorm, {
  required String searchText,
}) {
  final String prefix = searchText.trim();
  final Filter filter = prefix.isEmpty
      ? const Filter.empty()
      : Filter.text(
          prefix,
          field: ProductEntity.fields.name,
        );

  return dorm.products.repository.peekAll(
    filter,
    QueryOptions(
      orderBy: [OrderBy(ProductEntity.fields.name)],
    ),
  );
}
```

`Filter.text` is a prefix operation. It is not substring search, regular
expression matching, or full-text search. The same pattern applies to a
category selector, date range, or numeric range: read the control value,
construct a typed filter with `FieldSchema`, and pass it to the repository.

When several conditions must be combined, use `Filter.allOf` only with an
engine that declares logical-filter support:

```dart
final Filter filter = Filter.allOf([
  Filter.text(
    'keyboard',
    field: ProductEntity.fields.name,
  ),
  Filter.numericRange(
    const FilterRange<double>(to: 100),
    field: ProductEntity.fields.price,
  ),
]);
```

Do not silently download the whole collection to emulate a query unsupported
by the selected backend. Check the [engine and platform support table](../../reference/engine-support.md)
before composing optional filter operators.

## Keep pagination state with the query state

Pagination becomes inconsistent when the page number changes but the filter or
ordering is forgotten. Keep those values together and reset the offset when a
new search starts:

```dart
class ProductListState {
  const ProductListState({
    this.search = '',
    this.page = 0,
  });

  final String search;
  final int page;
}

Future<Page<Product>> loadProductPage(
  Dorm dorm,
  ProductListState state,
) {
  final Filter filter = state.search.trim().isEmpty
      ? const Filter.empty()
      : Filter.text(
          state.search.trim(),
          field: ProductEntity.fields.name,
        );

  return dorm.products.repository.peekPage(
    filter,
    OffsetPageRequest(
      size: 20,
      offset: state.page * 20,
      orderBy: [OrderBy(ProductEntity.fields.name)],
    ),
  );
}
```

When the search text changes, create a new state with `page: 0`. When the user
advances, increment the page only when the previous result has `hasNext`:

```dart
if (currentPage.hasNext) {
  state = ProductListState(
    search: state.search,
    page: state.page + 1,
  );
}
```

The current engines accept `OffsetPageRequest`. Keep the ordering stable for
every page request. See [Using pagination](../../operations/using-pagination.md)
for the page contract.

## Render a live collection in Flutter

Use `pullAll` when the screen must receive the initial collection and later
events. Create the stream once for the screen rather than rebuilding it on
every `build` call:

```dart
class ProductList extends StatefulWidget {
  const ProductList({required this.dorm, super.key});

  final Dorm dorm;

  @override
  State<ProductList> createState() => _ProductListState();
}

class _ProductListState extends State<ProductList> {
  late final Stream<List<Product>> products;

  @override
  void initState() {
    super.initState();
    products = widget.dorm.products.repository.pullAll(
      const Filter.empty(),
      QueryOptions(orderBy: [OrderBy(ProductEntity.fields.name)]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Product>>(
      stream: products,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Could not load products: ${snapshot.error}');
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }

        final List<Product> values = snapshot.data ?? const <Product>[];
        if (values.isEmpty) {
          return const Text('No products found.');
        }

        return ListView(
          children: [
            for (final Product product in values)
              ListTile(title: Text(product.name)),
          ],
        );
      },
    );
  }
}
```

The first event is the current result. Later events depend on the selected
engine. Some engines provide reactive streams, while others emit only the
initial read. Confirm the behavior in the [engine and platform support table](../../reference/engine-support.md)
before treating the stream as live synchronization.

## Load a model together with related records

A relation path is useful when the screen needs each source record paired with
its related value. The following pattern keeps a cart item even when its
product cannot be read:

```dart
final List<Join<CartItem, Product?>> rows = await dorm
    .relations
    .cartItems
    .productOrNull
    .peekAll(
      Filter.value(
        cartId,
        field: CartItemEntity.fields.cartId,
      ),
    );

for (final Join<CartItem, Product?> row in rows) {
  final String productName = row.right?.name ?? 'Product unavailable';
  print('${row.left.amount} × $productName');
}
```

Use the nullable path when missing related values should remain visible to the
application. Use the required path when a source record without its related
value should be removed from the result. The same generated paths can be
chained for deeper reads.

## Create related records as one application action

Create the parent first when its generated identity is needed by child
dependencies. Then pass one `Creation` per child to `putAll`:

```dart
final Cart cart = await dorm.carts.repository.put(
  Creation.auto(
    dependency: CartDependency(userId: user.id),
    data: CartData(timestamp: DateTime.now()),
  ),
);

await dorm.cartItems.repository.putAll([
  Creation.auto(
    dependency: CartItemDependency(
      cartId: cart.id,
      productId: firstProduct.id,
    ),
    data: const CartItemData(amount: 1),
  ),
  Creation.auto(
    dependency: CartItemDependency(
      cartId: cart.id,
      productId: secondProduct.id,
    ),
    data: const CartItemData(amount: 2),
  ),
]);
```

`Dependency` carries related identities; it does not become the new model's
own identity. When the parent and children must commit or roll back together,
run both repository operations through the temporary `tx` context supplied by
`TransactionalDorm`:

```dart
final TransactionalDorm txDorm = TransactionalDorm(engine);

await txDorm.transaction((tx) async {
  final Cart cart = await tx.carts.repository.put(
    Creation.auto(
      dependency: CartDependency(userId: user.id),
      data: CartData(timestamp: DateTime.now()),
    ),
  );

  await tx.cartItems.repository.putAll([
    Creation.auto(
      dependency: CartItemDependency(
        cartId: cart.id,
        productId: firstProduct.id,
      ),
      data: const CartItemData(amount: 1),
    ),
  ]);
});
```

Use the transaction form only with an engine that implements
`TransactionalEngine`. Obtain every repository from `tx`; do not mix the
outer `dorm` facade into the callback. See [Using transactions](../../operations/using-transactions.md)
for the transaction context rules.
