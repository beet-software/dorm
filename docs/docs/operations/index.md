# Operations in a generated repository

The generated store model gives each entity a repository. The repository uses
the same operation vocabulary for every engine, while the selected engine
performs the storage-specific work.

A repository is the object you call to work with one kind of record. First
choose whether you want to create, read, change, or remove data; then use the
operation that matches that action.

## Choose an operation by the data transition

| Task | Operation | Main input or result |
| --- | --- | --- |
| Create a model | `put` | `Creation` → identified `Model` |
| Create several models | `putAll` | `List<Creation>` → models |
| Read one model | `peek` | Identity → `Future<Model?>` |
| Read a collection | `peekAll` | `Filter`/options → `Future<List<Model>>` |
| Read a page | `peekPage` | `Filter`/page request → `Page<Model>` |
| Observe one model | `pull` | Identity → `Stream<Model?>` |
| Observe a collection | `pullAll` | `Filter`/options → `Stream<List<Model>>` |
| Replace an identified model | `push` | Complete `Model` |
| Change or remove conditionally | `patch` | Identity and callback |
| Remove one model | `pop` | Identity |
| Remove several identities | `popKeys` | List of identities |
| Remove matching models | `popAll` | `Filter` |
| Remove every model | `purge` | No input |

## Open a repository

The generated accessor comes from the `as` value in the `@Model` declaration:

```dart
final Dorm<Query, OffsetPageRequest> dorm = Dorm(Engine());

final userRepository = dorm.users.repository;
final productRepository = dorm.products.repository;
```

`UserData` is create/update input, `User` is the identified model, and
`UserDependency` carries the relationship values needed to construct a user.
The [generated API reference](../quickstart/generating-models.md)
shows how these types are produced.

## Continue by task

- [Create records](creating.md) covers `put`, `putAll`, automatic identities,
  and explicit identities.
- [Read records](reading.md) covers `peek`, `peekAll`, `peekPage`, `pull`,
  and `pullAll`.
- [Update records](updating.md) covers `push`, `pushAll`, and `patch`.
- [Delete records](deleting.md) covers `pop`, `popKeys`, `popAll`, and
  `purge`.
- [Using filters](using-filters.md) covers conditions,
  ordering, limits, and offset pages.
- [Using synchronization](using-synchronization.md) composes a primary
  engine with replicas, fallback reads, and an outbox.

All of these pages reuse the store model and the engine setup introduced in the
learning path.
