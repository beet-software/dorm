import 'dart:async';

import 'relationship.dart';

abstract class Merge<L, R> {}

class MapMerge<L, R> implements Merge<L, R> {
  final StreamController<Join<L, R>?> _controller =
      StreamController.broadcast();

  late final StreamSubscription<void> _subscription;
  StreamSubscription<void>? _childSubscription;

  MapMerge({required Stream<L?> left, required Stream<R> Function(L) map}) {
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

class ExpandMerge<L, R> implements Merge<L, R> {
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
