// dORM
// Copyright (C) 2023  Beet Software
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

import 'dart:async';

import 'package:dorm_framework/dorm_framework.dart';

import 'target.dart';

/// Applies one materialized change set to a replica target.
typedef SyncOperationApplier =
    Future<void> Function(SyncApplyTarget target, MutationChangeSet changeSet);

/// Resolves an operation into an applier after an outbox rehydrates it.
typedef SyncOperationResolver = SyncOperationApplier Function(String entityKey);

/// A synchronization operation waiting for one or more replicas.
class SyncOperation {
  /// Creates a synchronization operation.
  SyncOperation({
    required this.changeSet,
    required this.replicaIds,
    this.apply,
    String? entityKey,
  }) : entityKey = entityKey ?? changeSet.tableName;

  /// Exact primary mutation to deliver.
  final MutationChangeSet changeSet;

  /// Stable entity key used to rehydrate [apply].
  final String entityKey;

  /// Type-safe operation that applies the change set to a target.
  ///
  /// An in-memory outbox keeps this callback directly. A durable outbox may
  /// persist [toJson] and return an operation without [apply]; the coordinator
  /// then uses its [SyncOperationResolver].
  final SyncOperationApplier? apply;

  /// Replica identifiers that must receive the operation.
  final List<String> replicaIds;

  /// Converts this operation to JSON-compatible data.
  Map<String, Object?> toJson() => {
    'changeSet': changeSet.toJson(),
    'entityKey': entityKey,
    'replicaIds': replicaIds,
  };

  /// Rebuilds an operation from JSON-compatible data.
  factory SyncOperation.fromJson(
    Map<String, Object?> json, {
    SyncOperationApplier? apply,
  }) => SyncOperation(
    changeSet: MutationChangeSet.fromJson(
      Map<String, Object?>.from(json['changeSet']! as Map),
    ),
    entityKey: json['entityKey']! as String,
    replicaIds: List<String>.from(json['replicaIds']! as List<Object?>),
    apply: apply,
  );
}

/// A pending delivery for one operation and one replica.
class SyncDelivery {
  /// Creates a pending delivery.
  const SyncDelivery({
    required this.operation,
    required this.replicaId,
    this.attempts = 0,
    this.lastError,
    this.lastStackTrace,
  });

  /// Operation to deliver.
  final SyncOperation operation;

  /// Target replica.
  final String replicaId;

  /// Number of failed delivery attempts.
  final int attempts;

  /// Last delivery error, if any.
  final Object? lastError;

  /// Stack trace from the last failed delivery, if any.
  final StackTrace? lastStackTrace;
}

/// Reports a failed replica delivery.
class SyncFailure {
  /// Creates a synchronization failure.
  const SyncFailure({
    required this.delivery,
    required this.error,
    required this.stackTrace,
    this.terminal = false,
  });

  /// Failed delivery.
  final SyncDelivery delivery;

  /// Error thrown by the replica.
  final Object error;

  /// Stack trace captured from the replica failure.
  final StackTrace stackTrace;

  /// Whether the delivery was moved out of the retryable pending queue.
  final bool terminal;
}

/// Stores pending synchronization deliveries.
///
/// Implementations must make enqueue and acknowledge safe to retry. A
/// durable implementation owns persistence of operation payloads, delivery
/// state, attempt counts, and dead letters.
abstract interface class SyncOutbox {
  /// Adds an operation and creates one pending delivery per replica.
  Future<void> enqueue(SyncOperation operation);

  /// Lists deliveries that still need acknowledgement.
  Future<List<SyncDelivery>> pending();

  /// Lists deliveries moved to the dead-letter queue.
  Future<List<SyncDelivery>> deadLetters();

  /// Marks one operation/replica delivery as complete.
  Future<void> acknowledge(String operationId, String replicaId);

  /// Keeps a delivery pending and records its failure.
  Future<void> fail(
    SyncDelivery delivery,
    Object error, {
    StackTrace stackTrace,
  });

