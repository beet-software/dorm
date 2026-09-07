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
import 'package:rxdart/rxdart.dart';

import 'merge.dart';
import 'query.dart';

class Relationship implements BaseRelationship<Query> {
  const Relationship();

  @override
  OneToOneAssociation<L, I, R, Query>
      oneToOne<L, I extends Object, R, J extends Object>(
    RelationSource<L, I, Query> left,
    RelationSource<R, J, Query> right,
    J Function(L p1) on,
  ) {
    return _OneToOne(left: left, right: right, on: on);
  }

  @override
  OneToManyAssociation<L, I, R, Query>
      oneToMany<L, I extends Object, R, J extends Object>(
    RelationSource<L, I, Query> left,
    RelationSource<R, J, Query> right,
    BaseFilter<Query> Function(L p1) on,
  ) {
    return _OneToMany(left: left, right: right, on: on);
  }

  @override
  ManyToOneAssociation<L, I, R, J, Query>
      manyToOne<L, I extends Object, R, J extends Object>(
    RelationSource<L, I, Query> left,
    RelationSource<R, J, Query> right,
    J Function(L p1) on,
  ) {
    return _ManyToOne(left: left, right: right, on: on);
  }

  @override
  ManyToManyAssociation<M, I, L, R, Query>
      manyToMany<M, I extends Object, L, J extends Object, R, K extends Object>(
    RelationSource<M, I, Query> middle,
    RelationSource<L, J, Query> left,
    J Function(M p1) onLeft,
    RelationSource<R, K, Query> right,
    K Function(M p1) onRight,
  ) {
    return _ManyToMany(
      middle: middle,
      left: left,
      right: right,
      onLeft: onLeft,
      onRight: onRight,
    );
  }
}

class _OneToOne<L, I extends Object, R, J extends Object>
    implements OneToOneAssociation<L, I, R, Query> {
  final RelationSource<L, I, Query> left;
  final RelationSource<R, J, Query> right;
  final J Function(L) on;

  const _OneToOne({
    required this.left,
    required this.right,
    required this.on,
  });

  @override
  Future<Join<L, R?>?> peek(I id) async {
    final L? leftModel = await left.peek(id);
    if (leftModel == null) return null;
    final R? rightModel = await right.peek(on(leftModel));
    return Join(left: leftModel, right: rightModel);
  }

  @override
  Future<List<Join<L, R?>>> peekAll([
    BaseFilter<Query> filter = const BaseFilter.empty(),
  ]) async {
    final List<L> leftModels = await left.peekAll(filter);
    final List<Join<L, R?>> joins = [];
    for (L leftModel in leftModels) {
      final R? rightModel = await right.peek(on(leftModel));
      joins.add(Join(left: leftModel, right: rightModel));
    }
    return joins;
  }

  @override
  Stream<Join<L, R?>?> pull(I id) {
    return OneToOneSingleMerge<L, R?>(
      left: left.pull(id),
      map: (leftModel) => right.pull(on(leftModel)),
    ).stream;
  }

  @override
  Stream<List<Join<L, R?>>> pullAll([
    BaseFilter<Query> filter = const BaseFilter.empty(),
  ]) {
    return OneToOneBatchMerge<L, R?>(
      left: left.pullAll(filter),
      map: (leftModel) => right.pull(on(leftModel)),
    ).stream;
  }
}

class _OneToMany<L, I extends Object, R, J extends Object>
    implements OneToManyAssociation<L, I, R, Query> {
  final RelationSource<L, I, Query> left;
  final RelationSource<R, J, Query> right;
  final BaseFilter<Query> Function(L) on;

  const _OneToMany({
    required this.left,
    required this.right,
    required this.on,
  });

  @override
  Future<Join<L, List<R>>?> peek(I id) async {
    final L? leftModel = await left.peek(id);
    if (leftModel == null) return null;
    final List<R> rightModels = await right.peekAll(on(leftModel));
    return Join(left: leftModel, right: rightModels);
  }

  @override
  Future<List<Join<L, List<R>>>> peekAll([
    BaseFilter<Query> filter = const BaseFilter.empty(),
  ]) async {
    final List<L> leftModels = await left.peekAll(filter);
    final List<List<R>> associatedModels = await Future.wait(
        leftModels.map((leftModel) => right.peekAll(on(leftModel))).toList());

    final List<Join<L, List<R>>> joins = [];
    for (int i = 0; i < leftModels.length; i++) {
      final L leftModel = leftModels[i];
      final List<R> rightModels = associatedModels[i];
      joins.add(Join(left: leftModel, right: rightModels));
    }
    return joins;
  }

  @override
  Stream<Join<L, List<R>>?> pull(I id) {
    return OneToOneSingleMerge<L, List<R>>(
      left: left.pull(id),
      map: (leftModel) => right.pullAll(on(leftModel)),
    ).stream;
  }

  @override
  Stream<List<Join<L, List<R>>>> pullAll([
    BaseFilter<Query> filter = const BaseFilter.empty(),
  ]) {
    return OneToOneBatchMerge<L, List<R>>(
      left: left.pullAll(filter),
      map: (leftModel) => right.pullAll(on(leftModel)),
    ).stream;
  }
}

