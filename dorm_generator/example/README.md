# dorm_generator example

This example documents the build-time workflow provided by `dorm_generator`.
It is a documentation example for the Pub package page, not a separate package
with its own `pubspec.yaml`.

For a complete multi-file fixture with generated output, see
[`dorm_annotations/example`](https://github.com/ezgrs/dorm/tree/main/dorm_annotations/example).

## 1. Add the dependencies

In an application package that owns the model declarations, add the runtime
packages and the code-generation packages:

```shell
dart pub add dorm_annotations
dart pub add dorm_framework
dart pub add --dev dorm_generator
dart pub add --dev build_runner
```

## 2. Declare a model

Create `lib/models.dart` with matching generated part names:

```dart
import 'package:dorm_annotations/dorm_annotations.dart';
import 'package:dorm_framework/dorm_framework.dart';

part 'models.dorm.dart';
part 'models.g.dart';

@Model(name: 'users', as: #users)
abstract class _User {
  @Field(name: 'username')
  String get username;
}
```

The `part` names must match the source filename. Edit this annotated source,
not the generated files.

## 3. Generate the API

Run the generator from the application root:

```shell
dart pub get
dart run build_runner build
```

After changing annotations, fields, identities, relationships, or generator
configuration, run the command again. If old generated files conflict, use:

```shell
dart run build_runner build --delete-conflicting-outputs
```

## 4. Inspect the output

The build produces:

- `lib/models.dorm.dart`: entities, schema metadata, repositories,
  relationships, and the generated `Dorm` facade;
- `lib/models.g.dart`: JSON serialization and copy-with support.

The generated files are application source files consumed by the rest of the
project. Do not edit them manually.