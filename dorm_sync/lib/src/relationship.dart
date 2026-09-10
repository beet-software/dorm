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

Stream<R> _switchMap<T, R>(Stream<T> source, Stream<R> Function(T value) map) {
  final StreamController<R> controller = StreamController<R>.broadcast();
  StreamSubscription<T>? sourceSubscription;
  StreamSubscription<R>? childSubscription;
  bool sourceDone = false;
  bool childDone = true;

  Future<void> closeIfDone() async {
    if (sourceDone && childDone) await controller.close();
  }

  controller.onListen = () {
    sourceSubscription = source.listen(
      (value) async {
        childDone = false;
        await childSubscription?.cancel();
        childSubscription = map(value).listen(
          controller.add,
          onError: controller.addError,
          onDone: () {
            childDone = true;
            closeIfDone();
          },
        );
      },
      onError: controller.addError,
      onDone: () {
        sourceDone = true;
        closeIfDone();
      },
    );
  };
  controller.onCancel = () async {
    await sourceSubscription?.cancel();
    await childSubscription?.cancel();
  };
  return controller.stream;
}

Stream<List<T>> _combineLatest<T>(List<Stream<T>> streams) {
  if (streams.isEmpty) return Stream.value(<T>[]);

  final StreamController<List<T>> controller =
      StreamController<List<T>>.broadcast();
  final List<StreamSubscription<T>> subscriptions = [];
  final List<T?> values = List<T?>.filled(streams.length, null);
  final List<bool> received = List<bool>.filled(streams.length, false);
  int completed = 0;

  void emitIfReady() {
    if (received.every((value) => value)) {
      controller.add(
        List<T>.generate(streams.length, (index) => values[index] as T),
      );
    }
  }

  controller.onListen = () {
    for (int index = 0; index < streams.length; index++) {
      subscriptions.add(
        streams[index].listen(
          (value) {
            values[index] = value;
            received[index] = true;
            emitIfReady();
          },
          onError: controller.addError,
          onDone: () {
            completed++;
            if (completed == streams.length) controller.close();
          },
        ),
      );
    }
  };
  controller.onCancel = () async {
    await Future.wait(
      subscriptions.map((subscription) => subscription.cancel()),
    );
  };
  return controller.stream;
}

/// A portable implementation of dORM relationships.
class PortableRelationship<Q extends BaseQuery<Q>>
    implements BaseRelationship<Q> {
  const PortableRelationship();

  @override
  OneToOneAssociation<L, I, R, Q>
  oneToOne<L, I extends Object, R, J extends Object>(
    RelationSource<L, I, Q> left,
    RelationSource<R, J, Q> right,
    J Function(L value) on,
  ) => _OneToOne(left: left, right: right, on: on);

  @override
  OneToManyAssociation<L, I, R, Q>
  oneToMany<L, I extends Object, R, J extends Object>(
    RelationSource<L, I, Q> left,
    RelationSource<R, J, Q> right,
    BaseFilter<Q> Function(L value) on,
  ) => _OneToMany(left: left, right: right, on: on);

  @override
  ManyToOneAssociation<L, I, R, J, Q>
  manyToOne<L, I extends Object, R, J extends Object>(
    RelationSource<L, I, Q> left,
    RelationSource<R, J, Q> right,
    J Function(L value) on,
  ) => _ManyToOne(left: left, right: right, on: on);

  @override
  ManyToManyAssociation<M, I, L, R, Q>
  manyToMany<M, I extends Object, L, J extends Object, R, K extends Object>(
    RelationSource<M, I, Q> middle,
    RelationSource<L, J, Q> left,
    J Function(M value) onLeft,
    RelationSource<R, K, Q> right,
    K Function(M value) onRight,
  ) => _ManyToMany(
    middle: middle,
    left: left,
    right: right,
    onLeft: onLeft,
    onRight: onRight,
  );
}

class _OneToOne<
  L,
  I extends Object,
  R,
  J extends Object,
  Q extends BaseQuery<Q>
