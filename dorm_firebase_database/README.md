# dorm_firebase_database

<p>
  <a href="https://pub.dev/packages/dorm_firebase_database"><img src="https://img.shields.io/pub/v/dorm_firebase_database.svg?label=dorm_firebase_database" alt="dorm_firebase_database on pub.dev"></a>
  <a href="https://pub.dev/packages/dorm_firebase_database"><img src="https://img.shields.io/pub/points/dorm_firebase_database?logo=dart" alt="dorm_firebase_database pub points"></a>
  <a href="https://pub.dev/packages/dorm_firebase_database"><img src="https://img.shields.io/pub/popularity/dorm_firebase_database?logo=dart" alt="dorm_firebase_database popularity"></a>
  <a href="https://pub.dev/packages/dorm_firebase_database"><img src="https://img.shields.io/pub/likes/dorm_firebase_database?logo=dart" alt="dorm_firebase_database likes"></a>
  <a href="https://ezgrs.github.io/dorm/apply/use-firebase/"><img src="https://img.shields.io/badge/documentation-dORM-4c8bf5?style=flat" alt="dorm_firebase_database documentation"></a>
  <a href="https://github.com/ezgrs/dorm"><img src="https://img.shields.io/badge/repository-GitHub-181717?logo=github&style=flat" alt="dORM repository"></a>
  <a href="https://github.com/ezgrs/dorm"><img src="https://img.shields.io/github/license/ezgrs/dorm?style=flat" alt="License"></a>
  <a href="https://github.com/ezgrs/dorm/actions/workflows/dart.yml"><img src="https://github.com/ezgrs/dorm/actions/workflows/dart.yml/badge.svg" alt="Dart CI"></a>
</p>

dorm_firebase_database is the Flutter engine for Firebase Realtime Database.
It uses FirebaseInstance from this package and the Firebase SDK configured by
the application.

## Backend and runtime

This package requires Flutter and `firebase_database`. Firebase initialization,
authentication, emulator selection, and security rules remain application
configuration.

## Install

Run these commands in a Flutter project:

~~~shell
flutter pub add dorm_framework
flutter pub add dorm_firebase_database
flutter pub add firebase_core
flutter pub add firebase_database
flutter pub add --dev dorm_generator
flutter pub add --dev build_runner
~~~

Initialize Firebase with the platform configuration required by the Flutter
application before creating the engine.

## Create the engine and Dorm facade

~~~dart
import 'package:firebase_core/firebase_core.dart';
import 'package:dorm_firebase_database/dorm_firebase_database.dart';

await Firebase.initializeApp();

const FirebaseInstance instance = FirebaseInstance();
final Engine engine = Engine(instance);
final dorm = Dorm(engine);
~~~

The application initializes and owns Firebase. The engine does not create or
close the Firebase app. Pass path when the dORM data should live below a
configured Realtime Database path.

## Use repositories

~~~dart
final User user = await dorm.users.repository.put(
  Creation.auto(
    dependency: const UserDependency(),
    data: UserData(name: 'Ada'),
  ),
);

final stream = dorm.users.repository.pullAll(const BaseFilter.empty());
~~~

Firebase generates simple String push-key identities before persistence.
Creation.explicit can provide a String identity. Composite identities are not
supported by this engine.

pull and pullAll use Firebase listeners and emit later changes received from
the Realtime Database.

## Identities, filters, pages, and relationships

The engine translates the portable value, text, date, range, ordering, and
limit operations to the query forms supported by Realtime Database. The
backend does not provide general boolean query composition. Relationship
resolution uses the generated readable operations and may issue more than one
backend read.

## Transactions

The package does not implement the portable TransactionalDorm capability.
Firebase-specific operations and security rules remain application concerns.
There is no dORM schema generator or migration system.

## Streams

`pull` and `pullAll` use Firebase listeners and emit later changes received
from the Realtime Database.

## Schema, errors, and limitations

The Firebase SDK, Firebase project, emulator, authentication, and security
rules are configured outside this package. Errors from the SDK are propagated
to the application. The engine accepts String identities and does not provide
automatic composite-key generation.

## Run the example

See the [package example](example/README.md) for Firebase initialization,
emulator configuration, generation, and Flutter commands.

## Links

- [Run with Firebase](https://ezgrs.github.io/dorm/apply/use-firebase/)
- [firebase_database](https://pub.dev/packages/firebase_database)
- [Firebase Emulator Suite](https://firebase.google.com/docs/emulator-suite)
- [dorm_framework](https://pub.dev/packages/dorm_framework)
- [GitHub repository](https://github.com/ezgrs/dorm)
