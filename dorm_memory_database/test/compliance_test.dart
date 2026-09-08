import 'package:dorm_framework/dorm_framework.dart';
import 'package:dorm_memory_database/dorm_memory_database.dart';
import 'package:dorm_test/dorm_test.dart';

class _MemorySession implements TransactionalEngineTestSession<Query> {
  _MemorySession() : _engine = Engine();

  final Engine _engine;

  @override
  BaseEngine<Query, OffsetPageRequest> get engine => _engine;

  @override
  TransactionalEngine<Query, OffsetPageRequest> get transactionalEngine =>
      _engine;

  @override
  final EngineCapabilities capabilities = const EngineCapabilities(
    compositeIdentities: true,
    reactiveStreams: true,
    transactions: true,
  );

  @override
  Future<void> reset() async {}

  @override
  Future<void> close() async {}
}

class _MemoryAdapter implements TransactionalEngineTestAdapter<Query> {
  @override
  String get name => 'Memory';

  @override
  Future<TransactionalEngineTestSession<Query>> open() async =>
      _MemorySession();
}

void main() {
  defineEngineComplianceTests(_MemoryAdapter());
  defineEngineTransactionComplianceTests(_MemoryAdapter());
}
