import 'dart:async';
import 'package:dorm_framework/dorm_framework.dart';
import 'checksum.dart';

/// A record read by a document-oriented migration backend.
final class MigrationDocument {
  const MigrationDocument({required this.key, required this.data});

  final String key;
  final Map<String, Object?> data;
}

/// A page of documents returned in a stable traversal order.
final class MigrationDocumentPage {
  const MigrationDocumentPage({
    required this.documents,
    required this.nextCursor,
  });

  final List<MigrationDocument> documents;
  final String? nextCursor;
}

/// A persisted position for an interrupted document operation.
final class DocumentMigrationCheckpoint {
  const DocumentMigrationCheckpoint({
    required this.id,
    required this.fingerprint,
    required this.cursor,
  });

  final String id;
  final String fingerprint;
  final String cursor;
}

/// Controls page size, throttling, and resumable limits for document work.
final class DocumentMigrationPerformanceOptions {
  const DocumentMigrationPerformanceOptions({
    this.pageSize = 100,
    this.pauseBetweenPages = Duration.zero,
    this.maxPagesPerOperation,
  }) : assert(pageSize > 0),
       assert(maxPagesPerOperation == null || maxPagesPerOperation > 0);

  final int pageSize;
  final Duration pauseBetweenPages;
  final int? maxPagesPerOperation;
}

/// Thrown after a page is checkpointed because an operation reached its limit.
final class DocumentMigrationBatchLimitException implements Exception {
  const DocumentMigrationBatchLimitException({
    required this.pages,
    required this.maxPages,
  });

  final int pages;
  final int maxPages;

  @override
  String toString() =>
      'DocumentMigrationBatchLimitException: processed $pages page(s); '
      'the configured limit is $maxPages.';
}

/// The minimal access required by [DocumentMigrationAdapter].
abstract interface class DocumentMigrationBackend {
  Future<List<MigrationDocument>> read(String entityName);

  Future<void> write(String entityName, MigrationDocument document);

  Future<void> delete(String entityName, String key);

  Future<void> clear(String entityName);

  Future<T> lock<T>(Future<T> Function() action);
}

/// Provides stable, cursor-based pages for large document collections.
abstract interface class DocumentMigrationPagingBackend {
  Future<MigrationDocumentPage> readPage(
    String entityName, {
    required String? cursor,
    required int limit,
  });
}

/// Gives a document adapter the migration and operation currently executing.
abstract interface class DocumentMigrationOperationContextAdapter {
  Future<T> withOperation<T>(
    Migration migration,
    int operationIndex,
    Future<T> Function() action,
  );
}

/// Adds persistent lease support to a document migration backend.
abstract interface class DocumentMigrationLeaseBackend {
  Future<MigrationLease> acquireLease(
    String lockEntity, {
    required Duration ttl,
  });

  Future<void> verifyLease(String lockEntity, MigrationLease lease);

  Future<void> releaseLease(String lockEntity, MigrationLease lease);
}

