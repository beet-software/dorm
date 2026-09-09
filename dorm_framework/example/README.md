# dorm_framework example

<p>
  <a href="https://ezgrs.github.io/dorm/"><img src="https://img.shields.io/badge/documentation-dORM-4c8bf5?style=flat" alt="dORM documentation"></a>
  <a href="https://github.com/ezgrs/dorm"><img src="https://img.shields.io/badge/repository-GitHub-181717?logo=github&style=flat" alt="dORM repository"></a>
  <a href="https://github.com/ezgrs/dorm"><img src="https://img.shields.io/github/license/ezgrs/dorm?style=flat" alt="License"></a>
  <a href="https://github.com/ezgrs/dorm/actions/workflows/dart.yml"><img src="https://github.com/ezgrs/dorm/actions/workflows/dart.yml/badge.svg" alt="Dart CI"></a>
</p>

This Flutter application demonstrates the generated dORM API with a small
store domain. It includes model declarations, CRUD operations, relationships,
filters, forms, and live reads.

## Prerequisites

Install the Flutter SDK and ensure a browser or desktop target is available.
The example also needs the Firebase CLI when using its local Realtime Database
emulator.

## Run it

Execute these commands from this directory:

~~~shell
flutter pub get
dart run build_runner build
flutter analyze
flutter run
~~~

To start the optional local database emulator, run this command separately:

~~~shell
firebase emulators:start --only database --project dorm-example
~~~

The annotated source is lib/models.dart. The generated model and serialization
parts are derived from that file. Change the annotations in the source file,
then run build_runner again.

The application uses the generated Dorm facade and the configured engine. The
model and relationship declarations provide the starting point for adapting
the flow to another application.
