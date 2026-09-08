# Run the store with MongoDB

This page uses a pure Dart application and the `dorm_mongo_database` engine.
The application creates, opens, and closes the MongoDB `Db` instance.

## Add the packages

From the Dart application directory, execute:

```shell
dart pub add dorm_framework
dart pub add dorm_annotations
dart pub add dorm_mongo_database
dart pub add mongo_dart
dart pub add dev:dorm_generator
dart pub add dev:build_runner
dart pub add dev:json_serializable
```

The application imports `mongo_dart` directly to create the database
connection. The dORM engine barrel exports `Engine`, `Filter`, and `Query`.

## Open MongoDB and create the engine

Read the URI from application configuration, create a `Db`, open it, and pass
the opened object to `Engine`:

```dart
final Db database = Db(
  Platform.environment['MONGO_URI'] ??
      'mongodb://127.0.0.1:27017/dorm_example',
);
await database.open();

final Dorm<Query, OffsetPageRequest> dorm = Dorm(Engine(database));
```

Keep the `Db` open while generated repositories can issue operations. Close it
from the application lifecycle after those operations finish:

```dart
await database.close();
```

The URI's database must be available to the MongoDB server. The engine does
not create a separate dORM schema or migration history.

## Map model fields to documents

The model `name` values become MongoDB collection names and the field names in
the generated schema become document field names. A simple identity remains
in the declared identity field; dORM does not replace it with MongoDB's
`_id` field or convert it to `ObjectId`.

For generated models with a default `String` identity, `Creation.auto` causes
`put` to create a UUID string. Use `Creation.explicit` when the final identity
is known before creation. For a composite identity, pass a `CompositeKey` to
`Creation.explicit`; automatic generation of composite identities is not
supported.

## Execute CRUD, filters, and relationships

Use generated repositories and relationship paths through the same framework
surface as the other engines:

```dart
final User user = await dorm.users.repository.put(
  Creation.auto(
    dependency: UserDependency(),
    data: UserData(name: 'Ada'),
  ),
);

await dorm.posts.repository.push(
  Post(id: 'post-1', title: 'First post', userId: user.id),
);

final List<User> users = await dorm.users.repository.peekAll(
  Filter.text('Ad', key: UserEntity.fields.name.fieldName),
);

final List<Join<User, Post>> posts = await dorm.relations.users.posts
    .peekAll();
```

MongoDB filters support equality, text-prefix matching, date and range
conditions, ascending sort, and limits. Text prefixes are escaped before they
are used as regular expressions, so regex metacharacters in a prefix are
matched literally.

Identified writes use MongoDB replacement upserts. `patch` reads the model,
passes the current value to the callback, and replaces or removes the result.
`pushAll` performs replacement upserts one model at a time and is not atomic.

Relationship reads support one-to-one, one-to-many, many-to-one, and
many-to-many paths. Direct generated table sources can use grouped identity
selectors; other readable sources use their normal read operations.

## Read streams

MongoDB `pull` and `pullAll` emit the initial read and then complete. They do
not subscribe to MongoDB change streams. Use `peek` or `peekAll` for a single
read when a stream is not required.

## Create and clean development collections

Create collections and indexes with MongoDB tools or application code when
your project requires them. The package does not provide schema generation,
migrations, aggregation, native selector access, index management, public
transactions, or change-stream configuration.

Keep cleanup scoped to a development database. The pure Dart package example
uses `MONGO_URI` and explicitly clears its two development collections before
and after execution.

## Configure MongoDB access

The application owns the MongoDB URI, authentication settings, and `Db`
lifecycle. Keep the URI and credentials in deployment configuration. The dORM
engine does not provide an authorization or secrets-store abstraction.

MongoDB permissions and network access are enforced by the MongoDB deployment.
The engine translates framework filters into driver selectors; authorization
remains at the application and MongoDB boundaries.

## Understand the transaction boundary

MongoDB itself supports transactions across documents and collections, but the
current dORM engine receives an application-owned `Db` and uses its collection
operations directly. It does not receive or create a transaction session, so
`TransactionalDorm` is not available for this engine.

The current limitation is at the engine and driver integration boundary. A
MongoDB server transaction is not automatically applied to the existing
repository operations.

## Observe performance characteristics

Direct MongoDB operations map to collection reads, replacements, and deletes.
Identified writes use replacement upserts. `pushAll` performs replacement
operations one model at a time and does not provide an atomic batch guarantee.

When `popAll` uses a limit or ordering, the engine first reads the identities
and then removes them. Direct relationship sources can use grouped selectors;
other sources fall back to readable operations and can issue additional reads.
`pull` and `pullAll` emit the initial read only.