>
    implements OneToOneAssociation<L, I, R, Q> {
  final RelationSource<L, I, Q> left;
  final RelationSource<R, J, Q> right;
  final J Function(L) on;

  const _OneToOne({required this.left, required this.right, required this.on});

  @override
  Future<Join<L, R?>?> peek(I id) async {
    final L? leftModel = await left.peek(id);
    if (leftModel == null) return null;
    return Join(left: leftModel, right: await right.peek(on(leftModel)));
  }

  @override
  Future<List<Join<L, R?>>> peekAll([
    BaseFilter<Q> filter = const BaseFilter.empty(),
    QueryOptions options = const QueryOptions(),
  ]) async {
    final List<L> leftModels = await left.peekAll(filter, options);
    final List<R?> rightModels = await Future.wait(
      leftModels.map((model) => right.peek(on(model))),
    );
    return [
      for (int index = 0; index < leftModels.length; index++)
        Join(left: leftModels[index], right: rightModels[index]),
    ];
  }

  @override
  Stream<Join<L, R?>?> pull(I id) {
    return _switchMap(left.pull(id), (leftModel) {
      if (leftModel == null) return Stream.value(null);
      return right
          .pull(on(leftModel))
          .map((rightModel) => Join(left: leftModel, right: rightModel));
    });
  }

  @override
  Stream<List<Join<L, R?>>> pullAll([
    BaseFilter<Q> filter = const BaseFilter.empty(),
    QueryOptions options = const QueryOptions(),
  ]) {
    return _switchMap(left.pullAll(filter, options), (leftModels) {
      return _combineLatest(
        leftModels.map((model) => right.pull(on(model))).toList(),
      ).map(
        (rightModels) => [
          for (int index = 0; index < leftModels.length; index++)
            Join(left: leftModels[index], right: rightModels[index]),
        ],
      );
    });
  }
}

class _OneToMany<
  L,
  I extends Object,
  R,
  J extends Object,
  Q extends BaseQuery<Q>
>
    implements OneToManyAssociation<L, I, R, Q> {
  final RelationSource<L, I, Q> left;
  final RelationSource<R, J, Q> right;
  final BaseFilter<Q> Function(L) on;

  const _OneToMany({required this.left, required this.right, required this.on});

  @override
  Future<Join<L, List<R>>?> peek(I id) async {
    final L? leftModel = await left.peek(id);
    if (leftModel == null) return null;
    return Join(left: leftModel, right: await right.peekAll(on(leftModel)));
  }

  @override
  Future<List<Join<L, List<R>>>> peekAll([
    BaseFilter<Q> filter = const BaseFilter.empty(),
    QueryOptions options = const QueryOptions(),
  ]) async {
    final List<L> leftModels = await left.peekAll(filter, options);
    final List<List<R>> rightModels = await Future.wait(
      leftModels.map((model) => right.peekAll(on(model))),
    );
    return [
      for (int index = 0; index < leftModels.length; index++)
        Join(left: leftModels[index], right: rightModels[index]),
    ];
  }

  @override
  Stream<Join<L, List<R>>?> pull(I id) {
    return _switchMap(left.pull(id), (leftModel) {
      if (leftModel == null) return Stream.value(null);
      return right
          .pullAll(on(leftModel))
          .map((rightModels) => Join(left: leftModel, right: rightModels));
    });
  }

  @override
  Stream<List<Join<L, List<R>>>> pullAll([
    BaseFilter<Q> filter = const BaseFilter.empty(),
    QueryOptions options = const QueryOptions(),
  ]) {
    return _switchMap(left.pullAll(filter, options), (leftModels) {
      return _combineLatest(
        leftModels.map((model) => right.pullAll(on(model))).toList(),
      ).map(
        (rightModels) => [
          for (int index = 0; index < leftModels.length; index++)
            Join(left: leftModels[index], right: rightModels[index]),
        ],
      );
    });
  }
}

class _ManyToOne<
  L,
  I extends Object,
  R,
  J extends Object,
  Q extends BaseQuery<Q>
