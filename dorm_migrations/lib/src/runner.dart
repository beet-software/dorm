import 'dart:async';

import 'package:dorm_framework/dorm_framework.dart';

import 'checksum.dart';
import 'document.dart';

/// The result of one migration run.
final class MigrationRunResult {
  const MigrationRunResult({
    required this.applied,
    required this.skipped,
    this.duration,
  });

  final List<Migration> applied;
  final List<Migration> skipped;
  final Duration? duration;
}

/// Describes the migration history without changing the backend.
final class MigrationStatusReport {
  const MigrationStatusReport({
    required this.pending,
    required this.applied,
    required this.checksumMismatches,
    required this.legacyHistory,
    required this.unknownApplied,
  });

  final List<Migration> pending;
  final List<Migration> applied;
  final List<Migration> checksumMismatches;
  final List<MigrationHistoryEntry> legacyHistory;
  final List<MigrationHistoryEntry> unknownApplied;

  bool get isValid =>
      checksumMismatches.isEmpty &&
      legacyHistory.isEmpty &&
      unknownApplied.isEmpty;
}

/// Thrown when a migration list cannot be executed safely.
final class MigrationValidationException implements Exception {
  const MigrationValidationException(this.message);

  final String message;

  @override
  String toString() => 'MigrationValidationException: $message';
}

/// Controls whether pending migrations may remove or overwrite stored data.
enum MigrationDestructivePolicy {
  /// Reject destructive operations before they reach the backend.
  reject,

  /// Allow destructive operations after the caller explicitly opts in.
  allow,
}

/// Thrown when the runner encounters a destructive operation without opt-in.
final class MigrationDestructiveOperationException implements Exception {
  const MigrationDestructiveOperationException({
    required this.migration,
    required this.operationIndex,
    required this.operation,
  });

  final Migration migration;
  final int operationIndex;
  final MigrationOperation operation;

  @override
  String toString() =>
      'MigrationDestructiveOperationException: migration '
      '${migration.version} (${migration.name}) operation '
      '$operationIndex (${operation.runtimeType}) requires explicit opt-in.';
}

/// Checks an operation against project-specific data or deployment rules.
typedef MigrationOperationValidator =
    Future<void> Function(
      Migration migration,
      int operationIndex,
      MigrationOperation operation,
    );

/// Identifies a lifecycle point emitted while migrations run.
enum MigrationProgressStage {
  started,
  migrationStarted,
  operationStarted,
  operationCompleted,
  migrationCompleted,
  skipped,
  completed,
  failed,
}

/// A typed progress event emitted by [MigrationRunner].
final class MigrationProgress {
  const MigrationProgress({
    required this.stage,
    required this.timestamp,
    required this.completedMigrations,
    required this.totalMigrations,
    required this.completedOperations,
    required this.totalOperations,
    required this.elapsed,
    this.migration,
    this.operationIndex,
    this.operation,
    this.error,
  });

  final MigrationProgressStage stage;
  final DateTime timestamp;
  final int completedMigrations;
  final int totalMigrations;
  final int completedOperations;
  final int totalOperations;
  final Duration elapsed;
  final Migration? migration;
  final int? operationIndex;
  final MigrationOperation? operation;
  final Object? error;
}

/// A structured log record emitted by [MigrationRunner].
final class MigrationLogEntry {
  const MigrationLogEntry({
    required this.level,
    required this.event,
    required this.timestamp,
    required this.fields,
  });

  final MigrationLogLevel level;
  final String event;
  final DateTime timestamp;
  final Map<String, Object?> fields;
}

enum MigrationLogLevel { debug, info, warning, error }

/// A completed duration measurement emitted by [MigrationRunner].
final class MigrationMetric {
  const MigrationMetric({
    required this.name,
    required this.duration,
    required this.timestamp,
    required this.fields,
  });

  final String name;
  final Duration duration;
  final DateTime timestamp;
  final Map<String, Object?> fields;
}

