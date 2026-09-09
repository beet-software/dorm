# dORM glossary

This page gives short lookup definitions. The linked pages contain the
operational details.

## Model and schema terms

| Term | Meaning |
| --- | --- |
| Data | Generated or annotated field-value shape used as input to create/update a model. |
| Model | Identified value returned by repository reads and writes. The word also names the Model annotation and appears as a generic type parameter. |
| Field | Annotation and schema concept for a stored scalar or value field. |
| ForeignField | Field containing a related model identity and relationship metadata. |
| ModelField | Field containing an embedded Model or Data value. |
| DerivedField | Annotation on a static callback whose generated result is stored and exposed as a queryable field. |
| DerivedFieldSchema | Metadata for a generated derived field, including its path and storage root. |
| DerivedTransformations | Helper passed to derived callbacks for text, enum, date, and date-time normalization. |
| PolymorphicField | Field with payload data and a discriminator/pivot value. |
| EntitySchema | Engine-neutral description of an entity's fields, keys, and foreign keys. |
| FieldSchema | Engine-neutral description of one stored field. |

See [Define users, profiles, and products](../quickstart/declaring-models.md),
[Annotations](../annotations/index.md), and [Generated API](generated-api.md).

## Identity terms

| Term | Meaning |
| --- | --- |
| Identity / ID | Value used to address one model. |
| Primary key | One or more schema fields used to encode an identity. |
| Generated identity | Primary-key value supplied by an engine or generated model path. |
| Existing identity | Primary-key field already declared by the annotated class. |
| Composite key | Identity represented by an ordered set of values. |
| CompositeKey | Framework value object holding composite identity values. |
| PrimaryKeyCodec | Converts an identity to key-field values and decodes key-field values back to an identity. |
| Dependency | Values supplied with Data when a model is created. Strong dependencies have no related IDs; weak dependencies contain related IDs. |
| Strong dependency | Dependency created without foreign IDs. |
| Weak dependency | Dependency carrying IDs of related strong entities. |

See [@Model](../annotations/model.md), [Generated Dependency](../model-anatomy/dependency.md),
and [Create records](../build-the-store/creating.md).

## Data-access terms

| Term | Meaning |
| --- | --- |
| Engine | Concrete runtime adapter that implements framework contracts for one storage technology. |
| BaseEngine | Framework contract that creates a BaseReference and BaseRelationship for a query type. |
| Reference | Storage operation contract. BaseReference is the framework type; each engine has its own concrete implementation. |
| Repository | Application-facing object that delegates CRUD, filtering, and stream operations to a reference. |
| Query | Engine-specific query value implementing BaseQuery. |
| Filter | BaseFilter value that applies a condition or modifier to a Query. |
| Filter capability | Optional query interface that makes an additional filter family available to a concrete engine query. |
| ComparisonQuery | Optional capability for scalar comparisons, set membership, and null checks. |
| LogicalQuery | Optional capability for `allOf` and `anyOf` filter composition. |
| NegationQuery | Optional capability for negating one filter with `not`. |
| CollectionQuery | Optional capability for `contains` and `containsAny` on persisted collections. |
| FilterExpression | Framework representation of a filter's resolved field name, values, and composition structure. |
| `allOf` | Filter composition requiring every child filter to match; an empty list is the empty filter. |
| `anyOf` | Filter composition requiring at least one child filter to match; an empty list is invalid. |
| `not` | Filter composition that negates one child filter when the query supports `NegationQuery`. |
| `contains` | Collection-membership filter; it does not mean text substring search. |
| RelationSource | Readable source used by relationship associations. |
| RelationPlan | Metadata describing how an association source can be read and decoded. |
| RelationPath | Lazy generated chain of relationship steps. |
| RelationSpec | Metadata for one RelationPath step. |
| Association | Relationship read contract that returns Join values. |
| Join | Typed pair containing a source model and a related result. |
| Cardinality | Whether a relationship step produces one or many results; optional forms also distinguish null and empty-list behavior. |

See [Model anatomy](../model-anatomy/index.md) and
[Framework contracts](framework-contracts.md).

## Operation terms