  /// Removes a delivery from automatic retries after a terminal failure.
  Future<void> deadLetter(
    SyncDelivery delivery,
    Object error, {
    StackTrace stackTrace,
  });

  /// Emits every delivery failure.
  Stream<SyncFailure> get failures;

  /// Releases resources owned by this outbox.
  Future<void> close() async {}
}

/// An in-memory outbox suitable for tests and process-local applications.
///
/// Pending deliveries are lost when the process ends.
class MemorySyncOutbox implements SyncOutbox {
  final Map<String, SyncOperation> _operations = {};
  final Map<String, Map<String, SyncDelivery>> _deliveries = {};
  final Map<String, List<SyncDelivery>> _deadLetters = {};
  final StreamController<SyncFailure> _failures =
      StreamController<SyncFailure>.broadcast();

  @override
  Future<void> enqueue(SyncOperation operation) async {
    if (operation.replicaIds.isEmpty ||
        _operations.containsKey(operation.changeSet.operationId)) {
      return;
    }
    _operations[operation.changeSet.operationId] = operation;
    _deliveries[operation.changeSet.operationId] = {
      for (final String replicaId in operation.replicaIds)
        replicaId: SyncDelivery(operation: operation, replicaId: replicaId),
    };
  }

  @override
  Future<List<SyncDelivery>> pending() async => [
    for (final Map<String, SyncDelivery> deliveries in _deliveries.values)
      ...deliveries.values,
  ];

  @override
  Future<List<SyncDelivery>> deadLetters() async => [
    for (final List<SyncDelivery> deliveries in _deadLetters.values)
      ...deliveries,
  ];

  @override
  Future<void> acknowledge(String operationId, String replicaId) async {
    final Map<String, SyncDelivery>? deliveries = _deliveries[operationId];
    deliveries?.remove(replicaId);
    if (deliveries != null &&
        deliveries.isEmpty &&
        !_deadLetters.containsKey(operationId)) {
      _deliveries.remove(operationId);
      _operations.remove(operationId);
    }
  }

  @override
  Future<void> fail(
    SyncDelivery delivery,
    Object error, {
    StackTrace stackTrace = StackTrace.empty,
  }) async {
    final Map<String, SyncDelivery>? deliveries =
        _deliveries[delivery.operation.changeSet.operationId];
    if (deliveries == null) return;
    final SyncDelivery updated = _updatedDelivery(delivery, error, stackTrace);
    deliveries[delivery.replicaId] = updated;
    _failures.add(
      SyncFailure(delivery: updated, error: error, stackTrace: stackTrace),
    );
  }

  @override
  Future<void> deadLetter(
    SyncDelivery delivery,
    Object error, {
    StackTrace stackTrace = StackTrace.empty,
  }) async {
    final String operationId = delivery.operation.changeSet.operationId;
    final Map<String, SyncDelivery>? deliveries = _deliveries[operationId];
    if (deliveries == null) return;
    final SyncDelivery updated = _updatedDelivery(delivery, error, stackTrace);
    deliveries.remove(delivery.replicaId);
    _deadLetters.putIfAbsent(operationId, () => []).add(updated);
    _failures.add(
      SyncFailure(
        delivery: updated,
        error: error,
        stackTrace: stackTrace,
        terminal: true,
      ),
    );
    if (deliveries.isEmpty) _deliveries.remove(operationId);
  }

  SyncDelivery _updatedDelivery(
    SyncDelivery delivery,
    Object error,
    StackTrace stackTrace,
  ) => SyncDelivery(
    operation: delivery.operation,
    replicaId: delivery.replicaId,
    attempts: delivery.attempts + 1,
    lastError: error,
    lastStackTrace: stackTrace,
  );

  @override
  Stream<SyncFailure> get failures => _failures.stream;

  /// Releases resources used by the failure stream.
  @override
  Future<void> close() => _failures.close();
}