typedef MigrationProgressCallback = void Function(MigrationProgress event);
typedef MigrationLogCallback = void Function(MigrationLogEntry entry);
typedef MigrationMetricCallback = void Function(MigrationMetric metric);

/// Runs ordered migrations through an engine-specific adapter.
final class MigrationRunner {
  const MigrationRunner(
    this.adapter, {
    this.destructivePolicy = MigrationDestructivePolicy.reject,
    this.operationValidator,
    this.onProgress,
    this.onLog,
    this.onMetric,
  });

  final MigrationAdapter adapter;

  final MigrationDestructivePolicy destructivePolicy;

  /// Runs before each pending operation reaches the adapter.
  ///
  /// Use this for project-specific checks, such as confirming that no stored
  /// values would violate a new non-nullable definition. Throwing stops the
  /// migration before that operation is applied.
  final MigrationOperationValidator? operationValidator;

  /// Receives typed lifecycle events. Observer failures are ignored.
  final MigrationProgressCallback? onProgress;

  /// Receives structured lifecycle records. Observer failures are ignored.
  final MigrationLogCallback? onLog;

  /// Receives completed duration measurements. Observer failures are ignored.
  final MigrationMetricCallback? onMetric;

  /// Applies every migration that has not been recorded by [adapter].
  Future<MigrationRunResult> run(Iterable<Migration> source) async {
    final List<Migration> migrations = _prepare(source);
    return _withLock(() => _runLocked(migrations));
  }

  /// Compacts completed history into an externally prepared replacement.
  ///
  /// The replacement is recorded without executing its operations. Existing
  /// migrations through [through] must already be applied with valid checksums.
  /// Adapters must implement [MigrationHistoryCompactionAdapter] explicitly;
  /// other adapters reject this operation.
  Future<MigrationRunResult> compact(
    Iterable<Migration> source, {
    required Migration replacement,
    required int through,
  }) async {
    if (through <= 0 || replacement.version <= through) {
      throw const MigrationValidationException(
        'A replacement migration must have a version greater than through.',
      );
    }
    final List<Migration> migrations = _prepare(source);
    if (!migrations.any((migration) => migration.version == through)) {
      throw MigrationValidationException(
        'Compaction version $through is not present in the source list.',
      );
    }
    if (migrations.any(
      (migration) => migration.version == replacement.version,
    )) {
      throw MigrationValidationException(
        'Replacement version ${replacement.version} is already in the source list.',
      );
    }
    return _withLock(() => _compactLocked(migrations, replacement, through));
  }

  /// Reads migration history and classifies pending or inconsistent entries.
  Future<MigrationStatusReport> status(Iterable<Migration> source) async {
    final List<Migration> migrations = _prepare(source);
    return _withLock(() => _statusLocked(migrations));
  }

  /// Validates migration versions, history, and checksums without applying data.
  Future<MigrationStatusReport> validate(Iterable<Migration> source) =>
      status(source);

  /// Records migrations through [through] without executing their operations.
  ///
  /// This is an explicit baseline operation for a database whose schema was
  /// prepared outside the migration runner.
  Future<MigrationRunResult> baseline(
    Iterable<Migration> source, {
    required int through,
  }) async {
    if (through <= 0) {
      throw const MigrationValidationException(
        'Baseline version must be positive.',
      );
    }
    final List<Migration> migrations = _prepare(source);
    return _withLock(() => _baselineLocked(migrations, through));
  }

  /// Records one migration after it was completed outside the runner.
  Future<MigrationRunResult> resolve(
    Iterable<Migration> source, {
    required int version,
  }) async {
    if (version <= 0) {
      throw const MigrationValidationException(
        'Resolved version must be positive.',
      );
    }
    final List<Migration> migrations = _prepare(source);
    return _withLock(() => _resolveLocked(migrations, version));
  }

