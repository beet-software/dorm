# `@PolymorphicData`

Use `@PolymorphicData` on each abstract class that represents one variant of
a polymorphic value.

```dart title="lib/models.dart"
abstract class _ReviewContent {}

@PolymorphicData(name: 'product', as: #product)
abstract class _ProductReviewContent implements _ReviewContent {
  @Field(name: 'rating')
  int get rating;
}
```

The constructor is:

```dart
const PolymorphicData({
  required String name,
  Symbol? as,
})
```

`name` is the discriminator value for the variant. `as` names the generated
Dart variant. Each annotated class produces a concrete generated value with
the fields declared by that variant.

Declare one `@PolymorphicData` class for each payload shape. The classes can
implement a shared abstract type, which is then used by
[`@PolymorphicField`](polymorphic-field.md).

See [Add reviews with multiple content types](../quickstart/reviews-and-polymorphism.md)
for a complete set of product, service, and user review variants.
