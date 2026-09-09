# Generated Repository

Each generated entity exposes a repository. The repository combines the
generated entity mapping with the reference and relationship implementations
created by the selected engine.

```dart
final repository = dorm.users.repository;

final User? user = await repository.peek(userId);
final List<User> users = await repository.peekAll();
```

The operation vocabulary includes:

| Operation | Input or result |
| --- | --- |
| `put` / `putAll` | `Creation` values become identified models. |
| `peek` / `peekAll` | One model or a collection is read once. |
| `peekPage` | An offset page is read with a page request. |
| `pull` / `pullAll` | One model or a collection is exposed as a stream. |
| `push` / `pushAll` | Identified models are persisted. |
| `patch` | A model is read, changed by a callback, and persisted or removed. |
| `pop` / `popKeys` / `popAll` / `purge` | Models are removed. |

The repository delegates backend work. It does not directly build SQL,
MongoDB selectors, Firebase queries, or HTTP requests. Those operations belong
to the engine's reference and query implementations.

Use [Apply an operation](../build-the-store/overview.md) for task-oriented
operation details and [Public API](../reference/public-api.md) for signatures.