  Future<T> _withLock<T>(Future<T> Function() action) {
    final MigrationLeaseAdapter? leaseAdapter = switch (adapter) {
      final MigrationLeaseAdapter value => value,
      _ => null,
    };
    if (leaseAdapter?.lockMode == MigrationLockMode.persistentLease) {
      return leaseAdapter!.withLease((_) => action());
    }
    return adapter.lock(action);
  }

  List<Migration> _prepare(Iterable<Migration> source) {
    try {
      final List<Migration> migrations = MigrationGraph.order(source);
      _validate(migrations);
      return migrations;
    } on MigrationGraphException catch (error) {
      throw MigrationValidationException(error.message);
    }
  }

  Future<MigrationRunResult> _runLocked(List<Migration> migrations) async {
    final _MigrationRunContext context = _MigrationRunContext(
      totalMigrations: migrations.length,
      totalOperations: migrations.fold<int>(
        0,
        (total, migration) => total + migration.operations.length,
      ),
    );
    context.stopwatch.start();
    _notify(context, MigrationProgressStage.started);
    try {
      final Map<int, MigrationHistoryEntry> historyByVersion =
          await _historyByVersion();
      final List<Migration> applied = [];
      final List<Migration> skipped = [];

      for (final Migration migration in migrations) {
        final MigrationHistoryEntry? entry =
            historyByVersion[migration.version];
        if (entry != null) {
          _validateHistoryEntry(entry, migration);
          skipped.add(migration);
          context.completedMigrations++;
          _notify(
            context,
            MigrationProgressStage.skipped,
            migration: migration,
          );
          continue;
        }
        _validateDestructiveOperations(migration);
        _notify(
          context,
          MigrationProgressStage.migrationStarted,
          migration: migration,
        );
        final Stopwatch migrationStopwatch = Stopwatch()..start();
        await _applyMigration(migration, context: context);
        migrationStopwatch.stop();
        _metric(
          'migration',
          migrationStopwatch.elapsed,
          context: context,
          migration: migration,
        );
        applied.add(migration);
        context.completedMigrations++;
        _notify(
          context,
          MigrationProgressStage.migrationCompleted,
          migration: migration,
        );
      }
      final Duration duration = context.stopwatch.elapsed;
      _notify(context, MigrationProgressStage.completed, duration: duration);
      _metric('run', duration, context: context);
      return MigrationRunResult(
        applied: applied,
        skipped: skipped,
        duration: duration,
      );
    } catch (error) {
      final Duration duration = context.stopwatch.elapsed;
      _notify(context, MigrationProgressStage.failed, error: error);
      _metric('run', duration, context: context);
      rethrow;
    } finally {
      context.stopwatch.stop();
    }
  }

  void _validateDestructiveOperations(Migration migration) {
    if (destructivePolicy == MigrationDestructivePolicy.allow) return;
    final int operationIndex = migration.operations.indexWhere(
      (operation) => operation.isDestructive,
    );
    if (operationIndex == -1) return;
    throw MigrationDestructiveOperationException(
      migration: migration,
      operationIndex: operationIndex,
      operation: migration.operations[operationIndex],
    );
  }

  Future<void> _applyMigration(
    Migration migration, {
    required _MigrationRunContext context,
  }) {
    final TransactionalMigrationAdapter? capability = switch (adapter) {
      final TransactionalMigrationAdapter value => value,
      _ => null,
    };
    final MigrationTransactionMode mode = switch (capability) {
      final TransactionalMigrationAdapter value => value.transactionMode,
      null => MigrationTransactionMode.none,
    };

    return switch (mode) {
      MigrationTransactionMode.migration => capability!.transaction<void>(
        () => _applyAndRecord(migration, context: context),
      ),
      MigrationTransactionMode.operation => _applyPerOperation(
        migration,
        capability!,
        context: context,
      ),
      MigrationTransactionMode.none => _applyAndRecord(
        migration,
        context: context,
      ),
    };
  }

