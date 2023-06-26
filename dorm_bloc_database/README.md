# dorm_bloc_database

[![pub package](https://img.shields.io/pub/v/dorm_bloc_database.svg?label=dorm_bloc_database)](https://pub.dev/packages/dorm_bloc_database)
[![pub popularity](https://img.shields.io/pub/popularity/dorm_bloc_database?logo=dart)](https://pub.dev/packages/dorm_bloc_database)
[![pub likes](https://img.shields.io/pub/likes/dorm_bloc_database?logo=dart)](https://pub.dev/packages/dorm_bloc_database)
[![pub points](https://img.shields.io/pub/points/dorm_bloc_database?logo=dart)](https://pub.dev/packages/dorm_bloc_database)

A dORM's BaseReference and BaseQuery implementation using `bloc`.

## Getting started

Run the following commands in your command prompt:

```shell
dart pub add dorm_bloc_database
```

Using [`dorm_annotations`](https://pub.dev/packages/dorm_annotations) and
[`dorm_generator`](https://pub.dev/packages/dorm_generator), generate your dORM code:

```shell
dart run build_runner build
```

This will create a `Dorm` class, which you can use to connect to this package.

## Usage

Create a `Reference`:

```dart
void main() {
  final Reference reference = Reference();
}
```

Then pass the reference created above to your generated `Dorm` class:

```dart
void main() {
  final Dorm dorm = Dorm(reference);
}
```
