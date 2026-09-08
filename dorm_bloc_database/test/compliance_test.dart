import 'package:dorm_bloc_database/dorm_bloc_database.dart';
import 'package:dorm_framework/dorm_framework.dart';
import 'package:dorm_test/dorm_test.dart';

class _BlocSession implements TransactionalEngineTestSession<Query> {
  _BlocSession() : _engine = Engine();

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

class _BlocAdapter implements TransactionalEngineTestAdapter<Query> {
  @override
  String get name => 'BLoC';

  @override
  Future<TransactionalEngineTestSession<Query>> open() async => _BlocSession();
}

void main() {
  defineEngineComplianceTests(_BlocAdapter());
  defineEngineTransactionComplianceTests(_BlocAdapter());
}
