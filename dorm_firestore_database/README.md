# dorm_firestore_database

<p>
  <a href="https://pub.dev/packages/dorm_firestore_database"><img src="https://img.shields.io/pub/v/dorm_firestore_database.svg?label=dorm_firestore_database" alt="dorm_firestore_database on pub.dev"></a>
  <a href="https://pub.dev/packages/dorm_firestore_database"><img src="https://img.shields.io/pub/points/dorm_firestore_database?logo=dart" alt="dorm_firestore_database pub points"></a>
  <a href="https://pub.dev/packages/dorm_firestore_database"><img src="https://img.shields.io/pub/popularity/dorm_firestore_database?logo=dart" alt="dorm_firestore_database popularity"></a>
  <a href="https://pub.dev/packages/dorm_firestore_database"><img src="https://img.shields.io/pub/likes/dorm_firestore_database?logo=dart" alt="dorm_firestore_database likes"></a>
  <a href="https://ezgrs.github.io/dorm/apply/use-firestore/"><img src="https://img.shields.io/badge/documentation-dORM-4c8bf5?style=flat" alt="dorm_firestore_database documentation"></a>
  <a href="https://github.com/beet-software/dorm"><img src="https://img.shields.io/badge/repository-GitHub-181717?logo=github&style=flat" alt="dORM repository"></a>
  <a href="https://github.com/beet-software/dorm"><img src="https://img.shields.io/github/license/beet-software/dorm?style=flat" alt="License"></a>
  <a href="https://github.com/beet-software/dorm/actions/workflows/dart.yml"><img src="https://github.com/beet-software/dorm/actions/workflows/dart.yml/badge.svg" alt="Dart CI"></a>
</p>

dorm_firestore_database is a Flutter engine backed by Cloud Firestore. It
accepts an application-owned FirebaseFirestore instance from cloud_firestore.

## Backend and runtime

This package requires Flutter, `firebase_core`, and `cloud_firestore`. The
application initializes Firebase and selects production or emulator endpoints.

## Install

~~~shell
flutter pub add dorm_framework
flutter pub add dorm_firestore_database
flutter pub add firebase_core
flutter pub add cloud_firestore
flutter pub add --dev dorm_generator
flutter pub add --dev build_runner
~~~

Initialize Firebase and configure the Firestore instance before constructing
the dORM engine:

~~~dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:dorm_firestore_database/dorm_firestore_database.dart';

await Firebase.initializeApp();

final FirebaseFirestore firestore = FirebaseFirestore.instance;
final Engine engine = Engine(firestore);
final dorm = Dorm(engine);
~~~

For the local emulator, call useFirestoreEmulator before the first Firestore
operation.

## Create the engine and Dorm facade

The setup above creates both objects. Use the generated repositories through
the resulting `Dorm` facade.

## Use repositories

~~~dart
final User user = await dorm.users.repository.put(
  Creation.auto(
    dependency: const UserDependency(),
    data: UserData(name: 'Ada'),
  ),
);

final Page<User> page = await dorm.users.repository.peekPage(
  const BaseFilter.empty(),
  const OffsetPageRequest(size: 20, offset: 0),
);
~~~

Firestore document IDs are simple String identities. The ID is not duplicated
automatically in the document data. Composite identities are not supported.

## Identities, filters, pages, and relationships

Firestore document IDs are simple String identities. The ID is not duplicated
automatically in document data. Composite identities are not supported.
The engine supports framework filters, ordering, offset pagination, and
readable-operation relationship fallbacks.

## Transactions

putAll, pushAll, and popKeys use Firestore WriteBatch. patch uses the SDK
transaction internally. These mechanisms are implementation details of the
individual operations; this engine does not implement the portable
TransactionalDorm capability.

The engine reads and writes nested JSON-like values through Firestore document
maps. It does not convert DateTime values to Firestore Timestamp automatically.

## Streams

`pull` and `pullAll` use Firestore snapshots and emit the initial state followed
by later snapshot changes.

## Schema, errors, and limitations

The four framework relationship forms use readable-operation fallbacks. A
relationship can therefore perform multiple Firestore reads. `parentPath` can
place entity collections under a document such as tenants/acme.

The application owns Firestore rules, indexes, initialization, and data
migration. This package does not generate a schema, migrations, aggregation
queries, or arbitrary native selectors.

## Run the example

See the [package example](example/README.md) for Firebase initialization,
emulator configuration, generation, and Flutter commands.

## Links

- [Run with Cloud Firestore](https://ezgrs.github.io/dorm/apply/use-firestore/)
- [cloud_firestore](https://pub.dev/packages/cloud_firestore)
- [Firebase Emulator Suite](https://firebase.google.com/docs/emulator-suite)
- [dorm_framework](https://pub.dev/packages/dorm_framework)
- [GitHub repository](https://github.com/beet-software/dorm)
