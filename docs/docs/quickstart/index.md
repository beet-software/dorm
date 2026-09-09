# Build a small store

This section builds one small pure Dart store from an empty project. It starts
with the in-memory engine so you can reach a working repository without creating
a database, configuring credentials, or starting a server. In-memory is a fast
way to learn the generated API; it is not a recommendation that every
production application should use in-process storage.

The same model and repository surface can later be connected to a backend
engine. That is the main idea behind this path: learn the common operations
first, then choose the storage system and its capabilities for the application.

The modules use the same application throughout:

```text
installation
    -> annotated User, Profile, and Product models
    -> generated dORM and JSON code
    -> in-memory Engine and Dorm
    -> create and read a User
```

The first result uses `dorm_memory_database`, so no external database service
is needed. The generated repository shape is the same shape used when the
application later connects to MySQL, PostgreSQL, MongoDB, Firebase, Firestore,
HTTP, or SQLite. Backend-specific capabilities remain explicit when you move
to another engine.

Start with [Create the Dart project](installation.md), then follow the modules
in the sidebar order. Each module keeps the files and domain created by the
previous one.

After the first create/read result, continue the same store with:

- [carts and cart items](relations-and-cart.md);
- [reviews with multiple content types](reviews-and-polymorphism.md);
- [application input and live reads](forms-and-live-reads.md).
