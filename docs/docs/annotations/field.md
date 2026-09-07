# `@Field`

Use `@Field` on a getter that maps one scalar or value field to storage.

```dart title="lib/models.dart"
@Field(name: 'email')
String get email;
```

The annotation constructor is:

```dart
const Field({
  String? name,
  Object? defaultValue,
})
```

- `name` is the stored field name. If omitted, the annotated getter name is
  used.
- `defaultValue` supplies a generated default when the input does not provide
  one. A nullable field without an explicit default can default to `null`.

The Dart return type supplies the field's value type to the generator and JSON
conversion layer. The generated schema retains the stored name for filters,
serialization, and engine mapping.

`@Field` is also the base annotation for [`@ForeignField`](foreign-field.md),
[`@ModelField`](model-field.md), and [`@DerivedField`](derived-field.md). Those
annotations add relationship, embedded-value, or derived-value semantics to a
mapped getter.
