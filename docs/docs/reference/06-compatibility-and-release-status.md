# Compatibility and release status

This page separates explicit package facts, currently observed behavior, and
status that is not established by the available contracts.

## Package and runtime facts

| Area | Current status |
| --- | --- |
| Published package version in the eight workspace manifests | 1.0.0-alpha.5 |
| Workspace root Dart SDK | >=3.9.0 <4.0.0 |
| Workspace member SDK declarations | >=3.5.0 <4.0.0 for the members that use the workspace resolution; some packages declare >=3.11.5 <4.0.0 |
| Firebase package | Flutter/Firebase integration, not a backend-neutral Dart implementation |
| MySQL client | mysql_client |
| PostgreSQL client | postgres |
| MongoDB client | mongo_dart |
| Generator tooling | build_runner, source_gen, analyzer, json_serializable, and copy_with_extension_gen |
| Workspace mechanism | Dart Pub Workspace with Melos configuration in the root pubspec.yaml |

The SDK ranges are package configuration facts. They do not establish a
complete OS, platform-plugin, MySQL-server, Firebase-server, or SQL-mode
compatibility matrix.

## Current engine support

| Engine | Currently evidenced runtime |
| --- | --- |
| BLoC | Pure Dart in-process state through BLoC/Cubit dependencies. |
| Firebase | Flutter with Firebase Core, Realtime Database, and Authentication. |
| MySQL | Dart package using mysql_client and an external MySQL server. |
| PostgreSQL | Pure Dart package using postgres and an external PostgreSQL server. |
| MongoDB | Pure Dart package using mongo_dart and an external MongoDB server; the driver requires a runtime compatible with dart:io. |

The common generated API is observed with these engines. That observation is
not a promise that every operation has identical semantics across them.

## Identity compatibility

- The default generated identity shape is String.
- Firebase reference operations require String identities.
- BLoC, MySQL, PostgreSQL, and MongoDB currently generate UUID-backed String identities in their
  automatic identity paths.
- BLoC and MySQL reject automatic put operations for composite primary keys
  with UnsupportedError.
- Firebase composite foreign-key relationships and automatic composite-key
  generation are not supported by the current documented boundaries.

Use [Identity and dependencies](../03-understand/02-identity-and-dependencies.md)
for operation-level details.

## Stream and feature compatibility

| Feature | Status |
| --- | --- |
| CRUD | Implemented in the framework and engine paths with engine-specific behavior. |
| Filters | Implemented by BLoC, Firebase, MySQL, PostgreSQL, and MongoDB through different query representations. |
| Relationships | Implemented in the common framework and engine adapters; direct and fallback paths differ. |
| Streams | BLoC and Firebase currently provide state/value events; MySQL, PostgreSQL, and MongoDB currently perform an initial read only. |
| Transactions | No general public transaction API. Some engine operations use backend transactions internally. |
| Pagination | Explicitly unsupported by the current public scope. |
| Polymorphic serialization across every engine | Current serialized behavior exists, but universal cross-engine compatibility is not established. |
| MongoDB change streams | Not exposed by the current MongoDB engine. |
| MongoDB aggregation and migrations | Not exposed by the current MongoDB package. |

## Public API and generated output

The documented import surface is the eight package barrel files listed in
[Public API reference](01-public-api.md). Changes to exported barrels,
framework contracts, annotations, generator output, generated class names,
identity codecs, filters, or relationships affect the observable API surface.

Generated output currently includes .dorm.dart and .g.dart part files. The
stability of every generated identifier across future versions is not
explicitly guaranteed by the current package metadata.

## Legacy and migration evidence

The changelog records these historical API transitions:

- the package name dorm was changed to dorm_framework in alpha.3;
- relationship classes were replaced by the DatabaseEntity relationships
  field in alpha.5;
- BaseEngine and BaseRelationship were added in alpha.5;
- the current changelog lists alpha.6 changes, while the workspace manifests
  currently declare alpha.5.

These entries document historical release notes. A complete migration guide
for every version transition is not established.

## Release policy status

The package manifests use semantic-versioned alpha package versions. The
available release material does not define a formal deprecation period,
compatibility window, or migration-policy guarantee.

The changelog contains an Unreleased section and historical entries, but it
does not by itself define which changes are breaking for every package.

## What is not determined

The following compatibility properties are not established by the current
configuration and tests:

- supported operating-system and processor matrix;
- supported MySQL server versions, SQL modes, collations, or authentication
  configurations;
- complete Firebase platform, emulator, rules, and plugin matrix;
- future stability of generated names and internal implementation imports;
- cross-engine parity for every filter, relationship, stream, and composite
  identity path.

Treat these as undetermined status, not as future support promises.
