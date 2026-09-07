import 'dart:io';

import 'package:dorm_framework/dorm_framework.dart';
import 'package:dorm_mongo_database/src/filter.dart' as dorm;
import 'package:dorm_mongo_database/src/query.dart';
import 'package:dorm_mongo_database/src/reference.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:test/test.dart';

class _ItemData {
  final String title;
  final int value;

  const _ItemData({required this.title, required this.value});
}

class _Item extends _ItemData {
  final String id;

  const _Item({required this.id, required super.title, required super.value});
}

class _ItemDependency extends Dependency<_ItemData> {
  const _ItemDependency() : super.strong();
}

class _ItemEntity
    implements
        Entity<_ItemData, _Item, String, SimpleCreation<_ItemData, String>> {
  const _ItemEntity();

  @override
  bool get supportsAutomaticIdentity => true;

  @override
  PrimaryKeyCodec<String> get primaryKeyCodec => const SinglePrimaryKeyCodec();

  @override
  final EntitySchema schema = const EntitySchema(
    tableName: 'dorm_mongo_test_items',
    primaryKey: FieldSchema(fieldName: 'id', columnName: 'id'),
  );

  @override
  _Item convert(_Item model, _ItemData data) {
    return _Item(id: model.id, title: data.title, value: data.value);
  }

  @override
  _Item fromData(ResolvedCreation<_ItemData, String> creation) {
    return _Item(
      id: creation.id,
      title: creation.data.title,
      value: creation.data.value,
    );
  }

  @override
  _Item fromJson(String id, Map data) {
    return _Item(
      id: id,
      title: data['title'] as String,
      value: data['value'] as int,
    );
  }

  @override
  String identify(_Item model) => model.id;

  @override
  Map<String, Object?> toJson(_ItemData data) => {
    'title': data.title,
    'value': data.value,
  };
}

class _CompositeData {
  final String value;

  const _CompositeData(this.value);
}

class _CompositeModel extends _CompositeData {
  final CompositeKey id;

  const _CompositeModel({required this.id, required String value})
    : super(value);
}

class _CompositeDependency extends Dependency<_CompositeData> {
  const _CompositeDependency() : super.strong();
}

class _CompositeEntity
    implements
        Entity<
          _CompositeData,
          _CompositeModel,
          CompositeKey,
          ExplicitCreation<_CompositeData, CompositeKey>
        > {
  const _CompositeEntity();

  @override
  bool get supportsAutomaticIdentity => false;

  @override
  PrimaryKeyCodec<CompositeKey> get primaryKeyCodec =>
      const CompositePrimaryKeyCodec();

  @override
  final EntitySchema schema = const EntitySchema(
    tableName: 'dorm_mongo_test_composite_items',
    primaryKey: FieldSchema(fieldName: 'first', columnName: 'first'),
    primaryKeys: [
      FieldSchema(fieldName: 'first', columnName: 'first'),
      FieldSchema(fieldName: 'second', columnName: 'second'),
    ],
  );

  @override
  _CompositeModel convert(_CompositeModel model, _CompositeData data) =>
      _CompositeModel(id: model.id, value: data.value);

  @override
  _CompositeModel fromData(
    ResolvedCreation<_CompositeData, CompositeKey> creation,
  ) => _CompositeModel(id: creation.id, value: creation.data.value);

  @override
  _CompositeModel fromJson(CompositeKey id, Map data) =>
      _CompositeModel(id: id, value: data['value'] as String);

  @override
  CompositeKey identify(_CompositeModel model) => model.id;

  @override
  Map<String, Object?> toJson(_CompositeData data) => {'value': data.value};
}

