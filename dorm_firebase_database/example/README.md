# dorm_firebase_database example

<p>
  <a href="https://ezgrs.github.io/dorm/"><img src="https://img.shields.io/badge/documentation-dORM-4c8bf5?style=flat" alt="dORM documentation"></a>
  <a href="https://github.com/ezgrs/dorm"><img src="https://img.shields.io/badge/repository-GitHub-181717?logo=github&style=flat" alt="dORM repository"></a>
  <a href="https://github.com/ezgrs/dorm"><img src="https://img.shields.io/github/license/ezgrs/dorm?style=flat" alt="License"></a>
  <a href="https://github.com/ezgrs/dorm/actions/workflows/dart.yml"><img src="https://github.com/ezgrs/dorm/actions/workflows/dart.yml/badge.svg" alt="Dart CI"></a>
</p>

This Flutter example uses the Firebase Realtime Database engine. It can run
against a Firebase project or a local Realtime Database emulator.

## Prerequisites

Install the Firebase CLI and configure a Firebase application or emulator.
The Flutter application must have the Firebase platform configuration required
by its target.

## Run it

Execute these commands from this directory:

~~~shell
flutter pub get
dart run build_runner build
flutter analyze
~~~

For a local database emulator, start the database service separately:

~~~shell
firebase emulators:start --only database
~~~

Then run the Flutter application:

~~~shell
flutter run
~~~

The model source is lib/models.dart. Generated files are created from that
source. The example initializes Firebase, creates FirebaseInstance, constructs
Engine, and demonstrates repository reads and writes with live streams.
