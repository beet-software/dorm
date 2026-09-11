# Framework contracts

This page is the normative reference for the engine-neutral contracts in
`dorm_framework`. It describes the behavior an engine must preserve and the
capabilities it may add. Use [Implement a custom engine](../developer-guide/custom-engine.md)
for the implementation sequence.

## `Entity` and schema

An `Entity` connects generated values to storage metadata and identity conversion.
It provides:

- an `EntitySchema`;
- a `PrimaryKeyCodec`;
- conversion between serialized data and models;
- construction from a resolved creation;
- extraction of an identity from a model.

`EntitySchema` contains the stored fields, ordered primary keys, foreign-key
metadata, and derived-field metadata. `FieldSchema` is the metadata value passed
to filters and ordering. The framework, not an engine-specific query class,
owns the logical field name and stored name relationship.

A simple identity has one primary-key field and uses a single-key codec. A
composite identity has multiple ordered fields and uses `CompositeKey` with a
composite codec. The order and shape must agree between the entity, engine,
serialized data, and any synchronization target.

## `Repository` operations

A generated `Repository` combines read, write, and removal contracts for one
entity. The repository keeps the entity's data, model, identity, query, and
page types visible to the analyzer.

### Reads

| Operation | Contract |
| --- | --- |
| `peek` | Returns one model or null when the identity is absent. |
| `peekAll` | Returns every matching model, or an empty list when no model matches. |
| `peekPage` | Returns one `Page` using the entity's accepted `PageRequest` type. |
| `peekAllKeys` | Returns the stored identities. |
| `pull` | Streams one model or null. |
| `pullAll` | Streams matching model lists. |

Absence is a normal result. An engine must not convert an absent record or an
empty collection into a notFound error.

A stream's later events are determined by the engine. The common contract
defines the result shape, not a universal guarantee that every engine observes
external database changes.

### Writes and removal

| Operation | Contract |
| --- | --- |
| `put` | Resolves a creation request, persists the result, and returns the final model. |
| `putAll` | Resolves and persists each creation request and returns the final models. |
| `push` | Persists an already identified model. |
| `pushAll` | Persists identified models. |
| `patch` | Supplies the current model to a callback; a null callback result removes it. |
| `pop` | Removes one identity. |
| `popKeys` | Removes the supplied identities. |
| `popAll` | Removes the identities selected by the primary operation's filter. |
| `purge` | Removes all records for the entity. |

`Creation.auto` follows the identity strategy declared by the entity. An engine
may generate the identity, ask the database to generate it, or require an
explicit identity according to that strategy. `Creation.explicit` always
supplies the final identity.

The framework defines operation results and callback behavior. Atomicity,
isolation, and the number of backend statements remain engine capabilities
unless an operation or transaction contract states otherwise.

## Filters, queries, and pages

`BaseFilter` is a structured value. It resolves a `FieldSchema` and applies a
`FilterExpression` to a concrete `BaseQuery`. The framework does not parse SQL,
Firebase paths, MongoDB selectors, or arbitrary URL strings.

`BaseQuery` provides the portable operations needed by all engines:

- value equality;
- text-prefix matching;
- date comparison;
- range comparison;
- sorting;
- limit;
- offset.

Optional query interfaces advertise extra filter families:

| Capability | Adds |
| --- | --- |
| `ComparisonQuery` | scalar comparisons, set membership, and null checks |
| `LogicalQuery` | allOf and anyOf composition |
| `NegationQuery` | not |
| `CollectionQuery` | contains and containsAny |

A concrete query must implement a capability before its corresponding
structured filter factory is available. An engine must reject an unsupported
capability rather than silently broadening or moving the filter to an
undocumented client-side path.

`QueryOptions` carries ordering and read-window options. `PageRequest` and `Page`
carry pagination input and continuation metadata. Current official engines use
`OffsetPageRequest` as their typed page request; cursor pagination is not a
portable promise.

## Relationships

`BaseRelationship` creates one-to-one, one-to-many, many-to-one, and many-to-many
associations from `RelationSource` values.

`RelationSource` provides readable operations and may provide a `RelationPlan`.
A direct table plan can let an engine optimize a relationship, but readable
operations remain the portable semantic baseline.

Relationship result types distinguish:

- a missing source;
- a missing required related value;
- a nullable related value;
- an empty related collection;
- a populated related collection.

`RelationPath` evaluates lazily. Declaring a path does not execute a query; reads
occur when a `peek` or `pull` operation is called. The framework does not promise a
fixed query count or a native join for every backend.

## Transactions

`TransactionalEngine` is an optional capability:

~~~dart
Future<T> transaction<T>(
  Future<T> Function(BaseEngine<Q, P> engine) action,
);
~~~

`TransactionalDorm` is generated for an engine type that satisfies this
capability. The callback uses a temporary `Dorm` bound to the transaction
context, so repository operations can share the same local transaction.

Streams are unavailable in the transaction context and nested transactions are
not supported by the current generated facade. Engines that do not implement
`TransactionalEngine` remain valid `BaseEngine` implementations.

A backend may use an internal transaction for one operation without exposing
the public transaction capability. Those are separate guarantees.

## Synchronization

`ChangeTrackedEngine` is an optional capability used by `dorm_sync`. Its mutation
result contains the normal operation result and an exact `MutationChangeSet`.

The change set records the affected identities and final serialized data so a
replica can apply the primary result without re-running a callback or
recalculating a filter. `SynchronizedEngine` is not a `TransactionalEngine` and
does not provide distributed atomicity.

See [Synchronization protocol](synchronization.md) for the outbox and delivery
rules.

## Errors

Official external engines may implement `ErrorAwareEngine` and map provider
failures to `DormDatabaseException`. The mapper preserves the native cause,
stack trace, operation, engine, and provider code.

Validation errors raised before a provider call remain ordinary Dart errors.
An engine without `ErrorAwareEngine` may continue to propagate provider-native
errors.

See [Portable errors](errors.md) and [Handling errors](../operations/handling-errors.md).

## `Engine` boundary

A custom engine supplies:

~~~dart
abstract class BaseEngine<Q extends BaseQuery<Q>, P extends PageRequest> {
  BaseReference<Q, P> createReference();
  BaseRelationship<Q> createRelationship();
}
~~~

The reference implements the repository operation surface. The query
implements the engine's query representation. The relationship implementation
must preserve the framework result shape even when it uses a backend-native
plan.

The custom engine guide and the shared conformance tests are the practical
extension boundary. Internal concrete classes from official engines are not
required application APIs.
