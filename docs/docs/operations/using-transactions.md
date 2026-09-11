# Use transactions

Use `TransactionalDorm` when several repository operations must commit or
roll back as one unit. This API is available with the in-memory, BLoC, MySQL, and
PostgreSQL engines.

## Create the transactional facade

Pass the same engine instance to `TransactionalDorm` that you would pass to
`Dorm`:

~~~dart
final TransactionalDorm<Query, OffsetPageRequest> dorm =
    TransactionalDorm(engine);
~~~

The constructor accepts only an engine that implements
`TransactionalEngine<Query, OffsetPageRequest>`. The engine's concrete query
type is the `Query` imported from the selected engine package.

## Run repository operations together

Pass an asynchronous callback to `transaction`. The callback receives a
temporary `Dorm` context. Obtain every repository used by the operation from
that `tx` value:

~~~dart
final Order order = await dorm.transaction((tx) async {
  final User? user = await tx.users.repository.peek(userId);
  if (user == null) {
    throw StateError('The user does not exist.');
  }

  await tx.carts.repository.push(cart);
  return tx.orders.repository.put(
    Creation.auto(
      dependency: const OrderDependency(),
      data: OrderData(userId: user.id),
    ),
  );
});
~~~

The value returned by the callback becomes the result of `transaction`.
Reads, writes, pages, and relationship reads performed through `tx` use the
active transaction context.

## Handle commit and rollback

The transaction commits when the callback completes normally. If the callback
throws, or if the backend rejects an operation, the transaction fails and the
engine propagates the exception. Changes made before the failure are rolled
back by engines that implement this capability.

Use ordinary `try`/`catch` around the call when the application needs to turn a
transaction failure into an application result:

~~~dart
try {
  await dorm.transaction((tx) async {
    await tx.orders.repository.push(order);
    await tx.carts.repository.patch(cart.id, updateCart);
  });
} on Object catch (error) {
  // Handle the callback or backend error.
}
~~~

## Respect the transaction context

Do not keep the callback's `tx` value for later use. It represents the active
transaction only and is invalid after commit or rollback. Streams are not
transactional reads, so `pull` and `pullAll` fail when called from the
callback. Nested calls to `transaction` are also rejected.

The public API does not expose a driver connection, session, batch, savepoint,
SQL command, native selector, or backend-specific transaction object.

## Understand engine-specific transaction limits

The in-memory and BLoC engines keep transaction state in process memory. MySQL reuses the
connection transaction supplied by `mysql_client`, and PostgreSQL reuses the
`Session` supplied by `SessionExecutor.runTx`.

Firebase Realtime Database, Cloud Firestore, MongoDB, and HTTP do not implement
`TransactionalEngine` in the current API. Firebase and Firestore still use
backend transactions internally for individual `patch` operations. Those
internal transactions do not provide the multi-repository callback described
on this page.

The Firebase Realtime Database transaction handler is tied to one
`DatabaseReference`, and the current engine cannot use a filtered query inside
that handler. Cloud Firestore's Dart `Transaction` exposes document reads and
writes, while the dORM collection reads and relationship fallbacks use
collection queries; they are not exposed as one portable transaction context.

The MongoDB engine currently accepts an application-owned `mongo_dart` `Db`
and uses collection operations without a transaction session. MongoDB server
transactions therefore are not available through this dORM API. HTTP has no
transaction protocol in its mapping contract.
