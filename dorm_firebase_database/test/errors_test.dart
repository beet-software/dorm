import 'package:dorm_firebase_database/src/errors.dart';
import 'package:dorm_framework/dorm_framework.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:test/test.dart';

void main() {
  test('maps Firebase permission errors to authorization', () {
    final DormDatabaseException mapped = const FirebaseDatabaseErrorMapper()
        .map(
          FirebaseException(
            plugin: 'firebase_database',
            code: 'permission-denied',
            message: 'denied',
          ),
          StackTrace.current,
        );
    expect(mapped.kind, DormErrorKind.authorization);
    expect(mapped.providerCode, 'permission-denied');
    expect(mapped.engine, 'firebase_database');
  });
}
