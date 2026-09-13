import 'package:dorm_framework/dorm_framework.dart';

/// An adapter useful for tests and process-local tooling.
///
/// It records operations but does not pretend to provide a persistent schema.
/// Applications should use a backend adapter for production migrations.
final class MemoryMigrationAdapter
    implements MigrationAdapter, MigrationHistoryCompactionAdapter {
  MemoryMigrationAdapter({this.onApply});

  final Future<void> Function(MigrationOperation operation)? onApply;
  final List<MigrationOperation> operations = [];
  final List<Migration> recordedMigrations = [];
  final Map<int, MigrationHistoryEntry> _applied = {};
  bool _locked = false;

  @override
  Future<List<MigrationHistoryEntry>> appliedMigrations() async => [
    ..._applied.values,
  ];

  @override
  Future<T> lock<T>(Future<T> Function() action) async {
    if (_locked) {
      throw StateError('Another migration run already holds the lock.');
    }
    _locked = true;
    try {
      return await action();
    } finally {
      _locked = false;
    }
  }

  @override
  Future<void> apply(MigrationOperation operation) async {
    await onApply?.call(operation);
    operations.add(operation);
  }

  @override
  Future<void> record(Migration migration, {required String checksum}) async {
    _applied[migration.version] = MigrationHistoryEntry(
      version: migration.version,
      name: migration.name,
      checksum: checksum,
    );
    recordedMigrations.add(migration);
  }

  @override
  Future<void> compactHistory(
    Migration migration, {
    required int through,
    required String checksum,
  }) async {
    _applied.removeWhere((version, _) => version <= through);
    await record(migration, checksum: checksum);
  }
}
