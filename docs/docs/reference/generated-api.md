# Generated API

The dORM generator converts the declarations described in [Annotations](../annotations/index.md)
into concrete Dart types. This page describes the generated surface without
repeating the annotation constructors.

## Generated files

For a source file named `models.dart`, generation produces two part files:

| File | Producer | Role |
| --- | --- | --- |
| `models.dorm.dart` | `dorm_generator` | dORM data/model classes, dependencies, schema metadata, entities, `Dorm`, and generated relationship paths. |
| `models.g.dart` | `json_serializable` | JSON serialization helpers used by generated data and model classes. |

The source library must declare the parts:

```dart title="lib/models.dart"
part 'models.dorm.dart';
part 'models.g.dart';
```

Run generation from the directory containing the application `pubspec.yaml`:

```shell
dart run build_runner build
```

## Generated types for a model

For an annotated `_User` declaration, the generator creates types derived from
the declaration name:

| Generated type | Role |
| --- | --- |
| `UserData` | Field and embedded-data values used as create/update input. |
| `User` | Identified model extending `UserData`. |
| `UserDependency` | Dependency value supplied when creating a `User`. |
| `UserFields` | Field metadata used by filters and relationships. |
| `UserEntity` | Schema, identity, conversion, and serialization adapter. |
| `Dorm` | Engine-bound database access object containing entity accessors. |
| `TransactionalDorm` | Transaction-capable facade generated alongside `Dorm` for a transaction-capable engine. |

The generated `Product` model receives the corresponding `ProductData`,
`Product`, `ProductDependency`, `ProductFields`, and `ProductEntity` types.

## Data and model values

The generated data type contains the values supplied by application code. The
generated model adds its identity:

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

`UserData` and `User` receive generated JSON methods. The entity passes the
identity separately when it reconstructs a model from stored JSON.

## Generated dependencies

A model without foreign fields receives a strong dependency:

```dart
class UserDependency extends Dependency<UserData> {
  const UserDependency() : super.strong();
}
```

Models with foreign fields receive generated dependency fields for the related
identities and use weak dependencies. The dependency represents related
identities required to construct the model; it is not the model's own primary
identity.

## Generated entity

The generated entity implements the framework mapping contract. A simple
`String` identity has a shape like this:

```dart title="Generated entity shape"
class UserEntity
    implements Entity<UserData, User, String, SimpleCreation<UserData, String>> {
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

The complete generated entity also contains `fromJson`, `toJson`, and
`convert` implementations. Its schema includes stored fields, primary keys,
foreign fields, and derived-field metadata declared by the source annotations.

## Generated `Dorm`

The generator creates a generic `Dorm` class that receives the engine and
exposes one `DatabaseEntity` accessor for each `@Model`:

```dart title="Generated Dorm shape"
class Dorm<Q extends BaseQuery<Q>, P extends PageRequest> {
  const Dorm(this._engine);

  final BaseEngine<Q, P> _engine;

  DatabaseEntity<
    UserData,
    User,
    String,
    Q,
    SimpleCreation<UserData, String>,
    P
  > get users => DatabaseEntity(const UserEntity(), engine: _engine);
}
```

The `as: #users` value in `@Model` becomes the `users` accessor. Application
code normally reaches the generated operations through
`dorm.users.repository`.

When the selected engine implements `TransactionalEngine<Q, P>`, the generated
library also contains `TransactionalDorm<Q, P>`. It extends `Dorm<Q, P>` and
exposes `transaction`, whose callback receives a temporary `Dorm<Q, P>`.

## Generated relationship paths

`ForeignField.as` names a forward relationship accessor. When `inverseAs` is
provided, the generator creates the inverse accessor on the target model. If
`as` is omitted, the generator derives a name from the foreign-field name and
can remove a trailing `Id`.

Generated paths use `RelationPath` and expose forms corresponding to:

- `toOne`;
- `toOneOrNull`;
- `toMany`;
- `toManyOrEmpty`.

The result shape distinguishes omitted parents, nullable targets, and empty
lists according to the selected path. Duplicate generated path names fail
generation with a `StateError`. The [Quickstart relationship example](../quickstart/relations-and-cart.md)
shows the generated accessors in use.

## Generation boundary

Edit the annotated source, not generated files. Regenerate after changing
annotations, fields, model names, identities, relationships, or serialization
behavior.

Generation failures and conflicting declarations are covered in
[Code generation problems](../troubleshooting/code-generation-problems.md).