  Future<void> _applyPerOperation(
    Migration migration,
    TransactionalMigrationAdapter capability, {
    required _MigrationRunContext context,
  }) async {
    if (migration.operations.isEmpty) {
      await capability.transaction<void>(
        () => adapter.record(
          migration,
          checksum: MigrationChecksum.of(migration),
        ),
      );
      return;
    }

    for (final (index, operation) in migration.operations.indexed) {
      await capability.transaction<void>(() async {
        await _applyOperation(migration, index, operation, context: context);
        if (index == migration.operations.length - 1) {
          await adapter.record(
            migration,
            checksum: MigrationChecksum.of(migration),
          );
        }
      });
    }
  }

  Future<MigrationRunResult> _compactLocked(
    List<Migration> migrations,
    Migration replacement,
    int through,
  ) async {
    final MigrationHistoryCompactionAdapter? compaction = switch (adapter) {
      final MigrationHistoryCompactionAdapter value => value,
      _ => null,
    };
    if (compaction == null) {
      throw const MigrationUnsupportedException(
        'This migration adapter does not support history compaction.',
      );
    }
    final Map<int, MigrationHistoryEntry> history = await _historyByVersion();
    final MigrationHistoryEntry? replacementEntry =
        history[replacement.version];
    if (replacementEntry != null) {
      _validateHistoryEntry(replacementEntry, replacement);
      return MigrationRunResult(applied: const [], skipped: [replacement]);
    }
    for (final Migration migration in migrations) {
      if (migration.version > through) break;
      final MigrationHistoryEntry? entry = history[migration.version];
      if (entry == null) {
        throw MigrationValidationException(
          'Migration ${migration.version} is not applied and cannot be compacted.',
        );
      }
      _validateHistoryEntry(entry, migration);
    }
    final String checksum = MigrationChecksum.of(replacement);
    await compaction.compactHistory(
      replacement,
      through: through,
      checksum: checksum,
    );
    return MigrationRunResult(applied: [replacement], skipped: const []);
  }

  Future<MigrationStatusReport> _statusLocked(
    List<Migration> migrations,
  ) async {
    final Map<int, MigrationHistoryEntry> history = await _historyByVersion();
    final Set<int> knownVersions = migrations
        .map((migration) => migration.version)
        .toSet();
    final List<Migration> pending = [];
    final List<Migration> applied = [];
    final List<Migration> checksumMismatches = [];
    final List<MigrationHistoryEntry> legacyHistory = [];

    for (final Migration migration in migrations) {
      final MigrationHistoryEntry? entry = history[migration.version];
      if (entry == null) {
        pending.add(migration);
      } else if (entry.checksum == null) {
        legacyHistory.add(entry);
      } else if (entry.checksum != MigrationChecksum.of(migration)) {
        checksumMismatches.add(migration);
      } else {
        applied.add(migration);
      }
    }

    final List<MigrationHistoryEntry> unknownApplied = [
      for (final MigrationHistoryEntry entry in history.values)
        if (!knownVersions.contains(entry.version)) entry,
    ];
    return MigrationStatusReport(
      pending: List.unmodifiable(pending),
      applied: List.unmodifiable(applied),
      checksumMismatches: List.unmodifiable(checksumMismatches),
      legacyHistory: List.unmodifiable(legacyHistory),
      unknownApplied: List.unmodifiable(unknownApplied),
    );
  }

  Future<MigrationRunResult> _baselineLocked(
    List<Migration> migrations,
    int through,
  ) async {
    if (!migrations.any((migration) => migration.version == through)) {
      throw MigrationValidationException(
        'Baseline version $through is not present in the source list.',
      );
    }
    final Map<int, MigrationHistoryEntry> history = await _historyByVersion();
    final List<Migration> recorded = [];
    final List<Migration> skipped = [];
    for (final Migration migration in migrations) {
      if (migration.version > through) break;
      final MigrationHistoryEntry? entry = history[migration.version];
      if (entry != null) {
        _validateHistoryEntry(entry, migration);
        skipped.add(migration);
        continue;
      }
      await adapter.record(
        migration,
        checksum: MigrationChecksum.of(migration),
      );
      recorded.add(migration);
    }
    return MigrationRunResult(applied: recorded, skipped: skipped);
  }

