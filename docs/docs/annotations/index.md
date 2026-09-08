# Annotations

The [`dorm_annotations`](https://pub.dev/packages/dorm_annotations) package
defines the metadata read by the dORM generator. Add annotations to abstract
Dart classes and getters, then regenerate the `*.dorm.dart` and `*.g.dart`
parts.

!!! note
    An annotation declares names, fields, identities, or relationships. It
    does not open a connection or perform a database operation. The generated
    entity and the selected engine use the resulting metadata at runtime.

## Learn annotations in this order

Use the pages in this order when building a model from scratch:

1. [Data](data.md) for reusable serializable values;
2. [Model](model.md) for stored entities and their identities;
3. [Field](field.md) for scalar and value fields;
4. [ModelField](model-field.md) for embedded data or models;
5. [ForeignField](foreign-field.md) for related identities;
6. [`@DerivedField`](derived-field.md) for generated query values;
7. [`@PolymorphicData`](polymorphic-data.md) for variant declarations;
8. [`@PolymorphicField`](polymorphic-field.md) for storing a selected variant.

The [Quickstart](../quickstart/index.md) applies these annotations to one
continuous store application. Use these pages when you need the parameters,
defaults, generated names, or boundaries of a specific annotation.

All annotated source files must declare the generated parts:

```dart title="lib/models.dart"
part 'models.dorm.dart';
part 'models.g.dart';
```

After changing an annotation, run:

```shell
dart run build_runner build
```

The generated `.dorm.dart` file contains dORM entities, schema metadata,
repositories, the generated `Dorm`, and relationship paths. The `.g.dart` file
contains JSON helpers.
