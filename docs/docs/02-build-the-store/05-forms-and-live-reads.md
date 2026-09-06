# Connect forms to repositories and keep reads live

An application boundary usually collects values before it writes them. In a pure Dart application, that boundary may be a command handler, HTTP adapter, CLI parser, or service class rather than a UI form.

The repository API keeps input data, generated identities, and foreign dependencies separate. Use that separation when collecting input and when subscribing to changes.

## Turn input into a `Data` value

Collect the values needed by the model and construct its generated `Data` type:

```dart
UserData userDataFromInput(Map<String, String> input) {
  return UserData(
    username: input['username']!,
    email: input['email']!,
    profile: Profile(
      name: input['name']!,
      birthDate: DateTime.parse(input['birth-date']!),
      bio: input['bio'],
    ),
  );
}
```

Pass the resulting `UserData` to `put` together with `UserDependency`:

```dart
final User created = await dorm.users.repository.put(
  const UserDependency(),
  userDataFromInput(input),
);
```

For a new record, do not manufacture the model identity in the input object. `put` creates the identified `User`. For a related record, pass foreign identities through its dependency, as with `CartItemDependency(productId: ..., cartId: ...)`.

## Use an existing identity on an update

When an input operation edits an existing user, read or receive the identity separately and choose either `push` or `patch`:

```dart
final User? current = await dorm.users.repository.peek(userId);

if (current != null) {
  await dorm.users.repository.push(
    User(
      id: current.id,
      username: current.username,
      email: input['email']!,
      profile: current.profile,
    ),
  );
}
```

`UserData` supplies replacement field values. `User` supplies the identity required by `push`. `patch` is the alternative when the update must inspect the stored model inside the repository operation.

## Subscribe to one record

Use `pull` for a live read of one identity:

```dart
import 'dart:async';

StreamSubscription<User?> watchUser(String userId) {
  return dorm.users.repository.pull(userId).listen((user) {
    if (user == null) {
      print('The user is unavailable');
    } else {
      print('Signed in as ${user.username}');
    }
  });
}
```

The returned `StreamSubscription` belongs to the caller. Cancel it when the command, process, or screen that owns the subscription ends:

```dart
final StreamSubscription<User?> subscription = watchUser(user.id);

// ... stop consuming the user ...
await subscription.cancel();
```

The stream value remains nullable because the record may be removed after the subscription starts.

## Subscribe to a filtered collection

Use `pullAll` for a changing list:

```dart
final StreamSubscription<List<Product>> subscription = dorm
    .products
    .repository
    .pullAll(Filter.text('note', key: '_q-name'))
    .listen((products) {
      for (final Product product in products) {
        print(product.name);
      }
    });

await subscription.cancel();
```

The filter is applied to each emitted collection. The stream is not a snapshot object that updates itself after the subscription is canceled; canceling stops this consumer from receiving further events.

## Keep application concerns outside the repository

The repository receives generated `Data`, `Dependency`, and `Model` values. Parsing command-line arguments, decoding an HTTP request, deciding which fields are required by the application, and formatting output happen at the application boundary.

The repository then performs the model operation and returns either a model, a collection, a stream, or an error from the operation. Handle those results at the boundary that owns the command or subscription.
