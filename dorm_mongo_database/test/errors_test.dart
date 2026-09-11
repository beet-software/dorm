import 'package:dorm_framework/dorm_framework.dart';
import 'package:dorm_mongo_database/src/errors.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:test/test.dart';

void main() {
  test('maps MongoDB duplicate keys to conflict', () {
    final DormDatabaseException mapped = const MongoErrorMapper().map(
      MongoDartError('duplicate', mongoCode: 11000),
      StackTrace.current,
    );
    expect(mapped.kind, DormErrorKind.conflict);
    expect(mapped.providerCode, 11000);
    expect(mapped.engine, 'mongo');
  });
}
