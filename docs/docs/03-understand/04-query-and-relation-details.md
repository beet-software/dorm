# Query construction and relationship execution details

The task pages use `Filter`, generated query fields, and relation paths. Internally, those APIs are translated through query and relationship contracts that an engine implements.

## Move from `BaseFilter` to `BaseQuery`

`BaseFilter` stores a structured operation. Its `accept` method applies that operation to a backend-specific `BaseQuery`:

```text
Filter.value('ada', key: 'username')
        -> BaseFilter.accept(query)
        -> query.whereValue('username', 'ada')
        -> engine-specific Query
```

The framework provides filters for empty results, exact values, text prefixes, date units, and text/numeric/date ranges. Modifier filters add `limit` and `sort` by applying those operations to the query created by the wrapped filter.

An engine's `Query` implements the same methods for its storage technology. MySQL creates SQL text and parameter maps. Firebase calls Realtime Database query methods. BLoC evaluates its query representation against serialized in-memory values.

## Use generated query fields

`@QueryField` declares a persisted query value derived from other model fields:

```dart
@QueryField(
  name: '_q-username',
  referTo: [QueryToken(#username, QueryType.text)],
)
String get _qUsername;
```

The generated `User` computes `_qUsername` from `username` and writes `_q-username` into its serialized representation. The application then queries that generated key with `Filter.text`.

The review model uses a query field composed from `userId` and the normalized review type. Query fields and their normalization helpers are current generated behavior, but the author classifies this API as a legacy Firebase-oriented querying mechanism whose portable final form is not confirmed.

## Describe relation sources

Repositories implement `RelationSource`. A direct table-backed repository exposes:

- a model read interface (`peek`, `peekAll`, `pull`, `pullAll`);
- an `EntitySchema`;
- a `TableRelationPlan` containing schema, key encoding, and decoding behavior.

A composed source can expose a `CompositeRelationPlan` instead of a direct table schema. The engine can inspect this plan when it has a structural optimization, while callback/readable operations remain available for sources that cannot be planned that way.

## Resolve relation cardinality

The framework models relation cardinality through association types and generated path steps:

| Path operation | Result shape and missing-target behavior |
| --- | --- |
| to-one | `Join<Root, Target>`; parents without a target are omitted |
| to-one nullable | `Join<Root, Target?>`; parents remain with `null` |
| to-many | flattened `Join<Root, Target>` rows; parents without targets are omitted |
| to-many or empty | `Join<Root, List<Target>>`; parents remain with an empty list |
| many-to-many | middle model joined with a nullable pair `(Left?, Right?)` |

The generated store paths expose these semantics through names such as `product`, `productOrNull`, `items`, and `itemsOrEmpty`.

## Follow a generated relation path

Generated path getters append relation steps without performing the first database read:

```dart
final path = dorm.relations.users.carts.items.productOrNull;
final List<Join<User, Product?>> rows = await path.peekAll();
```

Each step stores a `RelationSpec` containing cardinality, source field, and target field. `peekAll` then loads the root source and resolves each step. Results are flattened to the root and terminal value rather than exposing intermediate join types.

`pullAll` uses the same path shape and yields the loaded result. Whether subsequent changes are emitted depends on the selected engine's stream implementation.

## Understand relation plans and fallbacks

The framework's relation layer supports two execution inputs:

1. a structured relation plan that an engine may batch or translate to a local join;
2. readable repository operations that can resolve the relationship through ordinary reads.

The MySQL engine checks for direct table plans and can use batched relationship reads. Its callback-based relationship tests use readable sources, which exercise the fallback form without requiring a live database server.

This is an execution boundary, not a second public model schema. The generated relation names and result shapes remain the application-facing contract.

## Keep result and error behavior separate

Relationship result shapes are defined by the cardinality operation. Errors can still originate from the source repository, identity conversion, query construction, serialization, or backend execution.

The framework does not wrap every relationship failure in one relationship-specific exception. A missing target is represented by omission or `null` according to the selected path; an invalid identity or backend failure is propagated as its corresponding Dart or engine error.
