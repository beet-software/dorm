# dorm_mongo_database

The MongoDB engine for dORM. It implements the engine-independent contracts
from `dorm_framework` using `mongo_dart`.

## Installation

Add the dORM packages, the MongoDB driver, and the generator to a pure Dart
application:

```shell
dart pub add dorm_framework
dart pub add dorm_annotations
dart pub add dorm_mongo_database
dart pub add mongo_dart
dart pub add dev:dorm_generator
dart pub add dev:build_runner
```

Open a `mongo_dart` `Db` in the application and pass it to `Engine`:

```dart
final Db database = Db(uri);
await database.open();
final Dorm dorm = Dorm(Engine(database));
```

The application owns the `Db` lifecycle and closes it after repository use.
The engine stores dORM identities in the fields declared by the generated
schema. It does not convert them to `ObjectId` or use MongoDB `_id` as the
dORM identity.

The package provides CRUD, framework filters, relationships, and initial-read
streams. Identified writes use replacement upserts. It does not expose public
transactions, change streams, aggregation, migrations, index management, or
arbitrary native selectors.

See [`example/`](example/) for a pure Dart application using `MONGO_URI` and
generated models.
