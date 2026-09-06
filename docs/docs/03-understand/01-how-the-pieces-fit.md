# How a dORM operation moves through the system

After using generated repositories, filters, and relation paths, it helps to see the boundaries between those pieces. dORM separates the model description, the generated entity metadata, the repository operations, and the engine implementation.

## Start at the generated database object

Application code starts with a generated `Dorm` and reaches an entity repository through an accessor:

```dart
final Dorm dorm = Dorm(Engine());
final Repository<UserData, User, String, Query> users =
    dorm.users.repository;
```

The `as: #users` value in the annotated model produces `dorm.users`. The generated accessor returns a `DatabaseEntity`; `.repository` exposes CRUD, read, filter, and relationship operations for that entity.

The application normally does not construct a concrete backend `Reference` or `Relationship` directly. It passes an engine to `Dorm`, and the generated `DatabaseEntity` asks that engine for the backend implementations.

## Follow a create operation

The create path has these observable stages:

```text
UserData + UserDependency
        -> Repository.put
        -> BaseReference.put
        -> Entity.fromData
        -> identified User model
        -> engine storage representation
        -> User returned to the caller
```

`UserData` contains field values. `UserDependency` contains creation dependencies. The generated `UserEntity.fromData` combines those values with the identity supplied by the engine and constructs `User`.

The engine then serializes the model through the entity mapping and stores the resulting representation. BLoC stores model-derived values in memory, Firebase writes a Firebase map, MySQL writes SQL values through its connection, and MongoDB writes document values through its collection API.

The exact identity generation and storage operation belong to the selected engine. The repository method and generated entity conversion are common framework boundaries.

## Follow a read operation

For `peek`, the path is:

```text
repository.peek(id)
        -> BaseReference.peek(entity, id)
        -> backend read
        -> Entity.fromJson(id, data)
        -> User? returned to the caller
```

If the backend has no record for the identity, the result is `null`. When a record exists, `Entity.fromJson` receives the identity separately from the stored data map and creates the generated model.

For `peekAll`, the repository also passes a `BaseFilter`. The engine turns that filter into its query representation or evaluates it against its in-memory representation before calling `fromJson` for each result.

## Understand the generated entity boundary

The generated `UserEntity` implements the framework `Entity<UserData, User, String>` contract. It supplies:

| Entity responsibility | Generated member or value |
| --- | --- |
| Persisted schema | `schema` and `EntitySchema` |
| Identity conversion | `primaryKeyCodec` and `identify` |
| Create conversion | `fromData` |
| Read conversion | `fromJson` |
| Write serialization | `toJson` |
| Existing-model update | `convert` |

The entity is the engine-independent mapping object. It knows the model's table name, field names, primary-key fields, and generated Dart conversions. It does not open a database connection.

## See where queries and relationships meet the engine

The engine implements three backend-facing contracts:

- `BaseReference<Q>` performs CRUD and read operations;
- `BaseQuery<Q>` receives filter operations such as value, text, date, range, limit, and sort;
- `BaseRelationship<Q>` resolves relationship associations.

`BaseEngine<Q>` creates the reference and relationship implementations. `DatabaseEntity` keeps those implementations and passes them into each repository. A repository therefore combines generated entity metadata with the engine's reference and relationship behavior.

For a generated relationship path, the path starts with a repository and adds `RelationSpec` steps. The first read happens when `peekAll` or `pullAll` is called. An engine may use the path's relation plan for a direct table source or fall back to readable repository operations.

## Distinguish observed behavior from architectural interpretation

### Observed behavior

- Generated `Dorm` receives a `BaseEngine`.
- `DatabaseEntity` requests a `BaseReference` and `BaseRelationship` from that engine.
- `Repository` delegates operations to the reference and exposes the entity schema and relation plan.
- Generated entities implement schema, identity, conversion, and serialization methods.
- Concrete engines implement the framework contracts separately.

### Reasonable architectural interpretation

The framework is the common application boundary. Generated entities are the mapping boundary between annotated Dart models and engine-neutral schema metadata. Engine packages are adapters that translate those contracts into in-memory, Firebase, SQL, or MongoDB operations.

### Not determined

- Whether every internal engine operation is intended to remain inaccessible to application code.
- Whether all engines must use the same internal execution strategy for a relation plan.
- Whether the current generated class layout is the complete long-term architecture.

The concrete setup for each available engine is shown in [Choose a dORM engine](../03-apply/01-choose-an-engine.md).
