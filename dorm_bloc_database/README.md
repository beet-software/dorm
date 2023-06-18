# dorm_bloc_database

A dORM's Reference implementation using `bloc`.

## Getting started

Run the following commands in your command prompt:

```shell
dart pub add dorm_bloc_database
```

Using `dorm_annotations` and `dorm_generator`, generate your dORM code:

```shell
dart run build_runner build
```

This will create a `Dorm` class, which you can use to connect to this package.

## Usage

Create a `Reference`:

```dart
final Reference reference = Reference();
```

Finally, pass the reference created above to your generated `Dorm` class:

```dart
final Dorm dorm = Dorm(reference);
```
