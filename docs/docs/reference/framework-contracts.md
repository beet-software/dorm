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
| supportsAutomaticIdentity | bool get supportsAutomaticIdentity | Whether automatic creation is supported. |
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
rejected at compile time by the generated contract. `Creation.auto` requests
an engine-generated identity, while `Creation.explicit` supplies the final
identity. push persists an already identified model. patch receives the
current model or null; returning null removes the record.

The framework documentation describes popKeys, popAll, pushAll, and patch as
operations expected to be atomic, but the public API does not expose a general
transaction object. Engine behavior can differ.

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

### BaseFilter<Q>

A filter applies a condition or modifier through Q accept(Q query).
Factories cover empty, value, text, text-range, numeric-range, date, and
date-range filters. QueryOptions applies OrderBy, limit, and offset to a
query. PageRequest describes an offset or cursor page, and Page contains the
returned items and continuation metadata. Current engine contracts use
`OffsetPageRequest` as `P`. A `CursorPageRequest` passed through a statically
typed current engine repository is rejected by the analyzer.

ValueFilter accepts either a string key or a FieldSchema; the current
constructor requires exactly one of those addressing forms.

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

## Error contract

There is no common dORM exception class. Contract users can observe ordinary
Dart errors, engine SDK errors, database client errors, and stream errors.
Identity codec mismatches produce StateError in existing key operations;
explicit creation identities are validated against the entity schema and use
ArgumentError for incompatible values. Engines retain UnsupportedError for
automatic composite creation when the generated static contract is bypassed.
