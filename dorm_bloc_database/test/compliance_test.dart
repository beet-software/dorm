import 'package:dorm_bloc_database/dorm_bloc_database.dart';
import 'package:dorm_framework/dorm_framework.dart';
import 'package:dorm_test/dorm_test.dart';

class _BlocSession implements EngineTestSession<Query> {
  _BlocSession() : _engine = Engine();

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

class _BlocAdapter implements EngineTestAdapter<Query> {
  @override
  String get name => 'BLoC';

  @override
  Future<EngineTestSession<Query>> open() async => _BlocSession();
}

void main() {
  defineEngineComplianceTests(_BlocAdapter());
}