class _ManyToOne<L, I extends Object, R, J extends Object>
    implements ManyToOneAssociation<L, I, R, J, Query> {
  final RelationSource<L, I, Query> left;
  final RelationSource<R, J, Query> right;
  final J Function(L) on;

  const _ManyToOne({
    required this.left,
    required this.right,
    required this.on,
  });

  @override
  Future<Join<R, L>?> peek(I id) async {
    final L? leftModel = await left.peek(id);
    if (leftModel == null) return null;
    final R? rightModel = await right.peek(on(leftModel));
    if (rightModel == null) return null;
    return Join(left: rightModel, right: leftModel);
  }

  @override
  Future<List<Join<R, List<L>>>> peekAll([
    BaseFilter<Query> filter = const BaseFilter.empty(),
  ]) async {
    final List<L> leftModels = await left.peekAll(filter);
    final Map<J, List<L>> groups = {};
    for (L leftModel in leftModels) {
      groups.putIfAbsent(on(leftModel), () => []).add(leftModel);
    }
    final List<MapEntry<J, List<L>>> entries = groups.entries.toList();
    final List<R?> rightModels = await Future.wait(
        entries.map((entry) => right.peek(entry.key)).toList());

    final List<Join<R, List<L>>> joins = [];
    for (int i = 0; i < entries.length; i++) {
      final MapEntry<J, List<L>> entry = entries[i];
      final List<L> leftModels = entry.value;
      final R? rightModel = rightModels[i];
      if (rightModel == null) continue;
      joins.add(Join(left: rightModel, right: leftModels));
    }
    return joins;
  }

  @override
  Stream<Join<R, L>?> pull(I id) {
    return ManyToOneSingleMerge<L, R>(
      left: left.pull(id),
      map: (leftModel) => right.pull(on(leftModel)),
    ).stream;
  }

  @override
  Stream<List<Join<R, List<L>>>> pullAll([
    BaseFilter<Query> filter = const BaseFilter.empty(),
  ]) {
    return ManyToOneBatchMerge<R, L, J>(
      left: left.pullAll(filter),
      onLeft: (leftModel) => on(leftModel),
      onRight: (rightId) => right.pull(rightId),
    ).stream;
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
    final M? middleModel = await middle.peek(id);
    if (middleModel == null) return null;

    final L? leftModel = await left.peek(onLeft(middleModel));
    final R? rightModel = await right.peek(onRight(middleModel));
    return Join(
      left: middleModel,
      right: (leftModel, rightModel),
    );
  }

  static Future<Map<K, V>> _waitAssociateWith<K, V>(
    List<K> keys,
    Future<V> Function(K) associate,
  ) async {
    final List<V> values = await Future.wait(keys.map(associate));
    final Map<K, V> result = {};
    for (int i = 0; i < values.length; i++) {
      final K key = keys[i];
      final V value = values[i];
      result[key] = value;
    }
    return result;
  }

  @override
  Future<List<Join<M, (L?, R?)>>> peekAll([
    BaseFilter<Query> filter = const BaseFilter.empty(),
  ]) async {
    final List<M> middleModels = await middle.peekAll(filter);
    final List<J> leftIds = middleModels.map(onLeft).toSet().toList();
    final List<K> rightIds = middleModels.map(onRight).toSet().toList();

    final Map<J, L?> leftModels = await _waitAssociateWith(leftIds, left.peek);
    final Map<K, R?> rightModels =
        await _waitAssociateWith(rightIds, right.peek);

    return middleModels.map((middleModel) {
      return Join(
        left: middleModel,
        right: (
          leftModels[onLeft(middleModel)],
          rightModels[onRight(middleModel)],
        ),
      );
    }).toList();
  }

  @override
  Stream<Join<M, (L?, R?)>?> pull(I id) {
    return ManyToManySingleMerge<M, L?, R?>(
      left: middle.pull(id),
      map: (model) => ZipStream(
          [left.pull(onLeft(model)), right.pull(onRight(model))],
          (values) => (values[0] as L?, values[1] as R?)),
    ).stream;
  }

  @override
  Stream<List<Join<M, (L?, R?)>>> pullAll([
    BaseFilter<Query> filter = const BaseFilter.empty(),
  ]) {
    return ManyToManyBatchMerge<M, L?, R?>(
      left: middle.pullAll(filter),
      onLeft: (model) => left.pull(onLeft(model)),
      onRight: (model) => right.pull(onRight(model)),
    ).stream;
  }
}
