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
