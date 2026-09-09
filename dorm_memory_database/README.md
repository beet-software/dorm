# dorm_memory_database

<p>
  <a href="https://pub.dev/packages/dorm_memory_database"><img src="https://img.shields.io/pub/v/dorm_memory_database.svg?label=dorm_memory_database" alt="dorm_memory_database on pub.dev"></a>
  <a href="https://pub.dev/packages/dorm_memory_database"><img src="https://img.shields.io/pub/points/dorm_memory_database?logo=dart" alt="dorm_memory_database pub points"></a>
  <a href="https://pub.dev/packages/dorm_memory_database"><img src="https://img.shields.io/pub/popularity/dorm_memory_database?logo=dart" alt="dorm_memory_database popularity"></a>
  <a href="https://pub.dev/packages/dorm_memory_database"><img src="https://img.shields.io/pub/likes/dorm_memory_database?logo=dart" alt="dorm_memory_database likes"></a>
  <a href="https://ezgrs.github.io/dorm/apply/use-memory/"><img src="https://img.shields.io/badge/documentation-dORM-4c8bf5?style=flat" alt="dorm_memory_database documentation"></a>
  <a href="https://github.com/ezgrs/dorm"><img src="https://img.shields.io/badge/repository-GitHub-181717?logo=github&style=flat" alt="dORM repository"></a>
  <a href="https://github.com/ezgrs/dorm"><img src="https://img.shields.io/github/license/ezgrs/dorm?style=flat" alt="License"></a>
  <a href="https://github.com/ezgrs/dorm/actions/workflows/dart.yml"><img src="https://github.com/ezgrs/dorm/actions/workflows/dart.yml/badge.svg" alt="Dart CI"></a>
</p>

dorm_memory_database is the pure Dart in-memory engine for dORM. It uses Dart
maps and UUID generation, so it does not require a database server or a
connection object.

## Backend and runtime

The backend is process-local Dart state. It is suitable for a pure Dart or
Flutter application that needs an in-process store.

## Install

~~~shell
dart pub add dorm_framework
dart pub add dorm_memory_database
dart pub add dorm_annotations
dart pub add --dev dorm_generator
dart pub add --dev build_runner
~~~

The generator dependencies are needed only when the application declares or
changes annotated models.

## Create the engine

The engine owns an independent in-process store:

~~~dart
import 'package:dorm_memory_database/dorm_memory_database.dart';

final Engine engine = Engine();
final dorm = Dorm(engine);
~~~

Reuse the same Engine instance wherever the application must see the same
records. A new Engine starts with empty state.

## Use repositories

The repository API is the same as the other dORM engines:

~~~dart
final User user = await dorm.users.repository.put(
  Creation.auto(
    dependency: const UserDependency(),
    data: UserData(name: 'Ada'),
  ),
);

final User? loaded = await dorm.users.repository.peek(user.id);
await dorm.users.repository.push(user.copyWith(name: 'Ada Lovelace'));
~~~

## Identities, filters, pages, and relationships

Filters, sorting, offset pages, relationships, and composite identities use
the contracts from dorm_framework.

## Identities

Simple Creation.auto identities are UUID strings. Composite identities must be
provided through Creation.explicit.

## Transactions

Memory implements TransactionalDorm. The transaction context isolates changes
until the callback completes:

~~~dart
final txDorm = TransactionalDorm(engine);

await txDorm.transaction((tx) async {
  final User? user = await tx.users.repository.peek(userId);
  if (user != null) {
    await tx.users.repository.push(user.copyWith(name: 'Updated'));
  }
});
~~~

An exception rolls the in-memory changes back. Streams do not publish
intermediate transaction state.

## Streams and lifecycle

pull and pullAll emit the current value and later changes caused by writes.
The engine has no external lifecycle to close. Its state ends when the Engine
instance is discarded.

## Schema, errors, and limitations

The engine provides:

- CRUD and batch operations;
- framework filters, sorting, and offset pagination;
- all framework relationship forms;
- reactive streams;
- the portable transaction callback;
- simple UUID identities and explicit composite identities.

The store is process-local. It is not a durable database and does not share
state with another process.

## Run an example

Generate a ready-to-run project with the showcase CLI:

~~~shell
dart pub global activate dorm_example
dorm_example -e memory
~~~

## Links

- [Run with Memory](https://ezgrs.github.io/dorm/apply/use-memory/)
- [dorm_framework](https://pub.dev/packages/dorm_framework)
- [dorm_annotations](https://pub.dev/packages/dorm_annotations)
- [GitHub repository](https://github.com/ezgrs/dorm)
