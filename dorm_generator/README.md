# dorm_generator

<p>
  <a href="https://pub.dev/packages/dorm_generator"><img src="https://img.shields.io/pub/v/dorm_generator.svg?label=dorm_generator" alt="dorm_generator on pub.dev"></a>
  <a href="https://pub.dev/packages/dorm_generator"><img src="https://img.shields.io/pub/points/dorm_generator?logo=dart" alt="dorm_generator pub points"></a>
  <a href="https://pub.dev/packages/dorm_generator"><img src="https://img.shields.io/pub/popularity/dorm_generator?logo=dart" alt="dorm_generator popularity"></a>
  <a href="https://pub.dev/packages/dorm_generator"><img src="https://img.shields.io/pub/likes/dorm_generator?logo=dart" alt="dorm_generator likes"></a>
  <a href="https://ezgrs.github.io/dorm/reference/generated-contract/"><img src="https://img.shields.io/badge/documentation-dORM-4c8bf5?style=flat" alt="dorm_generator documentation"></a>
  <a href="https://github.com/ezgrs/dorm"><img src="https://img.shields.io/badge/repository-GitHub-181717?logo=github&style=flat" alt="dORM repository"></a>
  <a href="https://github.com/ezgrs/dorm"><img src="https://img.shields.io/github/license/ezgrs/dorm?style=flat" alt="License"></a>
  <a href="https://github.com/ezgrs/dorm/actions/workflows/dart.yml"><img src="https://github.com/ezgrs/dorm/actions/workflows/dart.yml/badge.svg" alt="Dart CI"></a>
</p>

dorm_generator is the build_runner generator that turns dORM annotations
into model types, schema metadata, repositories, relationship paths, and
serialization code.

## Install

Add annotations and the framework as runtime dependencies, then add the
generator and build_runner as development dependencies:

~~~shell
dart pub add dorm_annotations
dart pub add dorm_framework
dart pub add --dev dorm_generator
dart pub add --dev build_runner
~~~

The generator is a build-time dependency. Your application imports the
annotations and generated API, while build_runner executes the generator.

## Prepare the annotated source

Create a Dart file under lib, commonly lib/models.dart:

~~~dart
import 'package:dorm_annotations/dorm_annotations.dart';
import 'package:dorm_framework/dorm_framework.dart';

part 'models.dorm.dart';
part 'models.g.dart';

@Model(name: 'users', as: #users)
abstract class _User {
  @Field(name: 'username')
  String get username;
}
~~~

The part names must match the source filename. For a different source name,
change both part directives to match it.

## Generate the API

Run generation from the application root:

~~~shell
dart run build_runner build
~~~

After changing annotations, fields, identities, relationships, or generator
configuration, run the command again. Use the delete-conflicting option when
old generated files prevent a clean build:

~~~shell
dart run build_runner build --delete-conflicting-outputs
~~~

Generated files include:

- models.dorm.dart for dORM entities, schema metadata, repositories, accessors,
  relationship paths, and the Dorm facade;
- models.g.dart for JSON serialization and copyWith support.

The generated files are source files consumed by the application. Do not edit
them manually.

## Generated types

For a model such as _User, generation produces distinct application-facing
types:

- UserData contains input data;
- User is the identified model;
- UserDependency carries related identities;
- UserEntity connects the model to framework contracts;
- UserRepository exposes repository operations;
- UserEntity.fields exposes FieldSchema values for filters and ordering;
- Dorm exposes users and other generated accessors.

The generated facade carries the query and page types inferred from the engine:

~~~dart
final engine = Engine();
final dorm = Dorm(engine);

final User? user = await dorm.users.repository.peek(userId);
~~~

If the engine implements the optional transaction capability, the generator
also emits TransactionalDorm for callback-scoped multi-repository operations.

## Identity generation hooks

For an engine-generated identity, declare the reserved static method directly
on the annotated class:

~~~dart
@Model(name: 'users', as: #users)
abstract class _User {
  static String $dorm$generateId(_User model, String generatedId) {
    return model.username;
  }

  @Field(name: 'username')
  String get username;
}
~~~

The method receives the intermediate model and the identity initially generated
by the engine. It is applied only to Creation.auto for GeneratedIdSpec. Explicit
identities and database-generated identities do not pass through it.

## Derived-field hooks

Derived fields use a synchronous static method with the reserved prefix:

~~~dart
@Model(name: 'users', as: #users)
abstract class _User {
  @DerivedField(name: 'q-username')
  static String $dorm$derived$qUsername(
    _User model,
    DerivedTransformations transformations,
  ) {
    return transformations.text(model.username) ?? '';
  }

  @Field(name: 'username')
  String get username;
}
~~~

The suffix becomes the generated getter name. The callback result is serialized
with the model and is available through the persisted derived field.

## Relationships and schema metadata

The generator reads ForeignField annotations and emits relationship paths with
the declared forward and inverse names. It also emits EntitySchema and
FieldSchema metadata used by engines to translate identifiers, filters,
relationships, and serialization.

Use generated FieldSchema values at the application boundary:

~~~dart
final products = await dorm.products.repository.peekAll(
  Filter.text('phone', field: ProductEntity.fields.name),
);
~~~

The engine receives the resolved persisted field name. This keeps application
code tied to declared schema metadata instead of repeated string literals.

## Polymorphism and nested values

ModelField, PolymorphicField, and DerivedField are generated into the same
entity and serialization surface. The generator preserves the declared Dart
shape for nested values and emits the metadata needed by document-oriented
engines.

For SQL engines, use only the model features supported by the schema and
serialization path of that engine.

## Common diagnostics

- A missing part file usually means the part name does not match the source
  filename or generation has not been run.
- A stale generated API means the annotated source changed without another
  build_runner invocation.
- An invalid reserved method signature is reported during generation.
- An identity or relation error usually points to a missing getter, an invalid
  referenced type, or an inconsistent primary-key declaration.
- A filter should receive a generated FieldSchema, not a storage-name string.

## Links

- [Annotations](https://pub.dev/packages/dorm_annotations)
- [Framework](https://pub.dev/packages/dorm_framework)
- [Generated API reference](https://ezgrs.github.io/dorm/reference/generated-contract/)
- [Code generation troubleshooting](https://ezgrs.github.io/dorm/troubleshooting/code-generation-problems/)
- [GitHub repository](https://github.com/ezgrs/dorm)

## Generate schema migrations

The optional migration CLI compares analyzed models with a versioned snapshot and
writes a reviewed Dart migration. It never connects to a database:

```shell
dart run dorm_generator:migrate initialize --input lib/models.dart
dart run dorm_generator:migrate diff --input lib/models.dart --name add-active
dart run dorm_generator:migrate index
```

The default snapshot is *migrations/schema.json*. Versioned migration sources
are written under *migrations/*. The generated *migrations/index.dart* is
ignored and can be rebuilt after a fresh clone or in CI. The optional
*dorm.yaml* supplies SQL type overrides and other generator inputs; it is not a
replacement for reviewing the generated migration.

Data operations such as `CopyFieldOperation` and
`RemoveFieldValueOperation` must be added to the generated Dart migration.
They are not configured through *dorm.yaml*.

For the complete workflow, safety rules, and recovery guidance, see [Use
migrations](https://ezgrs.github.io/dorm/operations/using-migrations/).