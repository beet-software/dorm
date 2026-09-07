# Build a small store

This section builds one small pure Dart store from an empty project. The
modules use the same application throughout:

```text
installation
    -> annotated User, Profile, and Product models
    -> generated dORM and JSON code
    -> memory Engine and Dorm
    -> create and read a User
```

The first result uses `dorm_memory_database`, so no external database service
is needed. The generated repository shape is the same shape used when the
application later connects to MySQL, PostgreSQL, MongoDB, Firebase, or HTTP.

Start with [Create the Dart project](installation.md), then follow the modules
in the sidebar order. Each module keeps the files and domain created by the
previous one.

After the first create/read result, continue the same store with:

- [carts and cart items](relations-and-cart.md);
- [reviews with multiple content types](reviews-and-polymorphism.md);
- [application input and live reads](forms-and-live-reads.md).
