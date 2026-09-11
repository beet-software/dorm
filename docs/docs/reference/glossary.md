# dORM glossary

Use this page for terms that appear across the dORM guides. The linked pages are
the canonical source for each contract.

## Model and schema terms

| Term | Meaning |
| --- | --- |
| Data | Field-value shape used as creation or update input. |
| Model | Identified value returned by repository reads and writes. |
| Field | Annotation and schema concept for one stored value. |
| ForeignField | Field containing a related identity and relationship metadata. |
| ModelField | Field containing an embedded Model or Data value. |
| DerivedField | Annotation whose generated callback produces a queryable derived value. |
| EntitySchema | Engine-neutral description of fields, keys, foreign keys, and derived metadata. |
| FieldSchema | Engine-neutral metadata for one stored field. |
| Dependency | Values supplied with Data when constructing a Model. |
| Primary key | One field or an ordered set of fields used to address a model. |
| CompositeKey | Framework value containing the ordered values of a composite identity. |
| PrimaryKeyCodec | Contract that encodes and decodes an identity through primary-key fields. |

See [Model anatomy](../model-anatomy/index.md), [Annotations](../annotations/index.md),
and [Generated output contract](generated-contract.md).

## Data-access terms

| Term | Meaning |
| --- | --- |
| Engine | Concrete runtime adapter for one storage technology. |
| BaseEngine | Framework contract that creates a reference and relationship implementation. |
| Reference | Storage operation boundary used by a repository. |
| Repository | Application-facing operations for one entity. |
| Query | Engine-specific value implementing BaseQuery. |
| Filter | Structured condition applied to a query. |
| FilterExpression | Resolved, engine-neutral representation of a filter. |
| Filter capability | Optional query interface that enables an additional filter family. |
| RelationSource | Readable source used by a relationship association. |
| RelationPlan | Optional metadata describing an optimized relationship source. |
| RelationPath | Lazy generated chain of relationship steps. |
| RelationSpec | Metadata for one relationship path step. |
| Association | Relationship read contract that returns Join values. |
| Join | Typed value containing a source model and related result. |
| Cardinality | Whether a relationship returns one or many results and whether null or empty results are retained. |

See [Framework contracts](framework-contracts.md) and
[Engine and platform support](engine-support.md).

## Repository operations

| Operation | Meaning |
| --- | --- |
| peek | One-shot read by identity; returns a model or null. |
| pull | Stream read by identity. |
| peekAll | One-shot filtered collection read. |
| pullAll | Stream filtered collection read. |
| peekAllKeys | One-shot read of stored identities. |
| put | Creates and persists a model through a creation request. |
| putAll | Batch form of put. |
| push | Persists an identified Model. |
| pushAll | Batch form of push. |
| patch | Updates, creates, or removes according to a callback result. |
| pop | Removes one identity. |
| popKeys | Removes selected identities. |
| popAll | Removes identities selected by a filter. |
| purge | Removes all records for an entity. |

See [Operations in a generated repository](../build-the-store/overview.md).

## Capability terms

| Term | Meaning |
| --- | --- |
| TransactionalEngine | Optional capability for a callback-scoped local transaction. |
| ChangeTrackedEngine | Optional capability that reports exact mutation change sets. |
| ErrorAwareEngine | Optional capability that maps provider errors to the portable error contract. |
| DormDatabaseException | Portable exception containing category, retryability, and provider diagnostics. |
| MutationChangeSet | Materialized description of one primary mutation for synchronization. |
| SyncOutbox | Store for pending replica deliveries. |
| SyncOperationResolver | Explicit registry that rebuilds typed synchronization appliers after restart. |

See [Portable errors](errors.md) and [Synchronization protocol](synchronization.md).

## Generation terms

| Term | Meaning |
| --- | --- |
| Annotation | Metadata consumed by the generator. |
| Builder | build_runner integration that invokes the generator. |
| Dorm | Generated class that receives an engine and exposes DatabaseEntity accessors. |
| DatabaseEntity | Framework wrapper combining an Entity with an engine and repository. |
| Generated part | A *.dorm.dart or *.g.dart file produced from source declarations. |
| Relation accessor | Generated getter that starts or continues a relationship path. |

See [Generated output contract](generated-contract.md) and
[Generate the store API](../quickstart/generating-models.md).

## Engine terms

| Term | Meaning |
| --- | --- |
| FirebaseInstance | Firebase dependency provider used by the Firebase engine. |
| OfflineMode | Firebase setting for local/remote event handling. |
| SessionExecutor | postgres driver abstraction accepted by the PostgreSQL engine. |
| Relation plan | Optional direct-source optimization used by some SQL and document engines. |
| Document ID | Simple String identity used by the Firestore engine. |
| Initial-read stream | Stream implementation that emits an initial result without later external-change events. |

See [Engine and platform support](engine-support.md).