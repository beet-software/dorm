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

import 'relationship.dart';

abstract class Merge {}

class ForwardLinkMerge<L, R> implements Merge {
  final StreamController<Join<L, R>?> _controller =
      StreamController.broadcast();

  late final StreamSubscription<void> _subscription;
  StreamSubscription<void>? _childSubscription;

  ForwardLinkMerge({
    required Stream<L?> left,
    required Stream<R> Function(L) map,
  }) {
    _subscription = left.listen(
      (leftModel) async {
        await _childSubscription?.cancel();
        if (leftModel == null) {
          _controller.add(null);
          _childSubscription = null;
        } else {
          _childSubscription = map(leftModel).listen(
            (rightModel) {
              _controller.add(Join(left: leftModel, right: rightModel));
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

  Stream<Join<L, R>?> get stream => _controller.stream;
}

class BackwardLinkMerge<R, L> implements Merge {
  final StreamController<Join<L, R>?> _controller =
      StreamController.broadcast();

  late final StreamSubscription<void> _subscription;
  StreamSubscription<void>? _childSubscription;

  BackwardLinkMerge({
    required Stream<R?> left,
    required Stream<L?> Function(R) map,
  }) {
    _subscription = left.listen(
      (leftModel) async {
        await _childSubscription?.cancel();
        if (leftModel == null) {
          _controller.add(null);
          _childSubscription = null;
        } else {
          _childSubscription = map(leftModel).listen(
            (rightModel) {
              _controller.add(rightModel == null
                  ? null
                  : Join(left: rightModel, right: leftModel));
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

  Stream<Join<L, R>?> get stream => _controller.stream;
}

class ExpandMerge<L, R> implements Merge {
  final StreamController<List<Join<L, R>>> _controller =
      StreamController.broadcast();

  late final StreamSubscription<void> _subscription;
  List<StreamSubscription<void>> _childSubscriptions = [];

  List<Join<L, R>?> _snapshots = [];

  ExpandMerge({
    required Stream<List<L>> left,
    required Stream<R> Function(L) map,
  }) {
    _subscription = left.listen(
      (leftModels) async {
        await Future.wait(_childSubscriptions.map((s) => s.cancel()));
        _snapshots = List.filled(leftModels.length, null);

        if (leftModels.isEmpty) {
          _controller.add([]);
          _childSubscriptions = [];
        } else {
          for (int i = 0; i < leftModels.length; i++) {
            final L leftModel = leftModels[i];
            _childSubscriptions.add(map(leftModel).listen(
              (rightModel) {
                _snapshots[i] = Join(left: leftModel, right: rightModel);
                _checkSnapshots();
              },
              onDone: () =>
                  Future.wait(_childSubscriptions.map((s) => s.cancel())),
              onError: (e, s) => _controller.addError(e, s),
            ));
          }
        }
      },
      onDone: () async {
        await _subscription.cancel();
        await _controller.close();
      },
      onError: (e, s) => _controller.addError(e, s),
    );
  }

  void _checkSnapshots() {
    final List<Join<L, R>> joins = [];
    for (Join<L, R>? join in _snapshots) {
      if (join == null) return;
      joins.add(join);
    }
    _controller.add(joins);
  }

  Stream<List<Join<L, R>>> get stream => _controller.stream;
}

class CollapseMerge<R, L> implements Merge {
  final StreamController<List<Join<L, List<R>>>> _controller =
      StreamController.broadcast();

  late final StreamSubscription<void> _subscription;
  List<StreamSubscription<void>> _childSubscriptions = [];

  List<Join<L?, List<R>>?> _snapshots = [];

  CollapseMerge({
    required Stream<List<R>> left,
    required String Function(R) onLeft,
    required Stream<L?> Function(String) onRight,
  }) {
    _subscription = left.listen(
      (leftModels) async {
        await Future.wait(_childSubscriptions.map((s) => s.cancel()));

        final Map<String, List<R>> groups = {};
        for (R leftModel in leftModels) {
          groups.putIfAbsent(onLeft(leftModel), () => []).add(leftModel);
        }
        _snapshots = List.filled(groups.length, null);

        if (groups.isEmpty) {
          _controller.add([]);
          _childSubscriptions = [];
        } else {
          final List<MapEntry<String, List<R>>> entries =
              groups.entries.toList();
          for (int i = 0; i < entries.length; i++) {
            final MapEntry<String, List<R>> entry = entries[i];
            final List<R> leftModels = entry.value;

            _childSubscriptions.add(onRight(entry.key).listen(
              (rightModel) {
                _snapshots[i] = Join(left: rightModel, right: leftModels);
                _checkSnapshots();
              },
              onDone: () =>
                  Future.wait(_childSubscriptions.map((s) => s.cancel())),
              onError: (e, s) => _controller.addError(e, s),
            ));
          }
        }
      },
      onDone: () async {
        await _subscription.cancel();
        await _controller.close();
      },
      onError: (e, s) => _controller.addError(e, s),
    );
  }

  void _checkSnapshots() {
    final List<Join<L, List<R>>> joins = [];
    for (Join<L?, List<R>>? join in _snapshots) {
      if (join == null) return;
      final L? left = join.left;

      if (left == null) continue;
      joins.add(Join(left: left, right: join.right));
    }
    _controller.add(joins);
  }

  Stream<List<Join<L, List<R>>>> get stream => _controller.stream;
}
