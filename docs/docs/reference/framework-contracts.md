# Framework contracts and abstractions

The framework package defines engine-neutral types. Generated entities and
repositories use these contracts; concrete engines provide the storage
behavior.

## Entity and schema contracts

### Entity<Data, Model extends Data, I extends Object, C extends Creation<Data, I>>

An entity maps generated data/model values to an engine-neutral schema and
identity:

| Member | Signature shape | Result |
| --- | --- | --- |
| schema | EntitySchema get schema | Field, foreign-key, and primary-key metadata. |
| primaryKeyCodec | PrimaryKeyCodec<I> get primaryKeyCodec | Identity-to-key-field conversion. |
| fromJson | Model fromJson(I id, Map data) | Model reconstructed from stored data and identity. |
| toJson | Map<String, Object?> toJson(Data data) | Data converted to stored field values. |
| convert | Model convert(Model model, Data data) | Existing model updated from data. |
| fromData | Model fromData(ResolvedCreation<Data, I>) | Model constructed from a resolved dependency, identity, and data. |
| identityGeneration | IdentityGenerationStrategy get identityGeneration | How `Creation.auto` obtains the final identity: `engine`, `database`, or `explicit`. |
| identify | I identify(Model model) | Identity extracted from a model. |

Generated entities implement this interface.

### DatabaseEntity

DatabaseEntity<Data, Model, I, Q, C, P> combines one Entity with a
BaseEngine<Q, P>. It exposes the repository whose `put` and `putAll` methods
accept `C` and whose `peekPage` accepts `P`, together with:

- repository;
- relationships;
- delegated entity conversion and identity methods.

Generated Dorm classes create one DatabaseEntity accessor per annotated model.

### Schema types

| Type | Role |
| --- | --- |
| EntitySchema | Entity name, fields, primary-key fields, and foreign-key metadata. |
| FieldSchema | Stored field name, Dart name/type metadata, and field properties. |
| ForeignKeySchema | Foreign-field metadata, target entity, and uniqueness. |
| PrimaryKeyCodec<I> | Encodes and decodes identity values. |
| SinglePrimaryKeyCodec<I> | Encodes one identity value and requires one decoded value. |
| CompositePrimaryKeyCodec | Encodes/decodes CompositeKey. |
| CompositeKey | Ordered collection of composite identity values. |

EntitySchema.primaryKeys is the ordered list of primary-key fields. It contains
one item for a simple key and multiple items for a composite key.

## Repository contracts

Repository<Data, Model, I, Q, C, P> combines SingleReadOperation,
BatchReadOperation, ModelRepository, and DataRepository. `C` is the creation
type and `P` is the page-request type accepted by that entity.

### Read contracts

~~~dart
Future<Model?> peek(I id);
Future<List<Model>> peekAll([
  BaseFilter<Q> filter,
  QueryOptions options,
]);
Future<Page<Model>> peekPage(BaseFilter<Q> filter, P request);
Stream<Model?> pull(I id);
Stream<List<Model>> pullAll([
  BaseFilter<Q> filter,
  QueryOptions options,
]);
Future<List<I>> peekAllKeys();
~~~

peek returns null for an absent identity. Collection reads return lists.
Streams expose the corresponding single or collection result shape. The
current MySQL implementation emits an initial read without a live database
listener.

### Write and removal contracts

~~~dart
Future<Model> put(C creation);
Future<List<Model>> putAll(List<C> creations);
Future<void> push(Model model);
Future<void> pushAll(List<Model> models);
Future<void> patch(I id, Model? Function(Model?) update);
Future<void> pop(I id);
Future<void> popKeys(Iterable<I> ids);
Future<void> popAll(BaseFilter<Q> filter);
Future<void> purge();
~~~

put creates a model from a creation request. Simple-key entities use
`SimpleCreation<Data, I>` and accept both factory results. Composite-key
entities use `ExplicitCreation<Data, CompositeKey>`, so automatic creation is
rejected at compile time by the generated contract. `Creation.auto` follows
the identity strategy declared by the entity, while `Creation.explicit`
supplies the final identity. push persists an already identified model. patch receives the
current model or null; returning null removes the record.

