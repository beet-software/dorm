import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:dorm_firestore_database/src/errors.dart';
import 'package:dorm_framework/dorm_framework.dart';
import 'package:test/test.dart';

void main() {
  test('maps Firestore unavailable errors to availability failures', () {
    final DormDatabaseException mapped = const FirestoreErrorMapper().map(
      firestore.FirebaseException(
        plugin: 'cloud_firestore',
        code: 'unavailable',
        message: 'offline',
      ),
      StackTrace.current,
    );
    expect(mapped.kind, DormErrorKind.unavailable);
    expect(mapped.isAvailabilityFailure, isTrue);
    expect(mapped.engine, 'firestore');
  });
}
