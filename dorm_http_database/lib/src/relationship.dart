import 'package:dorm_framework/dorm_framework.dart';
import 'query.dart';

/// HTTP relationships use the framework's readable-source fallback.
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
    return model == null
        ? null
        : Join(left: model, right: await right.peek(on(model)));
  }

  @override
  Future<List<Join<L, R?>>> peekAll([
    BaseFilter<Query> filter = const BaseFilter.empty(),
    QueryOptions options = const QueryOptions(),
  ]) async {
    final List<L> models = await left.peekAll(filter, options);
    final List<R?> related = await Future.wait(
      models.map((model) => right.peek(on(model))),
    );
    return [
      for (int index = 0; index < models.length; index++)
        Join(left: models[index], right: related[index]),
    ];
  }

  @override
  Stream<Join<L, R?>?> pull(I id) async* {
    yield await peek(id);
  }

  @override
  Stream<List<Join<L, R?>>> pullAll([
    BaseFilter<Query> filter = const BaseFilter.empty(),
    QueryOptions options = const QueryOptions(),
  ]) async* {
    yield await peekAll(filter, options);
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
    return model == null
        ? null
        : Join(left: model, right: await right.peekAll(on(model)));
  }

  @override
  Future<List<Join<L, List<R>>>> peekAll([
    BaseFilter<Query> filter = const BaseFilter.empty(),
    QueryOptions options = const QueryOptions(),
  ]) async {
    final List<L> models = await left.peekAll(filter, options);
    final List<List<R>> related = await Future.wait(
      models.map((model) => right.peekAll(on(model))),
    );
    return [
      for (int index = 0; index < models.length; index++)
        Join(left: models[index], right: related[index]),
    ];
  }

  @override
  Stream<Join<L, List<R>>?> pull(I id) async* {
    yield await peek(id);
  }

  @override
  Stream<List<Join<L, List<R>>>> pullAll([
    BaseFilter<Query> filter = const BaseFilter.empty(),
    QueryOptions options = const QueryOptions(),
  ]) async* {
    yield await peekAll(filter, options);
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
    final R? related = await right.peek(on(model));
    return related == null ? null : Join(left: related, right: model);
  }

  @override
  Future<List<Join<R, List<L>>>> peekAll([
    BaseFilter<Query> filter = const BaseFilter.empty(),
    QueryOptions options = const QueryOptions(),
  ]) async {
    final List<L> models = await left.peekAll(filter, options);
    final Map<J, List<L>> groups = {};
    for (final L model in models) {
      groups.putIfAbsent(on(model), () => []).add(model);
    }
    final List<MapEntry<J, List<L>>> entries = groups.entries.toList();
    final List<R?> related = await Future.wait(
      entries.map((entry) => right.peek(entry.key)),
    );
    return [
      for (int index = 0; index < entries.length; index++)
        if (related[index] != null)
          Join(left: related[index] as R, right: entries[index].value),
    ];
  }

  @override
  Stream<Join<R, L>?> pull(I id) async* {
    yield await peek(id);
  }

  @override
  Stream<List<Join<R, List<L>>>> pullAll([
    BaseFilter<Query> filter = const BaseFilter.empty(),
    QueryOptions options = const QueryOptions(),
  ]) async* {
    yield await peekAll(filter, options);
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
    final List<Object?> related = await Future.wait<Object?>([
      left.peek(onLeft(model)),
      right.peek(onRight(model)),
    ]);
    return Join(left: model, right: (related[0] as L?, related[1] as R?));
  }

  @override
  Future<List<Join<M, (L?, R?)>>> peekAll([
    BaseFilter<Query> filter = const BaseFilter.empty(),
    QueryOptions options = const QueryOptions(),
  ]) async {
    final List<M> models = await middle.peekAll(filter, options);
    final List<Join<M, (L?, R?)>> result = [];
    for (final M model in models) {
      final List<Object?> related = await Future.wait<Object?>([
        left.peek(onLeft(model)),
        right.peek(onRight(model)),
      ]);
      result.add(
        Join(left: model, right: (related[0] as L?, related[1] as R?)),
      );
    }
    return result;
  }

  @override
  Stream<Join<M, (L?, R?)>?> pull(I id) async* {
    yield await peek(id);
  }

  @override
  Stream<List<Join<M, (L?, R?)>>> pullAll([
    BaseFilter<Query> filter = const BaseFilter.empty(),
    QueryOptions options = const QueryOptions(),
  ]) async* {
    yield await peekAll(filter, options);
  }
}
