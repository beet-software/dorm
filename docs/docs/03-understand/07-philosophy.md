# Documented principles of dORM

These principles summarize statements explicitly confirmed by the author and repeated across related decisions. They describe the expectations of the current API; they do not turn limitations or accidental behavior into design principles.

## Generated models are the main integration surface

In practice, users describe models with annotations and consume generated data classes, models, dependencies, entities, fields, relation accessors, and `Dorm` accessors.

The generator supplies schema metadata, conversions, relationship structures, and repetitive ORM code. Application code normally edits annotated source and uses the generated API rather than manually assembling entities and references.

This implies two trade-offs:

- generated names and generated structure become compatibility concerns;
- the application uses several generated types, including `Data`, `Model`, and `Dependency`, instead of one universal type.

The principle is demonstrated by the generated model workflow and by the confirmed public status of generated names.

## Fundamental operations use simple, discoverable verbs

The API uses a small vocabulary:

| Verb | Meaning in the current model |
| --- | --- |
| `peek` | Read a current value once |
| `pull` | Observe a value through a stream |
| `put` | Create from `Data` and `Dependency` |
| `push` | Write an identified `Model` |

The author states that fundamental concepts should have one consistent verb and that names should help editor autocomplete discover the API.

The consequence is a distinction between operations instead of one generic persistence method. Users must learn the difference between `put` and `push`, but the operation name signals the expected input shape.

## The framework is the portable application boundary

Generated `Dorm` receives an engine. The engine supplies reference and relationship implementations, while the framework supplies the common contracts used by generated repositories and engine adapters.

Ordinary application code therefore depends on persistence concepts such as repositories, filters, and relation paths. Concrete backend internals are an exception for cases that deliberately require backend-specific behavior.

The trade-off is that the common boundary does not expose every database capability. Concrete `Reference` and `Relationship` implementations under engine internals are not the normal construction API.

## Portability applies to semantics, not every capability

dORM aims to preserve common model, filter, and relationship semantics across engines. Generated relationship-path result shapes are confirmed as cross-implementation contracts. Filter semantics are intended to be portable, although the current filter API is not confirmed as fully stable for every cross-engine case.

Realtime observation is different. `pull` and `pullAll` are best-effort because a common method cannot make every storage backend emit live changes. MySQL's current initial-read behavior is therefore a capability difference, not a different relationship result-shape contract.

This principle is useful when reading the engine matrix: shared method names describe the common semantic vocabulary, while backend capabilities remain explicit.

## Relationship metadata describes ORM meaning separately from storage constraints

Annotations and generated metadata describe relation names, cardinality, foreign fields, and executable relation paths. `ForeignField.unique` is a cardinality marker; it is not a physical database uniqueness constraint.

Relation plans can provide an optimization path, while readable or callback-based sources provide a fallback. Generated path result shapes remain the application-facing contract regardless of which execution path an engine uses.

The trade-off is that ORM relationship meaning can be represented independently of automatic DDL constraints, and engines can choose different internal execution strategies.

## Convention and generation are preferred over manual configuration

The preferred model workflow asks the user to declare the information needed to describe a model or override a name. The generator infers or creates the remaining schema, conversion, relation, and accessor structures.

This keeps ordinary source concise but makes generator behavior and generated names part of the effective public surface. A model that does not fit the supported annotation and inference forms may require a different boundary or backend-specific handling.

## Generated names are stable API names

Names such as `UserData`, `User`, `UserDependency`, `UserFields`, `UserEntity`, relation accessors, and `Dorm.users` are not treated as disposable output details.

The practical expectation is that application code may refer to these generated names. Generator naming changes can therefore be API changes even when the annotated source looks similar.

Generated normalization helpers with dollar-prefixed names are a separate category: they are emitted for generated querying code and are not confirmed stable extension utilities.

## The common abstraction is focused and permits an escape hatch

The author describes a common abstraction that handles ordinary cases while allowing exceptional cases to leave the common layer. This is a scope principle, not a classification of every current omission.

In practice, common model, repository, filter, and relationship operations use framework contracts. A backend-specific operation can remain outside those contracts when the application deliberately depends on a concrete engine.

The trade-off is a smaller portable API instead of an abstraction that exposes the union of every database feature. Transactions, pagination, composite-key restrictions, querying limitations, and polymorphism keep their individual current statuses rather than being reclassified as intentional exclusions.
