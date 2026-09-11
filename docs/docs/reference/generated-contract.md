# Generated output contract

The generator turns annotated declarations into the types that connect an
application to the framework. This page records the generated relationships
and invariants; [Model anatomy](../model-anatomy/index.md) explains the pieces
step by step.

## Source and generated parts

For a source library such as <i>lib/models.dart</i>, the application declares:

~~~dart
part 'models.dorm.dart';
part 'models.g.dart';
~~~

The builder produces:

| File | Role |
| --- | --- |
| <i>*.dorm.dart</i> | dORM data/model types, fields, dependencies, entities, repositories, `Dorm`, and generated relation paths. |
| <i>*.g.dart</i> | JSON serialization helpers used by the generated types. |

Edit the annotated source and regenerate both parts after changing model
declarations, identities, fields, relationships, or serialization behavior.

## Generated type family

For an annotated _User, the generated family normally contains:

| Type | Contract |
| --- | --- |
| `UserData` | `Fields` supplied when creating or updating a value. |
| `User` | Identified model returned by reads and writes. |
| `UserDependency` | Related identities required to construct the model. |
| `UserFields` | Field metadata used by filters, ordering, and relationships. |
| `UserEntity` | Schema, identity, serialization, and conversion adapter. |
| `Dorm` | `Engine`-bound access object containing `DatabaseEntity` accessors. |
| `TransactionalDorm` | Transaction facade emitted for transaction-capable engine types. |

The exact member list belongs to the generated API documentation on pub.dev.
The table above describes the role of each type, not every available member.

## Values and identity

`Data` is the value shape supplied by application code. `Model` extends that
shape with the resolved identity. `Dependency` carries related identities and
is separate from the model's own primary key.

A simple-key entity accepts the generated creation type for its identity
strategy. A composite-key entity accepts explicit `CompositeKey` identities;
automatic creation is rejected by the generated static contract.

`EntitySchema`.primaryKeys preserves the declared order of composite key fields.
`PrimaryKeyCodec` is the only framework boundary responsible for encoding and
decoding an identity into those fields. Engines must use the final identity
provided by the entity and must not silently generate another identity for a
replica operation.

## `Entity` and repository connection

A generated `Entity` supplies:

- the `EntitySchema`;
- the `PrimaryKeyCodec`;
- conversion from creation data to a model;
- conversion between models and serialized data;
- identity extraction from a model.

A generated `DatabaseEntity` combines that entity with the selected `BaseEngine`.
Its repository delegates operations to the engine while keeping the generated
data and identity types visible to the analyzer.

`Dorm` groups these accessors. The model accessor name comes from the generated
model declaration and its configured as name.

## `Fields` and relationship paths

`UserFields` exposes `FieldSchema` values. Use those values in filters and
ordering instead of repeating storage column or path names.

Generated relationship paths use the declared forward and inverse names from
`ForeignField`. Cardinality-specific paths preserve the distinction between:

- a missing parent;
- a missing required related value;
- a nullable related value;
- an empty related collection;
- a populated related collection.

The generated path is a typed convenience over the framework's `RelationPath`
and `RelationSource` contracts. It does not change the selected engine's query
or stream capabilities.

## Transactional generation

When the engine type implements `TransactionalEngine<Q, P>`, the generated
library exposes `TransactionalDorm<Q, P>`. Its callback receives a temporary
`Dorm` bound to the active transaction context.

This facade is not generated as a promise that every engine supports
transactions. A regular `BaseEngine` cannot be passed to it without satisfying
the transactional capability, and streams are unavailable inside the
transaction callback.

## Generation boundary

Generated files are checked-in outputs in the repository examples, but they
remain derived artifacts. Do not edit them to fix a model. Change the
annotation, source model, or generator and regenerate.

See [Code generation problems](../troubleshooting/code-generation-problems.md)
when the builder fails, and [Framework contracts](framework-contracts.md) for
the contracts implemented by the generated types.
