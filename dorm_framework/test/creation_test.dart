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
  test('auto creation requests do not carry an identity', () {
    final Creation<ItemData, String> creation = Creation.auto(
      dependency: ItemDependency(),
      data: ItemData('value'),
    );

    expect(creation.dependency, isA<ItemDependency>());
    expect(creation.data.value, 'value');
    expect(creation.identity, isA<AutoIdentity<String>>());
  });

  test('explicit creation requests preserve the final identity', () {
    final CompositeKey key = CompositeKey(['tenant', 7]);
    final Creation<ItemData, CompositeKey> creation = Creation.explicit(
      dependency: const ItemDependency(),
      data: const ItemData('value'),
      identity: key,
    );

    expect(creation.identity, isA<ExplicitIdentity<CompositeKey>>());
    expect((creation.identity as ExplicitIdentity<CompositeKey>).value, key);
  });

  test(
    'resolved creation keeps the dependency, data, and generation state',
    () {
      const ResolvedCreation<ItemData, String> creation = ResolvedCreation(
        dependency: ItemDependency(),
        data: ItemData('value'),
        id: 'id',
        wasGenerated: true,
      );

      expect(creation.dependency, isA<ItemDependency>());
      expect(creation.data.value, 'value');
      expect(creation.id, 'id');
      expect(creation.wasGenerated, isTrue);
    },
  );
}
