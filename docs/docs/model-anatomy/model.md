# Generated Model

`Model` is the generated identified value returned by reads and writes. It
contains the model fields together with the identity and relationship values
needed by application code.

```dart
final User user = await dorm.users.repository.peek(userId);
print(user.email);
print(user.id);
```

The generated model is used when the identity already exists:

```dart
await dorm.users.repository.push(
  User(
    id: user.id,
    username: user.username,
    email: 'ada@example.org',
    profile: user.profile,
  ),
);
```

Generated models also provide `copyWith`, which returns a new model with
selected fields changed, and `updateWith`, which applies a complete generated
`Data` value while retaining the model identity. [Update records](../build-the-store/updating.md)
shows when to use each helper before calling `push`.

The generated entity reads the identity through `identify(model)`. It passes
the identity separately to `fromJson` when reconstructing a model from stored
data. The identity is encoded according to the model's primary-key codec.

Use [Data](data.md) for creation or update input and [Dependency](dependency.md)
for related identities required during creation. The annotation that defines a
model and its identity is documented in [Annotations > Model](../annotations/model.md).