>
    implements ManyToOneAssociation<L, I, R, J, Q> {
  final RelationSource<L, I, Q> left;
  final RelationSource<R, J, Q> right;
  final J Function(L) on;

  const _ManyToOne({required this.left, required this.right, required this.on});

  @override
  Future<Join<R, L>?> peek(I id) async {
    final L? leftModel = await left.peek(id);
    if (leftModel == null) return null;
    final R? rightModel = await right.peek(on(leftModel));
    return rightModel == null ? null : Join(left: rightModel, right: leftModel);
  }

  @override
  Future<List<Join<R, List<L>>>> peekAll([
    BaseFilter<Q> filter = const BaseFilter.empty(),
    QueryOptions options = const QueryOptions(),
  ]) async {
    final List<L> leftModels = await left.peekAll(filter, options);
    final Map<J, List<L>> groups = {};
    for (final L model in leftModels) {
      groups.putIfAbsent(on(model), () => []).add(model);
    }
    final List<MapEntry<J, List<L>>> entries = groups.entries.toList();
    final List<R?> rightModels = await Future.wait(
      entries.map((entry) => right.peek(entry.key)),
    );
    return [
      for (int index = 0; index < entries.length; index++)
        if (rightModels[index] case final R rightModel)
          Join(left: rightModel, right: entries[index].value),
    ];
  }

  @override
  Stream<Join<R, L>?> pull(I id) {
    return _switchMap(left.pull(id), (leftModel) {
      if (leftModel == null) return Stream.value(null);
      return right
          .pull(on(leftModel))
          .map(
            (rightModel) => rightModel == null
                ? null
                : Join(left: rightModel, right: leftModel),
          );
    });
  }

  @override
  Stream<List<Join<R, List<L>>>> pullAll([
    BaseFilter<Q> filter = const BaseFilter.empty(),
    QueryOptions options = const QueryOptions(),
  ]) {
    return _switchMap(left.pullAll(filter, options), (leftModels) {
      final Map<J, List<L>> groups = {};
      for (final L model in leftModels) {
        groups.putIfAbsent(on(model), () => []).add(model);
      }
      final List<MapEntry<J, List<L>>> entries = groups.entries.toList();
      return _combineLatest(
        entries.map((entry) => right.pull(entry.key)).toList(),
      ).map(
        (rightModels) => [
          for (int index = 0; index < entries.length; index++)
            if (rightModels[index] case final R rightModel)
              Join(left: rightModel, right: entries[index].value),
        ],
      );
    });
  }
}

class _ManyToMany<
  M,
  I extends Object,
  L,
  J extends Object,
  R,
  K extends Object,
  Q extends BaseQuery<Q>
>
    implements ManyToManyAssociation<M, I, L, R, Q> {
  final RelationSource<M, I, Q> middle;
  final RelationSource<L, J, Q> left;
  final RelationSource<R, K, Q> right;
  final J Function(M) onLeft;
  final K Function(M) onRight;

  const _ManyToMany({
    required this.middle,
    required this.left,
    required this.right,
    required this.onLeft,
    required this.onRight,
  });

  @override
  Future<Join<M, (L?, R?)>?> peek(I id) async {
    final M? middleModel = await middle.peek(id);
    if (middleModel == null) return null;
    return Join(
      left: middleModel,
      right: (
        await left.peek(onLeft(middleModel)),
        await right.peek(onRight(middleModel)),
      ),
    );
  }

  @override
  Future<List<Join<M, (L?, R?)>>> peekAll([
    BaseFilter<Q> filter = const BaseFilter.empty(),
    QueryOptions options = const QueryOptions(),
  ]) async {
    final List<M> middleModels = await middle.peekAll(filter, options);
    final List<J> leftIds = middleModels.map(onLeft).toSet().toList();
    final List<K> rightIds = middleModels.map(onRight).toSet().toList();
    final Map<J, L?> leftModels = {
      for (final J id in leftIds) id: await left.peek(id),
    };
    final Map<K, R?> rightModels = {
      for (final K id in rightIds) id: await right.peek(id),
    };
    return middleModels
        .map(
          (model) => Join(
            left: model,
            right: (leftModels[onLeft(model)], rightModels[onRight(model)]),
          ),
        )
        .toList();
  }

  @override
  Stream<Join<M, (L?, R?)>?> pull(I id) {
    return _switchMap(middle.pull(id), (middleModel) {
      if (middleModel == null) return Stream.value(null);
      return _combineLatest<Object?>([
        left.pull(onLeft(middleModel)),
        right.pull(onRight(middleModel)),
      ]).map(
        (models) =>
            Join(left: middleModel, right: (models[0] as L?, models[1] as R?)),
      );
    });
  }

  @override
  Stream<List<Join<M, (L?, R?)>>> pullAll([
    BaseFilter<Q> filter = const BaseFilter.empty(),
    QueryOptions options = const QueryOptions(),
  ]) {
    return _switchMap(middle.pullAll(filter, options), (middleModels) {
      return _combineLatest<(L?, R?)>([
        for (final M model in middleModels)
          _combineLatest<Object?>([
            left.pull(onLeft(model)),
            right.pull(onRight(model)),
          ]).map((values) => (values[0] as L?, values[1] as R?)),
      ]).map(
        (values) => [
          for (int index = 0; index < middleModels.length; index++)
            Join(left: middleModels[index], right: values[index]),
        ],
      );
    });
  }
}

