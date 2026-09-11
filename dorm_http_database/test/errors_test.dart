import 'package:dorm_framework/dorm_framework.dart';
import 'package:dorm_http_database/src/errors.dart';
import 'package:dorm_http_database/src/error.dart';
import 'package:test/test.dart';

void main() {
  const HttpErrorMapper mapper = HttpErrorMapper();

  test('maps HTTP status categories and preserves 404', () {
    final DormDatabaseException unavailable = mapper.map(
      HttpDatabaseException(
        statusCode: 503,
        method: 'GET',
        uri: Uri.parse('https://example.test/users'),
        body: 'offline',
      ),
      StackTrace.current,
    );
    final DormDatabaseException missing = mapper.map(
      HttpDatabaseException(
        statusCode: 404,
        method: 'GET',
        uri: Uri.parse('https://example.test/users/1'),
        body: 'missing',
      ),
      StackTrace.current,
    );

    expect(unavailable.kind, DormErrorKind.unavailable);
    expect(missing.kind, DormErrorKind.notFound);
    expect(missing.providerCode, 404);

    expect(
      mapper
          .map(const FormatException('malformed response'), StackTrace.current)
          .kind,
      DormErrorKind.invalidData,
    );
  });
}
