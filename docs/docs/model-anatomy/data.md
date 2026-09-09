# Generated Data

`Data` is the generated input shape for model creation and updates. It holds
ordinary model fields, but it does not represent the model's own identity.

For a `User` model, generation produces `UserData`:

```dart
final UserData data = UserData(
  username: 'ada',
  email: 'ada@example.com',
  profile: profile,
);
```

Pass the value to `Creation` when creating a record:

```dart
final User user = await dorm.users.repository.put(
  Creation.auto(
    dependency: const UserDependency(),
    data: data,
  ),
);
```

`Data` values can also be passed to `convert` through `patch` or used by the
generated model update helpers. The selected engine receives their serialized
field values through the generated entity.

An annotated `@Data` declaration can produce a reusable embedded value such as
`Profile`. An annotated `@Model` produces a data type for the stored entity.
The annotation forms are documented in [Annotations > Data](../annotations/data.md)
and [Annotations > Model](../annotations/model.md).

The distinction between `Data` and the identified [Model](model.md) prevents
creation input from carrying an identity that has not yet been resolved.
