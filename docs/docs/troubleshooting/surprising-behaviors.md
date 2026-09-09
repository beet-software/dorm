# Check surprising behaviors

The same generated repository API can behave differently after the engine
changes. The following points are current behaviors that commonly affect
application code.

## Streams depend on the engine

`pull` and `pullAll` have the same names across engines, but their event
sources differ:

| Engine | Current behavior |
| --- | --- |
| In-memory and BLoC | Backed by in-process state changes. |
| Firebase | Backed by Realtime Database value events. Offline configuration changes which local and remote events are available. |
| MySQL | Performs an initial read without a live database-change listener. |
| PostgreSQL | Performs an initial read without a `LISTEN`/`NOTIFY` listener. |
| MongoDB | Performs an initial read without calling `watch` for change streams. |
| HTTP | Performs the configured initial request without polling or a push channel. |

The common method name does not make every engine emit the same event sequence.
See [Handle input and live reads](../quickstart/forms-and-live-reads.md) and
the selected engine page before relying on later events.

## Advanced filters can be rejected before execution

The portable filter set is available across engines, but comparison, set,
logical, negation, and collection filters are optional query capabilities. A
generated repository preserves the concrete query type, so a filter whose
generic bound is not implemented by that query produces an analyzer error.

This is different from a backend rejecting a valid query at runtime. For
example, Firestore may accept a logical expression only when its index and
query rules allow it, while Firebase Realtime Database does not advertise
general `allOf`, `anyOf`, or `not` composition. The HTTP engine exposes only
the filter operations implemented by its current mapping surface.

The engine does not download a larger result set to imitate an unsupported
filter in Dart. Use a supported condition, change the persisted value used by
the query, or make a separate local filtering step explicit in application
code when its data volume and semantics are known.

Remember that `Filter.text` is a prefix filter. It is not a substring search,
regular expression, or full-text search. `Filter.contains` applies to a
persisted collection and is not a text operator.

## Creation of composite identities is restricted by type

Generated entities expose different creation types according to their primary
key shape:

- simple-key entities accept `Creation.auto(...)` and
  `Creation.explicit(...)`;
- composite-key entities accept only `Creation.explicit(...)`, so
  `Creation.auto(...)` is rejected at compile time;
- calls through `dynamic`, casts, or a deliberately broad contract can bypass
  that static restriction and reach the runtime `UnsupportedError` guard;
- Firebase reference operations require identity values of type `String`.

Use [Create records](../build-the-store/creating.md) and
[`@Model`](../annotations/model.md) when the identity declaration or creation
operation is unclear.

## Engines can take different paths for the same operation

The common repository name does not guarantee the same number of conversions,
requests, or atomic steps:

- BLoC collection reads serialize and deserialize values while applying a
  query, even though a single `peek` can return the stored model directly.
- Firebase `popAll` reads matching models and then removes their keys.
- SQL engines use transactions for some operations, while MongoDB and HTTP
  have different batch and atomicity behavior.

Read the engine page for the backend-specific operation and transaction
behavior before treating an operation as all-or-nothing.

## Relationship names come from annotations

Generated relationship accessors use `ForeignField.as` and
`ForeignField.inverseAs`, together with inferred names. Two paths can therefore
produce the same generated name.

When generation reports a duplicate relation path, change the names in the
annotated source and regenerate. Do not rename the getter directly in a
`*.dorm.dart` file. See [ForeignField](../annotations/foreign-field.md).

## Derived and polymorphic values have backend-sensitive representations

`DerivedField` calls a static Dart callback to create a value that can be used
by filters. It does not automatically create the same index or query strategy
in every engine. The selected engine translates or evaluates the persisted
field in its own representation.

Polymorphic values currently use discriminator and payload data in their
serialized representation. The generated JSON-compatible shape is observable,
but its stability as one universal wire format across all engines is
`UNKNOWN`.

See [DerivedField](../annotations/derived-field.md),
[PolymorphicField](../annotations/polymorphic-field.md), and
[Model anatomy](../model-anatomy/entity.md) for the relevant mapping rules.

## Import the documented public surface

Concrete classes under a package's `lib/src/` directory may be importable by a
package URI without being re-exported by the package barrel. Use the documented
barrel imports in application code:

```text
package:dorm_framework/dorm_framework.dart
package:dorm_memory_database/dorm_memory_database.dart
package:dorm_postgres_database/dorm_postgres_database.dart
```

Importing an internal `lib/src/` class does not establish a supported public
contract.

## Keep mismatches qualified

When an example, generated output, exported symbol, and current implementation
disagree, treat the status as unresolved until the public contract identifies
which behavior applies. Do not turn an implementation detail into a
cross-engine guarantee.
