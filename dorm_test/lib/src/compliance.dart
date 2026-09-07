import 'package:dorm_framework/dorm_framework.dart';
import 'package:test/test.dart';

import 'adapter.dart';
import 'fixtures.dart';

/// Registers the shared dORM engine conformance tests.
void defineEngineComplianceTests<Q extends BaseQuery<Q>>(
  EngineTestAdapter<Q> adapter,
) {
  group('${adapter.name} dORM compliance', () {
    late EngineTestSession<Q> session;
    EngineTestSession<Q>? openedSession;
    late ComplianceFixtures<Q> fixtures;

    setUp(() async {
      openedSession = await adapter.open();
      session = openedSession!;
      fixtures = ComplianceFixtures(session.engine);
      await session.reset();
    });

    tearDown(() async {
      await openedSession?.close();
      openedSession = null;
    });

    group('portable contract', () {
      test('creates, reads, updates, and deletes identified models', () async {
        final Repository<
          ComplianceItemData,
          ComplianceItem,
          String,
          Q,
          SimpleCreation<ComplianceItemData, String>
        >
        repository = fixtures.items.repository;

        final ComplianceItem automatic = await repository.put(
          Creation.auto<ComplianceItemData, String>(
            dependency: const ComplianceDependency<ComplianceItemData>(),
            data: const ComplianceItemData(
              name: 'automatic',
              value: 0,
              active: true,
            ),
          ),
        );
        expect(automatic.id, isNotEmpty);
        expect(await repository.peek(automatic.id), automatic);

        final ComplianceItem created = await repository.put(
          Creation.explicit(
            dependency: const ComplianceDependency<ComplianceItemData>(),
            data: const ComplianceItemData(
              name: 'first',
              value: 1,
              active: true,
            ),
            identity: 'item-1',
          ),
        );
        expect(created.id, 'item-1');
        expect(await repository.peek('item-1'), created);

        await repository.push(
          const ComplianceItem(
            id: 'item-1',
            name: 'updated',
            value: 2,
            active: false,
          ),
        );
        expect((await repository.peek('item-1'))?.name, 'updated');

        await repository.patch('item-1', (model) {
          expect(model?.id, 'item-1');
          return ComplianceItem(
            id: model!.id,
            name: model.name,
            value: model.value + 1,
            active: model.active,
          );
        });
        expect((await repository.peek('item-1'))?.value, 3);

        await repository.patch('missing', (model) {
          expect(model, isNull);
          return null;
        });
        expect(await repository.peek('missing'), isNull);

        await repository.patch('item-1', (model) {
          expect(model?.id, 'item-1');
          return null;
        });
        expect(await repository.peek('item-1'), isNull);

        await repository.pop('item-1');
        expect(await repository.peek('item-1'), isNull);
      });

      test('keeps independent creations in putAll', () async {
        final repository = fixtures.items.repository;
        final List<ComplianceItem> models = await repository.putAll([
          Creation.explicit(
            dependency: const ComplianceDependency<ComplianceItemData>(),
            data: const ComplianceItemData(
              name: 'first',
              value: 1,
              active: true,
            ),
            identity: 'item-1',
          ),
          Creation.explicit(
            dependency: const ComplianceDependency<ComplianceItemData>(),
            data: const ComplianceItemData(
              name: 'second',
              value: 2,
              active: true,
            ),
            identity: 'item-2',
          ),
        ]);

        expect(models.map((model) => model.id), ['item-1', 'item-2']);
        expect(
          await repository.peekAllKeys(),
          containsAll(['item-1', 'item-2']),
        );
      });

      test('filters, sorts, and limits rows', () async {
        final repository = fixtures.items.repository;
        await repository.pushAll(const [
          ComplianceItem(id: 'a', name: 'alpha', value: 3, active: true),
          ComplianceItem(id: 'b', name: 'beta', value: 1, active: true),
          ComplianceItem(id: 'c', name: 'alphabet', value: 2, active: false),
        ]);

        final List<ComplianceItem> result = await repository.peekAll(
          BaseFilter<Q>.text('alph', key: 'name').sort(key: 'value').limit(1),
        );
        expect(result.map((model) => model.id), ['c']);

        expect(
          (await repository.peekAll(
            BaseFilter<Q>.value(true, key: 'active'),
          )).map((model) => model.id),
          containsAll(['a', 'b']),
        );
      });

      test('supports empty reads, batch deletion, and purge', () async {
        final repository = fixtures.items.repository;
        expect(await repository.peekAll(BaseFilter<Q>.empty()), isEmpty);
        expect(await repository.peekAllKeys(), isEmpty);

        await repository.pushAll(const [
          ComplianceItem(id: 'a', name: 'a', value: 1, active: true),
          ComplianceItem(id: 'b', name: 'b', value: 2, active: true),
          ComplianceItem(id: 'c', name: 'c', value: 3, active: false),
        ]);
        await repository.popKeys(['a']);
        expect(await repository.peek('a'), isNull);
        await repository.popAll(BaseFilter<Q>.value(false, key: 'active'));
        expect(await repository.peek('c'), isNull);
        expect(await repository.peek('b'), isNotNull);
        await repository.purge();
        expect(await repository.peekAll(BaseFilter<Q>.empty()), isEmpty);
      });

      test('emits the initial state from pull and pullAll', () async {
        final repository = fixtures.items.repository;
        await repository.push(
          const ComplianceItem(
            id: 'stream',
            name: 'stream',
            value: 1,
            active: true,
          ),
        );

        expect((await repository.pull('stream').first)?.id, 'stream');
        expect(
          (await repository.pullAll(BaseFilter<Q>.empty()).first).map(
            (model) => model.id,
          ),
          contains('stream'),
        );
      });
    });

    test('emits later changes from reactive streams', () async {
      if (!session.capabilities.reactiveStreams) {
        markTestSkipped('Reactive streams are not supported by this session.');
      }
      final repository = fixtures.items.repository;
      final Stream<List<ComplianceItem>> stream = repository.pullAll(
        BaseFilter<Q>.empty(),
      );
      final Future<List<List<ComplianceItem>>> emissions = stream
          .take(2)
          .toList();
      await repository.push(
        const ComplianceItem(
          id: 'reactive',
          name: 'reactive',
          value: 1,
          active: true,
        ),
      );
      expect((await emissions).last.single.id, 'reactive');
    });

    test('supports negative limits', () async {
      if (!session.capabilities.negativeLimits) {
        markTestSkipped('Negative limits are not supported by this session.');
      }
      final repository = fixtures.items.repository;
      await repository.pushAll(const [
        ComplianceItem(id: 'a', name: 'a', value: 1, active: true),
        ComplianceItem(id: 'b', name: 'b', value: 2, active: true),
      ]);
      expect(
        (await repository.peekAll(BaseFilter<Q>.empty().limit(-1))).length,
        1,
      );
    });

    test('supports explicit composite identities', () async {
      if (!session.capabilities.compositeIdentities) {
        markTestSkipped(
          'Composite identities are not supported by this session.',
        );
      }
      final repository = fixtures.composites.repository;
      final CompositeKey key = CompositeKey(['tenant', 7]);
      final ComplianceComposite model = await repository.put(
        Creation.explicit(
          dependency: const ComplianceDependency<ComplianceCompositeData>(),
          data: const ComplianceCompositeData('value'),
          identity: key,
        ),
      );

      expect(model.id, key);
      expect(await repository.peek(key), model);
    });

    test('rejects malformed composite identities', () async {
      if (!session.capabilities.compositeIdentities) {
        markTestSkipped(
          'Composite identities are not supported by this session.',
        );
      }
      final repository = fixtures.composites.repository;
      expect(
        () => repository.put(
          Creation.explicit<ComplianceCompositeData, CompositeKey>(
            dependency: const ComplianceDependency<ComplianceCompositeData>(),
            data: const ComplianceCompositeData('invalid'),
            identity: CompositeKey(['tenant']),
          ),
        ),
        throwsArgumentError,
      );
    });

    group('relationships', () {
      test(
        'supports one-to-one, one-to-many, many-to-one, and many-to-many',
        () async {
          final parents = fixtures.parents.repository;
          final profiles = fixtures.profiles.repository;
          final children = fixtures.children.repository;
          final links = fixtures.links.repository;

          await parents.push(
            const ComplianceParent(
              id: 'parent',
              name: 'parent',
              profileId: 'profile',
            ),
          );
          await profiles.push(
            const ComplianceProfile(id: 'profile', label: 'profile'),
          );
          await children.pushAll(const [
            ComplianceChild(id: 'child-1', parentId: 'parent', label: 'one'),
            ComplianceChild(id: 'child-2', parentId: 'parent', label: 'two'),
          ]);
          await links.push(
            const ComplianceLink(
              id: 'link',
              parentId: 'parent',
              profileId: 'profile',
            ),
          );

          final relationship = fixtures.parents.relationships;
          expect(
            (await relationship
                    .oneToOne(profiles, on: (parent) => parent.profileId)
                    .peekAll(BaseFilter<Q>.empty()))
                .single
                .right
                ?.id,
            'profile',
          );
          expect(
            (await relationship
                    .oneToMany(
                      children,
                      on: (parent) =>
                          BaseFilter<Q>.value('parent', key: 'parent_id'),
                    )
                    .peekAll(BaseFilter<Q>.empty()))
                .single
                .right,
            hasLength(2),
          );
          final Join<ComplianceParent, List<ComplianceChild>> manyToOne =
              (await fixtures.children.relationships
                      .manyToOne(parents, on: (child) => child.parentId)
                      .peekAll(BaseFilter<Q>.empty()))
                  .single;
          expect(manyToOne.left.id, 'parent');
          expect(manyToOne.right, hasLength(2));
          expect(
            (await fixtures.links.relationships
                    .manyToMany(
                      left: parents,
                      onLeft: (link) => link.parentId,
                      right: profiles,
                      onRight: (link) => link.profileId,
                    )
                    .peekAll(BaseFilter<Q>.empty()))
                .single
                .right
                .$1
                ?.id,
            'parent',
          );
        },
      );
    });
  });
}
