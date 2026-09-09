# Performance model

This page records observable execution behavior that is common across the
current architecture. It does not contain benchmark results or performance
targets.

## What every operation crosses

Repository calls first use generated entity mapping to turn application values
into the representation expected by the selected engine. The engine performs
the query or storage operation, then the generated mapping turns the result
back into a model or collection for the application.

Writes can allocate serialized maps and identity values. Reads can allocate
model objects, result lists, and deserialized nested values. These are code-
level observations, not measurements of elapsed time or memory usage.

## Relationship reads can add work

Generated relationship paths are assembled lazily. The first backend read
occurs when `peekAll` or `pullAll` is called. Each path step can then read a
related source and create `Join`, list, map, and identity structures.

An engine may recognize a direct relation plan and group some reads. When it
cannot use a plan, the relationship layer can fall back to readable repository
operations. The common API does not promise a fixed number of backend calls
for every relationship path.

## Caching and benchmarks

The framework does not expose a general query-result cache, relationship cache,
prepared-statement cache, or application-controlled performance policy. Driver
pooling and connection reuse remain properties of the supplied backend object.

The repository contains no benchmark suite, timing assertion, workload target,
or published throughput/latency result. Engine-specific pages describe the
allocation, batching, request, transaction, and stream behavior visible in
their implementations.

## Read the selected engine's behavior

The amount of work depends on the engine:

- in-memory engines copy or materialize state according to their state model;
- Firebase maps operations to snapshots and backend events;
- SQL engines construct statements and may use internal or public transaction
  boundaries;
- MongoDB uses document operations and replacement writes;
- HTTP relationships can issue additional requests and batch operations require
  configured batch endpoints.

Use the dedicated engine page for the backend-specific details before treating
an operation's current execution path as a property of all engines.
