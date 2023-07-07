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

import 'package:rxdart/rxdart.dart';

import 'relationship.dart';

abstract class Merge<T> {
  Stream<T> get stream;
}

/// Represents a merge that listens an [InputValue] and emits its respective
/// [OutputKey] joined with an [OutputValue].
abstract class SingleMerge<InputValue, OutputKey, OutputValue, R>
    implements Merge<Join<OutputKey, OutputValue>?> {
  final Stream<InputValue?> left;
  final Stream<R> Function(InputValue) map;

  late final StreamSubscription<void> _subscription;
  StreamSubscription<void>? _childSubscription;

  final StreamController<Join<OutputKey, OutputValue>?> _controller =
      StreamController.broadcast();

  SingleMerge({required this.left, required this.map}) {
    _subscription = left.listen(
      (leftModel) async {
        await _childSubscription?.cancel();
        if (leftModel == null) {
          _controller.add(null);
          _childSubscription = null;
        } else {
          _childSubscription = map(leftModel).listen(
            (rightModel) {
              _controller.add(parse(leftModel, rightModel));
            },
            onDone: () => _childSubscription?.cancel(),
            onError: (e, s) => _controller.addError(e, s),
          );
        }
      },
      onDone: () async {
        await _subscription.cancel();
        await _controller.close();
      },
      onError: (e, s) => _controller.addError(e, s),
    );
  }

  /// Transforms input values into joins.
  Join<OutputKey, OutputValue>? parse(InputValue leftModel, R rightModel);

  @override
  Stream<Join<OutputKey, OutputValue>?> get stream => _controller.stream;
}

/// Represents a merge that listens many [InputValue]s and emits their
/// respective [OutputKey]s joined with [OutputValue]s.
abstract class BatchMerge<InputValue, OutputKey, OutputValue>
    implements Merge<List<Join<OutputKey, OutputValue>>> {
  final Stream<List<InputValue>> left;

  final StreamController<List<Join<OutputKey, OutputValue>>> _controller =
      StreamController.broadcast();

  late final StreamSubscription<void> _subscription;
  List<StreamSubscription<void>> _childSubscriptions = [];
  List<Join<OutputKey?, OutputValue>?> _snapshots = [];

  BatchMerge({required this.left}) {
    _subscription = left.listen(
      (leftModels) async {
        await Future.wait(_childSubscriptions.map((s) => s.cancel()));

        final List<Stream<Join<OutputKey?, OutputValue>>> streams =
            parse(leftModels);
        _snapshots = List.filled(streams.length, null);
        if (streams.isEmpty) {
          _controller.add([]);
          _childSubscriptions = [];
        } else {
          _childSubscriptions.addAll(List.generate(streams.length, (i) {
            return streams[i].listen(
              (snapshot) {
                _snapshots[i] = snapshot;

                final List<Join<OutputKey, OutputValue>> joins = [];
                for (Join<OutputKey?, OutputValue>? snapshot in _snapshots) {
                  if (snapshot == null) return;

                  final OutputKey? outputKey = snapshot.left;
                  if (outputKey == null) continue;
                  joins.add(Join(left: outputKey, right: snapshot.right));
                }
                _controller.add(joins);
              },
              onDone: () =>
                  Future.wait(_childSubscriptions.map((s) => s.cancel())),
              onError: (e, s) => _controller.addError(e, s),
            );
          }));
        }
      },
      onDone: () async {
        await _subscription.cancel();
        await _controller.close();
      },
      onError: (e, s) => _controller.addError(e, s),
    );
  }

  /// Transforms input values into snapshots.
  List<Stream<Join<OutputKey?, OutputValue>>> parse(List<InputValue> values);

  @override
  Stream<List<Join<OutputKey, OutputValue>>> get stream => _controller.stream;
}

class OneToOneSingleMerge<L, R> extends SingleMerge<L, L, R, R> {
  OneToOneSingleMerge({required super.left, required super.map});

  @override
  Join<L, R> parse(L leftModel, R rightModel) {
    return Join(left: leftModel, right: rightModel);
  }
}

class ManyToOneSingleMerge<R, L> extends SingleMerge<R, L, R, L?> {
  ManyToOneSingleMerge({required super.left, required super.map});

  @override
  Join<L, R>? parse(R leftModel, L? rightModel) {
    return rightModel == null ? null : Join(left: rightModel, right: leftModel);
  }
}

class ManyToManySingleMerge<M, L, R>
    extends SingleMerge<M, M, (L?, R?), (L?, R?)> {
  ManyToManySingleMerge({required super.left, required super.map});

  @override
  Join<M, (L?, R?)>? parse(M leftModel, (L?, R?) rightModel) {
    return Join(left: leftModel, right: rightModel);
  }
}

class OneToOneBatchMerge<L, R> extends BatchMerge<L, L, R> {
  final Stream<R> Function(L) _map;

  OneToOneBatchMerge({
    required super.left,
    required Stream<R> Function(L) map,
  }) : _map = map;

  @override
  List<Stream<Join<L?, R>>> parse(List<L> values) {
    return values
        .map((leftModel) => _map(leftModel)
            .map((rightModel) => Join(left: leftModel, right: rightModel)))
        .toList();
  }
}

class ManyToOneBatchMerge<L, R> extends BatchMerge<R, L, List<R>> {
  final String Function(R) onLeft;
  final Stream<L?> Function(String) onRight;

  ManyToOneBatchMerge({
    required super.left,
    required this.onLeft,
    required this.onRight,
  });

  @override
  List<Stream<Join<L?, List<R>>>> parse(List<R> values) {
    final Map<String, List<R>> groups = {};
    for (R value in values) {
      groups.putIfAbsent(onLeft(value), () => []).add(value);
    }
    return groups.entries
        .map((entry) => onRight(entry.key)
            .map((leftModel) => Join(left: leftModel, right: entry.value)))
        .toList();
  }
}

class ManyToManyBatchMerge<M, L, R> extends BatchMerge<M, M, (L?, R?)> {
  final Stream<L> Function(M) onLeft;
  final Stream<R> Function(M) onRight;

  ManyToManyBatchMerge({
    required super.left,
    required this.onLeft,
    required this.onRight,
  });

  @override
  List<Stream<Join<M?, (L?, R?)>>> parse(List<M> values) {
    return values.map((middleModel) {
      return CombineLatestStream(
        [onLeft, onRight].map((apply) => apply(middleModel)),
        (values) => (values[0] as L?, values[1] as R?),
      ).map((join) => Join(left: middleModel, right: join));
    }).toList();
  }
}
