import 'package:dorm_framework/dorm_framework.dart';
import 'package:dorm_sqlite_database/src/errors.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

void main() {
  test('maps SQLite constraints and preserves extended codes', () {
    final DormDatabaseException mapped = const SqliteErrorMapper().map(
      SqliteException(
        extendedResultCode: SqlError.SQLITE_CONSTRAINT,
        message: 'constraint',
      ),
      StackTrace.current,
    );
    expect(mapped.kind, DormErrorKind.constraint);
    expect(mapped.providerCode, SqlError.SQLITE_CONSTRAINT);
    expect(mapped.engine, 'sqlite');
  });
}
