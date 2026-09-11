import 'dart:async';

import 'package:dorm_framework/dorm_framework.dart';
import 'package:test/test.dart';

void main() {
  test('preserves portable error metadata and native cause', () {
    final Object cause = StateError('provider failure');
    final StackTrace trace = StackTrace.current;
    final DormDatabaseException error = DormDatabaseException(
      kind: DormErrorKind.unavailable,
      retryability: DormRetryability.safe,
      message: 'Database is unavailable.',
      engine: 'test',
      operation: 'peek',
      providerCode: 503,
      cause: cause,
      stackTrace: trace,
    );

    expect(error.isRetryable, isTrue);
    expect(error.isAvailabilityFailure, isTrue);
    expect(error.cause, same(cause));
    expect(error.stackTrace, same(trace));
    expect(error.toString(), contains('unavailable'));
    expect(error.toString(), contains('503'));
  });

  test('maps Future failures with the original stack trace', () async {
    final StackTrace trace = StackTrace.current;
    final DormErrorMapper mapper = _Mapper();

    await expectLater(
      mapDormErrors<void>(
        () => Future<void>.error(Exception('provider'), trace),
        mapper,
        operation: 'put',
      ),
      throwsA(
        isA<DormDatabaseException>()
            .having((error) => error.operation, 'operation', 'put')
            .having((error) => error.cause, 'cause', isA<Exception>()),
      ),
    );
  });

  test('maps Stream failures', () async {
    final Stream<int> stream = mapDormStreamErrors<int>(
      Stream<int>.error(Exception('provider')),
      _Mapper(),
      operation: 'pull',
    );

    await expectLater(
      stream,
      emitsError(
        isA<DormDatabaseException>().having(
          (error) => error.operation,
          'operation',
          'pull',
        ),
      ),
    );
  });

  test('can map provider response format errors explicitly', () async {
    await expectLater(
      mapDormErrors<void>(
        () => Future<void>.error(const FormatException('response')),
        _Mapper(),
        mapFormatExceptions: true,
      ),
      throwsA(isA<DormDatabaseException>()),
    );
  });
  test('leaves dORM validation errors unchanged', () async {
    await expectLater(
      mapDormErrors<void>(
        () => Future<void>.error(ArgumentError('bad')),
        _Mapper(),
      ),
      throwsA(isA<ArgumentError>()),
    );
  });
}

final class _Mapper implements DormErrorMapper {
  @override
  DormDatabaseException map(
    Object error,
    StackTrace stackTrace, {
    String? operation,
  }) => DormDatabaseException(
    kind: DormErrorKind.unknown,
    retryability: DormRetryability.unknown,
    message: error.toString(),
    engine: 'test',
    operation: operation,
    cause: error,
    stackTrace: stackTrace,
  );
}
