# dorm_memory_database

A dORM's Reference implementation using Dart data types.

## Features

This package exposes two classes - `MemoryQuery` and `MemoryReference` - to use with dORM if your
application needs to use a database hosted on RAM, ideal for sample applications or if you want to
test dORM capabilities without setting up a remote database. It also exposes a `MemoryInstance`
class to act as a database.

## Getting started

Run the following in your project:

```shell
flutter pub add dorm_memory_database \
  --git-url https://github.com/enzo-santos/dorm.git \
  --git-ref main \
  --git-path dorm_memory_database
```

## Usage

### Accessing

First create a `MemoryInstance`:

```dart
final MemoryInstance instance = MemoryInstance({});

// Alternatively, if you want to initialize it with some data
final MemoryInstance instance = MemoryInstance({
  'lambeosaurus': {
    'height': 2.1,
    'length': 12.5,
    'weight': 5000,
  },
  'stegosaurus': {
    'height': 4,
    'length': 9,
    'weight': 2500,
  },
});
```

With this instance, create a `MemoryReference`:

```dart
final MemoryReference reference = instance.ref;
```

### Integrating with dORM

Pass the reference created above to your generated `Dorm` class:

```dart
final Dorm dorm = Dorm(reference);
```
