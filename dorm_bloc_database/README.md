# dorm_bloc_database

<p>
  <a href="https://pub.dev/packages/dorm_bloc_database"><img src="https://img.shields.io/pub/v/dorm_bloc_database.svg?label=dorm_bloc_database" alt="dorm_bloc_database on pub.dev"></a>
  <a href="https://pub.dev/packages/dorm_bloc_database"><img src="https://img.shields.io/pub/points/dorm_bloc_database?logo=dart" alt="dorm_bloc_database pub points"></a>
  <a href="https://pub.dev/packages/dorm_bloc_database"><img src="https://img.shields.io/pub/popularity/dorm_bloc_database?logo=dart" alt="dorm_bloc_database popularity"></a>
  <a href="https://pub.dev/packages/dorm_bloc_database"><img src="https://img.shields.io/pub/likes/dorm_bloc_database?logo=dart" alt="dorm_bloc_database likes"></a>
  <a href="https://ezgrs.github.io/dorm/apply/use-bloc/"><img src="https://img.shields.io/badge/documentation-dORM-4c8bf5?style=flat" alt="dorm_bloc_database documentation"></a>
  <a href="https://github.com/ezgrs/dorm"><img src="https://img.shields.io/badge/repository-GitHub-181717?logo=github&style=flat" alt="dORM repository"></a>
  <a href="https://github.com/ezgrs/dorm"><img src="https://img.shields.io/github/license/ezgrs/dorm?style=flat" alt="License"></a>
  <a href="https://github.com/ezgrs/dorm/actions/workflows/dart.yml"><img src="https://github.com/ezgrs/dorm/actions/workflows/dart.yml/badge.svg" alt="Dart CI"></a>
</p>

dorm_bloc_database adapts dORM repositories to BLoC-backed in-memory state.
It uses the bloc package and Dart streams instead of an external database
connection.

## Backend and runtime

The backend is process-local BLoC state. It runs in Dart or Flutter and does
not require a database server.

## Install

~~~shell
dart pub add dorm_framework
dart pub add dorm_bloc_database
dart pub add dorm_annotations
dart pub add --dev dorm_generator
dart pub add --dev build_runner
~~~

The package can be used from Dart or Flutter. Add bloc directly only when the
application also uses its BLoC APIs.

## Create the engine

BLoC creates and owns its in-memory reference:

~~~dart
import 'package:dorm_bloc_database/dorm_bloc_database.dart';

final Engine engine = Engine();
final dorm = Dorm(engine);
~~~

The Engine instance is the state boundary. Reuse it when multiple application
components must access the same records.

## Use repositories

~~~dart
final User user = await dorm.users.repository.put(
  Creation.auto(
    dependency: const UserDependency(),
    data: UserData(name: 'Ada'),
  ),
);

final List<User> users = await dorm.users.repository.peekAll(
  Filter.text('Ada', field: UserEntity.fields.name),
);
~~~

## Identities, filters, pages, and relationships

The same generated repositories expose relationships, ordering, limits, pages,
and explicit identities. Filters are declared with generated `FieldSchema`
values, so the application does not repeat persisted column names.

## Transactions

BLoC implements the portable transaction callback:

~~~dart
final txDorm = TransactionalDorm(engine);

await txDorm.transaction((tx) async {
  final User? user = await tx.users.repository.peek(userId);
  if (user != null) {
    await tx.users.repository.push(user.copyWith(active: false));
  }
});
~~~

Changes become visible outside the transaction after commit. A callback error
rolls the transaction state back. Nested transactions are not supported.

## Streams and lifecycle

pull and pullAll expose the BLoC-backed stream behavior. The application owns
the Engine instance; there is no external connection to open or close.

## Schema, errors, and limitations

The engine provides in-memory CRUD, framework filters, relationships, offset
pagination, reactive streams, simple generated identities, explicit composite
identities, and the portable transaction callback. It does not persist data
outside the process.

## Run the example

See the [package example](example/README.md) for the Flutter commands and
generated model setup.

## Links

- [Run with BLoC](https://ezgrs.github.io/dorm/apply/use-bloc/)
- [bloc on pub.dev](https://pub.dev/packages/bloc)
- [dorm_framework](https://pub.dev/packages/dorm_framework)
- [GitHub repository](https://github.com/ezgrs/dorm)
