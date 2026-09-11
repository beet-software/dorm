# Fix code generation problems

dORM generation produces two Dart part files:

- <i>*.dorm.dart</i>, written by `dorm_generator`;
- <i>*.g.dart</i>, written by `json_serializable`.

Both files belong to the annotated source library. A problem in either file
can prevent the model API from compiling.

## Check the part declarations

For a source file named `models.dart`, declare the generated parts beside the
source:

```dart title="lib/models.dart"
part 'models.dorm.dart';
part 'models.g.dart';
```

Keep the file names aligned with the `part` declarations. Edit `models.dart`,
not either generated file.

## Run generation from the application directory

Run the command from the directory containing the <i>pubspec.yaml</i> that declares
the model and generator dependencies:

```shell
dart pub get
dart run build_runner build
```

For a Flutter/Firebase application, use the Flutter toolchain:

```shell
flutter pub get
flutter pub run build_runner build
```

If `build_runner` reports conflicting outputs, run:

```shell
dart run build_runner build --delete-conflicting-outputs
```

The option removes conflicting generated outputs before writing the current
result. Use the Flutter equivalent in a Flutter application.

## Read generator validation errors

The generator validates declarations before it writes usable ORM output. A
`StateError` can identify problems such as:

- unsupported or incomplete primary-key specifications;
- nullable or derived values used as identities;
- invalid generated identity names or conflicts;
- foreign fields whose target is not an annotated model;
- unsupported composite-key relationship combinations;
- duplicate generated relationship path names;
- derived fields that reference invalid fields or symbols.

Read the model, field, or relationship named in the first error. Do not repair
the generated file to make the error disappear; change the annotated source
and generate again.

## Check relationship names

Generated relation accessors use `ForeignField.as` and
`ForeignField.inverseAs`, together with inferred names where applicable. Two
paths can therefore produce the same generated name.

If generation reports a duplicate path, change the names in the annotation and
regenerate. Do not rename the generated getter directly in <i>*.dorm.dart</i>.
See [`ForeignField`](../annotations/foreign-field.md) for the naming rules.

## Check identity declarations

Identity declarations are defined on [`@Model`](../annotations/model.md).
Simple-key entities accept automatic or explicit creation. Composite-key
entities accept explicit `CompositeKey` creation, so `Creation.auto` is
rejected by the generated type.

If the declaration is valid but an operation fails, inspect
[Create records](../operations/creating.md) and the selected engine page.
This separates a generation error from a runtime identity or backend error.

## Regenerate after source changes

Regenerate after changing:

- model or data fields;
- `@Field`, `@ForeignField`, `@ModelField`, or `@DerivedField` declarations;
- primary-key declarations;
- relationship names or targets;
- serialization-related declarations.

Then analyze from the same directory:

```shell
dart run build_runner build
dart analyze
```

Generated output from an older source shape can otherwise produce analyzer
errors that describe stale code rather than the current model.

## Distinguish dORM output from JSON output

If generated repositories, entities, or `Dorm` are missing, inspect the
<i>*.dorm.dart</i> stage and the dORM generator dependencies. If `toJson`,
`fromJson`, or JSON helper classes are missing, inspect the <i>*.g.dart</i> stage and
the `json_serializable` builder.

The two builders run in the same source library, so generation must complete
successfully for both parts before the annotated file can compile.
