import 'package:dorm_framework/dorm_framework.dart';
import 'package:test/test.dart';

class ItemData {
  final String value;

  const ItemData(this.value);
}

class ItemDependency extends Dependency<ItemData> {
  const ItemDependency() : super.strong();
}

void main() {
  test('creation factories return their specialized request types', () {
    final AutoCreation<ItemData, String> automatic = Creation.auto(
      dependency: ItemDependency(),
      data: ItemData('value'),
    );
    final ExplicitCreation<ItemData, String> explicit = Creation.explicit(
      dependency: const ItemDependency(),
      data: const ItemData('value'),
      identity: 'id',
    );

    expect(automatic, isA<SimpleCreation<ItemData, String>>());
    expect(explicit, isA<SimpleCreation<ItemData, String>>());
  });

  test('auto creation preserves its dependency and data', () {
    final AutoCreation<ItemData, String> creation = Creation.auto(
      dependency: ItemDependency(),
      data: ItemData('value'),
    );

    expect(creation.dependency, isA<ItemDependency>());
    expect(creation.data.value, 'value');
  });

  test('explicit creation requests preserve the final identity', () {
    final CompositeKey key = CompositeKey(['tenant', 7]);
    final ExplicitCreation<ItemData, CompositeKey> creation = Creation.explicit(
      dependency: const ItemDependency(),
      data: const ItemData('value'),
      identity: key,
    );

    expect(creation.identity, key);
  });

  test('resolved creation keeps the dependency, data, and identity source', () {
    const ResolvedCreation<ItemData, String> creation = ResolvedCreation(
      dependency: ItemDependency(),
      data: ItemData('value'),
      id: 'id',
      identitySource: CreationIdentitySource.generated,
    );

    expect(creation.dependency, isA<ItemDependency>());
    expect(creation.data.value, 'value');
    expect(creation.id, 'id');
    expect(creation.identitySource, CreationIdentitySource.generated);
  });
}
