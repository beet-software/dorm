# Generated Dorm

`Dorm` is the generated application-facing facade. It receives an engine and
exposes one generated entity accessor for each annotated `@Model`.

```dart
final dorm = Dorm(engine);

final user = await dorm.users.repository.peek(userId);
final product = await dorm.products.repository.peek(productId);
```

The generated class carries the engine's query and pagination types:

```dart
class Dorm<Q extends BaseQuery<Q>, P extends PageRequest> {
  const Dorm(this._engine);
}
```

In application code, type inference normally supplies `Q` and `P` from the
engine. The generated accessors return `DatabaseEntity` values, and the
repository is available through `.repository`.

For engines that implement the optional `TransactionalEngine` capability, the
same generated library also contains `TransactionalDorm<Q, P>`. It extends
`Dorm<Q, P>` and creates a temporary `Dorm` for the transaction callback.

`Dorm` also exposes generated relationship roots through `relations` when the
source models contain relationship metadata. See [Relationship paths](relations.md).

The engine instance remains the boundary for backend resources. `Dorm` does
not create or close an application-owned database connection, pool, client, or
database object.

See [Creating the engine](../quickstart/creating-the-engine.md) for setup and
[Generated output contract](../reference/generated-contract.md) for generated class signatures.
