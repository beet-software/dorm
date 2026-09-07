# Build your first dORM-backed app

dORM is a Dart ORM that turns annotated Dart classes into generated model and repository APIs. A generated `Dorm` object connects those APIs to a database engine.

This quickstart uses the pure Dart memory engine from `dorm_memory_database`. It stores data in memory, so the first workflow needs no external database server or Flutter setup.

## What this quickstart builds

Follow these steps to create a small store model with one `User` record:

1. add the dORM packages;
2. declare an annotated model;
3. generate the dORM files;
4. create a memory engine and a generated `Dorm` object;
5. create and read a user through its repository.

## Prerequisites

Install the Dart SDK and ensure that `dart` is available in your terminal.

Create a new application and enter its directory:

```shell
dart create -t console-simple dorm_store
cd dorm_store
```

## 1. Add the packages

From the project directory, add the packages used by this workflow:

```shell
dart pub add dorm_framework
dart pub add dorm_annotations
dart pub add dorm_memory_database
dart pub add json_annotation

dart pub add --dev dorm_generator
dart pub add --dev build_runner
dart pub add --dev json_serializable
```

`dorm_framework` provides the engine-independent ORM contracts. `dorm_annotations` provides the annotations in the source model. `dorm_memory_database` provides the pure Dart in-memory engine. `dorm_generator` and `build_runner` generate the dORM part file, while `json_serializable` and `json_annotation` generate and support JSON conversion.

## 2. Declare a user model

Create `lib/models.dart`:

```dart
import 'package:dorm_annotations/dorm_annotations.dart';
import 'package:dorm_memory_database/dorm_memory_database.dart';
import 'package:dorm_framework/dorm_framework.dart';

part 'models.g.dart';
part 'models.dorm.dart';

@Model(name: 'users', as: #users)
abstract class _User {
  @Field(name: 'name')
  String get name;
}
```

The `Model` annotation identifies the database table and the generated repository accessor. The `Field` annotation maps the Dart getter to a stored field.

The two `part` directives attach generated files to this library:

- `models.g.dart` is produced by `json_serializable`;
- `models.dorm.dart` is produced by the dORM generator.

## 3. Generate the dORM files

Run the generator from the project directory:

```shell
dart pub get
dart run build_runner build
```

The generator writes the ORM types to `models.dorm.dart`. The file supplies the generated types needed by the application.

## 4. Create the engine and generated database object

Create the memory engine and pass it to the generated `Dorm` class:

```dart
import 'package:dorm_memory_database/dorm_memory_database.dart';

import 'package:dorm_store/models.dart';

final Dorm dorm = Dorm(Engine());
```

`Dorm.users` is generated from `as: #users`. It exposes the `User` database entity, and `.repository` provides the model operations for that entity.

## 5. Create and read a user

Replace `bin/dorm_store.dart` with a small Dart application that creates a user, reads it back, and prints the result:

```dart
import 'package:dorm_memory_database/dorm_memory_database.dart';

import 'package:dorm_store/models.dart';

Future<void> main() async {
  final Dorm dorm = Dorm(Engine());
  final User created = await dorm.users.repository.put(
    Creation.auto(
      dependency: UserDependency(),
      data: UserData(name: 'Ada'),
    ),
  );
  final User? loaded = await dorm.users.repository.peek(created.id);

  print(loaded?.name ?? 'User not found');
}
```

`put` receives a `Creation` object. `Creation.auto` keeps the engine-generated identity behavior and carries the dependency and data used to construct the model. `put` returns the identified model. `peek` reads one model by its identity and returns `null` when no model exists for that identity.

## 6. Run the app

Run these commands from the project directory:

```shell
dart pub get
dart run build_runner build
dart run
```

The build step must run after `models.dart` changes so that `models.dorm.dart` and `models.g.dart` match the source declarations. `dart run` executes the generated Dart application and prints the name read through the repository.

## Continue with the store model

[Build the first model](02-build-the-first-model.md) extends the single-user result into the store domain.
