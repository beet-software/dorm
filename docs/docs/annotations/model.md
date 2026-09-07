# `@Model`

Use `@Model` on an abstract class that represents a stored entity.

```dart title="lib/models.dart"
@Model(name: 'users', as: #users)
abstract class _User {
  @Field(name: 'email')
  String get email;
}
```

The annotation constructor is:

```dart
const Model({
  String? name,
  List<IdSpec> primaryKey = const [GeneratedIdSpec()],
  Symbol? as,
  Function? primaryKeyGenerator,
})
```

- `name` is the stored table, collection, or resource name when the engine
  uses one. If omitted, the generated schema derives a name from the model
  declaration.
- `as` supplies the generated accessor name, such as `dorm.users`.
- `primaryKey` declares generated or existing identity fields.
- `primaryKeyGenerator` customizes the generated identity handling for a
  generated identity specification.

The default primary key is one generated `String` field named `id`.

## Identity specifications

`Model.primaryKey` accepts `IdSpec` values. The two concrete specifications
are `GeneratedIdSpec` and `ExistingIdSpec`.

### `GeneratedIdSpec`

Use the default or an explicit `GeneratedIdSpec` when dORM or the selected
engine generates the identity:

```dart
@Model(
  primaryKey: [
    GeneratedIdSpec(as: #id, name: 'id', type: String),
  ],
)
abstract class _User {
  @Field(name: 'email')
  String get email;
}
```

The constructor is:

```dart
const GeneratedIdSpec({
  Symbol as = #id,
  String name = 'id',
  Type type = String,
})
```

`as` is the generated Dart property name, `name` is the stored field name,
and `type` is the Dart identity type. `primaryKeyGenerator` can transform a
generated identity before the model is persisted.

### `ExistingIdSpec`

Use `ExistingIdSpec` when the primary-key field is already declared by the
annotated class:

```dart
@Model(
  primaryKey: [
    ExistingIdSpec(referTo: #externalId),
  ],
)
abstract class _ImportedUser {
  @Field(name: 'external-id')
  String get externalId;
}
```

For a composite identity, provide multiple existing fields in their declared
order:

```dart
@Model(
  primaryKey: [
    ExistingIdSpec(referTo: #userId),
    ExistingIdSpec(referTo: #productId),
  ],
)
abstract class _CartItem {
  @Field(name: 'user-id')
  String get userId;

  @Field(name: 'product-id')
  String get productId;
}
```

The generator preserves the order of composite key fields. Current generated
repositories require `Creation.explicit` with a `CompositeKey` for composite
creation; `Creation.auto` is rejected statically by the generated creation
type. The identity is part of the generated `Model`, while the generated
`Data` value contains the input fields.

Each `@Model` produces generated data and model types, an entity with schema
metadata, a repository accessor, and a relationship root when related fields
are present. The generated accessors and repository types are described in the
[generated API reference](../reference/generated-api.md).

Use [`@Field`](field.md), [`@ModelField`](model-field.md), and
[`@ForeignField`](foreign-field.md) on the model getters to describe its
stored values.