| Operation | Meaning |
| --- | --- |
| peek | One-shot read by identity; returns a model or null. |
| pull | Stream read by identity. |
| peekAll | One-shot filtered collection read. |
| pullAll | Stream filtered collection read. |
| peekAllKeys | One-shot read of stored identities. |
| put | Creates and persists a model from Data and Dependency; identity creation is part of the operation. |
| putAll | Batch form of put. |
| push | Persists an already identified Model. |
| pushAll | Batch form of push. |
| patch | Reads a model, passes it to a callback, and persists the callback result; null removes the record. |
| pop | Removes one identity. |
| popKeys | Removes selected identities. |
| popAll | Removes records matching a filter. |
| purge | Removes all records for an entity. |

See [Operations in a generated repository](../build-the-store/overview.md).

## Generation terms

| Term | Meaning |
| --- | --- |
| Annotation | Metadata on a Dart class or getter consumed by the generator. |
| Builder | build_runner integration that invokes the ORM generator. |
| OrmGenerator | Generator implementation that writes the dORM part file. |
| Dorm | Generated class that receives an engine and exposes DatabaseEntity accessors. |
| DatabaseEntity | Framework wrapper combining an Entity with an engine and exposing a Repository. |
| .dorm.dart | Generated dORM part file. |
| .g.dart | JSON serialization part file produced by json_serializable. |
| Relation accessor | Generated getter that starts or continues a relationship path. |

See [Generate the store API](../quickstart/generating-models.md).

## Engine-specific terms

| Term | Meaning |
| --- | --- |
| BLoC engine | In-process engine whose state is held by an Engine instance and exposed through BLoC/Cubit-backed streams. |
| FirebaseInstance | Firebase dependency provider used to construct the Firebase engine. |
| Firestore engine | Flutter engine that maps dORM repositories to Cloud Firestore collections and documents. |
| parentPath | Optional Firestore document path below which entity collections are stored. |
| Document ID | The simple String identity used by the Firestore engine, taken from `DocumentReference.id`. |
| WriteBatch | Firestore batch used internally for supported multi-document writes. |
| OfflineMode | Firebase setting with include and exclude modes for local/remote event handling. |
| MySQL Query | Query implementation that stores SQL text and named parameters. |
| Relation plan | In MySQL, direct table plans can enable grouped relationship reads; generic sources use readable operations. |
| PostgreSQL engine | SQL engine that accepts a `postgres` `SessionExecutor` and maps framework operations to PostgreSQL statements. |
| SessionExecutor | `postgres` driver abstraction accepted by the PostgreSQL engine; an opened `Connection` or `Pool` implements it. |
| MongoDB engine | Engine that accepts an opened `mongo_dart` `Db` and maps framework operations to MongoDB collection operations. |
| MongoDB selector | Map passed to `mongo_dart` collection reads and writes to match documents. The MongoDB `Query` builds selectors from framework filters. |
| MongoDB `Db` | `mongo_dart` database object supplied to `dorm_mongo_database.Engine`; opening and closing it remain application operations. |

See [Engine capability reference](engine-capabilities.md).

## Terms with recorded ambiguity

### Model

Model can mean the Model annotation, the annotated class, the generated
identified class, or a generic type parameter. The surrounding signature
determines which meaning applies.

### Reference

BaseReference is the framework contract. Reference is also the concrete class
name used inside multiple engines. Those concrete classes are not all exported
from the engine barrels.

### put and push

put receives Data and Dependency and participates in identity creation. push
receives an identified Model. The verbs do not map exactly to generic
create/insert/update terminology.

### pull and continuous reading

The common API names pull as a stream operation. BLoC and Firebase currently
emit later state/value events; MySQL currently emits an initial read only.

### Cardinality orientation

The names left, right, many-to-one, and the generic parameters of relationship
aliases are not sufficient to infer every direction. Read the concrete
signature and result shape.

### Transaction

A scoped execution of multiple repository operations with commit or rollback
semantics. `TransactionalDorm.transaction` exposes this portable capability
for Memory, BLoC, MySQL, PostgreSQL, and SQLite. The callback receives a temporary
`Dorm`; streams and nested transactions are not available in that context.
Backend transactions used internally by individual operations are a separate
scope.
