import 'package:dorm_framework/dorm_framework.dart';
import 'package:dorm_memory_database/dorm_memory_database.dart';
import 'package:dorm_test/dorm_test.dart';

class _MemorySession implements EngineTestSession<Query> {
  _MemorySession() : _engine = Engine();

  final Engine _engine;

  @override
  BaseEngine<Query, OffsetPageRequest> get engine => _engine;

  @override
  final EngineCapabilities capabilities = const EngineCapabilities(
    compositeIdentities: true,
    reactiveStreams: true,
  );

  @override
  Future<void> reset() async {}

  @override
  Future<void> close() async {}
}

class _MemoryAdapter implements EngineTestAdapter<Query> {
  @override
  String get name => 'Memory';

  @override
  Future<EngineTestSession<Query>> open() async => _MemorySession();
}

void main() {
  defineEngineComplianceTests(_MemoryAdapter());
}
