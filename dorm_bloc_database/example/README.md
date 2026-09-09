# dorm_bloc_database example

<p>
  <a href="https://ezgrs.github.io/dorm/"><img src="https://img.shields.io/badge/documentation-dORM-4c8bf5?style=flat" alt="dORM documentation"></a>
  <a href="https://github.com/beet-software/dorm"><img src="https://img.shields.io/badge/repository-GitHub-181717?logo=github&style=flat" alt="dORM repository"></a>
  <a href="https://github.com/beet-software/dorm"><img src="https://img.shields.io/github/license/beet-software/dorm?style=flat" alt="License"></a>
  <a href="https://github.com/beet-software/dorm/actions/workflows/dart.yml"><img src="https://github.com/beet-software/dorm/actions/workflows/dart.yml/badge.svg" alt="Dart CI"></a>
</p>

This Flutter example shows a generated dORM model using the BLoC-backed
in-memory engine. It does not require an external database service.

## Run it

Execute these commands from this directory:

~~~shell
flutter pub get
dart run build_runner build
flutter analyze
flutter run
~~~

The annotated source is lib/models.dart. The generated model API is produced
in lib/models.dorm.dart and lib/models.g.dart. Edit the annotated source and
run build_runner again after changing models or fields.

The application creates Engine, constructs Dorm, and exercises generated
repositories and streams. Reuse the Engine instance when the application
needs shared in-memory state.
