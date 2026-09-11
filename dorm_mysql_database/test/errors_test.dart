import 'package:dorm_framework/dorm_framework.dart';
import 'package:dorm_mysql_database/src/errors.dart';
import 'package:mysql_client/exception.dart';
import 'package:test/test.dart';

void main() {
  test('maps duplicate keys to conflict and preserves the code', () {
    final DormDatabaseException mapped = const MySqlErrorMapper().map(
      const MySQLServerException('duplicate', 1062),
      StackTrace.current,
    );
    expect(mapped.kind, DormErrorKind.conflict);
    expect(mapped.providerCode, 1062);
    expect(mapped.engine, 'mysql');
  });
}
