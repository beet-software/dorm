# `@DerivedField`

`@DerivedField` declares a stored query value assembled from one or more
annotated fields. The generated model calculates the value from the source
fields, and the entity exposes metadata for querying that value.

Use it when the value used by a query is not one field exactly as it appears in
the model. Typical cases are:

- prefix search over a normalized text field;
- exact matching over several fields joined into one value;
- ordering or filtering by a normalized date or date-time representation;
- a backend field whose storage path is separate from the source getters.

The derived value is a persisted representation. It is not an index, a full
text-search engine, or a query callback that runs only when a read is made.
The generated value must therefore be serialized with the model when the
source fields change.

```dart title="lib/models.dart"
@DerivedField(
  name: '_q-name',
  referTo: [DerivedToken(#name, DerivedTransform.text)],
)
// ignore: unused_element
String get _qName;
```

For example, combine two source fields when a single filter value should match
both parts:

```dart title="Combined query value"
@DerivedField(
  name: '_q-address',
  referTo: [DerivedToken(#zipCode), DerivedToken(#number)],
  joinBy: '_',
)
// ignore: unused_element
String get _qAddress;
```

The generated value for `zipCode == '99950'` and `number == 13` is
`99950_13`. A repository can query that persisted value with
`Filter.value('99950_13', field: AddressEntity.fields.qAddress)`.

For a date or date-time query value, apply the corresponding transformation to
the token:

```dart title="Normalized date query value"
@DerivedField(
  name: '_q-created-at',
  referTo: [DerivedToken(#createdAt, DerivedTransform.datetime)],
)
// ignore: unused_element
String get _qCreatedAt;
```

The annotation constructor is:

```dart
const DerivedField({
  String? name,
  required List<DerivedToken> referTo,
  String joinBy = '_',
})
```

`DerivedToken` selects a getter and optionally applies one transformation:

```dart
const DerivedToken(Symbol field, [DerivedTransform? transform])
```

The available transformations are:

| Transform | Observed conversion |
| --- | --- |
| `text` | Text normalization for prefix-style search. |
| `enumeration` | Enum-style normalization. |
| `date` | Fixed-width `YYYYMMDD` date value. |
| `datetime` | Fixed-width `YYYYMMDDHHmmssSSS` local date-time value. |

`joinBy` separates multiple derived components. A simple derived name maps to
a direct stored field. A path with one root and child segment maps to the
corresponding nested field shape where the engine supports it.

Derived values are generated on the model and exposed through generated field
metadata. They are persisted values; the annotation does not create a
database index automatically. Use [Using filters](../build-the-store/using-filters.md)
when querying a derived value.