void main() {
  test('rejects put for composite identities before database access', () {
    final Reference reference = Reference(Db('mongodb://invalid-host'));

    expect(
      () => reference.put(
        const _CompositeEntity(),
        const Creation.auto(
          dependency: _CompositeDependency(),
          data: _CompositeData('value'),
        ),
      ),
      throwsUnsupportedError,
    );
  });

  final String? uri = Platform.environment['MONGO_URI'];
  group(
    'MongoDB reference integration',
    () {
      late Db database;
      const _ItemEntity entity = _ItemEntity();
      late Reference reference;

      setUpAll(() async {
        database = Db(uri!);
        await database.open();
        reference = Reference(database);
        await database.collection(entity.schema.tableName).deleteMany({});
        await database
            .collection(const _CompositeEntity().schema.tableName)
            .deleteMany({});
      });

      setUp(() async {
        await database.collection(entity.schema.tableName).deleteMany({});
        await database
            .collection(const _CompositeEntity().schema.tableName)
            .deleteMany({});
      });

      tearDownAll(() async {
        await database.collection(entity.schema.tableName).drop();
        await database
            .collection(const _CompositeEntity().schema.tableName)
            .drop();
        await database.close();
      });

      test('inserts and reads a generated model', () async {
        final _Item item = await reference.put(
          entity,
          const Creation.auto(
            dependency: _ItemDependency(),
            data: _ItemData(title: 'first', value: 1),
          ),
        );

        expect(item.id, matches(RegExp(r'^[0-9a-f-]{36}$')));
        expect(await reference.peek(entity, item.id), item);
      });

      test('replaces an identified model with upsert semantics', () async {
        const _Item first = _Item(id: 'fixed', title: 'first', value: 1);
        const _Item second = _Item(id: 'fixed', title: 'second', value: 2);

        await reference.push(entity, first);
        await reference.push(entity, second);

        expect(await reference.peek(entity, 'fixed'), second);
      });

      test(
        'inserts and reads an explicitly identified composite document',
        () async {
          const _CompositeEntity composite = _CompositeEntity();
          final CompositeKey key = CompositeKey(['tenant', 7]);

          final _CompositeModel model = await reference.put(
            composite,
            Creation.explicit(
              dependency: const _CompositeDependency(),
              data: const _CompositeData('value'),
              identity: key,
            ),
          );

          expect(model.id, key);
          expect(await reference.peek(composite, key), model);
        },
      );

      test('inserts multiple generated models', () async {
        final List<_Item> items = await reference.putAll(entity, const [
          Creation.auto(
            dependency: _ItemDependency(),
            data: _ItemData(title: 'first', value: 1),
          ),
          Creation.auto(
            dependency: _ItemDependency(),
            data: _ItemData(title: 'second', value: 2),
          ),
        ]);

        expect(await reference.peekAllKeys(entity), hasLength(2));
        expect(items, hasLength(2));
      });

      test('filters, sorts, and limits documents', () async {
        await reference.pushAll(entity, const [
          _Item(id: 'a', title: 'alpha', value: 3),
          _Item(id: 'b', title: 'beta', value: 1),
          _Item(id: 'c', title: 'alphabet', value: 2),
        ]);

        final List<_Item> result = await reference.peekAll(
          entity,
          dorm.Filter.text('alph', key: 'title').sort(key: 'value').limit(1),
        );

        expect(result.map((item) => item.id), ['c']);
      });

      test('patches and removes a model', () async {
        await reference.push(
          entity,
          const _Item(id: 'patch', title: 'old', value: 1),
        );

        await reference.patch(entity, 'patch', (model) {
          final _Item current = model!;
          return _Item(id: current.id, title: 'new', value: current.value + 1);
        });
        expect((await reference.peek(entity, 'patch'))?.title, 'new');

        await reference.patch(entity, 'patch', (_) => null);
        expect(await reference.peek(entity, 'patch'), isNull);
      });

      test('removes the requested sorted and limited documents', () async {
        await reference.pushAll(entity, const [
          _Item(id: 'a', title: 'first', value: 3),
          _Item(id: 'b', title: 'second', value: 1),
          _Item(id: 'c', title: 'third', value: 2),
        ]);

        await reference.popAll(
          entity,
          BaseFilter<Query>.empty().sort(key: 'value').limit(1),
        );

        expect(await reference.peek(entity, 'b'), isNull);
        expect(await reference.peek(entity, 'a'), isNotNull);
      });

      test('reads and removes a composite identity', () async {
        const _CompositeEntity composite = _CompositeEntity();
        final CompositeKey key = CompositeKey(['tenant', 7]);
        final _CompositeModel model = _CompositeModel(
          id: CompositeKey(['tenant', 7]),
          value: 'value',
        );

        await reference.push(composite, model);
        expect(await reference.peek(composite, key), model);

        await reference.popKeys(composite, [key]);
        expect(await reference.peek(composite, key), isNull);
      });

      test('emits one initial value from pullAll', () async {
        await reference.push(
          entity,
          const _Item(id: 'stream', title: 'value', value: 1),
        );

        final List<List<_Item>> emissions = await reference
            .pullAll(entity, const dorm.Filter.empty())
            .toList();

        expect(emissions, hasLength(1));
        expect(emissions.single.single.id, 'stream');
      });
    },
    skip: uri == null
        ? 'Set MONGO_URI to run MongoDB integration tests.'
        : false,
  );
}