  Future<MigrationRunResult> _resolveLocked(
    List<Migration> migrations,
    int version,
  ) async {
    final Migration migration = migrations.firstWhere(
      (value) => value.version == version,
      orElse: () => throw MigrationValidationException(
        'Migration version $version is not present in the source list.',
      ),
    );
    final Map<int, MigrationHistoryEntry> history = await _historyByVersion();
    final MigrationHistoryEntry? entry = history[version];
    final String checksum = MigrationChecksum.of(migration);
    if (entry != null) {
      if (entry.checksum == checksum || entry.checksum == null) {
        if (entry.checksum == checksum) {
          return MigrationRunResult(applied: const [], skipped: [migration]);
        }
      } else {
        throw MigrationValidationException(
          'Migration $version has a different checksum from the recorded history.',
        );
      }
    }
    await adapter.record(migration, checksum: checksum);
    return MigrationRunResult(applied: [migration], skipped: const []);
  }

  Future<Map<int, MigrationHistoryEntry>> _historyByVersion() async {
    final List<MigrationHistoryEntry> history = await adapter
        .appliedMigrations();
    final Map<int, MigrationHistoryEntry> historyByVersion = {};
    for (final MigrationHistoryEntry entry in history) {
      if (historyByVersion.containsKey(entry.version)) {
        throw MigrationValidationException(
          'Migration history contains duplicate version ' +
              entry.version.toString() +
              '.',
        );
      }
      historyByVersion[entry.version] = entry;
    }
    return historyByVersion;
  }

  void _validateHistoryEntry(MigrationHistoryEntry entry, Migration migration) {
    if (entry.checksum == null) {
      throw MigrationValidationException(
        'Migration ${migration.version} has legacy history without a checksum. '
        'Resolve that history before running migrations.',
      );
    }
    final String expected = MigrationChecksum.of(migration);
    if (entry.checksum != expected) {
      throw MigrationValidationException(
        'Migration ${migration.version} has a different checksum from the recorded history.',
      );
    }
  }

  Future<void> _applyAndRecord(
    Migration migration, {
    required _MigrationRunContext context,
  }) async {
    for (final (index, operation) in migration.operations.indexed) {
      await _applyOperation(migration, index, operation, context: context);
    }
    await adapter.record(migration, checksum: MigrationChecksum.of(migration));
  }

  Future<void> _applyOperation(
    Migration migration,
    int operationIndex,
    MigrationOperation operation, {
    required _MigrationRunContext context,
  }) async {
    final Stopwatch stopwatch = Stopwatch()..start();
    _notify(
      context,
      MigrationProgressStage.operationStarted,
      migration: migration,
      operationIndex: operationIndex,
      operation: operation,
    );
    try {
      final MigrationOperationValidator? validator = operationValidator;
      if (validator != null) {
        await validator(migration, operationIndex, operation);
      }
      final DocumentMigrationOperationContextAdapter? operationContext =
          switch (adapter) {
            final DocumentMigrationOperationContextAdapter value => value,
            _ => null,
          };
      if (operationContext == null) {
        await adapter.apply(operation);
      } else {
        await operationContext.withOperation(
          migration,
          operationIndex,
          () => adapter.apply(operation),
        );
      }
      context.completedOperations++;
      final Duration duration = stopwatch.elapsed;
      _notify(
        context,
        MigrationProgressStage.operationCompleted,
        migration: migration,
        operationIndex: operationIndex,
        operation: operation,
      );
      _metric(
        'operation',
        duration,
        context: context,
        migration: migration,
        operationIndex: operationIndex,
        operation: operation,
      );
    } catch (error) {
      _notify(
        context,
        MigrationProgressStage.failed,
        migration: migration,
        operationIndex: operationIndex,
        operation: operation,
        error: error,
      );
      _metric(
        'operation_failed',
        stopwatch.elapsed,
        context: context,
        migration: migration,
        operationIndex: operationIndex,
        operation: operation,
        error: error,
      );
      rethrow;
    } finally {
      stopwatch.stop();
    }
  }

