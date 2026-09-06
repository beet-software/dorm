# Diagnose annotation and generated-code problems

Code generation has two outputs and two producers. dORM generates the ORM
types in `.dorm.dart` files, while `json_serializable` generates JSON
helpers in `.g.dart` files. Both files are Dart parts of the annotated source
library.

## Confirm the source and output parts

The annotated source file must declare the generated parts that its model
definitions use:

```dart
part 'models.dorm.dart';
part 'models.g.dart';
```

For a source file named `models.dart`, keep these files beside the source:

| File | Producer | Contains |
| --- | --- | --- |
| `models.dorm.dart` | `dorm_generator` | Generated data/model classes, dependencies, schema metadata, entities, `Dorm`, and generated relationship paths. |
| `models.g.dart` | `json_serializable` | JSON helpers used by generated model and data classes. |

Edit the annotated source. Generated files are outputs of the build and are
replaced by the next successful generation.

## Run generation from the application boundary

Run the command from the directory containing the application's
`pubspec.yaml`:

```shell
dart pub get
dart run build_runner build
```

This is the command for a pure Dart application. A Flutter/Firebase
application runs the corresponding command with its Flutter toolchain:

```shell
flutter pub get
flutter pub run build_runner build
```

Do not run the command from a parent directory just because that directory
contains another Dart package. The build configuration and dependency graph
come from the `pubspec.yaml` at the command boundary.

When build_runner reports conflicting generated outputs, run:

```shell
dart run build_runner build --delete-conflicting-outputs
```

Use the Flutter equivalent in a Flutter application. This option removes
conflicting generated outputs before writing the current build result.

## Read the first reported source condition

The generator validates annotated declarations before it writes usable ORM
output. Current validation failures include:

- primary-key specifications with unsupported types or missing required
  fields;
- nullable or query fields used where an identity field is required;
- invalid generated primary-key names or conflicts;
- foreign fields whose target is not an annotated model;
- foreign-field relationships involving unsupported composite primary-key
  combinations;
- duplicate generated relationship path names;
- query fields that refer to invalid fields or symbols.

These failures are raised as `StateError` from the generator and are reported
through `build_runner`. The message generally identifies the model, field, or
relationship name that caused the validation failure.

Read the declaration named in the first error before inspecting generated
files. A failed generation does not produce a usable partial repository API.

## Check generated names after changing relations

Generated relation accessors depend on the names declared in `ForeignField`.
When a relation has multiple paths to the same target, declare distinct
`as` and `inverseAs` names where the model API requires them.

For example, changing a relationship name can affect:

- the generated relation accessor;
- the inverse accessor on the related model;
- a `RelationPath` expression that starts from that accessor;
- code importing the generated `Dorm` API.

If generation reports a duplicate generated path name, resolve the duplicate
in the annotated source and generate again. Do not rename the generated class
or accessor directly in `.dorm.dart`.

The generated names and relation rules are introduced in
[Generate the model and repository API](../01-start-here/03-generate-the-model.md).

## Check identity declarations before changing the operation

Some identity combinations are rejected at generation time; others are
accepted by the generated API but rejected by an engine operation at runtime.

Separate these cases:

1. A source declaration that violates generator validation fails during
   `build_runner`.
2. A generated composite-key entity can reach an engine operation, but BLoC
   and MySQL reject automatic `put` because that operation has no explicit
   identity argument.
3. Firebase reference operations require identities that are `String` values.

Use [Identity and dependencies](../03-understand/02-identity-and-dependencies.md)
to identify whether the current failure belongs to source validation or to an
engine runtime restriction.

## Regenerate after every source-model change

Run generation after changing any of the following:

- model or data fields;
- `@Field`, `@ForeignField`, `@ModelField`, or `@QueryField` declarations;
- primary-key declarations;
- relationship names or targets;
- serialization-related model declarations.

Then run analysis from the same application directory:

```shell
dart run build_runner build
dart analyze
```

For a Flutter/Firebase application, use the Flutter toolchain for both
commands. Generated output that was produced from an older source shape can
otherwise cause analyzer errors that do not describe the current annotated
source.

## Distinguish dORM output from JSON output

If generated ORM types are missing, inspect `models.dorm.dart` generation and
the dORM package dependencies first. If `toJson`/`fromJson` methods or JSON
helper classes are missing, inspect `models.g.dart` generation and the
`json_serializable` configuration.

The two generated files are parts of one Dart library, so an error in either
part can prevent the source library from compiling. The producer and the
reported source location identify which generation stage failed.

## Keep generated output synchronized

A generated-file mismatch has two common symptoms:

- analysis refers to a type, field, or accessor that was removed or renamed in
  the annotated source;
- application code sees an older generated repository or relation API after a
  model change.

Regenerate from the application directory and inspect the resulting analyzer
message. If the mismatch remains, compare the `part` names with the generated
file names and confirm that the source library being built is the one you
edited.

Do not repair generated output by hand. The source declarations and generator
configuration are the inputs that determine the next generated result.
