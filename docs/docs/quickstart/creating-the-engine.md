# Connect the in-memory engine

The annotated source and generated parts now exist in `lib/models.dart`. The
next step is to construct the in-memory engine and pass it to the generated
`Dorm` facade.

## Create one engine instance

Create `bin/dorm_store.dart` with the engine and generated model library:

```dart title="bin/dorm_store.dart"
import 'package:dorm_memory_database/dorm_memory_database.dart';

import 'package:dorm_store/models.dart';

final Engine engine = Engine();
final dorm = Dorm(engine);
```

`Engine()` creates an in-process store. Keep the same instance for the part of
the application that should share these records. Creating another engine
creates another independent store.

## Follow the generated accessor

The `as: #users` value in the model annotation produces `dorm.users`. That
accessor contains the generated `User` entity, and `.repository` exposes the
operations for that entity:

```dart
final userRepository = dorm.users.repository;
```

The generated `Dorm` type infers the engine's query and page types from the
`Engine` instance. Keep the same `dorm` value when the application should use
the same in-memory store.

Continue with [Create and read a user](create-and-read-data.md).
