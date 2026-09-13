import 'dart:math';

import 'package:dorm_firebase_database/src/firebase_instance.dart';
import 'package:dorm_migrations/dorm_migrations.dart';
import 'package:firebase_database/firebase_database.dart' as fd;

/// Migration support for Firebase Realtime Database.
final class FirebaseDatabaseMigrationAdapter extends DocumentMigrationAdapter {
  factory FirebaseDatabaseMigrationAdapter(
    FirebaseInstance instance, {
    String? path,
    String historyEntity = '__dorm_migrations',
    String lockEntity = '__dorm_migration_lock',
    Duration leaseDuration = const Duration(minutes: 5),
  }) {
    return FirebaseDatabaseMigrationAdapter._(
      _FirebaseMigrationBackend(instance.database, path),
      historyEntity: historyEntity,
      lockEntity: lockEntity,
      leaseDuration: leaseDuration,
    );
  }

  FirebaseDatabaseMigrationAdapter._(
    super.backend, {
    super.historyEntity = '__dorm_migrations',
    super.lockEntity = '__dorm_migration_lock',
    super.leaseDuration = const Duration(minutes: 5),
  });
}

final class _FirebaseMigrationBackend
    implements
        DocumentMigrationBackend,
        DocumentMigrationPagingBackend,
        DocumentMigrationLeaseBackend {
  _FirebaseMigrationBackend(fd.FirebaseDatabase database, String? path)
    : root = database.ref(path),
      owner = _newLeaseOwner();

  final fd.DatabaseReference root;
  final String owner;
  _FirebaseMigrationLease? _lease;
  bool _locked = false;

  fd.DatabaseReference _entity(String entityName) => root.child(entityName);

  @override
  Future<List<MigrationDocument>> read(String entityName) async {
    await _verifyActiveLease();
    final fd.DataSnapshot snapshot = await _entity(entityName).get();
    return [
      for (final fd.DataSnapshot child in snapshot.children)
        if (child.key != null && child.value is Map)
          MigrationDocument(
            key: child.key!,
            data: Map<String, Object?>.from(child.value as Map),
          ),
    ];
  }

  @override
  Future<MigrationDocumentPage> readPage(
    String entityName, {
    required String? cursor,
    required int limit,
  }) async {
    await _verifyActiveLease();
    fd.Query query = _entity(entityName).orderByKey();
    if (cursor != null) {
      query = query.startAfter(null, key: cursor);
    }
    final fd.DataSnapshot snapshot = await query.limitToFirst(limit + 1).get();
    final List<fd.DataSnapshot> children = snapshot.children.toList();
    final bool hasMore = children.length > limit;
    final List<fd.DataSnapshot> selected = hasMore
        ? children.take(limit).toList()
        : children;
    if (hasMore && selected.isEmpty) {
      throw StateError('Firebase migration paging returned no progress.');
    }
    return MigrationDocumentPage(
      documents: [
        for (final fd.DataSnapshot child in selected)
          if (child.key != null && child.value is Map)
            MigrationDocument(
              key: child.key!,
              data: Map<String, Object?>.from(child.value as Map),
            ),
      ],
      nextCursor: hasMore ? selected.last.key : null,
    );
  }

  @override
  Future<void> write(String entityName, MigrationDocument document) =>
      _mutateRoot((data) {
        _setPath(data, [..._segments(entityName), document.key], document.data);
      });

  @override
  Future<void> delete(String entityName, String key) => _mutateRoot((data) {
    _removePath(data, [..._segments(entityName), key]);
  });

  @override
  Future<void> clear(String entityName) => _mutateRoot((data) {
    _removePath(data, _segments(entityName));
  });

  @override
  Future<T> lock<T>(Future<T> Function() action) async {
    if (_locked) {
      throw StateError(
        'Another Firebase migration run already holds the local lock.',
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
        'This Firebase migration adapter already owns a lease.',
      );
    }
    final fd.DatabaseReference lock = _entity(lockEntity);
    final fd.TransactionResult result = await lock.runTransaction((
      Object? value,
    ) {
      final Map<String, Object?> current = _asMap(value);
      final String? currentOwner = current['owner']?.toString();
      final int? currentExpiry = _integer(current['expiresAt']);
      final int currentFence = _integer(current['fence']) ?? 0;
      if (currentOwner != null &&
          currentExpiry != null &&
          currentExpiry > _now() &&
          currentOwner != owner) {
        return fd.Transaction.abort();
      }
      return fd.Transaction.success(
        _leaseData(
          owner: owner,
          fence: currentFence + 1,
          expiresAt: _now() + ttl.inMilliseconds,
        ),
      );
    }, applyLocally: false);
    if (!result.committed) {
      throw const MigrationLeaseException(
        'Could not acquire the Firebase migration lease.',
      );
    }
    final Map<String, Object?> data = _asMap(result.snapshot.value);
    final int? fence = _integer(data['fence']);
    final int? expiresAt = _integer(data['expiresAt']);
    if (fence == null || expiresAt == null) {
      throw const MigrationLeaseException(
        'Firebase returned an invalid migration lease.',
      );
    }
    final _FirebaseMigrationLease lease = _FirebaseMigrationLease(
      backend: this,
      lockEntity: lockEntity,
      owner: owner,
      fencingToken: fence,
      expiresAtMilliseconds: expiresAt,
      ttl: ttl,
    );
    _lease = lease;
    return lease;
  }

  @override
  Future<void> verifyLease(String lockEntity, MigrationLease lease) async {
    final _FirebaseMigrationLease current = _requireLease(lease, lockEntity);
    final fd.DataSnapshot snapshot = await _entity(lockEntity).get();
    if (!_matches(_asMap(snapshot.value), current) ||
        _now() >= current._expiresAtMilliseconds) {
      throw const MigrationLeaseException(
        'The Firebase migration lease is no longer valid.',
      );
    }
  }

  @override
  Future<void> releaseLease(String lockEntity, MigrationLease lease) async {
    final _FirebaseMigrationLease current = _requireLease(lease, lockEntity);
    final fd.DatabaseReference lock = _entity(lockEntity);
    await lock.runTransaction((Object? value) {
      final Map<String, Object?> data = _asMap(value);
      if (_matches(data, current)) {
        return fd.Transaction.success(null);
      }
      return fd.Transaction.success(data);
    }, applyLocally: false);
    if (identical(_lease, current)) {
      _lease = null;
    }
  }

  Future<void> _renewLease(_FirebaseMigrationLease lease, Duration ttl) async {
    _requireLease(lease, lease.lockEntity);
    final fd.DatabaseReference lock = _entity(lease.lockEntity);
    final int expiresAt = _now() + ttl.inMilliseconds;
    final fd.TransactionResult result = await lock.runTransaction((
      Object? value,
    ) {
      final Map<String, Object?> data = _asMap(value);
      if (!_matches(data, lease) || _now() >= lease._expiresAtMilliseconds) {
        return fd.Transaction.abort();
      }
      return fd.Transaction.success(
        _leaseData(
          owner: lease.owner,
          fence: lease.fencingToken,
          expiresAt: expiresAt,
        ),
      );
    }, applyLocally: false);
    if (!result.committed) {
      throw const MigrationLeaseException(
        'The Firebase migration lease could not be renewed.',
      );
    }
    lease._expiresAtMilliseconds = expiresAt;
  }

  Future<void> _mutateRoot(
    void Function(Map<String, Object?> data) mutate,
  ) async {
    final fd.TransactionResult result = await root.runTransaction((
      Object? value,
    ) {
      final Map<String, Object?> data = _asMap(value);
      final _FirebaseMigrationLease? lease = _lease;
      if (lease != null &&
          !_matches(
            _asMap(_readPath(data, _segments(lease.lockEntity))),
            lease,
          )) {
        return fd.Transaction.abort();
      }
      mutate(data);
      return fd.Transaction.success(data);
    }, applyLocally: false);
    if (!result.committed) {
      throw const MigrationLeaseException(
        'The Firebase migration lease was lost before a write.',
      );
    }
  }

  Future<void> _verifyActiveLease() async {
    final _FirebaseMigrationLease? lease = _lease;
    if (lease == null) return;
    await verifyLease(lease.lockEntity, lease);
  }

  _FirebaseMigrationLease _requireLease(
    MigrationLease lease,
    String lockEntity,
  ) {
    final _FirebaseMigrationLease? current = _lease;
    if (lease is! _FirebaseMigrationLease ||
        !identical(current, lease) ||
        lease.lockEntity != lockEntity) {
      throw const MigrationLeaseException(
        'The Firebase migration lease does not belong to this adapter.',
      );
    }
    return lease;
  }

  bool _matches(Map<String, Object?> data, _FirebaseMigrationLease lease) {
    return data['owner']?.toString() == lease.owner &&
        _integer(data['fence']) == lease.fencingToken &&
        (_integer(data['expiresAt']) ?? 0) > _now();
  }

  Map<String, Object?> _leaseData({
    required String owner,
    required int fence,
    required int expiresAt,
  }) => {'owner': owner, 'fence': fence, 'expiresAt': expiresAt};

  Map<String, Object?> _asMap(Object? value) {
    if (value is! Map) return <String, Object?>{};
    final Map<String, Object?> result = <String, Object?>{};
    value.forEach((key, value) {
      result[key.toString()] = value;
    });
    return result;
  }

  Object? _readPath(Map<String, Object?> data, List<String> path) {
    Object? current = data;
    for (final String segment in path) {
      if (current is! Map) return null;
      current = current[segment];
    }
    return current;
  }

  void _setPath(Map<String, Object?> data, List<String> path, Object? value) {
    if (path.isEmpty) return;
    Map<String, Object?> current = data;
    for (final String segment in path.take(path.length - 1)) {
      final Map<String, Object?> child = _asMap(current[segment]);
      current[segment] = child;
      current = child;
    }
    current[path.last] = value;
  }

  void _removePath(Map<String, Object?> data, List<String> path) {
    if (path.isEmpty) return;
    Map<String, Object?>? current = data;
    for (final String segment in path.take(path.length - 1)) {
      final Object? child = current?[segment];
      if (child is! Map) return;
      current = _asMap(child);
    }
    current?.remove(path.last);
  }
}

final class _FirebaseMigrationLease implements MigrationLease {
  _FirebaseMigrationLease({
    required this.backend,
    required this.lockEntity,
    required this.owner,
    required this.fencingToken,
    required int expiresAtMilliseconds,
    required this.ttl,
  }) : _expiresAtMilliseconds = expiresAtMilliseconds;

  final _FirebaseMigrationBackend backend;
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
  return [
    DateTime.now().toUtc().microsecondsSinceEpoch,
    random.nextInt(1 << 32),
  ].join('-');
}

int _now() => DateTime.now().toUtc().millisecondsSinceEpoch;

int? _integer(Object? value) {
  if (value is num) return value.toInt();
  return int.tryParse('$value');
}

List<String> _segments(String path) =>
    path.split('/').where((value) => value.isNotEmpty).toList();
