// dORM
// Copyright (C) 2023  Beet Software
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

import 'dart:async';

import 'package:dorm_framework/dorm_framework.dart';

import 'query.dart';

Stream<R> _switchMap<T, R>(Stream<T> source, Stream<R> Function(T) map) {
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

  void emit() {
    if (received.every((value) => value)) {
      controller.add([
        for (int index = 0; index < values.length; index++) values[index] as T,
      ]);
    }
  }

  controller.onListen = () {
    for (int index = 0; index < streams.length; index++) {
      subscriptions.add(
        streams[index].listen(
          (value) {
            values[index] = value;
            received[index] = true;
            emit();
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

/// A relationship implementation using the framework's readable operations.
class Relationship implements BaseRelationship<Query> {
  const Relationship();

  @override
  OneToOneAssociation<L, I, R, Query>
  oneToOne<L, I extends Object, R, J extends Object>(
    RelationSource<L, I, Query> left,
    RelationSource<R, J, Query> right,
    J Function(L) on,
  ) => _OneToOne(left: left, right: right, on: on);

  @override
  OneToManyAssociation<L, I, R, Query>
  oneToMany<L, I extends Object, R, J extends Object>(
    RelationSource<L, I, Query> left,
    RelationSource<R, J, Query> right,
    BaseFilter<Query> Function(L) on,
  ) => _OneToMany(left: left, right: right, on: on);

  @override
  ManyToOneAssociation<L, I, R, J, Query>
  manyToOne<L, I extends Object, R, J extends Object>(
    RelationSource<L, I, Query> left,
    RelationSource<R, J, Query> right,
    J Function(L) on,
  ) => _ManyToOne(left: left, right: right, on: on);

  @override
  ManyToManyAssociation<M, I, L, R, Query>
  manyToMany<M, I extends Object, L, J extends Object, R, K extends Object>(
    RelationSource<M, I, Query> middle,
    RelationSource<L, J, Query> left,
    J Function(M) onLeft,
    RelationSource<R, K, Query> right,
    K Function(M) onRight,
  ) => _ManyToMany(
    middle: middle,
    left: left,
    right: right,
    onLeft: onLeft,
    onRight: onRight,
  );
}

class _OneToOne<L, I extends Object, R, J extends Object>
    implements OneToOneAssociation<L, I, R, Query> {
  final RelationSource<L, I, Query> left;
  final RelationSource<R, J, Query> right;
  final J Function(L) on;

  const _OneToOne({required this.left, required this.right, required this.on});

  @override
  Future<Join<L, R?>?> peek(I id) async {
    final L? model = await left.peek(id);
    if (model == null) return null;
    return Join(left: model, right: await right.peek(on(model)));
  }

  @override
  Future<List<Join<L, R?>>> peekAll([
    BaseFilter<Query> filter = const BaseFilter.empty(),
    QueryOptions options = const QueryOptions(),
  ]) async {
    final List<L> models = await left.peekAll(filter, options);
    final List<R?> associated = await Future.wait(
      models.map((model) => right.peek(on(model))),
    );
    return [
      for (int index = 0; index < models.length; index++)
        Join(left: models[index], right: associated[index]),
    ];
  }

  @override
  Stream<Join<L, R?>?> pull(I id) {
    return _switchMap(left.pull(id), (model) {
      if (model == null) return Stream.value(null);
      return right
          .pull(on(model))
          .map((value) => Join(left: model, right: value));
    });
  }

  @override
  Stream<List<Join<L, R?>>> pullAll([
    BaseFilter<Query> filter = const BaseFilter.empty(),
    QueryOptions options = const QueryOptions(),
  ]) {
    return _switchMap(left.pullAll(filter, options), (models) {
      return _combineLatest(
        models.map((model) => right.pull(on(model))).toList(),
      ).map(
        (associated) => [
          for (int index = 0; index < models.length; index++)
            Join(left: models[index], right: associated[index]),
        ],
      );
    });
  }
}

class _OneToMany<L, I extends Object, R, J extends Object>
    implements OneToManyAssociation<L, I, R, Query> {
  final RelationSource<L, I, Query> left;
  final RelationSource<R, J, Query> right;
  final BaseFilter<Query> Function(L) on;

  const _OneToMany({required this.left, required this.right, required this.on});

  @override
  Future<Join<L, List<R>>?> peek(I id) async {
    final L? model = await left.peek(id);
    if (model == null) return null;
    return Join(left: model, right: await right.peekAll(on(model)));
  }

  @override
  Future<List<Join<L, List<R>>>> peekAll([
    BaseFilter<Query> filter = const BaseFilter.empty(),
    QueryOptions options = const QueryOptions(),
  ]) async {
    final List<L> models = await left.peekAll(filter, options);
    final List<List<R>> associated = await Future.wait(
      models.map((model) => right.peekAll(on(model))),
    );
    return [
      for (int index = 0; index < models.length; index++)
        Join(left: models[index], right: associated[index]),
    ];
  }

  @override
  Stream<Join<L, List<R>>?> pull(I id) {
    return _switchMap(left.pull(id), (model) {
      if (model == null) return Stream.value(null);
      return right
          .pullAll(on(model))
          .map((values) => Join(left: model, right: values));
    });
  }

  @override
  Stream<List<Join<L, List<R>>>> pullAll([
    BaseFilter<Query> filter = const BaseFilter.empty(),
    QueryOptions options = const QueryOptions(),
  ]) {
    return _switchMap(left.pullAll(filter, options), (models) {
      return _combineLatest(
        models.map((model) => right.pullAll(on(model))).toList(),
      ).map(
        (associated) => [
          for (int index = 0; index < models.length; index++)
            Join(left: models[index], right: associated[index]),
        ],
      );
    });
  }
}

class _ManyToOne<L, I extends Object, R, J extends Object>
    implements ManyToOneAssociation<L, I, R, J, Query> {
  final RelationSource<L, I, Query> left;
  final RelationSource<R, J, Query> right;
  final J Function(L) on;

  const _ManyToOne({required this.left, required this.right, required this.on});

  @override
  Future<Join<R, L>?> peek(I id) async {
    final L? model = await left.peek(id);
    if (model == null) return null;
    final R? associated = await right.peek(on(model));
    return associated == null ? null : Join(left: associated, right: model);
  }

  @override
  Future<List<Join<R, List<L>>>> peekAll([
    BaseFilter<Query> filter = const BaseFilter.empty(),
    QueryOptions options = const QueryOptions(),
  ]) async {
    final List<L> models = await left.peekAll(filter, options);
    final Map<J, List<L>> grouped = {};
    for (final L model in models) {
      grouped.putIfAbsent(on(model), () => []).add(model);
    }
    final List<MapEntry<J, List<L>>> entries = grouped.entries.toList();
    final List<R?> associated = await Future.wait(
      entries.map((entry) => right.peek(entry.key)),
    );
    return [
      for (int index = 0; index < entries.length; index++)
        if (associated[index] case final R model)
          Join(left: model, right: entries[index].value),
    ];
  }

  @override
  Stream<Join<R, L>?> pull(I id) {
    return _switchMap(left.pull(id), (model) {
      if (model == null) return Stream.value(null);
      return right
          .pull(on(model))
          .map(
            (associated) => associated == null
                ? null
                : Join(left: associated, right: model),
          );
    });
  }

  @override
  Stream<List<Join<R, List<L>>>> pullAll([
    BaseFilter<Query> filter = const BaseFilter.empty(),
    QueryOptions options = const QueryOptions(),
  ]) {
    return _switchMap(left.pullAll(filter, options), (models) {
      final Map<J, List<L>> grouped = {};
      for (final L model in models) {
        grouped.putIfAbsent(on(model), () => []).add(model);
      }
      final List<MapEntry<J, List<L>>> entries = grouped.entries.toList();
      return _combineLatest(
        entries.map((entry) => right.pull(entry.key)).toList(),
      ).map(
        (associated) => [
          for (int index = 0; index < entries.length; index++)
            if (associated[index] case final R model)
              Join(left: model, right: entries[index].value),
        ],
      );
    });
  }
}

class _ManyToMany<M, I extends Object, L, J extends Object, R, K extends Object>
    implements ManyToManyAssociation<M, I, L, R, Query> {
  final RelationSource<M, I, Query> middle;
  final RelationSource<L, J, Query> left;
  final RelationSource<R, K, Query> right;
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
    final M? model = await middle.peek(id);
    if (model == null) return null;
    return Join(
      left: model,
      right: (await left.peek(onLeft(model)), await right.peek(onRight(model))),
    );
  }

  @override
  Future<List<Join<M, (L?, R?)>>> peekAll([
    BaseFilter<Query> filter = const BaseFilter.empty(),
    QueryOptions options = const QueryOptions(),
  ]) async {
    final List<M> models = await middle.peekAll(filter, options);
    final Map<J, Future<L?>> leftValues = {
      for (final J id in models.map(onLeft).toSet()) id: left.peek(id),
    };
    final Map<K, Future<R?>> rightValues = {
      for (final K id in models.map(onRight).toSet()) id: right.peek(id),
    };
    final Map<J, L?> resolvedLeft = {
      for (final MapEntry<J, Future<L?>> entry in leftValues.entries)
        entry.key: await entry.value,
    };
    final Map<K, R?> resolvedRight = {
      for (final MapEntry<K, Future<R?>> entry in rightValues.entries)
        entry.key: await entry.value,
    };
    return [
      for (final M model in models)
        Join(
          left: model,
          right: (resolvedLeft[onLeft(model)], resolvedRight[onRight(model)]),
        ),
    ];
  }

  @override
  Stream<Join<M, (L?, R?)>?> pull(I id) {
    return _switchMap(middle.pull(id), (model) {
      if (model == null) return Stream.value(null);
      return _combineLatest<Object?>([
        left.pull(onLeft(model)),
        right.pull(onRight(model)),
      ]).map(
        (values) =>
            Join(left: model, right: (values[0] as L?, values[1] as R?)),
      );
    });
  }

  @override
  Stream<List<Join<M, (L?, R?)>>> pullAll([
    BaseFilter<Query> filter = const BaseFilter.empty(),
    QueryOptions options = const QueryOptions(),
  ]) {
    return _switchMap(middle.pullAll(filter, options), (models) {
      return _combineLatest(
        models
            .map(
              (model) => _combineLatest<Object?>([
                left.pull(onLeft(model)),
                right.pull(onRight(model)),
              ]).map((values) => (values[0] as L?, values[1] as R?)),
            )
            .toList(),
      ).map(
        (associated) => [
          for (int index = 0; index < models.length; index++)
            Join(left: models[index], right: associated[index]),
        ],
      );
    });
  }
}
