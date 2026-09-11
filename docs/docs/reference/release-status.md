# Release status

This page records current release facts that can be verified from the
repository. It is intentionally shorter than the engine support matrix and
does not repeat backend capabilities.

## Current release line

The root VERSION file currently declares:

~~~text
2.0.0-dev.4
~~~

The workspace uses fixed Melos versioning. A release updates the package
manifests together and creates one version tag. The release workflow validates
the workspace, pushes the tag, and publishes the public packages.

The package line is alpha/dev. Consumers should expect breaking API changes
until a stable compatibility policy is announced.

## SDK and workspace facts

- The workspace root requires Dart >=3.9.0 and <4.0.0.
- Some members and generated profiles require Dart >=3.11.5.
- The repository uses a Dart Pub Workspace with Melos configuration in the root
  pubspec.yaml.
- Firebase and Firestore packages require Flutter and their application-owned
  Firebase setup.
- The remaining official engine packages are pure Dart unless their package
  page or engine guide states otherwise.

These constraints describe package configuration. They do not establish a
complete operating-system, provider, server-version, SQL-mode, Firebase-rule,
or emulator compatibility matrix.

## Published package scope

The public workspace packages are the packages listed in the root workspace
and publication workflow. dorm_test is an internal conformance package and
remains publish_to: none.

Use the package's pub.dev page for the published version and generated API
documentation. Use [Public surface](public-surface.md) for supported imports
and [Engine and platform support](engine-support.md) for current runtime
behavior.

## Compatibility policy

The repository does not promise a general deprecation period, migration
window, or stable generated-name policy. Treat changes to exported symbols,
framework contracts, generated types, identities, filters, relationships,
capabilities, and portable errors as public API changes.

User-action changes belong in the package changelog and migration guide. The
current release workflow and version file are the source for release
automation; this page should not become a second changelog.

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