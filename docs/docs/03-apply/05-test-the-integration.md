# Test generated models, repositories, and engines

Validate a dORM application in the same order that it is built:

1. regenerate generated files;
2. analyze the affected package or application;
3. run tests that do not require an external service;
4. run integration tests with the required backend available.

## Identify the test categories

The available test suites cover different layers:

| Test area | Main evidence |
| --- | --- |
| Framework tests | Filters, relationship paths, primary keys, repository contracts, and generated-style operations |
| Generator tests | Generated output and source-model cases |
| BLoC package tests | In-memory reference behavior, including filtered removal |
| MySQL relationship tests | Relationship implementations using in-memory readable sources; no live MySQL server for those callback cases |
| MySQL reference tests | CRUD, filters, serialization, and SQL behavior; connection settings are required for live database cases |
| Generated example analysis | Whether annotated models and generated output remain analyzable |

Test presence is evidence for the named scenario. It does not establish an untested behavior as a general contract.

## Regenerate before analysis

Run the generator from the package or application directory that owns the annotated source:

```shell
dart pub get
dart run build_runner build
dart analyze
```

For a package test suite whose generated test files are part of the test inputs, the CI workflow uses:

```shell
dart run build_runner build test
```

Generation must run against the source declarations. Do not edit `.dorm.dart` or `.g.dart` files to make a test pass.

## Run framework and local engine tests

From the relevant package directory, run:

```shell
dart test
```

Framework and BLoC tests can run without a live external database. The BLoC package creates its in-memory `Engine` inside the test setup, so each test can control its own state.

For the workspace packages, the available root commands are:

```shell
melos run analyze
melos run test --no-select
melos run generate
```

Run the package-specific command when only one package or example is in scope.

## Run MySQL integration tests

The live MySQL reference tests load these environment values:

```dotenv
MYSQL_HOST=127.0.0.1
MYSQL_PORT=3306
MYSQL_USERNAME=[PLACEHOLDER: MySQL username]
MYSQL_PASSWORD=[PLACEHOLDER: MySQL password]
```

They connect to the server, select the `test` database, execute the test operations, and close the connection. Start the MySQL server and create the selected database before running those tests:

```shell
dart test
```

The relationship test suite contains callback-based cases that use readable in-memory sources. Those cases do not require the live connection even though they are located in the MySQL package's test directory.

## Validate an application engine setup

For a pure Dart BLoC application:

```shell
dart run build_runner build
dart analyze
dart test
dart run
```

For a Flutter/Firebase application, run the equivalent Flutter commands after Firebase initialization and emulator configuration:

```shell
flutter pub get
flutter pub run build_runner build
flutter analyze
flutter test
flutter run
```

The Firebase emulator command runs separately when the application uses the local Realtime Database emulator:

```shell
firebase emulators:start --only database
```

## Interpret a failing step

The failing command identifies the first layer to inspect:

- generation failure: annotated source or generator input;
- analysis failure: Dart types, imports, or generated/source mismatch;
- local test failure: framework or engine behavior under test;
- MySQL test failure: connection, schema, SQL, or driver state;
- Firebase run/test failure: Firebase initialization, rules, emulator, or network state.

Keep the generated outputs and the command's original error when reporting a failure. The framework does not wrap all backend failures in one dORM exception class.
