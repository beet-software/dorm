# Generated Fields

Each generated model has a field metadata class. For `User`, the generated
class is `UserFields`, exposed through `UserEntity.fields`.

Use generated fields when a query should refer to a declared field without
repeating its stored name:

```dart
final List<User> users = await dorm.users.repository.peekAll(
  Filter.value(
    'ada@example.com',
    field: UserEntity.fields.email,
  ),
);
```

The field metadata is also used by generated relationship paths and by engine
query implementations. It retains the storage name declared or inferred by
the annotation.

Derived fields appear in the generated metadata as queryable fields. Their
values are produced by the static callback declared with `@DerivedField` and
persisted with the model.
See [Annotations > DerivedField](../annotations/derived-field.md) for their
declaration and [Using filters](../build-the-store/using-filters.md) for a
query example.

Field metadata identifies a field; it does not execute a query by itself. The
repository operation receives the filter and passes the field information to
the selected engine.
