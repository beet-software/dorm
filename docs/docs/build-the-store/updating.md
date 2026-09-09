# Update records

Use `push` when the complete identified model is available. Use `patch` when
the update depends on the current stored value or may remove the record.

## Replace an identified model

```dart
final User updated = User(
  id: created.id,
  username: created.username,
  email: 'ada@example.org',
  profile: created.profile,
);

await dorm.users.repository.push(updated);
```

`push` writes the model using its existing identity. The identity used for the
operation comes from the model, not from a separate argument.

Use `pushAll` for a list of complete identified models:

```dart
await dorm.users.repository.pushAll([updated]);
```

The engine determines how replacement and batch writes are executed. The
common API does not turn every batch operation into a public transaction.

## Create a replacement with `copyWith`

The generated model exposes `copyWith` for changing selected model fields
while retaining the rest of the model. Use it when the current model already
contains the values that should remain unchanged:

```dart
final User updated = created.copyWith(
  email: 'ada-updated@example.com',
);

await dorm.users.repository.push(updated);
```

`copyWith` returns a new model. In this example, `id`, `username`, and
`profile` remain from `created`, so `push` replaces the same stored record.

## Convert updated data with `updateWith`

Use the generated `updateWith` extension when the application has a complete
`UserData` value, such as data assembled by a form or another boundary:

```dart
final UserData editedData = UserData(
  username: created.username,
  email: 'ada-updated@example.com',
  profile: created.profile,
);
final User updated = created.updateWith(editedData);

await dorm.users.repository.push(updated);
```

`updateWith` creates a model from the supplied data and keeps the identity of
the model on which it is called. The result can therefore be passed to
`push`.

## Change a model with `patch`

```dart
await dorm.users.repository.patch(created.id, (current) {
  if (current == null) {
    return null;
  }

  return User(
    id: current.id,
    username: current.username,
    email: 'ada@example.org',
    profile: current.profile,
  );
});
```

The callback receives `null` when the identity is absent. Returning a model
writes it back. Returning `null` removes it. The repository preserves the
identity supplied to `patch` for the update operation.

For a form that starts with untrusted input, validate it at the application
boundary before constructing `UserData`, then choose `put` or `push` according
to whether the model is new or already identified.
