# Run the store with Cloud Firestore

`dorm_firestore_database` connects the generated dORM repositories to Cloud
Firestore. It is a Flutter package: initialize Firebase and configure the
Firestore instance before constructing the engine.

!!! warning
    The engine does not initialize, open, or close `FirebaseFirestore`. Keep
    that lifecycle in the application and pass the configured instance to
    `Engine`.

## Add the engine package

From a Flutter project, run:

```shell title="Add the Cloud Firestore engine"
flutter pub add dorm_firestore_database
```

Add the Firebase SDK packages that your application imports directly:

```shell title="Add the Firebase SDK packages"
flutter pub add firebase_core
flutter pub add cloud_firestore
```

The model source and code-generation packages come from the [Quickstart
installation](../quickstart/installation.md). `firebase_core` and
`cloud_firestore` are direct application dependencies because the application
initializes Firebase and passes a `FirebaseFirestore` instance to `Engine`.

## Initialize Firebase and create the engine

Initialize Firebase before reading `FirebaseFirestore.instance`:

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dorm_firestore_database/dorm_firestore_database.dart';
import 'package:firebase_core/firebase_core.dart';

Future<Dorm<Query, OffsetPageRequest>> createDorm() async {
  await Firebase.initializeApp();

  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final Engine engine = Engine(firestore);
  return Dorm(engine);
}
```

The platform Firebase configuration must already be available to the Flutter
application. If the default app cannot be found, add the platform-specific
Firebase configuration for the target platform before running the app.

## Store entities in a nested collection

By default, an entity named `users` is stored in the top-level `users`
collection. To place entity collections below a tenant document, pass an even
segment document path:

```dart
final Engine engine = Engine(
  firestore,
  parentPath: 'tenants/acme',
);
```

The `users` entity then uses `tenants/acme/users`. A `parentPath` identifies a
document, not a collection; `tenants` is therefore invalid because it has only
one path segment.

## Use document IDs as dORM identities

Firestore document IDs are the dORM identities for this engine. Automatic
creation reserves an ID with `collection.doc()`, while explicit creation uses
the supplied non-empty `String` as the document ID.

The identity is passed to generated `fromJson` methods from the document
reference. It is not copied into the document body as another field.

```dart
final User user = await dorm.users.repository.put(
  Creation.auto(
    dependency: const UserDependency(),
    data: const UserData(name: 'Ada'),
  ),
);

await dorm.users.repository.put(
  Creation.explicit(
    dependency: const UserDependency(),
    data: const UserData(name: 'Grace'),
    identity: 'grace',
  ),
);
```

This engine accepts simple `String` identities. Composite identities are not
supported.

## Read, write, and update documents

The generated repository methods keep the same names as the other dORM
engines:

```dart
final User? user = await dorm.users.repository.peek(userId);

final List<User> users = await dorm.users.repository.peekAll(
  const Filter.text('Ad', key: 'name'),
);

await dorm.users.repository.push(
  User(id: userId, name: 'Updated name'),
);

await dorm.users.repository.patch(userId, (current) {
  if (current == null) return null;
  return current.copyWith(name: 'Patched name');
});

await dorm.users.repository.pop(userId);
```

`push` replaces the document at the supplied identity. `patch` runs the read,
callback, and write through a Firestore transaction. Firestore may retry the
transaction callback when a concurrently read document changes, so the
callback must not depend on a single execution.

## Use filters, sorting, and offset pages

Firestore queries support the portable dORM filters and sorting operations that
the engine maps to the SDK:

```dart
final List<User> users = await dorm.users.repository.peekAll(
  const Filter.value(true, key: 'active'),
  const QueryOptions(
    orderBy: [OrderBy('name')],
    limit: 20,
  ),
);
```

The current generated repository type accepts `OffsetPageRequest`. Firestore
does not expose a native offset operation through this engine, so an offset
page reads enough documents to skip the requested prefix and detect
`hasNext`, then applies the skip in the client:

```dart
final Page<User> page = await dorm.users.repository.peekPage(
  const Filter.empty(),
  const OffsetPageRequest(size: 20, offset: 40),
);
```

Firestore query rules, required indexes, and SDK errors remain visible to the
caller.

## Follow document and query changes

`pull` and `pullAll` use Firestore snapshots:

```dart
final Stream<User?> userChanges = dorm.users.repository.pull(userId);
final Stream<List<User>> activeUsers = dorm.users.repository.pullAll(
  const Filter.value(true, key: 'active'),
);
```

Each stream emits the current read when the listener starts and later emits
changes reported by Firestore. The engine does not add polling or a separate
event protocol.

## Use relationships

Foreign fields and generated relation paths use the same repository API as
other engines:

```dart
final List<Join<User, Post>> posts = await dorm.relations.users.posts.peekAll();
```

Firestore relationships use readable operations as their portable fallback.
The engine reads the source models, extracts related IDs, and reads the target
documents. A relationship can therefore issue multiple Firestore reads.

## Understand writes in batches

`putAll`, `pushAll`, and `popKeys` use one Firestore `WriteBatch` and commit the
batch atomically. The engine does not expose that batch as a public dORM
transaction API.

The Firestore batch limit applies. If one of these operations contains more
than 500 writes, the engine throws before sending the batch instead of splitting
it into non-atomic requests. `popAll` and `purge` first read matching
documents and then delete them in a batch; the selection and deletion are not
one public transaction.

## Understand the transaction boundary

Cloud Firestore provides native transactions, and this engine uses one
internally for `patch`. The current Dart transaction object reads individual
documents through `DocumentReference`; it does not provide the collection
query operation used by dORM's `peekAll`, pagination, and relationship
fallbacks.

For that reason, the engine does not implement `TransactionalDorm`. Its
internal `patch` transaction remains separate from a public transaction that
could compose multiple repositories.

## Run against the Firestore Emulator

Start the emulator from the Flutter project that contains your Firebase
configuration:

```shell title="Start the Firestore Emulator"
firebase emulators:start --only firestore
```

Configure the SDK before constructing the engine:

```dart
await Firebase.initializeApp();
final FirebaseFirestore firestore = FirebaseFirestore.instance;
firestore.useFirestoreEmulator('127.0.0.1', 8080);
final Dorm<Query, OffsetPageRequest> dorm = Dorm(Engine(firestore));
```

Use the emulator when developing rules and queries locally. The Firestore
security rules and Firebase Authentication state remain part of the Firebase
application configuration; the dORM engine does not provide an authorization
layer.

## Firestore-specific boundaries

The engine currently does not provide schema generation, migrations,
aggregation, collection-group queries, native selector access, index
management, or a public transaction object. Firestore batches and transactions
are used internally where the operation mapping requires them.
