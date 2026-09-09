# dorm_firestore_database example

<p>
  <a href="https://ezgrs.github.io/dorm/"><img src="https://img.shields.io/badge/documentation-dORM-4c8bf5?style=flat" alt="dORM documentation"></a>
  <a href="https://github.com/ezgrs/dorm"><img src="https://img.shields.io/badge/repository-GitHub-181717?logo=github&style=flat" alt="dORM repository"></a>
  <a href="https://github.com/ezgrs/dorm"><img src="https://img.shields.io/github/license/ezgrs/dorm?style=flat" alt="License"></a>
  <a href="https://github.com/ezgrs/dorm/actions/workflows/dart.yml"><img src="https://github.com/ezgrs/dorm/actions/workflows/dart.yml/badge.svg" alt="Dart CI"></a>
</p>

This Flutter example uses Cloud Firestore through the dORM Firestore engine.
Firebase must be initialized before the engine is created.

## Prerequisites

Configure a Firebase application for the target platform, or use the
Firestore Emulator Suite for local development.

## Run it

Execute these commands from this directory:

~~~shell
flutter pub get
dart run build_runner build
flutter analyze
~~~

For the local emulator:

~~~shell
firebase emulators:start --only firestore
$env:FIRESTORE_EMULATOR_HOST = '127.0.0.1:8080'
flutter run
~~~

The model source is lib/models.dart. Generated files come from that source.
The example constructs Engine with FirebaseFirestore, demonstrates CRUD,
filters, pagination, relationships, and Firestore snapshot streams.
