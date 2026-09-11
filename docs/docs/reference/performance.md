# Execution and performance model

This page explains predictable sources of work in the current dORM
architecture. It contains no benchmark results, latency targets, or universal
performance guarantees.

## What every operation crosses

A repository operation crosses generated conversion and engine execution:

1. application values are represented as creation data or a model;
2. `Entity` and `EntitySchema` resolve identity and stored field metadata;
3. the engine builds and executes its query or write;
4. serialized results are reconstructed as models or collections.

This can allocate serialized maps, identity values, model objects, result lists,
and nested values. These are execution characteristics, not measurements.

## Remote work and local work

A filter may be evaluated by an in-memory engine, translated to a backend query,
or represented as HTTP parameters. The common API does not promise that every
engine performs the same amount of work or uses the same index.

SQL and provider-native query plans are owned by the selected backend. The
framework does not expose a universal query planner, index advisor, cache, or
prepared-statement policy.

## Relationships

Relationship paths are lazy: declaring a path does not read data. Work begins
when a `peek` or `pull` method is called.

A direct relation plan may group reads or use a database join. A portable
readable-operation fallback may issue one or more additional reads per path
step or per parent. Therefore relationship result shape is portable, but query
count is not.

When relationship query count matters, use the engine support matrix and the
engine-specific guide before choosing a model shape or relation plan.

## Streams

Streams can be state-backed, provider-backed, table-watch based, or initial
read only. A backend that returns an initial read does not provide live
external-change notifications.

The common stream contract fixes result shape and error delivery, not event
frequency, backend listener cost, or cross-engine update latency. Streams also
remain attached to their selected source in `SynchronizedEngine`.

## Fallback and synchronization

`SynchronizedEngine` performs finite primary reads first. A classified fallback
can add the cost of trying one or more replicas. Empty and null results do not
trigger fallback.

A write can perform the primary operation, outbox insertion, and later replica
delivery. Replica delivery may be retried because synchronization is
at-least-once. This is a consistency and reliability tradeoff, not a universal
latency guarantee.

## Caching and measurement

dORM does not expose a general query-result cache, relationship cache, or
application-wide performance policy. Connection pooling, prepared statements,
provider caches, and indexes belong to the supplied backend.

The repository has no published throughput or latency benchmark. Measure the
workload in the target application, including representative data size,
relationship depth, page size, provider indexes, and network conditions.

See [Engine and platform support](engine-support.md) and the selected
[engine guide](../engines/index.md) before treating an implementation
detail as a portability guarantee.
