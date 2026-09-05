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

class ItemEntity implements Entity<ItemData, Item> {
  @override
  String get tableName => 'items';

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
  Item fromData(Dependency<ItemData> dependency, String id, ItemData data) {
    return Item(id: id, group: data.group);
  }

  @override
  String identify(Item model) => model.id;
}

void main() {
  late Repository<ItemData, Item> repository;

  setUp(() {
    final DatabaseEntity<ItemData, Item> entity = DatabaseEntity(
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
}
