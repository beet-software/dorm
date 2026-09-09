import 'package:dorm_framework/dorm_framework.dart';
import 'package:test/test.dart';

import 'adapter.dart';
import 'fixtures.dart';

const FieldSchema _nameField = FieldSchema(
  fieldName: 'name',
  columnName: 'name',
);
const FieldSchema _valueField = FieldSchema(
  fieldName: 'value',
  columnName: 'value',
);
const FieldSchema _activeField = FieldSchema(
  fieldName: 'active',
  columnName: 'active',
);
const FieldSchema _parentIdField = FieldSchema(
  fieldName: 'parentId',
  columnName: 'parent_id',
);

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
          SimpleCreation<ComplianceItemData, String>,
          OffsetPageRequest
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
          BaseFilter<Q>.text('alph', field: _nameField),
          const QueryOptions(orderBy: [OrderBy(_valueField)], limit: 1),
        );
        expect(result.map((model) => model.id), ['c']);

        expect(
          (await repository.peekAll(
            BaseFilter<Q>.value(true, field: _activeField),
          )).map((model) => model.id),
          containsAll(['a', 'b']),
        );
      });

      test('reads an offset page with continuation metadata', () async {
        final repository = fixtures.items.repository;
        await repository.pushAll(const [
          ComplianceItem(id: 'a', name: 'a', value: 1, active: true),
          ComplianceItem(id: 'b', name: 'b', value: 2, active: true),
          ComplianceItem(id: 'c', name: 'c', value: 3, active: true),
        ]);

        final Page<ComplianceItem> page = await repository.peekPage(
          BaseFilter<Q>.empty(),
          const OffsetPageRequest(
            size: 1,
            offset: 1,
            orderBy: [OrderBy(_valueField)],
          ),
        );

        expect(page.items.map((model) => model.id), ['b']);
        expect(page.hasNext, isTrue);
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
        await repository.popAll(
          BaseFilter<Q>.value(false, field: _activeField),
        );
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
                          BaseFilter<Q>.value('parent', field: _parentIdField),
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

/// Registers scalar, set, and null-filter conformance tests.
void defineEngineComparisonFilterTests<Q extends ComparisonQuery<Q>>(
  EngineTestAdapter<Q> adapter,
) {
  group('${adapter.name} comparison filters', () {
    late EngineTestSession<Q> session;
    EngineTestSession<Q>? openedSession;

    setUp(() async {
      openedSession = await adapter.open();
      session = openedSession!;
      if (!session.capabilities.comparisonFilters) {
        markTestSkipped(
          'Comparison filters are not supported by this session.',
        );
      }
      await session.reset();
    });

    tearDown(() async {
      await openedSession?.close();
      openedSession = null;
    });

    test('supports comparisons, sets, and null checks', () async {
      final ComplianceFixtures<Q> fixtures = ComplianceFixtures(session.engine);
      final repository = fixtures.items.repository;
      await repository.pushAll(const [
        ComplianceItem(id: 'low', name: 'low', value: 1, active: true),
        ComplianceItem(id: 'high', name: 'high', value: 10, active: false),
      ]);

      expect(
        (await repository.peekAll(
          BaseFilter.greaterThan<Q>(2, field: _valueField),
        )).map((model) => model.id),
        ['high'],
      );
      expect(
        (await repository.peekAll(
          BaseFilter.inValues<Q>(const [1], field: _valueField),
        )).map((model) => model.id),
        ['low'],
      );
      expect(
        (await repository.peekAll(
          BaseFilter.isNotNull<Q>(field: _nameField),
        )).map((model) => model.id),
        containsAll(['low', 'high']),
      );
    });
  });
}

/// Registers boolean-composition conformance tests.
void defineEngineLogicalFilterTests<Q extends LogicalQuery<Q>>(
  EngineTestAdapter<Q> adapter,
) {
  group('${adapter.name} logical filters', () {
    late EngineTestSession<Q> session;
    EngineTestSession<Q>? openedSession;

    setUp(() async {
      openedSession = await adapter.open();
      session = openedSession!;
      if (!session.capabilities.logicalFilters) {
        markTestSkipped('Logical filters are not supported by this session.');
      }
      await session.reset();
    });

    tearDown(() async {
      await openedSession?.close();
      openedSession = null;
    });

    test('supports allOf and anyOf', () async {
      final ComplianceFixtures<Q> fixtures = ComplianceFixtures(session.engine);
      final repository = fixtures.items.repository;
      await repository.pushAll(const [
        ComplianceItem(id: 'a', name: 'alpha', value: 1, active: true),
        ComplianceItem(id: 'b', name: 'beta', value: 2, active: false),
        ComplianceItem(id: 'c', name: 'charlie', value: 3, active: true),
      ]);

      final BaseFilter<Q> active = BaseFilter<Q>.value(
        true,
        field: _activeField,
      );
      final BaseFilter<Q> named = BaseFilter<Q>.text('al', field: _nameField);
      expect(
        (await repository.peekAll(
          BaseFilter.allOf<Q>([active, named]),
        )).map((model) => model.id),
        ['a'],
      );
      expect(
        (await repository.peekAll(
          BaseFilter.anyOf<Q>([active, named]),
        )).map((model) => model.id),
        containsAll(['a', 'c']),
      );
    });
  });
}

/// Registers negation conformance tests.
void defineEngineNegationFilterTests<Q extends NegationQuery<Q>>(
  EngineTestAdapter<Q> adapter,
) {
  group('${adapter.name} negation filters', () {
    late EngineTestSession<Q> session;
    EngineTestSession<Q>? openedSession;

    setUp(() async {
      openedSession = await adapter.open();
      session = openedSession!;
      if (!session.capabilities.negationFilters) {
        markTestSkipped('Negation filters are not supported by this session.');
      }
      await session.reset();
    });

    tearDown(() async {
      await openedSession?.close();
      openedSession = null;
    });

    test('supports not', () async {
      final ComplianceFixtures<Q> fixtures = ComplianceFixtures(session.engine);
      final repository = fixtures.items.repository;
      await repository.pushAll(const [
        ComplianceItem(id: 'active', name: 'active', value: 1, active: true),
        ComplianceItem(
          id: 'inactive',
          name: 'inactive',
          value: 2,
          active: false,
        ),
      ]);

      final BaseFilter<Q> active = BaseFilter<Q>.value(
        true,
        field: _activeField,
      );
      expect(
        (await repository.peekAll(
          BaseFilter.not<Q>(active),
        )).map((model) => model.id),
        ['inactive'],
      );
    });
  });
}

/// Registers the optional portable transaction conformance tests.
void defineEngineTransactionComplianceTests<Q extends BaseQuery<Q>>(
  TransactionalEngineTestAdapter<Q> adapter,
) {
  group('${adapter.name} dORM transactions', () {
    late TransactionalEngineTestSession<Q> session;
    TransactionalEngineTestSession<Q>? openedSession;

    setUp(() async {
      openedSession = await adapter.open();
      session = openedSession!;
      if (!session.capabilities.transactions) {
        markTestSkipped('Transactions are not supported by this session.');
      }
      await session.reset();
    });

    tearDown(() async {
      await openedSession?.close();
      openedSession = null;
    });

    test('commits work across repositories', () async {
      late BaseEngine<Q, OffsetPageRequest> transactionContext;
      final String id = await session.transactionalEngine.transaction((
        engine,
      ) async {
        transactionContext = engine;
        final ComplianceFixtures<Q> fixtures = ComplianceFixtures(engine);
        final ComplianceItem item = await fixtures.items.repository.put(
          Creation.explicit(
            dependency: const ComplianceDependency<ComplianceItemData>(),
            data: const ComplianceItemData(
              name: 'transactional',
              value: 1,
              active: true,
            ),
            identity: 'transaction-item',
          ),
        );
        await fixtures.profiles.repository.put(
          Creation.explicit(
            dependency: const ComplianceDependency<ComplianceProfileData>(),
            data: const ComplianceProfileData(label: 'transactional'),
            identity: 'transaction-profile',
          ),
        );
        return item.id;
      });

      final ComplianceFixtures<Q> fixtures = ComplianceFixtures(session.engine);
      expect(id, 'transaction-item');
      expect(await fixtures.items.repository.peek(id), isNotNull);
      expect(
        await fixtures.profiles.repository.peek('transaction-profile'),
        isNotNull,
      );
      expect(
        () => transactionContext.createReference(),
        throwsA(isA<StateError>()),
      );
    });

    test('rolls back work when the callback fails', () async {
      late BaseEngine<Q, OffsetPageRequest> transactionContext;
      await expectLater(
        session.transactionalEngine.transaction<void>((engine) async {
          transactionContext = engine;
          final ComplianceFixtures<Q> fixtures = ComplianceFixtures(engine);
          await fixtures.items.repository.push(
            const ComplianceItem(
              id: 'rolled-back',
              name: 'rolled-back',
              value: 1,
              active: true,
            ),
          );
          throw StateError('abort transaction');
        }),
        throwsA(isA<StateError>()),
      );

      final ComplianceFixtures<Q> fixtures = ComplianceFixtures(session.engine);
      expect(await fixtures.items.repository.peek('rolled-back'), isNull);
      expect(
        () => transactionContext.createReference(),
        throwsA(isA<StateError>()),
      );
    });

    test('rejects streams inside a transaction', () async {
      await expectLater(
        session.transactionalEngine.transaction<void>((engine) async {
          final ComplianceFixtures<Q> fixtures = ComplianceFixtures(engine);
          expect(
            () => fixtures.items.repository.pull('stream'),
            throwsA(isA<UnsupportedError>()),
          );
        }),
        completes,
      );
    });

    test('rejects nested transactions', () async {
      await expectLater(
        session.transactionalEngine.transaction<void>((engine) async {
          await expectLater(
            session.transactionalEngine.transaction<void>((_) async {}),
            throwsA(isA<StateError>()),
          );
        }),
        completes,
      );
    });
  });
}
