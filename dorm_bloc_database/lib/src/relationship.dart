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
import 'filter.dart';
import 'reference.dart';

class Relationship implements BaseRelationship<Reference> {
  const Relationship();

  @override
  OneToOneAssociation<L, R, Reference> oneToOne<L, R>(
    Readable<L, Reference> left,
    Readable<R, Reference> right,
    String Function(L p1) on,
  ) {
    return _OneToOne(left: left, right: right, on: on);
  }

  @override
  OneToManyAssociation<L, R, Reference> oneToMany<L, R>(
    Readable<L, Reference> left,
    Readable<R, Reference> right,
    Filter Function(L p1) on,
  ) {
    return _OneToMany(left: left, right: right, on: on);
  }

  @override
  ManyToOneAssociation<L, R, Reference> manyToOne<L, R>(
    Readable<L, Reference> left,
    Readable<R, Reference> right,
    String Function(L p1) on,
  ) {
    return _ManyToOne(left: left, right: right, on: on);
  }

  @override
  ManyToManyAssociation<M, L, R, Reference> manyToMany<M, L, R>(
    Readable<M, Reference> middle,
    Readable<L, Reference> left,
    String Function(M p1) onLeft,
    Readable<R, Reference> right,
    String Function(M p1) onRight,
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

class _OneToOne<L, R> implements OneToOneAssociation<L, R, Reference> {
  final Readable<L, Reference> left;
  final Readable<R, Reference> right;
  final String Function(L) on;

  const _OneToOne({
    required this.left,
    required this.right,
    required this.on,
  });

  @override
  Future<Join<L, R?>?> peek(String id) async {
    final L? leftModel = await left.peek(id);
    if (leftModel == null) return null;
    final R? rightModel = await right.peek(on(leftModel));
    return Join(left: leftModel, right: rightModel);
  }

  @override
  Future<List<Join<L, R?>>> peekAll([Filter? filter]) async {
    final List<L> leftModels = await left.peekAll(filter);
    final List<Join<L, R?>> joins = [];
    for (L leftModel in leftModels) {
      final R? rightModel = await right.peek(on(leftModel));
      joins.add(Join(left: leftModel, right: rightModel));
    }
    return joins;
  }

  @override
  Stream<Join<L, R?>?> pull(String id) {
    return OneToOneSingleMerge<L, R?>(
      left: left.pull(id),
      map: (leftModel) => right.pull(on(leftModel)),
    ).stream;
  }

  @override
  Stream<List<Join<L, R?>>> pullAll([Filter? filter]) {
    return OneToOneBatchMerge<L, R?>(
      left: left.pullAll(filter),
      map: (leftModel) => right.pull(on(leftModel)),
    ).stream;
  }
}

class _OneToMany<L, R> implements OneToManyAssociation<L, R, Reference> {
  final Readable<L, Reference> left;
  final Readable<R, Reference> right;
  final Filter Function(L) on;

  const _OneToMany({
    required this.left,
    required this.right,
    required this.on,
  });

  @override
  Future<Join<L, List<R>>?> peek(String id) async {
    final L? leftModel = await left.peek(id);
    if (leftModel == null) return null;
    final List<R> rightModels = await right.peekAll(on(leftModel));
    return Join(left: leftModel, right: rightModels);
  }

  @override
  Future<List<Join<L, List<R>>>> peekAll([Filter? filter]) async {
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
  Stream<Join<L, List<R>>?> pull(String id) {
    return OneToOneSingleMerge<L, List<R>>(
      left: left.pull(id),
      map: (leftModel) => right.pullAll(on(leftModel)),
    ).stream;
  }

  @override
  Stream<List<Join<L, List<R>>>> pullAll([Filter? filter]) {
    return OneToOneBatchMerge<L, List<R>>(
      left: left.pullAll(filter),
      map: (leftModel) => right.pullAll(on(leftModel)),
    ).stream;
  }
}

class _ManyToOne<L, R> implements ManyToOneAssociation<L, R, Reference> {
  final Readable<L, Reference> left;
  final Readable<R, Reference> right;
  final String Function(L) on;

  const _ManyToOne({
    required this.left,
    required this.right,
    required this.on,
  });

  @override
  Future<Join<R, L>?> peek(String id) async {
    final L? leftModel = await left.peek(id);
    if (leftModel == null) return null;
    final R? rightModel = await right.peek(on(leftModel));
    if (rightModel == null) return null;
    return Join(left: rightModel, right: leftModel);
  }

  @override
  Future<List<Join<R, List<L>>>> peekAll([Filter? filter]) async {
    final List<L> leftModels = await left.peekAll(filter);
    final Map<String, List<L>> groups = {};
    for (L leftModel in leftModels) {
      groups.putIfAbsent(on(leftModel), () => []).add(leftModel);
    }
    final List<MapEntry<String, List<L>>> entries = groups.entries.toList();
    final List<R?> rightModels = await Future.wait(
        entries.map((entry) => right.peek(entry.key)).toList());

    final List<Join<R, List<L>>> joins = [];
    for (int i = 0; i < entries.length; i++) {
      final MapEntry<String, List<L>> entry = entries[i];
      final List<L> leftModels = entry.value;
      final R? rightModel = rightModels[i];
      if (rightModel == null) continue;
      joins.add(Join(left: rightModel, right: leftModels));
    }
    return joins;
  }

  @override
  Stream<Join<R, L>?> pull(String id) {
    return ManyToOneSingleMerge<L, R>(
      left: left.pull(id),
      map: (leftModel) => right.pull(on(leftModel)),
    ).stream;
  }

  @override
  Stream<List<Join<R, List<L>>>> pullAll([Filter? filter]) {
    return ManyToOneBatchMerge<R, L>(
      left: left.pullAll(filter),
      onLeft: (leftModel) => on(leftModel),
      onRight: (rightId) => right.pull(rightId),
    ).stream;
  }
}

class _ManyToMany<M, L, R>
    implements ManyToManyAssociation<M, L, R, Reference> {
  final Readable<M, Reference> middle;
  final Readable<L, Reference> left;
  final Readable<R, Reference> right;
  final String Function(M) onLeft;
  final String Function(M) onRight;

  const _ManyToMany({
    required this.middle,
    required this.left,
    required this.right,
    required this.onLeft,
    required this.onRight,
  });

  @override
  Future<Join<M, (L?, R?)>?> peek(String id) async {
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
  Future<List<Join<M, (L?, R?)>>> peekAll([Filter? filter]) async {
    final List<M> middleModels = await middle.peekAll(filter);
    final List<String> leftIds = middleModels.map(onLeft).toSet().toList();
    final List<String> rightIds = middleModels.map(onRight).toSet().toList();

    final Map<String, L?> leftModels =
        await _waitAssociateWith(leftIds, left.peek);
    final Map<String, R?> rightModels =
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
  Stream<Join<M, (L?, R?)>?> pull(String id) {
    return ManyToManySingleMerge<M, L?, R?>(
      left: middle.pull(id),
      map: (model) => ZipStream(
          [left.pull(onLeft(model)), right.pull(onRight(model))],
          (values) => (values[0] as L?, values[1] as R?)),
    ).stream;
  }

  @override
  Stream<List<Join<M, (L?, R?)>>> pullAll([Filter? filter]) {
    return ManyToManyBatchMerge<M, L?, R?>(
      left: middle.pullAll(filter),
      onLeft: (model) => left.pull(onLeft(model)),
      onRight: (model) => right.pull(onRight(model)),
    ).stream;
  }
}
