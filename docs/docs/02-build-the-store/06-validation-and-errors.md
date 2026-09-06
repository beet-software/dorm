# Validate input and handle failures

dORM represents several different failure sources. Application input rules are separate from generated type checks, repository programming errors, and failures raised by the selected database engine.

## Validate application input before creating `Data`

Generated constructors enforce Dart's required fields and declared types. Business rules such as an email format, a minimum quantity, or a permitted review rating belong at the application input boundary.

Use a normal Dart validation step before constructing the generated value:

```dart
String? validateUserInput({
  required String username,
  required String email,
}) {
  if (username.trim().isEmpty) {
    return 'Username is required';
  }

  if (!email.contains('@')) {
    return 'Email is invalid';
  }

  return null;
}
```

Only create and submit `UserData` after the input passes the rules used by the application:

```dart
final String? error = validateUserInput(
  username: inputUsername,
  email: inputEmail,
);

if (error != null) {
  print(error);
  return;
}

final User user = await dorm.users.repository.put(
  const UserDependency(),
  UserData(
    username: inputUsername,
    email: inputEmail,
    profile: profile,
  ),
);
```

The repository API does not add a general-purpose business validation layer around `put`, `push`, or `patch`. The generated model annotations provide field and serialization metadata; they do not replace application validation rules.

## Treat generation failures as source-model errors

The generator reads the annotated source and validates relationships, fields, query declarations, primary keys, and generated names. Invalid or incompatible declarations fail during `build_runner` execution rather than during a repository read.

Run generation after changing the annotated source:

```shell
dart run build_runner build
```

Read the reported source location and declaration when generation fails. Do not edit the generated `.dorm.dart` or `.g.dart` files to repair the error; the next generation replaces those outputs from the annotated source.

## Handle missing records as values

Several read operations represent absence without throwing:

```dart
final User? user = await dorm.users.repository.peek(userId);
final List<Product> products = await dorm.products.repository.peekAll();
```

`peek` returns `null` for an absent identity. `peekAll` returns an empty list when no records match. `pull` can emit `null` when a watched identity is absent or is removed.

Use explicit branches for these results before accessing model fields.

## Handle programming errors separately

The framework and engines use ordinary Dart error classes for invalid operations and unsupported combinations. The observed classes include `ArgumentError`, `StateError`, and `UnsupportedError`.

For example, the BLoC engine rejects `put` and `putAll` for entities with composite primary keys because those operations require an identity that `put` does not receive:

```dart
try {
  await repository.put(dependency, data);
} on UnsupportedError catch (error) {
  print('This engine cannot generate this identity: $error');
}
```

Use `push` with an explicitly identified model when that engine and entity require it. The exact supported operation depends on the identity and engine involved.

## Let engine and database errors propagate

The framework repository delegates storage work to the selected engine. Database connection failures, driver errors, serialization failures, and backend-specific failures are not converted into one documented dORM exception type by the repository API.

Catch errors at the application boundary when the operation must be reported or retried:

```dart
import 'package:decimal/decimal.dart';

try {
  final Product product = await dorm.products.repository.put(
    const ProductDependency(),
    ProductData(
      name: 'Notebook',
      description: 'A lined notebook',
      price: Decimal.fromInt(12),
    ),
  );
  print(product.id);
} catch (error, stackTrace) {
  print('Product write failed: $error');
  print(stackTrace);
}
```

Keep the original error and stack trace when logging or forwarding the failure. The repository does not guarantee that backend errors contain the same fields or class across engines.

## Check the result of a write

Successful writes return the generated or updated model for operations that return a model. A `Future` completing does not mean that an application-level rule was satisfied unless that rule was checked before the call. Treat a completed repository operation and a validated business command as separate steps.
