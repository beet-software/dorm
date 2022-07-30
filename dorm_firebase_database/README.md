# dorm_firebase_database

A dORM's Reference implementation using firebase_database.

## Features

This package exposes two classes - `FirebaseQuery` and `FirebaseReference` - to use with dORM if
your application needs the [`firebase_database` package](https://pub.dev/packages/firebase_database).

## Getting started

Add the following in your *pubspec.yaml* file:

```yaml
dependencies:
  firebase_core:
  dorm_firebase_database:

  # If your application does not use the default Firebase app or it uses more than one Firebase app,
  # you should also add the package below. If your application only uses the default Firebase app,
  # this package is not necessary since `dorm_firebase_database` already handles it. 
  firebase_database:
```

## Usage

### Initializing

Before accessing any Firebase classes, initialize your app:

```dart
void main() async {
  await Firebase.initializeApp();

  // Alternatively, if you're working with non-default apps
  await Firebase.initializeApp(name: 'app-1');
}
```

In any of the calls above, you can also pass the `options` parameter as desired:

```dart
void main() async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}
```

### Accessing

Create a `FirebaseReference` using `FirebaseDatabase`:

```dart
void _create() {
  final FirebaseReference ref = FirebaseReference.path();
  final FirebaseReference ref = FirebaseReference.path('production');

  // Alternatively, if you're working with non-default apps
  final FirebaseReference ref = FirebaseReference(FirebaseDatabase.instance.ref());
  final FirebaseReference ref = FirebaseReference(FirebaseDatabase.instance.ref('production'));
  final FirebaseReference ref = FirebaseReference(
      FirebaseDatabase.instanceFor(app: FirebaseApp('app-1')));

  return ref;
}
```

### Integrating with dORM

Pass the instance created above to your generated `Dorm` class:

```dart
void _integrate() {
  final FirebaseReference ref = _create();
  final Dorm dorm = Dorm(ref);
}
```

> Top-level functions above were used only to illustrate code execution and does not have any
> special meaning while using this package.
