# dorm_test

<p>
  <a href="https://github.com/beet-software/dorm"><img src="https://img.shields.io/badge/repository-GitHub-181717?logo=github&style=flat" alt="dORM repository"></a>
  <a href="https://github.com/beet-software/dorm"><img src="https://img.shields.io/github/license/beet-software/dorm?style=flat" alt="License"></a>
  <a href="https://ezgrs.github.io/dorm/development/test-an-engine/"><img src="https://img.shields.io/badge/development-engine%20compliance-4c8bf5?style=flat" alt="Engine compliance guide"></a>
  <a href="https://github.com/beet-software/dorm/actions/workflows/dart.yml"><img src="https://github.com/beet-software/dorm/actions/workflows/dart.yml/badge.svg" alt="Dart CI"></a>
</p>

dorm_test is the shared conformance harness for dORM engines. It is an
internal workspace package and is not a runtime dependency or a published
application package.

## Add the harness to engine tests

An engine adds dorm_test as a development dependency and creates an adapter.
The adapter owns backend setup, cleanup, connection lifecycle, and capability
declarations.

The harness does not import concrete engines. Each engine test constructs its
own Engine and passes it to the shared suite.

## Adapter shape

An adapter opens an EngineTestSession:

~~~dart
class MyEngineAdapter implements EngineTestAdapter<Query> {
  @override
  String get name => 'My engine';

  @override
  Future<EngineTestSession<Query>> open() async {
    final engine = createMyEngine();
    return EngineTestSession(
      engine: engine,
      capabilities: const EngineCapabilities(),
      reset: resetBackend,
      close: closeBackend,
    );
  }
}
~~~

The adapter must leave each test with an isolated backend state. External
services are configured by the engine package rather than by this harness.

## Define the suite

~~~dart
void main() {
  defineEngineComplianceTests(MyEngineAdapter());
}
~~~

The shared suite identifies the engine in failure output and calls reset and
close through the session lifecycle.

## Required contract

The portable groups cover behavior common to the framework:

- simple automatic and explicit creation;
- independent putAll items;
- reads by identity and filters;
- empty reads and peekAllKeys;
- push and pushAll;
- pop, popKeys, popAll, and purge;
- patch update and removal;
- identity preservation;
- serialization and deserialization;
- portable filters, ordering, limits, and relationships;
- initial stream values;
- absence of records.

## Optional capabilities

Declare capabilities explicitly when an engine supports behavior that is not
portable across all backends:

- composite identities;
- reactive stream updates;
- atomic batch writes;
- atomic patch;
- portable transactions;
- real backend integration.

The harness does not infer capabilities from the driver or from skipped tests.
An integration group skipped because a backend is not configured is not a
passing backend verification.

## Run the tests

Memory and BLoC adapters can run without an external service. Database-backed
adapters use the environment variables documented by their engine package:

~~~shell
dart pub get
dart test test/compliance_test.dart
~~~

Keep engine-specific query translation, driver behavior, schema setup, and
backend error tests in the engine package. Use dorm_test for the framework
contract that users can observe across engines.

## Links

- [Test an engine](https://ezgrs.github.io/dorm/development/test-an-engine/)
- [Framework contracts](https://ezgrs.github.io/dorm/reference/framework-contracts/)
- [GitHub repository](https://github.com/beet-software/dorm)