  void _notify(
    _MigrationRunContext context,
    MigrationProgressStage stage, {
    Migration? migration,
    int? operationIndex,
    MigrationOperation? operation,
    Duration? duration,
    Object? error,
  }) {
    final DateTime timestamp = DateTime.now().toUtc();
    final MigrationProgress event = MigrationProgress(
      stage: stage,
      timestamp: timestamp,
      completedMigrations: context.completedMigrations,
      totalMigrations: context.totalMigrations,
      completedOperations: context.completedOperations,
      totalOperations: context.totalOperations,
      elapsed: context.stopwatch.elapsed,
      migration: migration,
      operationIndex: operationIndex,
      operation: operation,
      error: error,
    );
    try {
      onProgress?.call(event);
    } catch (_) {}

    final Map<String, Object?> fields = {
      'completedMigrations': context.completedMigrations,
      'totalMigrations': context.totalMigrations,
      'completedOperations': context.completedOperations,
      'totalOperations': context.totalOperations,
      if (migration != null) 'migrationVersion': migration.version,
      if (migration != null) 'migrationName': migration.name,
      if (operationIndex != null) 'operationIndex': operationIndex,
      if (operation != null) 'operation': operation.runtimeType.toString(),
      if (duration != null) 'durationMicros': duration.inMicroseconds,
      if (error != null) 'error': error.toString(),
    };
    final MigrationLogLevel level = switch (stage) {
      MigrationProgressStage.failed => MigrationLogLevel.error,
      MigrationProgressStage.operationStarted ||
      MigrationProgressStage.migrationStarted ||
      MigrationProgressStage.started => MigrationLogLevel.debug,
      _ => MigrationLogLevel.info,
    };
    try {
      onLog?.call(
        MigrationLogEntry(
          level: level,
          event: stage.name,
          timestamp: timestamp,
          fields: Map.unmodifiable(fields),
        ),
      );
    } catch (_) {}
  }

  void _metric(
    String name,
    Duration duration, {
    required _MigrationRunContext context,
    Migration? migration,
    int? operationIndex,
    MigrationOperation? operation,
    Object? error,
  }) {
    final Map<String, Object?> fields = {
      if (migration != null) 'migrationVersion': migration.version,
      if (migration != null) 'migrationName': migration.name,
      if (operationIndex != null) 'operationIndex': operationIndex,
      if (operation != null) 'operation': operation.runtimeType.toString(),
      if (error != null) 'error': error.toString(),
    };
    try {
      onMetric?.call(
        MigrationMetric(
          name: name,
          duration: duration,
          timestamp: DateTime.now().toUtc(),
          fields: Map.unmodifiable(fields),
        ),
      );
    } catch (_) {}
  }

  void _validate(List<Migration> migrations) {
    final Set<int> versions = {};
    for (final Migration migration in migrations) {
      if (migration.version <= 0) {
        throw MigrationValidationException(
          'Migration versions must be positive: ${migration.version}.',
        );
      }
      if (!versions.add(migration.version)) {
        throw MigrationValidationException(
          'Migration version ${migration.version} is declared more than once.',
        );
      }
      if (migration.name.trim().isEmpty) {
        throw MigrationValidationException(
          'Migration ${migration.version} must have a name.',
        );
      }
    }
  }
}

final class _MigrationRunContext {
  _MigrationRunContext({
    required this.totalMigrations,
    required this.totalOperations,
  });

  final int totalMigrations;
  final int totalOperations;
  final Stopwatch stopwatch = Stopwatch();
  int completedMigrations = 0;
  int completedOperations = 0;
}
