import 'package:dorm_firestore_database/src/helpers.dart';
import 'package:dorm_framework/dorm_framework.dart';
import 'package:test/test.dart';

void main() {
  group('Firestore paths', () {
    test('uses top-level collections without a parent path', () {
      expect(firestoreCollectionPath('users', null), 'users');
    });

    test('appends an entity collection below a document path', () {
      expect(
        firestoreCollectionPath('users', 'tenants/acme'),
        'tenants/acme/users',
      );
    });

    test('rejects paths that identify a collection instead of a document', () {
      expect(
        () => firestoreCollectionPath('users', 'tenants'),
        throwsArgumentError,
      );
    });

    test('rejects collection names containing path separators', () {
      expect(
        () => firestoreCollectionPath('users/members', null),
        throwsArgumentError,
      );
    });
  });

  group('Firestore identities', () {
    test('accepts non-empty document IDs', () {
      expect(firestoreDocumentId('user-1'), 'user-1');
    });

    test('rejects empty and nested document IDs', () {
      expect(() => firestoreDocumentId(''), throwsArgumentError);
      expect(() => firestoreDocumentId('users/user-1'), throwsArgumentError);
    });
  });

  group('Firestore date values', () {
    final DateTime date = DateTime(2024, 3, 5, 14, 6, 7, 123);

    test('creates the same ISO prefixes used by generated JSON', () {
      expect(firestoreDatePrefix(date, DateFilterUnit.year), '2024');
      expect(firestoreDatePrefix(date, DateFilterUnit.month), '2024-03');
      expect(firestoreDatePrefix(date, DateFilterUnit.day), '2024-03-05');
      expect(
        firestoreDatePrefix(date, DateFilterUnit.milliseconds),
        '2024-03-05T14:06:07.123',
      );
    });

    test('normalizes DateTime values to ISO strings for comparisons', () {
      expect(firestoreComparableValue(date), date.toIso8601String());
      expect(firestoreComparableValue(7), 7);
    });
  });
}