/// Applies document-oriented migrations.
///
/// Structural field operations are intentionally no-ops because document
/// stores do not need a separate field declaration. Data operations read and
/// write the affected documents. The backend may implement [read] with pages.
class DocumentMigrationAdapter
    implements
        MigrationAdapter,
        MigrationHistoryCompactionAdapter,
        MigrationLeaseAdapter,
        DocumentMigrationOperationContextAdapter {
  DocumentMigrationAdapter(
    this.backend, {
    this.historyEntity = '__dorm_migrations',
    this.lockEntity = '__dorm_migration_lock',
    this.checkpointEntity = '__dorm_migration_checkpoints',
    this.performance = const DocumentMigrationPerformanceOptions(),
    int? pageSize,
    this.leaseDuration = const Duration(minutes: 5),
  }) : pageSize = pageSize ?? performance.pageSize,
       assert(pageSize == null || pageSize > 0);

  final DocumentMigrationBackend backend;
  final String historyEntity;
  final String lockEntity;
  final String checkpointEntity;
  final int pageSize;
  final DocumentMigrationPerformanceOptions performance;
  final Duration leaseDuration;
  MigrationLease? _activeLease;
  _DocumentMigrationOperationContext? _operationContext;

  @override
  MigrationLockMode get lockMode => switch (backend) {
    DocumentMigrationLeaseBackend() => MigrationLockMode.persistentLease,
    _ => MigrationLockMode.local,
  };

  @override
  Future<T> withLease<T>(
    Future<T> Function(MigrationLease lease) action,
  ) async {
    final DocumentMigrationLeaseBackend leaseBackend = switch (backend) {
      final DocumentMigrationLeaseBackend value => value,
      _ => throw const MigrationLeaseException(
        'This document backend does not provide persistent leases.',
      ),
    };
    final MigrationLease lease = await leaseBackend.acquireLease(
      lockEntity,
      ttl: leaseDuration,
    );
    _activeLease = lease;
    final int renewalMilliseconds = leaseDuration.inMilliseconds ~/ 3;
    final Timer renewalTimer = Timer.periodic(
      Duration(milliseconds: renewalMilliseconds < 1 ? 1 : renewalMilliseconds),
      (_) => unawaited(_renew(lease)),
    );
    try {
      await _verifyActiveLease();
      final T result = await action(lease);
      await _verifyActiveLease();
      return result;
    } finally {
      renewalTimer.cancel();
      _activeLease = null;
      await lease.release();
    }
  }

  @override
  Future<T> withOperation<T>(
    Migration migration,
    int operationIndex,
    Future<T> Function() action,
  ) async {
    final _DocumentMigrationOperationContext? previous = _operationContext;
    _operationContext = _DocumentMigrationOperationContext(
      migrationVersion: migration.version,
      operationIndex: operationIndex,
      fingerprint: MigrationChecksum.of(migration),
    );
    try {
      return await action();
    } finally {
      _operationContext = previous;
    }
  }

  Future<void> _renew(MigrationLease lease) async {
    try {
      await lease.renew();
    } catch (_) {
      // The next provider operation verifies the fencing token and reports
      // the lease failure through the normal migration error path.
    }
  }

  Future<void> _verifyActiveLease() async {
    final MigrationLease? lease = _activeLease;
    if (lease == null) return;
    final DocumentMigrationLeaseBackend leaseBackend = switch (backend) {
      final DocumentMigrationLeaseBackend value => value,
      _ => throw const MigrationLeaseException(
        'The active document lease backend is unavailable.',
      ),
    };
    await leaseBackend.verifyLease(lockEntity, lease);
  }

  @override
  Future<List<MigrationHistoryEntry>> appliedMigrations() async {
    await _verifyActiveLease();
    final List<MigrationDocument> documents = await backend.read(historyEntity);
    return [
      for (final MigrationDocument document in documents)
        if (int.tryParse('${document.data['version'] ?? document.key}')
            case final int version)
          MigrationHistoryEntry(
            version: version,
            name: '${document.data['name'] ?? ''}',
            checksum: document.data['checksum']?.toString(),
          ),
    ];
  }

  @override
  Future<T> lock<T>(Future<T> Function() action) => backend.lock(action);

  @override
  Future<void> compactHistory(
    Migration migration, {
    required int through,
    required String checksum,
  }) async {
    await _verifyActiveLease();
    final List<MigrationDocument> documents = await backend.read(historyEntity);
    for (final MigrationDocument document in documents) {
      final int? version = int.tryParse(
        '${document.data['version'] ?? document.key}',
      );
      if (version != null && version <= through) {
        await _verifyActiveLease();
        await backend.delete(historyEntity, document.key);
      }
    }
    await record(migration, checksum: checksum);
  }

  @override
  Future<void> apply(MigrationOperation operation) async {
    await _verifyActiveLease();
    switch (operation) {
      case CreateEntityOperation():
      case AddFieldOperation():
      case AlterFieldOperation():
        return;
      case ProviderMigrationOperation():
      case CreateSequenceOperation():
      case DropSequenceOperation():
      case CreateTriggerOperation():
      case DropTriggerOperation():
      case CreateViewOperation():
      case DropViewOperation():
      case CreateCheckConstraintOperation():
      case DropCheckConstraintOperation():
      case CreateIndexOperation():
      case DropIndexOperation():
      case CreateUniqueConstraintOperation():
      case DropUniqueConstraintOperation():
      case CreateForeignKeyOperation():
      case DropForeignKeyOperation():
        throw const MigrationUnsupportedException(
          'Document stores do not support provider-specific schema operations through the portable migration adapter.',
        );
      case DropEntityOperation():
        await _clear(operation);
      case RemoveFieldOperation():
        await _update(operation, (data) {
          data.remove(operation.field);
        });
      case RenameFieldOperation():
        await _update(operation, (data) {
          if (data.containsKey(operation.from)) {
            data[operation.to] = data.remove(operation.from);
          }
        });
      case BackfillFieldOperation():
        await _update(operation, (data) {
          if (!operation.onlyMissing ||
              !data.containsKey(operation.field) ||
              data[operation.field] == null) {
            data[operation.field] = operation.value;
          }
        }, pageSize: operation.batchSize);
      case CopyFieldOperation():
        await _update(operation, (data) {
          if (data.containsKey(operation.from) &&
              (!operation.onlyMissing ||
                  !data.containsKey(operation.to) ||
                  data[operation.to] == null)) {
            data[operation.to] = data[operation.from];
          }
        }, pageSize: operation.batchSize);
      case RemoveFieldValueOperation():
        await _update(operation, (data) {
          data[operation.field] = null;
        }, pageSize: operation.batchSize);
      case TransformFieldOperation():
        await _update(operation, (data) {
          if (!_matches(operation.filter, data)) return;
          if (operation.onlyMissing && data[operation.field] != null) return;
          data[operation.field] = _transform(operation.transform, data);
        }, pageSize: operation.batchSize);
    }
  }

  @override
  Future<void> record(Migration migration, {required String checksum}) async {
    await _verifyActiveLease();
    await backend.write(
      historyEntity,
      MigrationDocument(
        key: '${migration.version}',
        data: {
          'version': migration.version,
          'name': migration.name,
          'checksum': checksum,
        },
      ),
    );
  }

  Future<void> _clear(DropEntityOperation operation) async {
    final _DocumentMigrationOperationContext? context = _operationContext;
    final String? checkpointId = context?.id;
    String? cursor;
    int pages = 0;

    if (checkpointId != null) {
      final DocumentMigrationCheckpoint? checkpoint = await _readCheckpoint(
        checkpointId,
      );
      if (checkpoint != null) {
        if (checkpoint.fingerprint == context!.fingerprint) {
          cursor = checkpoint.cursor;
        } else {
          await _clearCheckpoint(checkpointId);
        }
      }
    }

    while (true) {
      final MigrationDocumentPage page = await _readPage(
        operation.entityName,
        cursor: cursor,
      );
      if (page.documents.isEmpty) {
        if (page.nextCursor != null) {
          throw StateError(
            'Document migration paging returned a cursor without documents.',
          );
        }
        if (checkpointId != null) await _clearCheckpoint(checkpointId);
        return;
      }

      for (final MigrationDocument document in page.documents) {
        await _verifyActiveLease();
        await backend.delete(operation.entityName, document.key);
      }

      pages++;
      final String? nextCursor = page.nextCursor;
      if (nextCursor == null) {
        if (checkpointId != null) await _clearCheckpoint(checkpointId);
        return;
      }
      if (nextCursor == cursor) {
        throw StateError(
          'Document migration paging did not advance its cursor.',
        );
      }
      if (context != null) {
        await _writeCheckpoint(
          DocumentMigrationCheckpoint(
            id: context.id,
            fingerprint: context.fingerprint,
            cursor: nextCursor,
          ),
        );
      }
      if (performance.maxPagesPerOperation case final int maxPages
          when pages >= maxPages) {
        throw DocumentMigrationBatchLimitException(
          pages: pages,
          maxPages: maxPages,
        );
      }
      await _pauseBetweenPages();
      cursor = nextCursor;
    }
  }

  bool _matches(FilterExpression expression, Map<String, Object?> data) {
    return switch (expression) {
      EmptyFilterExpression() => true,
      ValueFilterExpression(:final field, :final value) => data[field] == value,
      TextFilterExpression(:final field, :final prefix) =>
        data[field] is String && (data[field] as String).startsWith(prefix),
      DateFilterExpression(:final field, :final value, :final unit) =>
        _datePart(data[field], unit) == _datePart(value, unit),
      RangeFilterExpression(:final field, :final range) => _inRange(
        data[field],
        range,
      ),
      ComparisonFilterExpression(:final field, :final operator, :final value) =>
        _compare(data[field], operator, value),
      SetFilterExpression(:final field, :final values, :final negated) =>
        negated
            ? !values.any((value) => data[field] == value)
            : values.any((value) => data[field] == value),
      NullFilterExpression(:final field, :final isNull) =>
        (data[field] == null) == isNull,
      ContainsFilterExpression(:final field, :final value) =>
        data[field] is Iterable && (data[field] as Iterable).contains(value),
      ContainsAnyFilterExpression(:final field, :final values) =>
        data[field] is Iterable &&
            values.any((value) => (data[field] as Iterable).contains(value)),
      AllFilterExpression(:final filters) => filters.every(
        (filter) => _matches(filter, data),
      ),
      AnyFilterExpression(:final filters) => filters.any(
        (filter) => _matches(filter, data),
      ),
      NotFilterExpression(:final filter) => !_matches(filter, data),
    };
  }

  bool _compare(
    Object? left,
    FilterComparisonOperator operator,
    Object? right,
  ) {
    if (left == null || right == null) return false;
    final int? result = switch ((left, right)) {
      (num left, num right) => left.compareTo(right),
      (DateTime left, DateTime right) => left.compareTo(right),
      (String left, String right) => left.compareTo(right),
      _ => null,
    };
    if (result == null) return false;
    return switch (operator) {
      FilterComparisonOperator.notEqual => result != 0,
      FilterComparisonOperator.lessThan => result < 0,
      FilterComparisonOperator.lessThanOrEqual => result <= 0,
      FilterComparisonOperator.greaterThan => result > 0,
      FilterComparisonOperator.greaterThanOrEqual => result >= 0,
    };
  }

  bool _inRange(Object? value, FilterRange<dynamic> range) {
    if (value == null) return false;
    if (range.from != null &&
        !_compare(
          value,
          FilterComparisonOperator.greaterThanOrEqual,
          range.from,
        )) {
      return false;
    }
    if (range.to != null &&
        !_compare(value, FilterComparisonOperator.lessThanOrEqual, range.to)) {
      return false;
    }
    return true;
  }

  int _datePart(Object? value, DateFilterUnit unit) {
    final DateTime? date = switch (value) {
      DateTime value => value,
      String value => DateTime.tryParse(value),
      _ => null,
    };
    return date == null ? -1 : unit.access(date);
  }

  Object? _transform(
    MigrationValueTransform transform,
    Map<String, Object?> data,
  ) {
    return switch (transform) {
      CopyMigrationValue(:final sourceField) => data[sourceField],
      TextMigrationValue(:final sourceField, :final operation) =>
        switch (data[sourceField]) {
          null => null,
          String value => switch (operation) {
            MigrationTextTransform.trim => value.trim(),
            MigrationTextTransform.lowerCase => value.toLowerCase(),
            MigrationTextTransform.upperCase => value.toUpperCase(),
          },
          Object value => throw FormatException(
            'Expected text in $sourceField, got ${value.runtimeType}.',
          ),
        },
      ConvertMigrationValue(:final sourceField, :final outputType) => _convert(
        data[sourceField],
        outputType,
        sourceField,
      ),
    };
  }

  Object? _convert(Object? value, MigrationValueType type, String field) {
    if (value == null) return null;
    return switch (type) {
      MigrationValueType.text => '$value',
      MigrationValueType.integer => switch (value) {
        int value => value,
        num value => value.toInt(),
        String value =>
          int.tryParse(value) ??
              (throw FormatException('Cannot convert $field to integer.')),
        _ => throw FormatException('Cannot convert $field to integer.'),
      },
      MigrationValueType.real => switch (value) {
        num value => value.toDouble(),
        String value =>
          double.tryParse(value) ??
              (throw FormatException('Cannot convert $field to real.')),
        _ => throw FormatException('Cannot convert $field to real.'),
      },
      MigrationValueType.boolean => switch (value) {
        bool value => value,
        String value when value.toLowerCase() == 'true' || value == '1' => true,
        String value when value.toLowerCase() == 'false' || value == '0' =>
          false,
        _ => throw FormatException('Cannot convert $field to boolean.'),
      },
      MigrationValueType.dateTime => switch (value) {
        DateTime value => value,
        String value =>
          DateTime.tryParse(value) ??
              (throw FormatException('Cannot convert $field to dateTime.')),
        _ => throw FormatException('Cannot convert $field to dateTime.'),
      },
      MigrationValueType.json =>
        value is Map || value is Iterable
            ? value
            : throw FormatException('Cannot convert $field to json.'),
      MigrationValueType.binary => value,
    };
  }

  Future<void> _update(
    MigrationOperation operation,
    void Function(Map<String, Object?> data) update, {
    int? pageSize,
  }) async {
    final _DocumentMigrationOperationContext? context = _operationContext;
    if (context == null) {
      await _updateDocuments(operation.entityName, update);
      return;
    }

    final String checkpointId = context.id;
    final DocumentMigrationCheckpoint? checkpoint = await _readCheckpoint(
      checkpointId,
    );
    String? cursor;
    int pages = 0;
    if (checkpoint != null) {
      if (checkpoint.fingerprint == context.fingerprint) {
        cursor = checkpoint.cursor;
      } else {
        await _clearCheckpoint(checkpointId);
      }
    }

    while (true) {
      final MigrationDocumentPage page = await _readPage(
        operation.entityName,
        cursor: cursor,
        pageSize: pageSize,
      );
      if (page.documents.isEmpty) {
        if (page.nextCursor != null) {
          throw StateError(
            'Document migration paging returned a cursor without documents.',
          );
        }
        await _clearCheckpoint(checkpointId);
        return;
      }

      for (final MigrationDocument document in page.documents) {
        final Map<String, Object?> data = Map.of(document.data);
        update(data);
        await _verifyActiveLease();
        await backend.write(
          operation.entityName,
          MigrationDocument(key: document.key, data: data),
        );
      }

      pages++;
      final String? nextCursor = page.nextCursor;
      if (nextCursor == null) {
        await _clearCheckpoint(checkpointId);
        return;
      }
      if (nextCursor == cursor) {
        throw StateError(
          'Document migration paging did not advance its cursor.',
        );
      }
      await _writeCheckpoint(
        DocumentMigrationCheckpoint(
          id: checkpointId,
          fingerprint: context.fingerprint,
          cursor: nextCursor,
        ),
      );
      if (performance.maxPagesPerOperation case final int maxPages
          when pages >= maxPages) {
        throw DocumentMigrationBatchLimitException(
          pages: pages,
          maxPages: maxPages,
        );
      }
      await _pauseBetweenPages();
      cursor = nextCursor;
    }
  }

  Future<void> _pauseBetweenPages() async {
    final Duration pause = performance.pauseBetweenPages;
    if (pause > Duration.zero) {
      await Future<void>.delayed(pause);
    }
  }

  Future<void> _updateDocuments(
    String entityName,
    void Function(Map<String, Object?> data) update,
  ) async {
    await _verifyActiveLease();
    final List<MigrationDocument> documents = await backend.read(entityName);
    for (final MigrationDocument document in documents) {
      final Map<String, Object?> data = Map.of(document.data);
      update(data);
      await _verifyActiveLease();
      await backend.write(
        entityName,
        MigrationDocument(key: document.key, data: data),
      );
    }
  }

  Future<MigrationDocumentPage> _readPage(
    String entityName, {
    required String? cursor,
    int? pageSize,
  }) async {
    await _verifyActiveLease();
    final DocumentMigrationPagingBackend? paging = switch (backend) {
      final DocumentMigrationPagingBackend value => value,
      _ => null,
    };
    if (paging == null) {
      return MigrationDocumentPage(
        documents: await backend.read(entityName),
        nextCursor: null,
      );
    }
    return paging.readPage(
      entityName,
      cursor: cursor,
      limit: pageSize ?? this.pageSize,
    );
  }

  Future<DocumentMigrationCheckpoint?> _readCheckpoint(String id) async {
    await _verifyActiveLease();
    final List<MigrationDocument> documents = await backend.read(
      checkpointEntity,
    );
    for (final MigrationDocument document in documents) {
      if (document.key != id) continue;
      final String? fingerprint = document.data['fingerprint']?.toString();
      final String? cursor = document.data['cursor']?.toString();
      if (fingerprint == null || cursor == null) return null;
      return DocumentMigrationCheckpoint(
        id: id,
        fingerprint: fingerprint,
        cursor: cursor,
      );
    }
    return null;
  }

  Future<void> _writeCheckpoint(DocumentMigrationCheckpoint checkpoint) async {
    await _verifyActiveLease();
    await backend.write(
      checkpointEntity,
      MigrationDocument(
        key: checkpoint.id,
        data: {
          'fingerprint': checkpoint.fingerprint,
          'cursor': checkpoint.cursor,
        },
      ),
    );
  }

  Future<void> _clearCheckpoint(String id) async {
    await _verifyActiveLease();
    await backend.delete(checkpointEntity, id);
  }
}

final class _DocumentMigrationOperationContext {
  const _DocumentMigrationOperationContext({
    required this.migrationVersion,
    required this.operationIndex,
    required this.fingerprint,
  });

  final int migrationVersion;
  final int operationIndex;
  final String fingerprint;

  String get id => '$migrationVersion-$operationIndex';
}
