# Reference

Use this section when you already know the basic dORM workflow and need to
understand a contract, a boundary, or a behavior that must remain consistent
when the engine changes.

The reference is organized by decision rather than by package:

| When you need to... | Read |
| --- | --- |
| Understand how annotations become storage operations | [Architecture and boundaries](architecture.md) |
| Check what application code may import and extend | [Public surface](public-surface.md) |
| Understand generated files and types | [Generated output contract](generated-contract.md) |
| Implement or review an engine | [Framework contracts](framework-contracts.md) |
| Compare backend behavior before choosing an engine | [Engine and platform support](engine-support.md) |
| Classify failures across providers | [Portable errors](errors.md) |
| Review primary-to-replica behavior | [Synchronization protocol](synchronization.md) |
| Estimate where an operation can do more work | [Execution and performance model](performance.md) |
| Check a term used by more than one section | [Glossary](glossary.md) |
| Check current version and compatibility status | [Release status](release-status.md) |

## How this section relates to the rest of the docs

- [Operations](../build-the-store/overview.md) explains how to perform a task
  in an application.
- [Model anatomy](../model-anatomy/index.md) explains the generated pieces in
  learning order.
- [Annotations](../annotations/index.md) explains how to declare models.
- [Engines](../apply/choose-an-engine.md) explains how to configure a concrete
  backend.
- [Developer guide](../development/index.md) explains how to contribute to or
  implement engines.
- This section records the contracts and decisions that connect those guides.

Use the generated API documentation on pub.dev for the exhaustive list of
public members and signatures. Use this repository reference for behavior,
invariants, compatibility, and engine differences that a generated member
reference cannot explain.

## Reading guarantees

A statement in this section is a framework guarantee only when it is described
as part of a framework contract. Engine-specific tables and notes describe the
current implementation and tested behavior of that engine. They do not make a
promise about another backend.

When the repository does not establish a compatibility fact, the documentation
must say so explicitly rather than turning an inference into a guarantee.