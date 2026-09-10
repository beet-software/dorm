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

import 'outbox.dart';
import 'relationship.dart';
import 'reference.dart';
import 'target.dart';

/// Decides whether a finite primary-read failure may use a replica.
typedef SyncFallbackPolicy = bool Function(Object error, StackTrace stackTrace);

/// Coordinates primary mutations and ordered replica delivery.
class SyncCoordinator {
  /// Creates a synchronization coordinator.
  SyncCoordinator({
    required this.primary,
    required Iterable<SyncReadApplyTarget> replicas,
    required this.outbox,
    this.resolver,
    this.maxAttempts,
  }) : replicas = List<SyncReadApplyTarget>.unmodifiable(replicas),
       _targets = {
         for (final SyncReadApplyTarget target in [primary, ...replicas])
           target.id: target,
       } {
    if (maxAttempts != null && maxAttempts! < 1) {
      throw ArgumentError.value(
        maxAttempts,
        'maxAttempts',
        'Must be greater than zero.',
      );
    }
  }

  /// The source-of-truth target.
  final SyncMutationTarget primary;

  /// Replica targets in delivery and fallback order.
  final List<SyncReadApplyTarget> replicas;

  /// Durable or in-memory delivery store.
  final SyncOutbox outbox;

  /// Rebuilds appliers for operations restored without callbacks.
  final SyncOperationResolver? resolver;

  /// Maximum attempts before a delivery is moved to dead letters.
  final int? maxAttempts;

  final Map<String, SyncReadApplyTarget> _targets;
  Future<void> _tail = Future<void>.value();
  bool _closed = false;

  /// Registers a primary change and schedules replica delivery.
  Future<void> enqueue(
    SyncOperationApplier apply,
    MutationChangeSet changeSet,
  ) async {
    if (_closed) {
      throw StateError('Synchronization coordinator is closed.');
    }
    if (replicas.isEmpty) return;
    final SyncOperation operation = SyncOperation(
      changeSet: changeSet,
      apply: apply,
      replicaIds: [
        for (final SyncReadApplyTarget target in replicas) target.id,
      ],
    );
    await outbox.enqueue(operation);
    _tail = _tail.then((_) => _deliver(operation));
    unawaited(_tail.catchError((Object _) {}));
  }

  /// Waits for deliveries already scheduled by this coordinator.
  Future<void> flush() => _tail;

  /// Retries pending deliveries, optionally restricted by operation or replica.
  Future<void> retry({
    Iterable<String>? operationIds,
    Iterable<String>? replicaIds,
  }) async {
    await _tail;
    final Set<String>? selectedOperations = operationIds == null
        ? null
        : operationIds.toSet();
    final Set<String>? selectedReplicas = replicaIds == null
        ? null
        : replicaIds.toSet();
    final List<SyncDelivery> pending = [
      for (final SyncDelivery delivery in await outbox.pending())
        if ((selectedOperations == null ||
                selectedOperations.contains(
                  delivery.operation.changeSet.operationId,
                )) &&
            (selectedReplicas == null ||
                selectedReplicas.contains(delivery.replicaId)))
          delivery,
    ];
    final Map<String, List<SyncDelivery>> byOperation = {};
    for (final SyncDelivery delivery in pending) {
      byOperation
          .putIfAbsent(delivery.operation.changeSet.operationId, () => [])
          .add(delivery);
    }
    final List<List<SyncDelivery>> batches = byOperation.values.toList()
      ..sort(
        (left, right) => left.first.operation.changeSet.sequence.compareTo(
          right.first.operation.changeSet.sequence,
        ),
      );
    for (final List<SyncDelivery> batch in batches) {
      await _deliver(batch.first.operation);
    }
  }

  /// Stops scheduling work and closes the outbox.
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    await _tail;
    await outbox.close();
  }

  Future<void> _deliver(SyncOperation operation) async {
    final List<SyncDelivery> pending = await outbox.pending();
    for (final SyncDelivery delivery in pending.where(
      (delivery) =>
          delivery.operation.changeSet.operationId ==
          operation.changeSet.operationId,
    )) {
      final bool blockedByEarlierOperation = pending.any(
        (other) =>
            other.replicaId == delivery.replicaId &&
            other.operation.changeSet.sequence < operation.changeSet.sequence,
      );
      if (blockedByEarlierOperation) continue;
      final SyncReadApplyTarget? target = _targets[delivery.replicaId];
      if (target == null) {
        await outbox.fail(
          delivery,
          StateError('Unknown replica ${delivery.replicaId}.'),
        );
        continue;
      }
      try {
        final SyncOperationApplier? apply =
            operation.apply ?? resolver?.call(operation.entityKey);
        if (apply == null) {
          throw StateError(
            'No operation resolver is registered for ${operation.entityKey}.',
          );
        }
        await apply(target, operation.changeSet);
        await outbox.acknowledge(
          operation.changeSet.operationId,
          delivery.replicaId,
        );
      } catch (error, stackTrace) {
        final int nextAttempt = delivery.attempts + 1;
        if (maxAttempts != null && nextAttempt >= maxAttempts!) {
          await outbox.deadLetter(delivery, error, stackTrace: stackTrace);
        } else {
          await outbox.fail(delivery, error, stackTrace: stackTrace);
        }
      }
    }
  }
}

/// A dORM engine that writes to one primary and asynchronously replicates to
///
/// The primary is authoritative. Replica failures do not fail an already
/// successful primary mutation; they remain visible through the outbox.
///
/// This engine deliberately does not implement distributed transactions.
/// zero or more targets.
///
/// Reads use the primary. Finite reads may use a replica only when [fallback]
/// classifies the primary error as an availability failure. Streams never
/// fall back. Replica delivery is at-least-once and is not a distributed
/// transaction.
class SynchronizedEngine<Q extends BaseQuery<Q>, P extends PageRequest>
    implements BaseEngine<Q, P> {
  /// Creates a synchronized engine from already-adapted targets.
  SynchronizedEngine({
    required SyncMutationTarget primary,
    required Iterable<SyncReadApplyTarget> replicas,
    required SyncOutbox outbox,
    required SyncFallbackPolicy fallback,
    SyncOperationResolver? resolver,
    int? maxAttempts,
  }) : _coordinator = SyncCoordinator(
         primary: primary,
         replicas: replicas,
         outbox: outbox,
         resolver: resolver,
         maxAttempts: maxAttempts,
       ),
       _fallback = fallback {
    final Set<String> ids = {
      _coordinator.primary.id,
      ..._coordinator.replicas.map((target) => target.id),
    };
    if (ids.length != _coordinator.replicas.length + 1) {
      throw ArgumentError.value(
        replicas,
        'replicas',
        'Target IDs must be unique.',
      );
    }
  }

  final SyncCoordinator _coordinator;
  final SyncFallbackPolicy _fallback;

  /// The shared synchronization coordinator.
  SyncCoordinator get coordinator => _coordinator;

  /// Retries pending replica deliveries.
  Future<void> retry({
    Iterable<String>? operationIds,
    Iterable<String>? replicaIds,
  }) => _coordinator.retry(operationIds: operationIds, replicaIds: replicaIds);

  /// Waits for all deliveries currently scheduled.
  Future<void> flush() => _coordinator.flush();

  /// Closes the coordinator and its outbox.
  Future<void> close() => _coordinator.close();

  @override
  BaseReference<Q, P> createReference() => SynchronizedReference<Q, P>(
    coordinator: _coordinator,
    fallback: _fallback,
  );

  @override
  BaseRelationship<Q> createRelationship() => PortableRelationship<Q>();
}
