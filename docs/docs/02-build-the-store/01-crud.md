# Create, read, update, and remove store records

The generated store model gives each entity a repository. Use that repository for the normal record lifecycle: create a record, read it, update it, and remove it.

This guide assumes that `lib/models.dart` already contains the generated `User` and `Product` types from [Generate the model](../01-start-here/03-generate-the-model.md).

## Open a repository

Create the engine and the generated database object in the application code:

```dart
import 'package:dorm_bloc_database/dorm_bloc_database.dart';

import 'package:dorm_store/models.dart';

final Dorm dorm = Dorm(Engine());

final userRepository = dorm.users.repository;
final productRepository = dorm.products.repository;
```

The generated `Dorm` accessor comes from the `as` value in each `@Model` declaration. `dorm.users` identifies the `User` entity, and `.repository` exposes its CRUD operations.

The repository type is generated with the entity's data type, model type, and identity type. In this store model, `UserData` is create/update input, `User` is the identified model, and the identity is a `String`.

## Create a user with `put`

Pass a generated dependency and a generated data object to `put`:

```dart
final User created = await userRepository.put(
  const UserDependency(),
  UserData(
    username: 'ada',
    email: 'ada@example.com',
    profile: Profile(
      name: 'Ada Lovelace',
      birthDate: DateTime(1815, 12, 10),
      bio: null,
    ),
  ),
);

print(created.id);
```

`put` creates the `User` model from the `UserData` values, assigns an identity through the selected engine, stores the model, and returns the resulting `User`.

`UserDependency` is generated from the model's dependencies. `User` has no foreign fields, so its dependency has no values. Models with foreign fields use those values in their dependency; the cart workflow uses that form later.

Keep the distinction between these generated types clear:

- `UserData` contains values supplied by the application;
- `User` contains those values plus the record identity;
- `UserDependency` carries the dependency values required to construct a `User`.

## Read one record with `peek`

Use `peek` for one asynchronous read:

```dart
final User? loaded = await userRepository.peek(created.id);

if (loaded == null) {
  print('User not found');
} else {
  print(loaded.email);
}
```

The result is nullable. A missing identity produces `null`, rather than an exception from the repository operation.

Use `peekAll` for a one-shot collection read:

```dart
final List<User> users = await userRepository.peekAll();
```

An empty collection produces an empty list. Pass a filter to restrict the collection; the filter syntax is described in [Search and filter the store](02-query-and-filter.md).

## Read changes with `pull`

Use `pull` when the application needs a stream for one record:

```dart
final subscription = userRepository.pull(created.id).listen((user) {
  if (user == null) {
    print('User was removed');
    return;
  }

  print('Current email: ${user.email}');
});

// Keep the subscription while the consumer is active.
await subscription.cancel();
```

`pull` returns `Stream<User?>`, so the stream can represent both a present record and the absence of that identity. `pullAll` is the collection equivalent and returns `Stream<List<User>>`.

Cancel a stream subscription when the consuming operation ends. A repository stream has a different lifecycle from `peek`, which completes after one read.

## Replace a model with `push`

Use `push` when the complete identified model is available:

```dart
final User updated = User(
  id: created.id,
  username: created.username,
  email: 'ada@example.org',
  profile: created.profile,
);

await userRepository.push(updated);
```

`push` writes the model using its existing identity. The operation replaces the stored value for that identity. The identity must remain the one being updated; the repository identifies the model from its `id` field.

## Change a model with `patch`

Use `patch` when the update depends on the current value or when the caller does not want to rebuild a model before the operation:

```dart
await userRepository.patch(created.id, (current) {
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

The callback receives `null` when the identity is absent. Returning `null` removes the record. Returning a model writes it back. If the callback returns a model with a different identity, the repository keeps the `id` supplied to `patch` for the update operation.

## Remove records

Use the operation that matches the scope of the removal:

```dart
await userRepository.pop(created.id);

await userRepository.popKeys(['user-id-1', 'user-id-2']);

await userRepository.popAll(
  Filter.value('ada@example.org', key: 'email'),
);

await userRepository.purge();
```

`pop` removes one identity and does nothing when that identity is absent. `popKeys` removes the supplied identities. `popAll` removes the records matching a filter. `purge` removes all records from that repository.

## Write several records

Use the batch operations when the input is already grouped:

```dart
final List<User> createdUsers = await userRepository.putAll(
  const UserDependency(),
  [
    UserData(
      username: 'ada',
      email: 'ada@example.com',
      profile: Profile(
        name: 'Ada Lovelace',
        birthDate: DateTime(1815, 12, 10),
        bio: null,
      ),
    ),
  ],
);

await userRepository.pushAll(createdUsers);
```

`putAll` creates models from one dependency and a list of data values. `pushAll` writes already identified models. `peekAllKeys` returns the identities currently stored by the repository.

The CRUD API has separate one-shot operations and stream operations. Choose the one-shot form when the caller needs a completed `Future`; keep and cancel the subscription when the caller needs ongoing updates.
