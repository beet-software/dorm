import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart' as fs;
import 'package:dorm_firestore_database/src/helpers.dart';
import 'package:dorm_migrations/dorm_migrations.dart';

/// Migration support for Cloud Firestore.
final class FirestoreMigrationAdapter extends DocumentMigrationAdapter {
  factory FirestoreMigrationAdapter(
    fs.FirebaseFirestore firestore, {
    String? parentPath,
    String historyEntity = '__dorm_migrations',
    String lockEntity = '__dorm_migration_lock',
    Duration leaseDuration = const Duration(minutes: 5),
  }) {
    return FirestoreMigrationAdapter._(
      _FirestoreMigrationBackend(firestore, parentPath),
      historyEntity,
      lockEntity,
      leaseDuration,
    );
  }

  FirestoreMigrationAdapter._(
    _FirestoreMigrationBackend backend,
    String historyEntity,
    String lockEntity,
    Duration leaseDuration,
  ) : super(
        backend,
        historyEntity: historyEntity,
        lockEntity: lockEntity,
        leaseDuration: leaseDuration,
      );
}

final class _FirestoreMigrationBackend
    implements
        DocumentMigrationBackend,
        DocumentMigrationPagingBackend,
        DocumentMigrationLeaseBackend {
  _FirestoreMigrationBackend(this.firestore, this.parentPath)
    : owner = _newLeaseOwner();

  final fs.FirebaseFirestore firestore;
  final String? parentPath;
  final String owner;
  _FirestoreMigrationLease? _lease;
  bool _locked = false;

  fs.CollectionReference<Map<String, dynamic>> _collection(String name) =>
      firestore.collection(firestoreCollectionPath(name, parentPath));

  fs.DocumentReference<Map<String, dynamic>> _lockDocument(String entity) =>
      _collection(entity).doc('__lease__');

  @override
  Future<List<MigrationDocument>> read(String entityName) async {
    await _verifyActiveLease();
    final fs.QuerySnapshot<Map<String, dynamic>> snapshot = await _collection(
      entityName,
    ).get();
    return [
      for (final fs.QueryDocumentSnapshot<Map<String, dynamic>> document
          in snapshot.docs)
        MigrationDocument(key: document.id, data: document.data()),
    ];
  }

  @override
  Future<MigrationDocumentPage> readPage(
    String entityName, {
    required String? cursor,
    required int limit,
  }) async {
    await _verifyActiveLease();
    fs.Query<Map<String, dynamic>> query = _collection(
      entityName,
    ).orderBy(fs.FieldPath.documentId).limit(limit + 1);
    if (cursor != null) {
      query = query.startAfter([cursor]);
    }
    final fs.QuerySnapshot<Map<String, dynamic>> snapshot = await query.get();
    final bool hasMore = snapshot.docs.length > limit;
    final List<fs.QueryDocumentSnapshot<Map<String, dynamic>>> selected =
        hasMore ? snapshot.docs.take(limit).toList() : snapshot.docs;
    if (hasMore && selected.isEmpty) {
      throw StateError('Firestore migration paging returned no progress.');
    }
    return MigrationDocumentPage(
      documents: [
        for (final fs.QueryDocumentSnapshot<Map<String, dynamic>> document
            in selected)
          MigrationDocument(key: document.id, data: document.data()),
      ],
      nextCursor: hasMore ? selected.last.id : null,
    );
  }

  @override
  Future<void> write(String entityName, MigrationDocument document) =>
      _writeDocument(_collection(entityName).doc(document.key), document.data);

  @override
  Future<void> delete(String entityName, String key) =>
      _deleteDocument(_collection(entityName).doc(key));

  @override
  Future<void> clear(String entityName) async {
    final fs.QuerySnapshot<Map<String, dynamic>> snapshot = await _collection(
      entityName,
    ).get();
    for (final List<fs.QueryDocumentSnapshot<Map<String, dynamic>>> batch
        in _batches(snapshot.docs, 500)) {
      await firestore.runTransaction<void>((transaction) async {
        await _verifyInTransaction(transaction);
        for (final fs.QueryDocumentSnapshot<Map<String, dynamic>> document
            in batch) {
          transaction.delete(document.reference);
        }
      });
    }
  }

  @override
  Future<T> lock<T>(Future<T> Function() action) async {
    if (_locked) {
      throw StateError(
        'Another Firestore migration run already holds the local lock.',
      );
    }
    _locked = true;
    try {
      return await action();
    } finally {
      _locked = false;
    }
  }

  @override
  Future<MigrationLease> acquireLease(
    String lockEntity, {
    required Duration ttl,
  }) async {
    if (_lease != null) {
      throw const MigrationLeaseException(
        'This Firestore migration adapter already owns a lease.',
      );
    }
    final fs.DocumentReference<Map<String, dynamic>> lock = _lockDocument(
      lockEntity,
    );
    final Map<String, int> values = await firestore
        .runTransaction<Map<String, int>>((transaction) async {
          final fs.DocumentSnapshot<Map<String, dynamic>> snapshot =
              await transaction.get(lock);
          final Map<String, dynamic> current = snapshot.data() ?? {};
          final String? currentOwner = current['owner']?.toString();
          final int? currentExpiry = _integer(current['expiresAt']);
          final int currentFence = _integer(current['fence']) ?? 0;
          if (currentOwner != null &&
              currentExpiry != null &&
              currentExpiry > _now() &&
              currentOwner != owner) {
            throw const MigrationLeaseException(
              'The Firestore migration lease is already held.',
            );
          }
          final int fence = currentFence + 1;
          final int expiresAt = _now() + ttl.inMilliseconds;
          transaction.set(lock, {
            'owner': owner,
            'fence': fence,
            'expiresAt': expiresAt,
          });
          return {'fence': fence, 'expiresAt': expiresAt};
        });
    final _FirestoreMigrationLease lease = _FirestoreMigrationLease(
      backend: this,
      lockEntity: lockEntity,
      owner: owner,
      fencingToken: values['fence']!,
      expiresAtMilliseconds: values['expiresAt']!,
      ttl: ttl,
    );
    _lease = lease;
    return lease;
  }

  @override
  Future<void> verifyLease(String lockEntity, MigrationLease lease) async {
    final _FirestoreMigrationLease current = _requireLease(lease, lockEntity);
    final fs.DocumentSnapshot<Map<String, dynamic>> snapshot =
        await _lockDocument(lockEntity).get();
    if (!_matches(snapshot.data() ?? {}, current)) {
      throw const MigrationLeaseException(
        'The Firestore migration lease is no longer valid.',
      );
    }
  }

  @override
  Future<void> releaseLease(String lockEntity, MigrationLease lease) async {
    final _FirestoreMigrationLease current = _requireLease(lease, lockEntity);
    await firestore.runTransaction<void>((transaction) async {
      final fs.DocumentReference<Map<String, dynamic>> lock = _lockDocument(
        lockEntity,
      );
      final fs.DocumentSnapshot<Map<String, dynamic>> snapshot =
          await transaction.get(lock);
      if (_matches(snapshot.data() ?? {}, current)) {
        transaction.delete(lock);
      }
    });
    if (identical(_lease, current)) {
      _lease = null;
    }
  }

  Future<void> _renewLease(_FirestoreMigrationLease lease, Duration ttl) async {
    _requireLease(lease, lease.lockEntity);
    final int expiresAt = _now() + ttl.inMilliseconds;
    await firestore.runTransaction<void>((transaction) async {
      final fs.DocumentReference<Map<String, dynamic>> lock = _lockDocument(
        lease.lockEntity,
      );
      final fs.DocumentSnapshot<Map<String, dynamic>> snapshot =
          await transaction.get(lock);
      if (!_matches(snapshot.data() ?? {}, lease)) {
        throw const MigrationLeaseException(
          'The Firestore migration lease could not be renewed.',
        );
      }
      transaction.set(lock, {
        'owner': lease.owner,
        'fence': lease.fencingToken,
        'expiresAt': expiresAt,
      });
    });
    lease._expiresAtMilliseconds = expiresAt;
  }

  Future<void> _writeDocument(
    fs.DocumentReference<Map<String, dynamic>> document,
    Map<String, Object?> data,
  ) async {
    final _FirestoreMigrationLease? lease = _lease;
    if (lease == null) {
      await document.set(Map<String, dynamic>.from(data));
      return;
    }
    await firestore.runTransaction<void>((transaction) async {
      await _verifyInTransaction(transaction);
      transaction.set(document, Map<String, dynamic>.from(data));
    });
  }

  Future<void> _deleteDocument(
    fs.DocumentReference<Map<String, dynamic>> document,
  ) async {
    final _FirestoreMigrationLease? lease = _lease;
    if (lease == null) {
      await document.delete();
      return;
    }
    await firestore.runTransaction<void>((transaction) async {
      await _verifyInTransaction(transaction);
      transaction.delete(document);
    });
  }

  Future<void> _verifyInTransaction(fs.Transaction transaction) async {
    final _FirestoreMigrationLease? lease = _lease;
    if (lease == null) return;
    final fs.DocumentSnapshot<Map<String, dynamic>> snapshot = await transaction
        .get(_lockDocument(lease.lockEntity));
    if (!_matches(snapshot.data() ?? {}, lease)) {
      throw const MigrationLeaseException(
        'The Firestore migration lease was lost before a write.',
      );
    }
  }

  Future<void> _verifyActiveLease() async {
    final _FirestoreMigrationLease? lease = _lease;
    if (lease == null) return;
    await verifyLease(lease.lockEntity, lease);
  }

  _FirestoreMigrationLease _requireLease(
    MigrationLease lease,
    String lockEntity,
  ) {
    final _FirestoreMigrationLease? current = _lease;
    if (lease is! _FirestoreMigrationLease ||
        !identical(current, lease) ||
        lease.lockEntity != lockEntity) {
      throw const MigrationLeaseException(
        'The Firestore migration lease does not belong to this adapter.',
      );
    }
    return lease;
  }

  bool _matches(Map<String, dynamic> data, _FirestoreMigrationLease lease) {
    return data['owner']?.toString() == lease.owner &&
        _integer(data['fence']) == lease.fencingToken &&
        (_integer(data['expiresAt']) ?? 0) > _now();
  }

  Iterable<List<T>> _batches<T>(List<T> values, int size) sync* {
    for (int offset = 0; offset < values.length; offset += size) {
      final int end = (offset + size).clamp(0, values.length);
      yield values.sublist(offset, end);
    }
  }
}

final class _FirestoreMigrationLease implements MigrationLease {
  _FirestoreMigrationLease({
    required this.backend,
    required this.lockEntity,
    required this.owner,
    required this.fencingToken,
    required int expiresAtMilliseconds,
    required this.ttl,
  }) : _expiresAtMilliseconds = expiresAtMilliseconds;

  final _FirestoreMigrationBackend backend;
  final String lockEntity;
  @override
  final String owner;
  @override
  final int fencingToken;
  final Duration ttl;
  int _expiresAtMilliseconds;

  @override
  DateTime get expiresAt =>
      DateTime.fromMillisecondsSinceEpoch(_expiresAtMilliseconds, isUtc: true);

  @override
  Future<void> renew() => backend._renewLease(this, ttl);

  @override
  Future<void> release() => backend.releaseLease(lockEntity, this);
}

String _newLeaseOwner() {
  final Random random = Random.secure();
  return DateTime.now().toUtc().microsecondsSinceEpoch.toString() +
      '-' +
      random.nextInt(1 << 32).toString();
}

int _now() => DateTime.now().toUtc().millisecondsSinceEpoch;

int? _integer(Object? value) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}
