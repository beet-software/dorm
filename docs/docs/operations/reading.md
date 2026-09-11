# Read records

Use a one-shot repository method when the application needs one completed result.
Use a stream method when it needs to keep listening for values and controls how
long that subscription stays active.

## Read one identity

```dart
final User? user = await dorm.users.repository.peek('user-id');

if (user == null) {
  print('User not found');
} else {
  print(user.email);
}
```

`peek` returns `null` when the identity is not present. Missing data is a
result value in this operation, not automatically an exception.

## Read a collection

```dart
final List<User> users = await dorm.users.repository.peekAll();
```

An empty collection returns an empty list. Pass a filter to restrict the
collection. Use [Using filters](using-filters.md) when the read needs matching
conditions, [Using sorting](using-sorting.md) when the result order matters, or
[Using pagination](using-pagination.md) when the result must be bounded by a
page request.

## Subscribe to one record

```dart
final subscription = dorm.users.repository.pull('user-id').listen((user) {
  print(user?.email ?? 'User removed');
});

await subscription.cancel();
```

`pull` returns `Stream<User?>`, so a later value can represent removal. Cancel
the subscription when the consumer no longer needs it.

## Subscribe to a collection

Use `pullAll` for the collection equivalent. The first emitted value is a list
of models. Whether later changes are emitted depends on the engine; compare the
engine and platform support table before relying on live updates.
