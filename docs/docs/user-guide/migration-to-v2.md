# Migration to v2

This guide updates an application from the latest published v1 prerelease,
`1.0.0-alpha.7`, to the current dORM API.

The change is not limited to package versions. The current API changes how
new models are created, how generated entities are typed, and how identity
metadata is described. Update the dORM packages together, then regenerate the
application parts before analyzing the project.

## Before you start

Create a branch or commit for the migration, then locate the Dart library that
contains your annotated models.

The published v1 packages are available on [pub.dev for
`dorm_annotations`](https://pub.dev/packages/dorm_annotations),
[`dorm_framework`](https://pub.dev/packages/dorm_framework), and
[`dorm_generator`](https://pub.dev/packages/dorm_generator). The examples in
this guide use the current API exposed by those packages.

## Migrating application code
This section changes the packages, annotations, creation calls, and
generated files used by an application.

### Update package dependencies

Keep the runtime packages and the generator package on the same dORM release
line:

```shell
dart pub add dorm_framework
dart pub add dorm_annotations
dart pub add dorm_memory_database
dart pub add --dev dorm_generator
dart pub add --dev build_runner
dart pub get
```

Replace `dorm_memory_database` with the engine package used by the application.

The roles remain separate:

| Package | Role in the migrated application |
| --- | --- |
| `dorm_annotations` | Model, field, relationship, and identity annotations. |
| `dorm_framework` | Engine-independent repositories, filters, identities, relationships, and generated-type contracts. |
| `dorm_generator` | Builder that generates dORM parts and coordinates JSON and copy-with generation. |
| Database engine | Concrete storage implementation used to construct `Dorm`. |

If application source imports `json_annotation`, `copy_with_extension`, or
another package directly, keep that dependency according to the imports in
that source file.

If the application still imports the package name from the earliest releases,
replace:

```dart title="v1"
import 'package:dorm/dorm.dart';
```

with:

```dart title="v2"
import 'package:dorm_framework/dorm_framework.dart';
```

### Replace `uidType` identity declarations

The published v1 annotation described identity behavior with `uidType`. It
provided four forms: `UidType.simple()`, `UidType.composite()`,
`UidType.sameAs(...)`, and `UidType.custom(...)`.

#### UidType.simple

```dart title="v1"
@Model(name: 'users', as: #users, uidType: UidType.simple())
abstract class _User {
  @Field(name: 'username')
  String get username;
}
```

The current default has the same generated `String` identity and does not need
an explicit `primaryKey` entry:

```dart title="v2"
@Model(name: 'users', as: #users)
abstract class _User {
  @Field(name: 'username')
  String get username;
}
```

#### UidType.sameAs

```dart title="v1"
@Model(name: 'country', as: #countries)
abstract class _Country {}

@Model(
  name: 'capitals',
  as: #capitals,
  uidType: UidType.sameAs(_Country),
)
abstract class _Capital {
  @ForeignField(name: 'country_id', referTo: _Country)
  String get countryId;
}
```

`UidType.sameAs(_Country)` made the annotated model use the value of its foreign
key to `_Country` as its own identity. In the current API, reference that
foreign-key getter with `ExistingIdSpec`:

```dart title="v2"
@Model(
  name: 'capitals',
  as: #capitals,
  primaryKey: [ExistingIdSpec(referTo: #countryId)],
)
abstract class _Capital {
  @ForeignField(name: 'country_id', referTo: _Country)
  String get countryId;
}
```

The foreign-key type must match the identity type of `_Country`.

#### UidType.composite

The published v1 `UidType.composite()` behavior produced a readable
single-string identity by joining selected foreign-key values with `_` and
appending a unique value. The current equivalent is an engine-generated
simple identity customized with `$dorm$generateId`.

```dart title="v1"
@Model(name: 'orders', as: #orders)
abstract class _Order {}

@Model(name: 'products', as: #products)
abstract class _Product {}

@Model(name: 'order_lines', as: #orderLines, uidType: UidType.composite())
abstract class _OrderLine {
  @ForeignField(name: 'order_id', referTo: _Order)
  String get orderId;

  @ForeignField(name: 'product_id', referTo: _Product)
  String get productId;
}
```

In the current API, keep the model's identity simple and customize the
generated value with `$dorm$generateId`:

```dart title="v2"
@Model(name: 'order_lines', as: #orderLines)
abstract class _OrderLine {
  static String $dorm$generateId(_OrderLine model, String generatedId) {
    return '${model.orderId}_${model.productId}_$generatedId';
  }

  @ForeignField(name: 'order_id', referTo: _Order)
  String get orderId;

  @ForeignField(name: 'product_id', referTo: _Product)
  String get productId;
}
```

The generated identity remains a single `String`, while the foreign-key values
are included in its readable prefix. The second parameter preserves the unique
identity initially generated by the engine and should remain at the end of the
constructed value.

#### UidType.custom

```dart title="v1"
CustomUidValue _identifyCitizen(Object data) {
  data as _Citizen;
  if (data.isForeigner) {
    return CustomUidValue.value(data.visaCode);
  }
  if (data.socialSecurity != null) {
    return CustomUidValue.value(data.socialSecurity);
  }
  return const CustomUidValue.simple();
}

@Model(
  name: 'citizens',
  as: #citizens,
  uidType: UidType.custom(_identifyCitizen),
)
abstract class _Citizen {
  @Field(name: 'is_foreigner')
  bool get isForeigner;

  @Field(name: 'visa_code')
  String get visaCode;

  @Field(name: 'social_security')
  String? get socialSecurity;
}
```

`UidType.custom(...)` must be split according to the value returned by its
callback. A custom simple value can use `GeneratedIdSpec` together with the
reserved `$dorm$generateId` method:

```dart title="v2"
@Model(
  name: 'citizens',
  as: #citizens,
  primaryKey: [GeneratedIdSpec()],
)
abstract class _Citizen {
  static String $dorm$generateId(_Citizen model, String generatedId) {
    if (model.isForeigner) return model.visaCode;
    if (model.socialSecurity != null) return model.socialSecurity!;
    return generatedId;
  }

  @Field(name: 'is_foreigner')
  bool get isForeigner;

  @Field(name: 'visa_code')
  String get visaCode;

  @Field(name: 'social_security')
  String? get socialSecurity;
}
```

The current generator convention receives the generated identity as its second
parameter and returns the final simple identity.

### Replace query fields with derived fields

If the old model uses `QueryField`, replace it with `DerivedField`. A derived
field combines values from other annotated fields into a stored/queryable
value:

```dart title="v1"
@QueryField(
  name: 'search_name',
  referTo: [
    QueryToken(#firstName, QueryType.text),
    QueryToken(#lastName, QueryType.text),
  ],
)
String get searchName;
```

The current annotation is:

```dart title="v2"
@DerivedField(
  name: 'search_name',
  referTo: [
    DerivedToken(#firstName, DerivedTransform.text),
    DerivedToken(#lastName, DerivedTransform.text),
  ],
)
String get searchName;
```

The field names referenced by `DerivedToken` must be declared fields or foreign
fields on the same model. The current API also supports `DerivedTransform.date`
and `DerivedTransform.datetime` for `DateTime` values.

### Update identity generation

#### Replace the old `put` calls

The published API accepted a dependency and data as separate arguments:

```dart title="v1"
final User user = await dorm.users.repository.put(
  const UserDependency(),
  const UserData(username: 'ada'),
);
```

The current API receives one creation object. `Creation.auto` follows the
identity strategy declared by the model:

```dart title="v2"
final User user = await dorm.users.repository.put(
  Creation.auto(
    dependency: const UserDependency(),
    data: const UserData(username: 'ada'),
  ),
);
```

#### Update `putAll`

The old `putAll` used one dependency for a list of data values:

```dart title="v1"
await dorm.users.repository.putAll(
  const UserDependency(),
  [userAData, userBData],
);
```

The current method receives one `Creation` per item. Each item can have its
own dependency, data, and identity strategy:

```dart title="v2"
await dorm.users.repository.putAll([
  Creation.auto(
    dependency: const UserDependency(),
    data: userAData,
  ),
  Creation.explicit(
    dependency: const UserDependency(),
    data: userBData,
    identity: 'legacy-user-42',
  ),
]);
```

`Dependency.ids` continues to describe identities of related entities. It is
not the identity of the model being created.

### Move custom generated-ID logic into the model

```dart title="v1"
@Model(primaryKeyGenerator: _User.generateId)
abstract class _User {
  static String generateId(_User model, String generatedId) => model.username;
}
```

Declare the reserved static method directly on the annotated class instead, using `$dorm$generateId`:

```dart title="v2"
@Model(name: 'users', as: #users)
abstract class _User {
  static String $dorm$generateId(_User model, String generatedId) {
    return model.username;
  }
}
```

The method must be declared directly on the annotated class, be `static`, have
two required positional parameters, and use the annotated class as its first
parameter type. Its second parameter and return type must match the generated
identity type. The method receives the initially generated identity and is
used only when the identity source is `generated`.

It is not used for `Creation.explicit` or for a database/backend-generated
identity. In `ExistingIdSpec`, `DatabaseGeneratedIdSpec`, or composite-key
models, the method is invalid.

When no `$dorm$generateId` method is declared, the generated model keeps the
identity supplied by the creation resolution.

### Regenerate the generated API

After updating the annotations and source signatures, run the commands from
the application directory:

```shell
dart pub get
dart run build_runner build --delete-conflicting-outputs
dart analyze
dart test
```

For a Flutter application, use the Flutter equivalents from the Flutter
project directory:

```shell
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
```

Do not edit `*.dorm.dart` or `*.g.dart` to resolve migration errors. A stale
part file can keep old signatures visible after the source has been updated;
regeneration replaces that derived API.

The published v1 generated facade was not generic over the page-request type:

```dart title="v1"
class Dorm {
  const Dorm(this._engine);

  final BaseEngine<Query> _engine;
}
```

The current generated facade is generic over both the query and page-request
types:

```dart title="v2"
class Dorm<Q extends BaseQuery<Q>, P extends PageRequest> {
  const Dorm(this._engine);

  final BaseEngine<Q, P> _engine;
}
```

The published v1 facade was commonly used without type arguments:

```dart title="v1"
final Dorm dorm = Dorm(engine);
```

The current facade can still infer its types from the engine:

```dart title="v2"
final dorm = Dorm(engine);
```

If an explicit type is needed, provide both current parameters. The v1
declaration had only the facade type itself:

```dart title="v1"
final Dorm dorm = Dorm(engine);
```

The current declaration includes the concrete query and page-request types:

```dart title="v2"
final Dorm<Query, OffsetPageRequest> dorm = Dorm(engine);
```

Replace `Query` with the concrete query type exposed by the selected engine.

The generated library also contains `TransactionalDorm<Q, P>` when the engine
implements the optional `TransactionalEngine<Q, P>` capability.

## Migrating custom dORM integrations

This section applies to custom engines, custom entities, custom repositories,
and other code that implements dORM framework contracts. Applications that
only consume generated models and a published engine do not need these
internal changes.

### Update custom `Entity.fromData`

Custom entities using the old three-argument method:

```dart title="v1"
User fromData(UserDependency dependency, String id, UserData data);
```

must accept a `ResolvedCreation`:

```dart title="v2"
User fromData(ResolvedCreation<UserData, String> creation) {
  return User(
    id: creation.id,
    username: creation.data.username,
  );
}
```

Use `creation.dependency`, `creation.data`, and `creation.id` when constructing
the model. `creation.identitySource` reports whether the final identity came
from the engine, the database/backend, or the caller.

### Update engine and reference types

The old engine contract had one query parameter:

```dart title="v1"
abstract class BaseEngine<Q extends BaseQuery<Q>> {
  BaseReference<Q> createReference();
}
```

The current contract also declares the accepted page-request type:

```dart title="v2"
abstract class BaseEngine<
  Q extends BaseQuery<Q>,
  P extends PageRequest
> {
  BaseReference<Q, P> createReference();
  BaseRelationship<Q> createRelationship();
}
```

Current engines expose `OffsetPageRequest` as `P`. Update custom references and
repositories to carry the same type. A `CursorPageRequest` is not accepted by
the current engines' statically typed repositories.

### Update entity and repository types

The published v1 `Entity` contract had no creation type and exposed the table
name directly:

```dart title="v1"
abstract class Entity<Data, Model extends Data, I extends Object> {
  String get tableName;
  Model fromData(Dependency<Data> dependency, I id, Data data);
  I identify(Model model);
}
```

The current `Entity` contract includes the creation type and schema metadata:

```dart title="v2"
abstract class Entity<
  Data,
  Model extends Data,
  I extends Object,
  C extends Creation<Data, I>
> {
  EntitySchema get schema;
  PrimaryKeyCodec<I> get primaryKeyCodec;
  IdentityGenerationStrategy get identityGeneration;
}
```

The published v1 repository type was:

```dart title="v1"
Repository<Data, Model, I, Q>
```

The current repository type is:

```dart title="v2"
Repository<Data, Model, I, Q, C, P>
```

Generated code supplies `SimpleCreation<Data, I>` for simple identities and an
explicit creation type for composite identities. Regenerate generated code
instead of changing these type arguments by hand.

### Update schema access

Use the current schema metadata rather than a direct entity table-name or
singular-key property:

```dart title="v1"
final String tableName = entity.tableName;
```

Use the current schema metadata:

```dart title="v2"
final String tableName = entity.schema.tableName;
final List<FieldSchema> keys = entity.schema.primaryKeys;
```

`PrimaryKeyCodec` remains responsible for encoding and decoding identity
values. It is separate from `IdentityGenerationStrategy`, which describes how
`Creation.auto` obtains the identity.

## Migration checklist

- Update `dorm_annotations`, `dorm_framework`, `dorm_generator`, and the selected
  engine together.
- Replace each `uidType` declaration with its current equivalent: the default
  generated identity, `ExistingIdSpec`, or `$dorm$generateId`, as applicable.
- Replace `QueryField` with `DerivedField` where applicable.
- Replace `primaryKeyGenerator` with a directly declared static
  `$dorm$generateId` method.
- Replace `put(dependency, data)` with `put(Creation.auto(...))` or
  `put(Creation.explicit(...))`.
- Replace the old two-argument `putAll` call with one `Creation` per item.
- Update custom `Entity.fromData` implementations to accept
  `ResolvedCreation`.
- Update custom engines and repositories to carry `I`, `C`, `Q`, and `P`.
- Replace direct table and key metadata access with `entity.schema` and
  `entity.schema.primaryKeys`.
- Regenerate `*.dorm.dart` and `*.g.dart`.
- Update explicit `Dorm` types to `Dorm<Q, P>`.
- Run analysis and tests for the application and selected engine.
- Recheck identity generation, composite identities, relationships, pagination,
  and streams after the migration.

## Common migration errors

### `put` expects one argument

The repository now expects a `Creation` object. Wrap the dependency and data
with `Creation.auto`, or provide the final identity with
`Creation.explicit`.

### `fromData` no longer matches `Entity`

Change the custom implementation from three parameters to one
`ResolvedCreation<Data, I>` parameter and read its `dependency`, `data`, and
`id` fields.

### `Creation.auto` is rejected for a composite model

This is expected for a true multi-column identity declared in the current API.
Provide an ordered `CompositeKey` through `Creation.explicit`. To reproduce
the published `UidType.composite()` readable string, use the simple identity
and `$dorm$generateId` migration shown in the annotated-models section instead.

### `Dorm<OffsetPageRequest>` no longer compiles

The current facade has two type parameters. Use `Dorm<Q, OffsetPageRequest>` or
let Dart infer both types from `Dorm(engine)`.

### A cursor request is rejected

Current engines expose `OffsetPageRequest`. Passing `CursorPageRequest` through
a statically typed current repository is not supported.

### `$dorm$generateId` is rejected during generation

Check that the method is static, declared directly on the annotated class, has
exactly two required positional parameters, and uses the generated identity
type for its second parameter and return value. The method is valid only for a
`GeneratedIdSpec` model with a simple identity.

### Old signatures remain in generated code

Delete or replace conflicting generated outputs through the build command, then
run generation again. The source model and annotations are the inputs; the
generated parts are not migration-editable source.
