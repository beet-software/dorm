# Serialization, generated mapping, and database values

Generated models cross several representations during a repository operation. Dart values become maps or backend values on writes, and backend values become generated models on reads.

## Locate the generated serialization hooks

For each generated data or model class, dORM emits JSON methods through `json_serializable`:

```dart
final Map<String, Object?> data = userData.toJson();
final User user = User.fromJson(userId, storedMap);
```

The generated entity delegates to those methods:

```text
Data/Model object
      -> Entity.toJson
      -> generated toJson
      -> map accepted by the engine

backend map/row
      -> Entity.fromJson(id, data)
      -> generated fromJson
      -> Model object
```

The identity is passed separately to `fromJson`. Generated model `toJson` removes the internal identity entry before returning the persisted field map; the engine receives the identity through the model/schema path.

The source library must declare both generated parts:

```dart
part 'models.dorm.dart';
part 'models.g.dart';
```

Regenerate after changing fields, annotations, or serialization behavior:

```shell
dart run build_runner build
```

## Observe scalar conversions

The generated store model demonstrates these conversions:

| Dart value | Generated representation observed in the model |
| --- | --- |
| `DateTime` | ISO-8601 text on `toJson`; parsed with `DateTime.parse` on read |
| `Decimal` | Decimal JSON string; reconstructed with `Decimal.fromJson` |
| enum | String value selected by the generated enum map |
| nullable field | Omitted or nullable JSON value according to generated serialization metadata |
| nested data object | Nested map produced by the nested object's `toJson` |

For example, `Profile.birthDate` is parsed from the `birth-date` map entry, and `Product.price` is serialized through the generated Decimal conversion.

The accepted scalar and collection types follow the `json_serializable` integration used by the generated classes. A custom type must provide a conversion that the cooperating serializer can use; dORM does not add a separate universal converter for arbitrary Dart classes.

## Map embedded values

`Profile` is annotated with `@Data`, not `@Model`. `User.profile` is declared with `@ModelField`, so the generated `UserData.toJson` nests the profile representation:

```text
UserData
  -> profile.toJson()
  -> { "profile": { "name": ..., "birth-date": ..., "bio": ... } }
```

The embedded value is reconstructed with `Profile.fromJson` while `User.fromJson` is being created. There is no separate `Profile` repository accessor in the generated `Dorm` for this declaration.

## Map polymorphic values

`Review.content` uses `@PolymorphicField(name: 'content', pivotName: 'type')`. The generated representation contains both:

- `type`, which identifies the variant;
- `content`, which contains that variant's serialized fields.

The generated `ReviewContent.fromType` selects the concrete class:

```text
Review JSON map
  -> read type
  -> ReviewContent.fromType(type, content)
  -> ProductReviewContent / ServiceReviewContent / UserReviewContent
```

The current example maps `ReviewContentType.product` to `ProductReviewContent`, `service` to `ServiceReviewContent`, and `user` to `UserReviewContent`.

The polymorphic representation originated in the Firebase-oriented part of the project and is not confirmed as a stable cross-engine wire-format contract. The generated classes currently serialize it as nested JSON-compatible values.

## Cross the backend mapping boundary

The engine receives the map or query values after entity serialization:

- BLoC converts model values for collection filtering and keeps selected results in memory;
- Firebase writes maps below the configured Realtime Database path and reconstructs models from Firebase snapshots;
- MySQL maps serialized fields to SQL columns and reconstructs models from rows.

The backend representation is therefore engine-specific. A successful `toJson`/`fromJson` pair does not by itself establish identical storage representations between BLoC, Firebase, and MySQL.

## Track information changes

Information can change representation at these boundaries:

1. Dart field names can map to different persisted names, such as `birthDate` to `birth-date`.
2. Model identity is separated from the persisted data map.
3. Date, decimal, and enum values become serializer-defined strings or values.
4. Query fields add generated persisted values such as `_q-username` and `_q-type`.
5. Backend adapters may represent the same map as an in-memory value, Firebase snapshot, or SQL row.

The generated entity and cooperating serializer own these conversions. Backend errors and deserialization errors propagate through the repository operation rather than being converted into one common error type.
