# Create the Dart project

This module creates a pure Dart application and adds the packages required by
the dORM quickstart. The example uses the in-memory engine, so it does not require
a database server or a Flutter project.

## Create the Dart application

Install the [Dart SDK](https://dart.dev/get-dart), then create and enter a new
console application:

```shell title="Create the application"
dart create -t console-simple dorm_store
cd dorm_store
```

Run the remaining commands from the directory that contains `pubspec.yaml`.

## Add the runtime packages

```shell title="Add dORM runtime packages"
dart pub add dorm_framework
dart pub add dorm_annotations
dart pub add dorm_memory_database
```

Each package has a separate role in the application:

| Package | Why the quickstart needs it |
| --- | --- |
| [`dorm_framework`](https://pub.dev/packages/dorm_framework) | Defines the engine-independent entities, repositories, filters, identities, and read/write contracts. |
| [`dorm_annotations`](https://pub.dev/packages/dorm_annotations) | Provides `@Model`, `@Data`, `@Field`, and related annotations used in the source model. It also reexports the JSON annotation types used by generated code. |
| [`dorm_memory_database`](https://pub.dev/packages/dorm_memory_database) | Provides the pure Dart engine used by the first application. It stores records in process memory and generates UUID identities for simple models. |

## Add the development packages

```shell title="Add code-generation packages"
dart pub add --dev dorm_generator
dart pub add --dev build_runner
```

These packages are used during generation:

| Package | Why it is a development dependency |
| --- | --- |
| [`dorm_generator`](https://pub.dev/packages/dorm_generator) | Generates dORM model, entity, repository, and `Dorm` types from the annotated source. |
| [`build_runner`](https://pub.dev/packages/build_runner) | Runs the dORM builder and the builders it applies in the application project. |

!!! note
    `dorm_annotations` reexports `json_annotation` and `dorm_generator` automatically
    applies the `json_serializable` and `copy_with_extension_gen` builders when
    generation runs, so you don't need to add them directly to your project.

## Resolve the dependency graph

Run Pub after adding the packages:

```shell title="Resolve packages"
dart pub get
```

At this point the project has the runtime contracts, annotations, in-memory
engine, and builders needed by the rest of the quickstart. Continue with
[Define users, profiles, and products](declaring-models.md).
