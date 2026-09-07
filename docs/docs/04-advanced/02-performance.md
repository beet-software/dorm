# Understand observable performance behavior

This page describes work visible in the current implementation. It does not assign speed or efficiency claims to an operation, and the project contains no benchmark results or performance target.

## Separate measurements from code-based observations

No benchmark suite, timing assertion, workload definition, memory measurement, or published throughput/latency result is present in the current project.

The observations below come from the operation paths and tests. Complexity statements describe the loops, maps, serializations, and backend calls visible in those paths; they are not measured results.

## Framework work common to the engines

Repository methods delegate through `BaseReference` and pass generated `Entity` metadata to the engine. Filter modifiers build query values before the reference or relationship operation executes.

Writes and reads cross the generated mapping boundary:

```text
model/data
  -> entity serialization or identity encoding
  -> engine query or storage operation
  -> backend result
  -> entity deserialization
  -> model/list/stream result
```

Generated JSON methods allocate maps for serialized values. Reads allocate model objects and result lists as they materialize backend values.

Relationship paths are lazy while they are being assembled. The first database or storage read occurs at `peekAll` or `pullAll`; each path step can then load related values and create intermediate join/list structures.

## BLoC engine: in-memory maps and state copies

The BLoC engine stores each entity table in a `Map<I, Model>` inside its entity state.

Observed direct operations:

- `peek` looks up one identity in the table map;
- `peekAllKeys` copies the map keys into a list;
- `peekAll` copies the current model values, serializes them for filter/query evaluation, and reconstructs selected models;
- mutations copy the complete table map before applying the mutation and emitting a new state;
- `putAll` and `pushAll` prepare multiple models and emit one table-state mutation;
- `purge` clears the entity table in the copied state.

The map copy performed by a mutation is proportional to the number of rows in that table in the current implementation, including when the requested mutation addresses one identity. This is a code-based allocation observation, not a measured timing result.

`pull(id)` maps table-state events to one model lookup. `pullAll(filter)` re-runs serialization, filter evaluation, and model reconstruction when a table-state event arrives. No incremental filtered-result structure is present in the reference implementation.

The in-memory table map is storage state. The code does not expose a separate query-result cache, and filtered result lists are rebuilt for reads and stream events.

## Firebase engine: remote reads, updates, and snapshots

The Firebase reference performs these backend operations:

| Repository operation | Firebase work currently visible |
| --- | --- |
| `peek` | One `.get()` on the entity child, then model deserialization |
| `peekAll` | One filtered query `.get()`, then snapshot-child map/list materialization |
| `peekAllKeys` | One REST request with `shallow=true`, then key decoding |
| `push` | One `update` through `pushAll` |
| `pushAll` | One `update` containing all serialized models |
| `put` | One-model form of `putAll` |
| `putAll` | Allocates push keys/models, then one `update` |
| `pop` | One child `remove` |
| `popKeys` | One `update` mapping selected keys to `null` |
| `popAll` | One `peekAll`, followed by `popKeys` |
| `patch` | One Firebase `runTransaction` on the model child |
| `purge` | One `remove` on the entity reference |

`pull` and `pullAll` subscribe to Firebase value events and reconstruct models from snapshots. `OfflineMode.include` adds the `OfflineAdapter`, which switches between Firebase value events while connected and child-added events while disconnected. No dORM-owned result cache, expiry policy, or invalidation mechanism is present.

## MySQL engine: SQL statements and transaction scope

The MySQL reference builds SQL text and passes named parameter maps to `MySQLConnection.execute`.

The current direct operation paths are:

- `peek`: one `SELECT *` with a primary-key predicate;
- `peekAll`: one `SELECT *` after applying the filter query;
- `peekAllKeys`: one `SELECT` containing only key columns;
- `pop`: one `DELETE` with a primary-key predicate;
- `popAll`: one filtered `DELETE`;
- `popKeys`: one `DELETE` using `IN` for simple keys or row-value tuples for composite keys;
- `purge`: one unfiltered `DELETE`;
- `push`: one `REPLACE` statement;
- `put`: one UUID generation, model construction, and `INSERT`.

The number of driver-level network exchanges inside `mysql_client` is not measured by the project.

`pushAll` opens one transaction but executes one `REPLACE` per model. `putAll` opens one transaction but executes one `INSERT` per data value. `patch` opens one transaction, reads the current model, invokes the callback, and then performs either a delete or replacement write.

SQL construction allocates buffers, parameter maps, column/key lists, serialized model maps, and materialized model lists. Composite identities add key encoding and multiple SQL parameter values.

MySQL `pull` and `pullAll` currently perform an initial read and emit that result once. They do not maintain a live database subscription or a dORM relationship-result cache.

## Relationships and additional reads

Generic relationship implementations read a source and then resolve related sources:

| Relationship form | Generic collection work |
| --- | --- |
| One-to-one | Root collection, then a target read for each root model |
| One-to-many | Root collection, then a target collection read for each root model |
| Many-to-one | Group source models by related key, then read each distinct related key |
| Many-to-many | Read middle models, then read distinct left and right identities |

Nested `RelationPath` segments repeat this pattern for each path step. Each step creates lists, maps, identifiers, and `Join` objects for the intermediate/result shape.

The MySQL relationship implementation can use direct `TableRelationPlan` metadata for grouped reads:

- one-to-one can read the right-side IDs in one grouped query;
- one-to-many can read rows by a common foreign-key field in one grouped query;
- many-to-one can read distinct related IDs in one grouped query;
- many-to-many can group left and right ID reads.

When the plan is unavailable or a callback cannot be recognized structurally, the implementation falls back to readable operations. The fallback can issue one read per parent or key, often submitted with `Future.wait`.

These are observed execution paths. The relation-plan API is an optimization hook and does not provide a measured performance guarantee.

## Streams, batching, and reuse

The current stream behavior differs by engine:

| Engine | Current stream work |
| --- | --- |
| BLoC | State events are transformed into model or collection results; filtered collections are rematerialized per event |
| Firebase | Firebase snapshots are transformed into model or collection results; offline mode changes the underlying event source |
| MySQL | Initial read is added to a stream; no repeated database read is maintained |

Batch methods also differ internally:

- BLoC batches multiple models into one in-memory state emission;
- Firebase batches multiple serialized values into one `update` call for `putAll`/`pushAll`;
- MySQL uses one transaction for `putAll`/`pushAll` but one SQL execution per model.

The framework does not expose a general query cache, relationship cache,
prepared-statement cache, or application-controlled transaction API. Offset
pages are exposed by the common read surface; current engine types accept
`OffsetPageRequest`, while cursor requests are rejected by the typed surface.
Driver-level connection behavior is outside the code described
here and is `UNKNOWN`.

## Current performance boundaries

The following facts affect the amount of work an operation can perform:

- BLoC mutations copy the full entity table map before changing state;
- BLoC filtered reads serialize and rebuild selected models;
- generic relationship paths can perform related reads per parent or key;
- MySQL uses grouped relation reads only for recognized direct-table plans;
- Firebase `popAll` reads matching models before deleting their keys;
- MySQL batch writes execute one SQL statement per item inside a transaction;
- MySQL streams do not perform repeated reads after the initial result;
- cursor pagination is not handled by the current framework.

No benchmark in the project turns these observations into a latency, throughput, memory, or collection-size guarantee.
