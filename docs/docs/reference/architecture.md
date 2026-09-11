# Architecture and boundaries

This page explains how an application operation travels through dORM. It is
for readers who need to reason about generated code, engine boundaries, or
backend-specific behavior without reading every implementation.

## The execution path

~~~text
annotations
    |
    v
dorm_generator + build_runner
    |
    v
Data / Model / Dependency / Fields / Entity / Repository / Dorm
    |
    v
generated repository operation
    |
    v
Entity + EntitySchema + FieldSchema
    |
    v
BaseEngine
    |
    +--> BaseReference + BaseQuery + BaseRelationship
    |
    v
concrete engine
    |
    v
memory store, SQL database, Firebase, MongoDB, HTTP API, or SQLite
~~~

The generated layer keeps application-facing types consistent. The engine
decides how those operations are represented and executed by its backend.

## Responsibilities by layer

| Layer | Responsibility |
| --- | --- |
| Annotation | Declares model shape, fields, identities, relationships, and generated metadata. |
| Generator | Converts declarations into source code during build time. |
| Data | Carries fields supplied when creating or updating a value. |
| Model | Adds the resolved identity to a data value. |
| Dependency | Carries the related identities required to construct a model. |
| Fields | Exposes generated field metadata for filters, ordering, and relationship paths. |
| Entity | Converts data and identities and exposes the engine-neutral schema. |
| EntitySchema | Describes stored fields, primary keys, foreign keys, and derived metadata. |
| Repository | Provides the application operation surface for one entity. |
| Engine | Connects framework contracts to one storage technology. |
| Backend | Stores, queries, streams, or serves the serialized values. |

Dorm is the generated object that groups the DatabaseEntity accessors. A
DatabaseEntity combines an Entity with an engine and exposes its repository
and relationships.

## Build-time generation, runtime execution

dORM uses build-time generation. The application edits annotated source and
runs build_runner; it does not discover model metadata through runtime
reflection.

The generated files are part of the application source graph:

- *.dorm.dart contains dORM types and metadata;
- *.g.dart contains JSON serialization helpers.

The generated code is an implementation of the declared model contract. It
does not replace the annotated source as the place where models are changed.

## Schema metadata is the portable boundary

EntitySchema, FieldSchema, foreign-key metadata, and primary-key codecs
describe the stored shape without choosing SQL, Firebase paths, MongoDB
selectors, HTTP parameters, or another provider format.

The application-facing filter API receives field metadata. The engine resolves
that metadata into its own query representation. This keeps storage names
centralized and prevents application code from repeating backend-specific
column or path strings.

The same boundary lets a relationship expose a field or entity schema to
portable relationship logic while allowing an engine to use a native
relationship plan when it can.

## Query and relationship translation

The framework represents filters and page requests structurally. A concrete
engine translates them to an in-memory predicate, a Firebase query, a SQL
statement, a MongoDB selector, HTTP parameters, or another supported form.

A relationship has the same two levels:

1. the portable relationship contract defines result shape and nullability;
2. the engine may optimize a direct source, such as a SQL join or a batched
   lookup;
3. the readable-operation fallback remains the semantic baseline.

Therefore the common API does not promise a fixed number of backend calls or
the same query plan across engines.

## Optional capabilities

The common BaseEngine contract is deliberately small. Additional behavior is
advertised through separate capabilities:

- TransactionalEngine exposes the portable transaction facade;
- ChangeTrackedEngine exposes exact mutation change sets for synchronization;
- ErrorAwareEngine exposes portable provider-error classification.

An engine that does not implement a capability remains usable through the
common surface, but the corresponding generated or composed feature is not
available.

## Reads and writes

A finite read follows this conceptual path:

1. the repository validates and delegates the operation;
2. the entity resolves fields, identity values, and serialized data;
3. the engine builds and executes its query;
4. the entity reconstructs the model or collection result.

A write follows the same path in the opposite direction:

1. the creation or identified model supplies values;
2. the entity resolves the final identity strategy;
3. the engine persists the serialized representation;
4. the repository returns the model or operation result.

A primary-to-replica synchronization wrapper adds a separate delivery path
after the primary mutation. It does not turn the backend operation into a
distributed transaction.

## Boundary rules

- Application code should import package barrels, not lib/src paths.
- Generated files should be regenerated, not manually edited.
- Engine implementations may use provider APIs internally; those APIs are not
  automatically part of the dORM contract.
- A behavior shared by the framework must not depend on one provider's error,
  query, identity, or transaction model.
- A backend-specific optimization must preserve the framework result contract
  before it is documented as a capability.

See [Public surface](public-surface.md), [Framework contracts](framework-contracts.md),
and [Implement a custom engine](../development/custom-engine.md).