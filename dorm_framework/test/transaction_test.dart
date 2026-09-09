import 'package:dorm_framework/dorm_framework.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

class _Query extends Fake implements BaseQuery<_Query> {}

class _TransactionalEngine extends Fake
    implements TransactionalEngine<_Query, OffsetPageRequest> {
  @override
  Future<T> transaction<T>(
    Future<T> Function(BaseEngine<_Query, OffsetPageRequest> engine) action,
  ) {
    return action(this);
  }
}

void main() {
  test(
    'transactional engines expose the base engine to the callback',
    () async {
      final _TransactionalEngine engine = _TransactionalEngine();
      final Object result = await engine.transaction((context) async {
        expect(identical(context, engine), isTrue);
        return 'completed';
      });

      expect(result, 'completed');
    },
  );

  test('transaction callback errors remain observable', () async {
    final _TransactionalEngine engine = _TransactionalEngine();

    await expectLater(
      engine.transaction<void>((_) async {
        throw StateError('failed');
      }),
      throwsA(isA<StateError>()),
    );
  });
}
