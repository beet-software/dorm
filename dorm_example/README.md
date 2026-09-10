# dorm_example

<p>
  <a href="https://pub.dev/packages/dorm_example"><img src="https://img.shields.io/pub/v/dorm_example.svg?label=dorm_example" alt="dorm_example on pub.dev"></a>
  <a href="https://pub.dev/packages/dorm_example"><img src="https://img.shields.io/pub/points/dorm_example?logo=dart" alt="dorm_example pub points"></a>
  <a href="https://pub.dev/packages/dorm_example"><img src="https://img.shields.io/pub/popularity/dorm_example?logo=dart" alt="dorm_example popularity"></a>
  <a href="https://pub.dev/packages/dorm_example"><img src="https://img.shields.io/pub/likes/dorm_example?logo=dart" alt="dorm_example likes"></a>
  <a href="https://ezgrs.github.io/dorm/quickstart/generate-a-showcase/"><img src="https://img.shields.io/badge/documentation-dORM-4c8bf5?style=flat" alt="dorm_example documentation"></a>
  <a href="https://github.com/ezgrs/dorm"><img src="https://img.shields.io/badge/repository-GitHub-181717?logo=github&style=flat" alt="dORM repository"></a>
  <a href="https://github.com/ezgrs/dorm"><img src="https://img.shields.io/github/license/ezgrs/dorm?style=flat" alt="License"></a>
  <a href="https://github.com/ezgrs/dorm/actions/workflows/dart.yml"><img src="https://github.com/ezgrs/dorm/actions/workflows/dart.yml/badge.svg" alt="Dart CI"></a>
</p>

dorm_example is a command-line generator for complete dORM showcase projects.
It creates the annotated source, generated-code commands, application flow,
and backend configuration for one selected engine.

## Install the generator

Install the executable globally:

~~~shell
dart pub global activate dorm_example
~~~

Check the available options:

~~~shell
dorm_example --help
~~~

## Generate a project

Choose one engine and, optionally, an output directory. Without `--output`, the
directory name defaults to the selected engine:

~~~shell
dorm_example --engine memory
dorm_example --engine postgres --output store_example
~~~

For example, `dorm_example --engine memory` creates `memory/`. The output
directory must be empty or must not exist. The generator does not
overwrite existing files, run pub get, run build_runner, start Docker, or start
the generated application.

## Generated profiles

| Profile | Application | Infrastructure |
| --- | --- | --- |
| in-memory | Flutter Web | None |
| bloc | Flutter Web | None |
| firebase | Flutter Web | Firebase Emulator Suite |
| firestore | Flutter Web | Firebase Emulator Suite |
| http | Flutter Web | Local Dart HTTP server |
| postgres | Pure Dart | PostgreSQL in Docker Compose |
| mysql | Pure Dart | MySQL in Docker Compose |
| mongo | Pure Dart | MongoDB in Docker Compose |
| sqlite | Pure Dart | Local SQLite file |

All profiles use the same store domain with users, products, categories, carts,
cart items, wishlists, and reviews. SQL profiles keep the model surface
portable and avoid JSON-specific annotations such as ModelField,
PolymorphicField, and DerivedField.

## Run a generated project

After generation, enter the output directory and follow the generated README.
A typical pure Dart profile uses:

~~~shell
cd store_example
docker compose up -d
dart pub get
dart run build_runner build
dart analyze
dart run
~~~

A Flutter profile uses:

~~~shell
cd store_example
flutter pub get
dart run build_runner build
flutter analyze
flutter run -d chrome
~~~

Flutter profiles require Flutter **3.47.1 or newer**. Pure Dart profiles do
not have this Flutter requirement.

Docker Compose starts infrastructure only. The Dart or Flutter application runs
on the host so that local environment variables, browser access, and Flutter
development tools remain available.

## Backend configuration

- PostgreSQL, MySQL, and MongoDB generate Docker Compose files, environment
  templates, and backend-specific startup instructions.
- SQLite generates sql/schema.sql and reads that rendered file when the
  application starts.
- Firebase and Firestore generate local Firebase Emulator configuration.
- HTTP generates a local in-memory Dart server and a configured HttpMapping.
- The in-memory and BLoC profiles run without an external service.

The generated .env.example file documents required variables. It is a reference
file; the generated application does not load it automatically.

## Modify the showcase

Edit the generated lib/models.dart file when changing models. Then regenerate
the model API:

~~~shell
dart run build_runner build --delete-conflicting-outputs
~~~

The generated *.dorm.dart and *.g.dart files are derived output. Keep the
annotated source as the file you edit.

## Troubleshooting

- A non-empty output directory fails by design; choose another path or remove
  only the generated directory.
- A missing generated API means build_runner has not been run in the project
  root.
- A database profile cannot connect until its Compose service is running and
  its environment values match the generated configuration.
- A Flutter profile needs Flutter and a browser target installed.
- The HTTP profile requires its generated http-api service to be running.

## Links

- [dORM documentation](https://ezgrs.github.io/dorm/)
- [Showcase guide](https://ezgrs.github.io/dorm/quickstart/generate-a-showcase/)
- [GitHub repository](https://github.com/ezgrs/dorm)
