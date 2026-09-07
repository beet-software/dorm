# dorm_test

`dorm_test` contains the canonical shared conformance suite for dORM database engines.
It is an internal workspace package and is not a runtime dependency of an
application.

Each engine adds it as a development dependency, implements an
`EngineTestAdapter`, and calls `defineEngineComplianceTests` from its tests.
The adapter owns backend setup, cleanup, and connection lifecycle. The session
returned by the adapter declares the capabilities supported by that session.

The portable suite checks CRUD, filters, ordering, limits, initial stream
values, and relationships. Reactive streams, composite identities, and
atomicity are separate capabilities because their behavior is not identical
across the current engines.

Database-backed adapters are opt-in. Their compliance tests are skipped until
the environment variables required by the corresponding backend are set.
