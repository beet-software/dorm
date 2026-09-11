# Release status

This page records release facts that are stable enough to guide a user or
contributor. It does not copy a version number that would become stale.

## Release source

The root *VERSION* file is the input to the release workflow. The workspace
uses fixed Melos versioning: a release updates the package manifests together,
creates one version tag, and publishes the public packages after validation.

The package line is alpha/dev. Consumers should expect breaking API changes
until a stable compatibility policy is announced.

## SDK and workspace facts

Read SDK constraints from the root *pubspec.yaml* and each package manifest
before choosing a toolchain. The repository uses a Dart Pub Workspace with
Melos configuration in the root manifest. Flutter-backed packages also require
application-owned Firebase setup where their engine guide says so.

These constraints do not establish a complete operating-system, provider,
server-version, SQL-mode, Firebase-rule, or emulator compatibility matrix.

## Published package scope

The public workspace packages are the packages listed in the root workspace
and publication workflow. `dorm_test` is an internal conformance package and
remains `publish_to: none`.

Use the package's pub.dev page for the published version and generated API
documentation. Use [Public surface](public-surface.md) for supported imports
and [Engine and platform support](engine-support.md) for runtime behavior.

## Compatibility policy

The repository does not promise a general deprecation period, migration
window, or stable generated-name policy. Treat changes to exported symbols,
framework contracts, generated types, identities, filters, relationships,
capabilities, and portable errors as public API changes.

`User`-action changes belong in the package changelog and migration guide. The
release workflow and *VERSION* file are the source for release automation; this
page should not become a second changelog.

## Unverified compatibility

The following are not established by the repository as universal guarantees:

- supported versions of every external server or provider SDK;
- complete operating-system and processor matrices;
- identical filter, relationship, stream, or transaction semantics across all
  engines;
- stable names for generated members that are not part of the documented
  generated contract;
- cross-engine compatibility when identity types, key counts, codecs, or
  serialized schemas differ.

When a release depends on one of these facts, document the specific tested
environment in the relevant engine guide or mark the decision as:

> HUMAN DECISION REQUIRED: compatibility has not been established by the
> repository.
