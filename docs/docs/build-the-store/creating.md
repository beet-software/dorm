# Create records

Use `put` when the application has create/update input and needs the repository
to construct and identify the model. Use `push` when the complete identified
model already exists; the update page covers that operation.

## Create one record

Pass a `Creation` containing the dependency, data, and identity request:

```dart
final User created = await dorm.users.repository.put(
  Creation.auto(
    dependency: const UserDependency(),
    data: UserData(
      username: 'ada',
      email: 'ada@example.com',
      profile: Profile(
        name: 'Ada Lovelace',
        birthDate: DateTime(1815, 12, 10),
        bio: null,
      ),
    ),
  ),
);
```

`Creation.auto` asks the engine to generate the identity when that entity
supports automatic identity generation. The returned `User` contains the
final identity and can be passed to later reads or updates.

For a simple identity that the application already owns, use
`Creation.explicit`:

```dart
final User imported = await dorm.users.repository.put(
  Creation.explicit(
    dependency: const UserDependency(),
    data: UserData(
      username: 'grace',
      email: 'grace@example.com',
      profile: Profile(
        name: 'Grace Hopper',
        birthDate: DateTime(1906, 12, 9),
        bio: null,
      ),
    ),
    identity: 'legacy-user-42',
  ),
);
```

The identity is final. The engine does not apply its automatic identity
generator to an explicitly supplied value.

## Create records with dependencies

A model with foreign fields receives those related identities through its
generated dependency type. Create the dependency from the relation values and
pass it with the model data. The dependency is not the new model's own
identity; it describes the related records needed to construct it.

The cart workflow in [Add carts and cart items](../quickstart/relations-and-cart.md)
uses this form.

## Create several records

Use `putAll` with one `Creation` per record:

```dart
final List<User> createdUsers = await dorm.users.repository.putAll([
  Creation.auto(
    dependency: const UserDependency(),
    data: UserData(
      username: 'ada',
      email: 'ada@example.com',
      profile: Profile(
        name: 'Ada Lovelace',
        birthDate: DateTime(1815, 12, 10),
        bio: null,
      ),
    ),
  ),
  Creation.explicit(
    dependency: const UserDependency(),
    data: UserData(
      username: 'grace',
      email: 'grace@example.com',
      profile: Profile(
        name: 'Grace Hopper',
        birthDate: DateTime(1906, 12, 9),
        bio: null,
      ),
    ),
    identity: 'legacy-user-42',
  ),
]);
```

Each item carries its own dependency, data, and identity strategy. A composite
identity must be supplied explicitly; the generated API does not accept
`Creation.auto` for a composite-key entity.

## Confirm the write result

`put` and `putAll` return the identified models produced by the operation. Use
those returned values when the next operation needs the generated identity.
For an existing model, continue with [Update records](updating.md).
