# dorm_annotations example

This directory contains annotated model declarations used to demonstrate
`dorm_annotations` together with `dorm_generator`.

The source files are:

- `lib/school.dart`: simple models and fields;
- `lib/social_network.dart`: relationships and generated accessors;
- `lib/drawing.dart`: embedded and polymorphic values.

Install dependencies and regenerate the derived files from this directory:

```shell
dart pub get
dart run build_runner build
```

The `*.dorm.dart` and `*.g.dart` files are generated outputs. Edit the source
files and run the generator again after changing annotations or model fields.
