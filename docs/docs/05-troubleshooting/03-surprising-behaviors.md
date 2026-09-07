# Behaviors that may surprise users

The same generated repository API can expose different observable behavior
after the engine changes. Use the status of each behavior to distinguish a
current implementation fact from a confirmed cross-engine contract.

| Status | Meaning in this page |
| --- | --- |
| `CONFIRMED` | The behavior or its intended API status is explicitly documented. |
| `CURRENT BEHAVIOR` | The behavior is visible in the current implementation or tests. |
| `IMPLEMENTATION GAP` | The common API exists, but the current engine implementation is incomplete for that capability. |
| `UNKNOWN` | The source shows the behavior, but its long-term status or intended stability is not established. |

## Stream behavior depends on the engine

`pull` and `pullAll` have the same framework-level names across engines,
but their event sources differ:

| Engine | Current stream behavior |
| --- | --- |
| BLoC | Reads are backed by in-process state changes. |
| Firebase | Reads are backed by Realtime Database value events. Offline configuration changes which local/remote events are available. |
| MySQL | The current implementation performs an initial read and does not attach a live database-change listener. |
| PostgreSQL | The current implementation performs an initial read and does not attach a PostgreSQL `LISTEN`/`NOTIFY` listener. |
| MongoDB | The current implementation performs an initial read and does not call `watch` for change streams. |

The MySQL result is therefore an initial stream event in the current
implementation, not evidence of a live subscription to later MySQL changes.
The common method name does not make all engines emit the same event sequence.

See [Connect forms and live reads](../02-build-the-store/05-forms-and-live-reads.md)
for application-level stream usage and the engine setup pages for backend-specific
stream behavior.

## BLoC single reads and collection reads take different paths

In the BLoC engine, `peek` can return the stored model directly. Collection
reads such as `peekAll` and `pullAll` serialize stored models, apply the
query operation to serialized values, and deserialize the selected rows.

This means that two read methods for the same entity can pass through
different conversion steps. The behavior is current BLoC implementation
behavior; it is not a general distinction established by the framework
repository contract.

## Firebase `popAll` reads before deleting

The Firebase implementation of `popAll` first reads the matching models and
then removes their keys. The operation is therefore a read-then-delete
sequence in the current adapter.

Do not treat the method as a universal all-or-nothing transaction across
engines. A failure between the read and the key removal can leave the
operation incomplete. The current non-atomic path is classified as an
implementation limitation, while the broader framework operation does not
give every engine a public transaction API.

## Generated relation names are part of the generated API shape

Relationship accessors are generated from `ForeignField.as` and
`ForeignField.inverseAs`, together with inferred names where applicable. A
relationship can therefore compile with one accessor name and fail to
generate after a second path creates the same generated name.

When generation reports a duplicate relationship path, check the names in the
annotated source. Do not assume that a relation accessor can be renamed only
at the call site; the accessor is generated from the relation metadata.

The distinction between an association name and a generated relation path is
described in [Query and relationship details](../03-understand/04-query-and-relation-details.md).

## Composite identities have a statically restricted creation path

Generated entities expose different creation types according to their primary
key shape:

- simple-key entities accept both `Creation.auto(...)` and
  `Creation.explicit(...)`;
- composite-key entities accept only `Creation.explicit(...)`, so passing
  `Creation.auto(...)` to their generated `put` or `putAll` is a compile-time
  error;
- if the static type is bypassed with `dynamic`, a cast, or a broad custom
  contract, the engines still throw `UnsupportedError` for automatic
  composite-key creation;
- Firebase reference operations require identity values of type `String`.

An explicitly identified model may use `push` where the automatic `put` path
cannot create an identity. The generated API prevents the invalid automatic
creation call before execution; the runtime error remains a safeguard for
statically bypassed calls.

Read [Identity and dependencies](../03-understand/02-identity-and-dependencies.md)
before interpreting a composite-key error as a model-generation failure. Use
`Creation.explicit` with a `CompositeKey` when the selected engine supports
composite-key creation.

## Query fields carry legacy and portability qualifications

`DerivedField` and generated derived metadata are used by current filters and
relationship examples. The existing query-field representation originated in
the Firebase-oriented part of the implementation and has portability limits
in the current abstraction.

Treat a derived field as the current generated/query API shape. Do not infer
that every query-field operation has identical server-side behavior in BLoC,
Firebase, and MySQL. The selected engine translates or evaluates the query in
its own backend representation.

## Polymorphic values retain a backend-sensitive representation

Generated polymorphic values currently use discriminator and payload data in
their serialized representation. The representation is observable in the
generated JSON-compatible model path, but its stability as a universal wire
format across all engines is `UNKNOWN`.

When a polymorphic value fails during mapping, inspect both the generated JSON
shape and the selected engine's conversion boundary. Do not diagnose every
polymorphic failure as a relationship or identity error.

## Public barrels and internal implementation paths are different

Concrete classes under a package's `lib/src/` directory may be importable by a
package URI while not being re-exported by the package barrel. Tests or local
code that import such a path do not establish the same public status as an
API exported from:

```text
package:dorm_annotations/dorm_annotations.dart
package:dorm_framework/dorm_framework.dart
package:dorm_generator/dorm_generator.dart
package:dorm_bloc_database/dorm_bloc_database.dart
package:dorm_firebase_database/dorm_firebase_database.dart
package:dorm_mysql_database/dorm_mysql_database.dart
```

Use the barrel imports for application code. The support status of a concrete
`lib/src/` import is `UNKNOWN` unless it is also part of the documented
public barrel surface.

## Keep mismatches qualified

If an example, a README statement, an exported symbol, and the current
generated API disagree, record the disagreement as `UNKNOWN` until the
public contract is clarified. Do not silently turn one implementation detail
into a compatibility guarantee.

For current version, runtime, engine, and API status, read
[Boundaries and compatibility](../03-understand/05-boundaries-and-compatibility.md).
