# `@PolymorphicField`

Use `@PolymorphicField` on a model getter that stores the selected
polymorphic payload.

```dart title="lib/models.dart"
@Model(name: 'Reviews', as: #reviews)
abstract class _Review {
  @PolymorphicField(name: 'content', pivotName: 'type')
  _ReviewContent get content;
}
```

The constructor is:

```dart
const PolymorphicField({
  String? name,
  required String pivotName,
  Symbol? pivotAs,
})
```

- `name` is the payload storage name.
- `pivotName` is the discriminator storage name.
- `pivotAs` can name the generated Dart pivot field.

Generation produces a discriminator type, a polymorphic value type, and a
concrete generated class for each [`@PolymorphicData`](polymorphic-data.md)
variant. The selected payload and its discriminator are serialized together.

Use a normal [`@ModelField`](model-field.md) for one fixed embedded shape. Use
`@PolymorphicField` when the payload shape varies according to its
discriminator.
