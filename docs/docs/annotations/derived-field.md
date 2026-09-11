# `@DerivedField`

`@DerivedField` marks a static callback that produces a value stored with the
model. The generated model evaluates the callback, and the entity exposes the
persisted value through `DerivedFieldSchema` for filtering or ordering.

Use a derived field when the value needed by a query is calculated from one or
more model properties, such as normalized text, a combined search value, or a
structured value.

The callback name must use the reserved `$dorm$derived$` prefix. The suffix
becomes the generated getter and schema field name. `name` identifies the
persisted storage name; when omitted, the suffix is used.

```dart title="lib/models.dart"
@Model(name: 'users', as: #users)
abstract class _User {
  @Field(name: 'username')
  String get username;

  @DerivedField(name: '_query/username')
  static String $dorm$derived$qUsername(
    _User model,
    DerivedTransformations transformations,
  ) => transformations.text(model.username) ?? '';
}
```

The generated model has a `qUsername` getter and persists its value at
`_query/username`. Query the generated field metadata:

```dart
final users = await dorm.users.repository.peekAll(
  Filter.text(
    'ADA',
    field: UserEntity.fields.qUsername,
  ),
);
```

## Callback signature

Every derived callback must:

- be declared directly on the annotated model class;
- be `static`;
- use exactly two required positional parameters;
- receive the annotated model type first;
- receive `DerivedTransformations` second;
- return a synchronous, non-`void` value.

The generator rejects methods with incompatible signatures, inherited methods,
top-level functions, and asynchronous return types. The callback body is not
analysed for complete serializability; the returned value must be accepted by
the project's serialization and database engine.

## Combining values

The callback controls composition directly. There is no token list and no
automatic separator:

```dart
@DerivedField(name: '_query/address')
static String $dorm$derived$qAddress(
  _Address model,
  DerivedTransformations transformations,
) => '${model.zipCode}_${model.number}';
```

Use the generated field in a query through its `FieldSchema`:

```dart
final addresses = await dorm.addresses.repository.peekAll(
  Filter.value(
    '99950_13',
    field: AddressEntity.fields.qAddress,
  ),
);
```

## Built-in transformations

`DerivedTransformations` provides the normalization helpers used by the
previous token-based API. Each method returns a nullable `String`, so the
callback decides how a null source should be represented.

| Method | Result |
| --- | --- |
| `text` | Removes spaces, replaces supported diacritics, and uppercases text. |
| `enumeration` | Uses an enum's name or normalizes enum-like values. |
| `date` | Formats a date as `YYYYMMDD`. |
| `datetime` | Formats local date and time as `YYYYMMDDHHmmssSSS`. |

```dart
@DerivedField(name: '_query/created-at')
static String $dorm$derived$qCreatedAt(
  _Event model,
  DerivedTransformations transformations,
) => transformations.datetime(model.createdAt) ?? '';
```

The callback may also return a number, boolean, list, map, date, or `null`
when the configured serialization and engine support that representation.

## Storage paths and persistence

A simple `name` creates a direct stored field. A name with one root and one
child segment, such as `_query/username`, preserves that nested shape where the
engine supports it. The generated value is included in model serialization and
is written when the model is persisted.

`@DerivedField` does not create a database index or run as a server-side query
expression. When source properties change, the model must be persisted again so
the stored derived value is updated.

Use [Using filters](../operations/using-filters.md) for query examples.
