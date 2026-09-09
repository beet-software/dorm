# dorm_mongo_database

<p>
  <a href="https://pub.dev/packages/dorm_mongo_database"><img src="https://img.shields.io/pub/v/dorm_mongo_database.svg?label=dorm_mongo_database" alt="dorm_mongo_database on pub.dev"></a>
  <a href="https://pub.dev/packages/dorm_mongo_database"><img src="https://img.shields.io/pub/points/dorm_mongo_database?logo=dart" alt="dorm_mongo_database pub points"></a>
  <a href="https://pub.dev/packages/dorm_mongo_database"><img src="https://img.shields.io/pub/popularity/dorm_mongo_database?logo=dart" alt="dorm_mongo_database popularity"></a>
  <a href="https://pub.dev/packages/dorm_mongo_database"><img src="https://img.shields.io/pub/likes/dorm_mongo_database?logo=dart" alt="dorm_mongo_database likes"></a>
  <a href="https://ezgrs.github.io/dorm/apply/use-mongo/"><img src="https://img.shields.io/badge/documentation-dORM-4c8bf5?style=flat" alt="dorm_mongo_database documentation"></a>
  <a href="https://github.com/beet-software/dorm"><img src="https://img.shields.io/badge/repository-GitHub-181717?logo=github&style=flat" alt="dORM repository"></a>
  <a href="https://github.com/beet-software/dorm"><img src="https://img.shields.io/github/license/beet-software/dorm?style=flat" alt="License"></a>
  <a href="https://github.com/beet-software/dorm/actions/workflows/dart.yml"><img src="https://github.com/beet-software/dorm/actions/workflows/dart.yml/badge.svg" alt="Dart CI"></a>
</p>

dorm_mongo_database adapts dORM repositories to MongoDB through mongo_dart.
It accepts an application-owned opened Db and does not manage its lifecycle.

## Backend and runtime

The backend is MongoDB through `mongo_dart`. It requires a Dart runtime
compatible with `dart:io`.

## Install

~~~shell
dart pub add dorm_framework
dart pub add dorm_mongo_database
dart pub add mongo_dart
dart pub add dorm_annotations
dart pub add --dev dorm_generator
dart pub add --dev build_runner
~~~

The package requires a Dart runtime compatible with dart:io.

## Create the engine and Dorm facade

~~~dart
import 'package:mongo_dart/mongo_dart.dart';
import 'package:dorm_mongo_database/dorm_mongo_database.dart';

final Db database = Db('[PLACEHOLDER: MongoDB URI]');
await database.open();

try {
  final engine = Engine(database);
  final dorm = Dorm(engine);
  // Use generated repositories here.
} finally {
  await database.close();
}
~~~

The application opens and closes Db. Reusing the same Engine and Db keeps all
repositories connected to the same database.

## Use repositories

~~~dart
final User user = await dorm.users.repository.put(
  Creation.auto(
    dependency: const UserDependency(),
    data: UserData(name: 'Ada'),
  ),
);

await dorm.users.repository.push(user.copyWith(name: 'Ada Lovelace'));
~~~

## Identities

The engine stores dORM identities in fields declared by EntitySchema. It does
not convert the identity to MongoDB ObjectId and does not use MongoDB _id as
the dORM identity.

Creation.auto generates UUID strings for supported simple identities.
Creation.explicit supplies the final identity. push and pushAll use replacement
upserts.

## Filters, pages, and relationships

The engine supports framework filters, sorting, offset pagination, and all
framework relationship forms. Relationship fallbacks can perform multiple
MongoDB reads.

## Streams

`pull` and `pullAll` emit the initial read only. Change streams are not exposed
by the dORM API.

## Transactions

The engine does not implement `TransactionalDorm` or MongoDB sessions.

## Schema, errors, and limitations

The engine does not implement TransactionalDorm, MongoDB sessions, aggregation,
index management, native selectors, schema generation, or migrations.

The application owns collection setup, indexes, authentication, and database
permissions.

## Run the example

See the [package example](example/README.md) for the MongoDB URI, connection
lifecycle, generation, and Dart commands.

## Links

- [Run with MongoDB](https://ezgrs.github.io/dorm/apply/use-mongo/)
- [mongo_dart](https://pub.dev/packages/mongo_dart)
- [dorm_framework](https://pub.dev/packages/dorm_framework)
- [GitHub repository](https://github.com/beet-software/dorm)
