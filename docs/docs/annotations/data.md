# `@Data`

Use `@Data()` for a reusable serializable value. A data type can be embedded
in a model or used as the input value for creation and updates.

```dart title="lib/models.dart"
@Data()
abstract class _Profile {
  @Field(name: 'name')
  String get name;

  @Field(name: 'bio')
  String? get bio;
}
```

The generator creates a concrete `Profile` value and JSON conversion methods
for the annotated shape. `@Data` does not declare an entity identity and does
not create a repository accessor.

Use `@Field` inside the data declaration to describe each stored value. See
[`@Field`](field.md) for field names and defaults.

When a data value is embedded in a stored entity, declare the containing getter
with [`@ModelField`](model-field.md). The generated `Data` value then contains
the embedded value, while the containing model keeps its own identity.

The generated data value is distinct from the generated model:

- `Data` contains values supplied by an application command;
- `Model` contains the persisted identity and model fields.

See the [Generated output contract](../reference/generated-contract.md) for the types
produced from an annotated data declaration.
