import 'package:dorm_framework/dorm_framework.dart';
import 'package:test/test.dart';

class _Query extends BaseQuery<_Query> {
  final String? key;
  final Object? value;

  _Query({this.key, this.value});

  @override
  _Query whereValue(String key, Object? value) {
    return _Query(key: key, value: value);
  }

  @override
  _Query whereText(String key, String prefix) => this;

  @override
  _Query whereDate(String key, DateTime date, DateFilterUnit unit) => this;

  @override
  _Query whereRange<R>(String key, FilterRange<R> range) => this;

  @override
  _Query limit(int count) => this;

  @override
  _Query sorted(String key) => this;
}

class _User {
  final String id;

  const _User(this.id);
}

class _Cart {
  final String id;
  final String userId;

  const _Cart(this.id, this.userId);
}

class _Product {
  final String id;

  const _Product(this.id);
}

class _CartItem {
  final String id;
  final String cartId;
  final String productId;

  const _CartItem(this.id, this.cartId, this.productId);
}

class _Source<Model> implements RelationSource<Model, String, _Query> {
  final List<Model> values;
  final String Function(Model) identify;
  final Map<String, Object?> Function(Model) fields;

  const _Source({
    required this.values,
    required this.identify,
    required this.fields,
  });

  @override
  RelationPlan<Model, String> get plan => const CompositeRelationPlan();

  @override
  EntitySchema? get schema => null;

  @override
  Future<Model?> peek(String id) async {
    for (final Model model in values) {
      if (identify(model) == id) return model;
    }
    return null;
  }

  @override
  Future<List<Model>> peekAll([
    BaseFilter<_Query> filter = const BaseFilter.empty(),
  ]) async {
    if (filter is! ValueFilter<_Query>) return values;
    return values
        .where((model) => fields(model)[filter.key] == filter.value)
        .toList();
  }

  @override
  Stream<Model?> pull(String id) async* {
    yield await peek(id);
  }

  @override
  Stream<List<Model>> pullAll([
    BaseFilter<_Query> filter = const BaseFilter.empty(),
  ]) async* {
    yield await peekAll(filter);
  }
}

void main() {
  test(
    'navigates generated-style paths without exposing on callbacks',
    () async {
      final _Source<_User> users = _Source(
        values: const [_User('u1')],
        identify: (model) => model.id,
        fields: (model) => {'id': model.id},
      );
      final _Source<_Cart> carts = _Source(
        values: const [_Cart('c1', 'u1')],
        identify: (model) => model.id,
        fields: (model) => {'id': model.id, 'user-id': model.userId},
      );
      final _Source<_CartItem> items = _Source(
        values: const [_CartItem('i1', 'c1', 'p1')],
        identify: (model) => model.id,
        fields: (model) => {'id': model.id, 'cart-id': model.cartId},
      );
      final _Source<_Product> products = _Source(
        values: const [_Product('p1')],
        identify: (model) => model.id,
        fields: (model) => {'id': model.id},
      );

      final RelationPath<Object, _User, _User, _Query> path = RelationPath.root(
        users,
        context: Object(),
      );
      final List<Join<_User, _Product>> result = await path
          .toMany(
            carts,
            spec: const RelationSpec(
              cardinality: RelationCardinality.many,
              source: FieldSchema(fieldName: 'id', columnName: 'id'),
              target: FieldSchema(fieldName: 'userId', columnName: 'user-id'),
            ),
            on: (user) => const BaseFilter.value('u1', key: 'user-id'),
          )
          .toMany(
            items,
            spec: const RelationSpec(
              cardinality: RelationCardinality.many,
              source: FieldSchema(fieldName: 'id', columnName: 'id'),
              target: FieldSchema(fieldName: 'cartId', columnName: 'cart-id'),
            ),
            on: (cart) => BaseFilter.value(cart.id, key: 'cart-id'),
          )
          .toOne(
            products,
            spec: const RelationSpec(
              cardinality: RelationCardinality.one,
              source: FieldSchema(
                fieldName: 'productId',
                columnName: 'product-id',
              ),
              target: FieldSchema(fieldName: 'id', columnName: 'id'),
            ),
            on: (_) => 'p1',
          )
          .peekAll();

      expect(result, hasLength(1));
      expect(result.single.left.id, 'u1');
      expect(result.single.right.id, 'p1');
    },
  );

  test('distinguishes inner and left to-one paths', () async {
    final _Source<_CartItem> items = _Source(
      values: const [
        _CartItem('i1', 'c1', 'p1'),
        _CartItem('i2', 'c1', 'missing'),
      ],
      identify: (model) => model.id,
      fields: (model) => {'id': model.id, 'cart-id': model.cartId},
    );
    final _Source<_Product> products = _Source(
      values: const [_Product('p1')],
      identify: (model) => model.id,
      fields: (model) => {'id': model.id},
    );
    final RelationPath<Object, _CartItem, _CartItem, _Query> path =
        RelationPath.root(items, context: Object());
    const RelationSpec spec = RelationSpec(
      cardinality: RelationCardinality.one,
      source: FieldSchema(fieldName: 'productId', columnName: 'product-id'),
      target: FieldSchema(fieldName: 'id', columnName: 'id'),
    );

    final List<Join<_CartItem, _Product>> inner = await path
        .toOne(products, spec: spec, on: (item) => item.productId)
        .peekAll();
    final List<Join<_CartItem, _Product?>> left = await path
        .toOneOrNull(products, spec: spec, on: (item) => item.productId)
        .peekAll();

    expect(inner, hasLength(1));
    expect(inner.single.left.id, 'i1');
    expect(left, hasLength(2));
    expect(left.first.right?.id, 'p1');
    expect(left.last.right, isNull);
  });

  test('toManyOrEmpty preserves parents without children', () async {
    final _Source<_User> users = _Source(
      values: const [_User('u1'), _User('u2')],
      identify: (model) => model.id,
      fields: (model) => {'id': model.id},
    );
    final _Source<_Cart> carts = _Source(
      values: const [_Cart('c1', 'u1')],
      identify: (model) => model.id,
      fields: (model) => {'id': model.id, 'user-id': model.userId},
    );

    final List<Join<_User, List<_Cart>>> result =
        await RelationPath.root(users, context: Object())
            .toManyOrEmpty(
              carts,
              spec: const RelationSpec(
                cardinality: RelationCardinality.many,
                source: FieldSchema(fieldName: 'id', columnName: 'id'),
                target: FieldSchema(fieldName: 'userId', columnName: 'user-id'),
              ),
              on: (user) => BaseFilter.value(user.id, key: 'user-id'),
            )
            .peekAll();

    expect(result, hasLength(2));
    expect(result.first.right, hasLength(1));
    expect(result.last.right, isEmpty);
  });
}
