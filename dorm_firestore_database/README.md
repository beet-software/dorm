# dorm_firestore_database

Cloud Firestore engine for dORM applications.

This package is Flutter-specific. Initialize Firebase and configure a
`FirebaseFirestore` instance in the application, then pass that instance to
`Engine`:

```dart
await Firebase.initializeApp();
final FirebaseFirestore firestore = FirebaseFirestore.instance;
final Engine engine = Engine(firestore);
final Dorm<Query, OffsetPageRequest> dorm = Dorm(engine);
```

The engine uses Firestore document IDs as simple `String` identities. It uses
Firestore queries and snapshots for reads and streams, `WriteBatch` for
`putAll`, `pushAll`, and `popKeys`, and `runTransaction` for `patch`.

`parentPath` can identify a document such as `tenants/acme`; entity names are
stored as child collections below that document. Composite identities,
migrations, schema generation, aggregation, and a public dORM transaction API
are not provided by this engine.

See `example/` for a Flutter application and the public documentation for
Firebase initialization, emulator setup, query behavior, and Firestore rules.
