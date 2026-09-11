import 'package:dorm_framework/dorm_framework.dart';
import 'package:dorm_postgres_database/src/errors.dart';
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

void main() {
  test('maps a fatal PostgreSQL provider error to unavailable', () {
    final DormDatabaseException mapped = const PostgresErrorMapper().map(
      PgException('connection closed', severity: Severity.fatal),
      StackTrace.current,
    );
    expect(mapped.kind, DormErrorKind.unavailable);
    expect(mapped.engine, 'postgres');
    expect(mapped.cause, isA<PgException>());
  });
}