The framework documentation describes popKeys, popAll, pushAll, and patch as
operations expected to be atomic where the selected engine provides that
behavior. `TransactionalDorm` is the separate public contract for composing
multiple repository operations; engines that do not implement it retain their
individual operation semantics.

## Filter and query contracts

### BaseQuery<Q extends BaseQuery<Q>>

Concrete queries implement:

~~~dart
Q whereValue(String key, Object? value);
Q whereText(String key, String prefix);
Q whereDate(String key, DateTime date, DateFilterUnit unit);
Q whereRange<T>(String key, FilterRange<T> range);
Q limit(int count);
Q offset(int count);
Q sorted(String key, {bool ascending = true});
~~~

The concrete query determines how these operations become in-memory
predicates, Firebase query clauses, or SQL.

Optional query capabilities extend `BaseQuery` without changing the portable
contract:

```dart
abstract interface class ComparisonQuery<Q extends ComparisonQuery<Q>>
    implements BaseQuery<Q> {
  Q whereComparison(String key, FilterComparisonOperator operator, Object? value);
  Q whereSet(String key, Iterable<Object?> values, {required bool negated});
  Q whereNull(String key, {required bool isNull});
}

abstract interface class LogicalQuery<Q extends LogicalQuery<Q>>
    implements BaseQuery<Q> {
  Q whereAll(Iterable<BaseFilter> filters);
  Q whereAny(Iterable<BaseFilter> filters);
}
```

`NegationQuery` and `CollectionQuery` provide the corresponding `whereNot`,
`whereContains`, and `whereContainsAny` operations. A query advertises a
capability by implementing the interface; the structured filter factories use
the same generic bound. This keeps unsupported operations from being silently
translated into a different query.

### BaseFilter<Q>

A filter applies a condition or modifier through Q accept(Q query).
Factories cover empty, value, text, text-range, numeric-range, date, and
date-range filters. Capability-based factories add scalar comparisons, set
membership, null checks, collection membership, and `allOf`, `anyOf`, and
`not` composition. `allOf([])` is the empty filter; `anyOf([])` throws
`ArgumentError`.

QueryOptions applies OrderBy, limit, and offset to a query. PageRequest
describes an offset or cursor page, and Page contains the returned items and
continuation metadata. Current engine contracts use `OffsetPageRequest` as
`P`. A `CursorPageRequest` passed through a statically typed current engine
repository is rejected by the analyzer.

Values remain structured parameters passed to the engine. The framework does
not define regex, full-text, aggregation, geospatial, JSON-path, or arbitrary
backend-selector filters, and it does not fall back to client-side filtering
when an engine cannot translate a supported capability.

Structured filters require a `FieldSchema` and resolve its `columnName` before
calling `BaseQuery`. `OrderBy` also requires a `FieldSchema`. The `BaseQuery`
contract receives the resolved storage name as a string because it is the
engine-level query construction contract.

The structured constructors are equivalent to:

```dart
Filter.value(value, field: entityField);
Filter.text(prefix, field: entityField);
Filter.textRange(range, field: entityField);
Filter.numericRange(range, field: entityField);
Filter.dateRange(range, field: entityField);
Filter.date(date, field: entityField);
const OrderBy(entityField);
```

For fields that are not generated, create the metadata explicitly:

```dart
const FieldSchema(
  fieldName: 'externalName',
  columnName: 'external_name',
)
```

## Relationship contracts

### Sources and plans

RelationSource combines single and batch readable operations with a
RelationPlan and optional EntitySchema.

| Type | Role |
| --- | --- |
| RelationPlan | Describes how an association source can be executed. |
| TableRelationPlan | Describes a direct entity/table source and key decoding. |
| CompositeRelationPlan | Marks a source produced by another relationship. |
| RelationSpec | Describes one generated path step and its cardinality/fields. |
| Join<L, R> | Carries a left model and related result. |

### Associations

The type aliases describe result cardinalities:

~~~dart
OneToOneAssociation<L, I, R, Q>  // R?
OneToManyAssociation<L, I, R, Q> // List<R>
ManyToOneAssociation<L, I, R, J, Q>
ManyToManyAssociation<M, I, L, R, Q> // (L?, R?)
~~~

BaseRelationship<Q> creates the association forms from readable sources and
callbacks that determine related identities or filters.

### RelationPath

RelationPath<Context, Root, Current, Q> accumulates generated relationship
steps. It reads lazily: related data is requested when peekAll or pullAll is
called. Results are Join<Root, Current> values.

Generated path variants retain cardinality-specific behavior:

- required to-one paths omit a root without a related value;
- nullable to-one paths retain the root with null;
- to-many paths flatten related values;
- empty-preserving to-many paths retain an empty list.

## Engine boundary

~~~dart
abstract class BaseEngine<Q extends BaseQuery<Q>, P extends PageRequest> {
  BaseReference<Q, P> createReference();
  BaseRelationship<Q> createRelationship();
}
~~~

BaseReference<Q, P> implements the storage operation surface, and
BaseRelationship<Q> implements relationship associations. A custom engine
implements these contracts and exposes a concrete Engine.

See [Implement a custom engine](../development/custom-engine.md) for the
extension boundary and [Engine capability reference](engine-capabilities.md)
for concrete implementations.

## Transaction capability

An engine that supports the portable transaction API also implements:

~~~dart
abstract interface class TransactionalEngine<
  Q extends BaseQuery<Q>,
  P extends PageRequest
> implements BaseEngine<Q, P> {
  Future<T> transaction<T>(
    Future<T> Function(BaseEngine<Q, P> engine) action,
  );
}
~~~

The generator emits `TransactionalDorm<Q, P>` for the same model set as
`Dorm<Q, P>`. Its `transaction` callback receives a temporary `Dorm<Q, P>`
whose repositories use the active engine context. The callback can compose
repository reads, writes, relationships, and pages. `pull` and `pullAll` are
not available in that context and nested transactions are rejected.

`TransactionalDorm` requires `TransactionalEngine<Q, P>` statically. A
regular `BaseEngine<Q, P>` cannot be passed to its constructor without a
cast or type erasure. The in-memory, BLoC, MySQL, PostgreSQL, and SQLite engines currently implement
the capability.

## Synchronization capability

Synchronization is an optional capability layered above `BaseEngine`. A primary
engine must implement `ChangeTrackedEngine<Q, P>` and return a
`ChangeTrackedReference<Q, P>`. The reference executes a mutation and reports a
`MutationResult` containing both the ordinary operation result and an exact
`MutationChangeSet`.

A change set contains the operation kind, entity table name, ordered sequence,
operation id, affected encoded identities, and final serialized data where
applicable. This allows a replica to apply the result without executing the
primary callback or recomputing a primary filter.

The `dorm_sync` package composes these contracts through
`SynchronizedEngine<Q, P>`. Its target interfaces intentionally separate
capabilities:

- `SyncReadTarget` supports finite reads and streams;
- `SyncApplyTarget` applies materialized change sets;
- `SyncReadApplyTarget` combines read and apply behavior for replicas;
- `SyncMutationTarget` adds primary change-tracked mutations.

`EngineSyncTarget` adapts a change-tracked primary. `EngineReplicaTarget`
adapts a regular `BaseEngine` for read fallback and materialized delivery.
The composed engine is not a `TransactionalEngine`; replica delivery is
ordered and at-least-once, not a distributed transaction.

See [Synchronize database engines](synchronization.md) for the outbox,
fallback, identity, relationship, retry, and lifecycle semantics.
## Error contract

There is no common dORM exception class. Contract users can observe ordinary
Dart errors, engine SDK errors, database client errors, and stream errors.
Identity codec mismatches produce StateError in existing key operations;
explicit creation identities are validated against the entity schema and use
ArgumentError for incompatible values. Engines retain UnsupportedError for
automatic composite creation when the generated static contract is bypassed.
