import 'package:dorm_bloc_database/dorm_bloc_database.dart';
import 'package:dorm_framework/dorm_framework.dart';
import 'package:test/test.dart';

class ItemData {
  final String group;

  const ItemData({required this.group});
}

class Item extends ItemData {
  final String id;

  const Item({required this.id, required super.group});
}

class ItemDependency extends Dependency<ItemData> {
  const ItemDependency() : super.strong();
}

class ItemEntity
    implements Entity<ItemData, Item, String, SimpleCreation<ItemData, String>> {
  @override
  PrimaryKeyCodec<String> get primaryKeyCodec => const SinglePrimaryKeyCodec();

  @override
  bool get supportsAutomaticIdentity => true;

  @override
  EntitySchema get schema => const EntitySchema(
        tableName: 'items',
        primaryKey: FieldSchema(fieldName: 'id', columnName: 'id'),
      );

  @override
  Item fromJson(String id, Map data) {
    return Item(id: id, group: data['group'] as String);
  }

  @override
  Map<String, Object?> toJson(ItemData data) {
    return {'group': data.group};
  }

  @override
  Item convert(Item model, ItemData data) {
    return Item(id: model.id, group: data.group);
  }

  @override
  Item fromData(ResolvedCreation<ItemData, String> creation) {
    return Item(id: creation.id, group: creation.data.group);
  }

  @override
  String identify(Item model) => model.id;
}

class CompositeItemData {
  final String value;

  const CompositeItemData(this.value);
}

class CompositeItem extends CompositeItemData {
  final CompositeKey id;

  const CompositeItem({required this.id, required String value}) : super(value);
}

class CompositeItemDependency extends Dependency<CompositeItemData> {
  const CompositeItemDependency() : super.strong();
}

class CompositeItemEntity
    implements
        Entity<
          CompositeItemData,
          CompositeItem,
          CompositeKey,
          ExplicitCreation<CompositeItemData, CompositeKey>
        > {
  @override
  PrimaryKeyCodec<CompositeKey> get primaryKeyCodec =>
      const CompositePrimaryKeyCodec();

  @override
  bool get supportsAutomaticIdentity => false;

  @override
  EntitySchema get schema => const EntitySchema(
        tableName: 'composite-items',
        primaryKey: FieldSchema(fieldName: 'tenant', columnName: 'tenant'),
        primaryKeys: [
          FieldSchema(fieldName: 'tenant', columnName: 'tenant'),
          FieldSchema(fieldName: 'number', columnName: 'number'),
        ],
      );

  @override
  CompositeItem convert(CompositeItem model, CompositeItemData data) =>
      CompositeItem(id: model.id, value: data.value);

  @override
  CompositeItem fromData(
    ResolvedCreation<CompositeItemData, CompositeKey> creation,
  ) =>
      CompositeItem(id: creation.id, value: creation.data.value);

  @override
  CompositeItem fromJson(CompositeKey id, Map data) =>
      CompositeItem(id: id, value: data['value'] as String);

  @override
  CompositeKey identify(CompositeItem model) => model.id;

  @override
  Map<String, Object?> toJson(CompositeItemData data) => {'value': data.value};
}

void main() {
  late Repository<
    ItemData,
    Item,
    String,
    Query,
    SimpleCreation<ItemData, String>
  > repository;

  setUp(() {
    final DatabaseEntity<
      ItemData,
      Item,
      String,
      Query,
      SimpleCreation<ItemData, String>
    > entity = DatabaseEntity(
      ItemEntity(),
      engine: Engine(),
    );
    repository = entity.repository;
  });

  test('popAll removes only rows matching the filter', () async {
    await repository.pushAll(const [
      Item(id: '1', group: 'remove'),
      Item(id: '2', group: 'keep'),
      Item(id: '3', group: 'remove'),
    ]);

    await repository.popAll(const Filter.value('remove', key: 'group'));

    expect(await repository.peekAllKeys(), ['2']);
  });

  test('popAll with an empty filter removes every row', () async {
    await repository.pushAll(const [
      Item(id: '1', group: 'remove'),
      Item(id: '2', group: 'keep'),
    ]);

    await repository.popAll(const Filter.empty());

    expect(await repository.peekAllKeys(), isEmpty);
  });

  test('put accepts an explicit composite identity', () async {
    final DatabaseEntity<
      CompositeItemData,
      CompositeItem,
      CompositeKey,
      Query,
      ExplicitCreation<CompositeItemData, CompositeKey>
    > entity = DatabaseEntity(
      CompositeItemEntity(),
      engine: Engine(),
    );

    final CompositeItem item = await entity.repository.put(
      Creation.explicit(
        dependency: const CompositeItemDependency(),
        data: const CompositeItemData('value'),
        identity: CompositeKey(['tenant', 7]),
      ),
    );

    expect(await entity.repository.peek(item.id), item);
  });

  test('put rejects automatic identity for composite entities', () {
    final DatabaseEntity<
      CompositeItemData,
      CompositeItem,
      CompositeKey,
      Query,
      ExplicitCreation<CompositeItemData, CompositeKey>
    > entity = DatabaseEntity(
      CompositeItemEntity(),
      engine: Engine(),
    );

    expect(
      () => entity.repository.put(
        const Creation.auto(
          dependency: CompositeItemDependency(),
          data: CompositeItemData('value'),
        ),
      ),
      throwsUnsupportedError,
    );
  });

  test('put rejects an explicit identity with the wrong number of values', () {
    final DatabaseEntity<
      CompositeItemData,
      CompositeItem,
      CompositeKey,
      Query,
      ExplicitCreation<CompositeItemData, CompositeKey>
    > entity = DatabaseEntity(
      CompositeItemEntity(),
      engine: Engine(),
    );

    expect(
      () => entity.repository.put(
        Creation.explicit(
          dependency: const CompositeItemDependency(),
          data: const CompositeItemData('value'),
          identity: CompositeKey(['tenant']),
        ),
      ),
      throwsArgumentError,
    );
  });

  test('putAll resolves each creation independently', () async {
    final DatabaseEntity<
      ItemData,
      Item,
      String,
      Query,
      SimpleCreation<ItemData, String>
    > entity = DatabaseEntity(
      ItemEntity(),
      engine: Engine(),
    );

    final List<Item> items = await entity.repository.putAll([
      Creation.explicit(
        dependency: const ItemDependency(),
        data: const ItemData(group: 'first'),
        identity: 'first-id',
      ),
      Creation.explicit(
        dependency: const ItemDependency(),
        data: const ItemData(group: 'second'),
        identity: 'second-id',
      ),
    ]);

    expect(items.map((item) => item.id), ['first-id', 'second-id']);
    expect(items.map((item) => item.group), ['first', 'second']);
  });
}
