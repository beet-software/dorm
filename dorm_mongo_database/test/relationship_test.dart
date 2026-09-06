import 'package:dorm_framework/dorm_framework.dart';
import 'package:dorm_mongo_database/src/filter.dart';
import 'package:dorm_mongo_database/src/query.dart';
import 'package:dorm_mongo_database/src/relationship.dart';
import 'package:test/test.dart';

class _Parent {
  final String id;

  const _Parent(this.id);
}

class _Child {
  final String id;
  final String parentId;

  const _Child(this.id, this.parentId);
}

class _Link {
  final String id;
  final String parentId;
  final String childId;

  const _Link(this.id, this.parentId, this.childId);
}

class _Readable<Model, I extends Object>
    implements RelationSource<Model, I, Query> {
  final Map<I, Model> models;
  final Map<String, Object?> Function(Model) json;

  const _Readable(this.models, this.json);

  @override
  RelationPlan<Model, I> get plan => const CompositeRelationPlan();

  @override
  EntitySchema? get schema => null;

  @override
  Future<Model?> peek(I id) async => models[id];

  @override
  Future<List<Model>> peekAll([
    BaseFilter<Query> filter = const BaseFilter.empty(),
  ]) async {
    final String? key = filter is ValueFilter<Query> ? filter.key : null;
    final Object? value = filter is ValueFilter<Query> ? filter.value : null;
    return models.values.where((model) {
      if (key == null) return true;
      return json(model)[key] == value;
    }).toList();
  }

  @override
  Stream<Model?> pull(I id) async* {
    yield await peek(id);
  }

  @override
  Stream<List<Model>> pullAll([
    BaseFilter<Query> filter = const BaseFilter.empty(),
  ]) async* {
    yield await peekAll(filter);
  }
}

void main() {
  const FieldSchema parentField = FieldSchema(
    fieldName: 'parentId',
    columnName: 'parent-id',
  );
  final _Readable<_Parent, String> parents = _Readable({
    'parent-1': const _Parent('parent-1'),
    'parent-2': const _Parent('parent-2'),
  }, (model) => {'id': model.id});
  final _Readable<_Child, String> children = _Readable({
    'child-1': const _Child('child-1', 'parent-1'),
    'child-2': const _Child('child-2', 'parent-1'),
    'child-3': const _Child('child-3', 'parent-2'),
  }, (model) => {'id': model.id, 'parent-id': model.parentId});
  final _Readable<_Link, String> links = _Readable(
    {'link-1': const _Link('link-1', 'parent-1', 'child-1')},
    (model) => {
      'id': model.id,
      'parent-id': model.parentId,
      'child-id': model.childId,
    },
  );
  const Relationship relationship = Relationship();

  test('resolves one-to-one relationships', () async {
    final association = relationship.oneToOne(
      parents,
      children,
      (parent) => parent.id == 'parent-1' ? 'child-1' : 'child-3',
    );

    final Join<_Parent, _Child?>? result = await association.peek('parent-1');

    expect(result?.left.id, 'parent-1');
    expect(result?.right?.id, 'child-1');
  });

  test('resolves one-to-many relationships with schema fields', () async {
    final association = relationship.oneToMany(
      parents,
      children,
      (parent) => Filter.value(parent.id, field: parentField),
    );

    final Join<_Parent, List<_Child>>? result = await association.peek(
      'parent-1',
    );

    expect(result?.right.map((child) => child.id), ['child-1', 'child-2']);
  });

  test('resolves many-to-one relationships', () async {
    final association = relationship.manyToOne(
      children,
      parents,
      (child) => child.parentId,
    );

    final List<Join<_Parent, List<_Child>>> result = await association
        .peekAll();

    expect(result, hasLength(2));
    expect(
      result.firstWhere((join) => join.left.id == 'parent-1').right,
      hasLength(2),
    );
  });

  test('resolves many-to-many relationships', () async {
    final association = relationship.manyToMany(
      links,
      parents,
      (link) => link.parentId,
      children,
      (link) => link.childId,
    );

    final Join<_Link, (_Parent?, _Child?)>? result = await association.peek(
      'link-1',
    );

    expect(result?.right.$1?.id, 'parent-1');
    expect(result?.right.$2?.id, 'child-1');
  });
}
