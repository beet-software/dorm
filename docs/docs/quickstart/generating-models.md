# Generate the store API

dORM generates the concrete Dart types that connect annotated source declarations to the framework repository API. The generator runs as a `build_runner` builder and writes `.dorm.dart` files beside the annotated source.

This module assumes that `lib/models.dart` contains the `User`, `Profile`, and
`Product` declarations from [Define users, profiles, and products](declaring-models.md).

## Start from an annotated source file

The source library must declare both generated parts:

```dart title="lib/models.dart"
part 'models.dorm.dart';
part 'models.g.dart';
```

The two files are parts of the same Dart library. dORM writes the ORM types to `.dorm.dart`, while `json_serializable` writes JSON helpers to `.g.dart`.

## Run the generator

From the project directory:

```shell title="Generate the store API"
dart pub get
dart run build_runner build
```

Run the command from the directory that contains the application's `pubspec.yaml`.

## Generated files

For a source file named `models.dart`, generation produces:

| File | Producer | Role |
| --- | --- | --- |
| `models.dorm.dart` | `dorm_generator` | dORM data/model classes, dependencies, schema metadata, entities, `Dorm`, and generated relationship paths |
| `models.g.dart` | `json_serializable` | JSON serialization helpers used by generated data and model classes |

Both files are Dart `part` files of `models.dart`. They are compiled together with the source library.

## Generated types for one model

For the annotated `_User` declaration, the dORM generator creates these public types:

| Generated type | Role |
| --- | --- |
| `UserData` | Field and embedded-data values used as create/update input |
| `User` | Identified model; it extends `UserData` and contains the generated `id` |
| `UserDependency` | Dependency value supplied when creating a `User` |
| `UserFields` | Field metadata used by filters and relationships |
| `UserEntity` | Schema, identity, conversion, and serialization adapter |
| `Dorm` | Database access object containing generated `DatabaseEntity` accessors |

The generated `Product` model produces the corresponding `ProductData`, `Product`, `ProductDependency`, `ProductFields`, and `ProductEntity` types.

### Inspect `UserData` and `User`

For the store's annotated user model, the generated types have this shape:

```dart title="Generated model shape"
class UserData {
  const UserData({
    required this.username,
    required this.email,
    required this.profile,
  });

  final String username;
  final String email;
  final Profile profile;
}

class User extends UserData {
  const User({
    required this.id,
    required super.username,
    required super.email,
    required super.profile,
  });

  final String id;
}
```

`UserData` and `User` also receive generated JSON methods. The model's `toJson` output removes the internal `_id` entry before the entity writes the model data, while the identity is passed separately to `fromJson`.

### Inspect the generated dependency

A model with no foreign-key dependency gets a strong dependency:

```dart title="Generated dependency shape"
class UserDependency extends Dependency<UserData> {
  const UserDependency() : super.strong();
}
```

The store's `CartDependency` and `CartItemDependency` contain the foreign IDs required by their model declarations and use weak dependencies.

### Inspect the generated entity

`UserEntity` implements the framework's `Entity<UserData, User, String>` contract. It exposes the engine-neutral schema and model conversions:

```dart title="Generated entity shape"
class UserEntity implements Entity<UserData, User, String> {
  const UserEntity();

  @override
  EntitySchema get schema => _schema;

  @override
  PrimaryKeyCodec<String> get primaryKeyCodec =>
      const SinglePrimaryKeyCodec();

  @override
  User fromData(ResolvedCreation<UserData, String> creation) {
    return User(
      id: creation.id,
      username: creation.data.username,
      email: creation.data.email,
      profile: creation.data.profile,
    );
  }

  @override
  String identify(User model) => model.id;
}
```

The complete generated entity also contains `fromJson`, `convert`, and `toJson` implementations.

### Inspect the generated `Dorm` accessor

The generator creates a `Dorm` class that receives the engine and exposes a `DatabaseEntity` for each annotated model:

```dart title="Generated Dorm shape"
class Dorm<Q extends BaseQuery<Q>, P extends PageRequest> {
  const Dorm(this._engine);

  final BaseEngine<Q, P> _engine;

  DatabaseEntity<UserData, User, String, Q, SimpleCreation<UserData, String>, P> get users =>
      DatabaseEntity(const UserEntity(), engine: _engine);
}
```

The `as: #users` value in `@Model` is reflected by the `users` accessor. Application code reaches the repository through `dorm.users.repository`.

Continue with [Connect the memory engine](creating-the-engine.md) to connect
this generated API to the memory engine.
