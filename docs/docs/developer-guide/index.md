# Work on dORM locally

Use this section when you are contributing to dORM itself, developing a new
engine, or checking a change across the workspace. Application projects should
start with [Quickstart](../quickstart/index.md) or [Choose an engine](../engines/index.md).

## Clone the source

Install Git and the Dart SDK, then clone the project and enter its directory:

```shell
git clone https://github.com/ezgrs/dorm.git
cd dorm
```

The root directory contains the Pub Workspace and the Melos configuration. Run
workspace commands from this directory unless a page gives a package or
example directory explicitly.

## Resolve workspace dependencies

Install the repository's Melos version and resolve the workspace packages:

```shell
dart pub global activate melos
dart pub get
melos bootstrap
```

`dart pub get` resolves the root Pub Workspace. `melos bootstrap` applies the
workspace package setup used by the repository's scripts and package links.

Check the packages that Melos sees with:

```shell
melos list --long
```

## Work on one package

Move into the package you are changing before running package commands:

```shell
cd dorm_framework
dart analyze
dart test
```

Use the package's own <i>pubspec.yaml</i> as the command boundary. The Firebase
package and its Flutter example use Flutter commands; the other package and
example workflows are pure Dart.

## Run workspace checks

After a change that affects more than one package, run the workspace checks
from the root:

```shell
melos run analyze
melos run test --no-select
```

Use `melos run generate` when the change affects generated source. Generated
files are outputs: edit annotations, source models, or generator code, then
regenerate them instead of editing the generated files directly.

## Work with generated files

Annotated source files can produce both <i>*.dorm.dart</i> and <i>*.g.dart</i> parts. Run
the generator from the package or example directory that owns the annotated
source:

```shell
dart pub get
dart run build_runner build --delete-conflicting-outputs
```

The `dorm_generator` builder writes the dORM part, and `json_serializable`
writes the JSON part. Analyze the same directory after generation:

```shell
dart analyze
```

Do not hand-edit `.dorm.dart`, `.g.dart`, `.dart_tool/`, or `build/` files.

## Update the documentation

The documentation project is under <i>docs/</i> and uses Poetry for its Python
dependencies:

```shell
cd docs
poetry install
```

Edit Markdown files under <i>docs/docs/</i> and the navigation in <i>docs/mkdocs.yml</i>.
Use static link and formatting checks when editing documentation. Do not use
the documentation build as a substitute for Dart package analysis.

## Prepare a package for release checks

The repository contains a preparation script for package metadata and license
headers:

```shell
dart run tool/prepare_package.dart --package dorm_framework
```

This is a release-preparation command. Do not run publication or versioning
commands as part of an ordinary package change.

## Synchronize showcase dependency versions

`dorm_example` renders the current dORM release into the generated project's
<i>pubspec.yaml</i>. After Melos updates the workspace package versions, synchronize
the embedded version before committing the release:

```shell
dart run tool/sync_dorm_example_version.dart
```

The script reads *dorm_example/pubspec.yaml*, verifies that the published dORM
packages share that version, and updates the version metadata used by the
Mustache templates. Run it from the repository root.

Continue with [Implement a custom engine](custom-engine.md) when the change is
a new backend, or [Test an engine](test-an-engine.md) when the change needs
cross-engine contract coverage.
