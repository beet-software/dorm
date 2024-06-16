import 'dart:async';

import 'package:dorm_framework/dorm_framework.dart';
import 'package:dorm_mysql_database/src/engine.dart';
import 'package:dotenv/dotenv.dart';
import 'package:mysql_client/mysql_client.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

class ModelData {
  final int value;

  const ModelData({required this.value});
}

class Model extends ModelData {
  final String id;

  const Model({required this.id, required super.value});
}

class ModelDependency extends Dependency<ModelData> {
  const ModelDependency() : super.strong();
}

class ModelEntity implements Entity<ModelData, Model> {
  const ModelEntity();

  @override
  Model convert(Model model, ModelData data) {
    return Model(id: model.id, value: data.value);
  }

  @override
  Model fromData(
    covariant Dependency<ModelData> dependency,
    String id,
    ModelData data,
  ) {
    return Model(id: id, value: data.value);
  }

  @override
  Model fromJson(String id, Map data) => Model(id: id, value: data['value']);

  @override
  String identify(Model model) => model.id;

  @override
  final String tableName = 'Models';

  @override
  Map<String, Object?> toJson(ModelData data) => {'value': data.value};
}

void main() async {
  final DotEnv env = DotEnv();
  env.load();

  // Shall run
  // ```sql
  // CREATE TABLE IF NOT EXISTS Models (
  //   id CHAR(36) NOT NULL,
  //   value INTEGER NOT NULL,
  //   PRIMARY KEY (id)
  // );
  // ```
  final MySQLConnection connection = await MySQLConnection.createConnection(
    host: env['MYSQL_HOST']!,
    port: int.parse(env['MYSQL_PORT']!),
    userName: env['MYSQL_USERNAME']!,
    password: env['MYSQL_PASSWORD']!,
  );
  await connection.connect();
  await connection.execute("USE test;");
  final Engine engine = Engine(connection);
  final BaseReference reference = engine.createReference();
  const ModelEntity entity = ModelEntity();
  final RegExp uuidRegExp = RegExp(
      r'^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$');
  setUp(() async {
    await connection.execute("DELETE FROM Models;");
  });

  group('querying', () {
    group('empty state', () {
      test('peek', () async {
        final Model? model = await reference.peek(entity, 'abcdef');
        expect(model, isNull);
      });
      test('peekAll', () async {
        final List<Model> models =
            await reference.peekAll(entity, Filter.empty());
        expect(models, isEmpty);
      });
      test('peekAllKeys', () async {
        final List<String> keys = await reference.peekAllKeys(entity);
        expect(keys, isEmpty);
      });
      test('pull', () async {
        late StreamSubscription<void> subscription;
        subscription = reference.pull(entity, 'abcdef').listen((model) {
          expect(model, null);
          subscription.cancel();
        });
        addTearDown(subscription.cancel);
      });
      test('pullAll', () async {
        final List<Model> models =
            await reference.pullAll(entity, Filter.empty()).first;
        expect(models, isEmpty);
      });
    });
    test('put', () async {
      final Model model = await reference.put(
        entity,
        ModelDependency(),
        ModelData(value: 42),
      );
      expect(model.id, matches(uuidRegExp));
      expect(model.value, 42);
    });
    group('put (post)', () {
      late Model localModel;
      setUp(() async {
        localModel = await reference.put(
          entity,
          ModelDependency(),
          ModelData(value: 42),
        );
      });
      test('peek', () async {
        final Model? model = await reference.peek(entity, localModel.id);
        expect(model, isNotNull);
        expect(model?.id, localModel.id);
        expect(model?.value, 42);
      });
      test('peekAll', () async {
        final List<Model> model =
            await reference.peekAll(entity, const Filter.empty());
        expect(model, isNotEmpty);
        expect(model.length, 1);
        expect(model[0].id, localModel.id);
        expect(model[0].value, 42);
      });
      test('peekAllKeys', () async {
        final List<String> keys = await reference.peekAllKeys(entity);
        expect(keys, isNotEmpty);
        expect(keys.length, 1);
        expect(keys[0], localModel.id);
      });
      test('pull', () async {
        late StreamSubscription<void> subscription;
        subscription = reference.pull(entity, 'abcdef').listen((model) {
          expect(model?.value, 42);
          subscription.cancel();
        });
        addTearDown(subscription.cancel);
      });
      test('pullAll', () async {
        final List<Model> model =
            await reference.pullAll(entity, const Filter.empty()).first;
        expect(model, isNotEmpty);
        expect(model.length, 1);
        expect(model[0].id, localModel.id);
        expect(model[0].value, 42);
      });
    });
    test('push: non-existing', () async {
      await reference.push(entity, Model(id: 'abcdef', value: 42));
    });
    test('push: existing', () async {
      await reference.push(entity, Model(id: 'abcdef', value: 42));
      final Model? m1 = await reference.peek(entity, 'abcdef');
      expect(m1?.value, 42);
      await reference.push(entity, Model(id: 'abcdef', value: 43));
      final Model? m2 = await reference.peek(entity, 'abcdef');
      expect(m2?.value, 43);
    });
    group('push (post)', () {
      final Model localModel = Model(id: 'abcdef', value: 42);
      setUp(() async {
        await reference.push(entity, localModel);
      });
      test('peek', () async {
        final Model? model = await reference.peek(entity, localModel.id);
        expect(model, isNotNull);
        expect(model?.id, localModel.id);
        expect(model?.value, 42);
      });
      test('peekAll', () async {
        final List<Model> model =
            await reference.peekAll(entity, const Filter.empty());
        expect(model, isNotEmpty);
        expect(model.length, 1);
        expect(model[0].id, localModel.id);
        expect(model[0].value, 42);
      });
      test('peekAllKeys', () async {
        final List<String> keys = await reference.peekAllKeys(entity);
        expect(keys, isNotEmpty);
        expect(keys.length, 1);
        expect(keys[0], localModel.id);
      });
      test('pull', () async {
        late StreamSubscription<void> subscription;
        subscription = reference.pull(entity, 'abcdef').listen((model) {
          expect(model?.value, 42);
          subscription.cancel();
        });
        addTearDown(subscription.cancel);
      });
      test('pullAll', () async {
        final List<Model> model =
            await reference.pullAll(entity, const Filter.empty()).first;
        expect(model, isNotEmpty);
        expect(model.length, 1);
        expect(model[0].id, localModel.id);
        expect(model[0].value, 42);
      });
    });
    test('putAll', () async {
      await reference.putAll(entity, const ModelDependency(), [
        ModelData(value: 2),
        ModelData(value: 3),
      ]);
    });
    group('putAll (post)', () {
      late List<Model> localModels;
      setUp(() async {
        await reference.push(entity, Model(id: 'abcdef', value: 1));
        localModels = await reference.putAll(entity, const ModelDependency(), [
          ModelData(value: 2),
          ModelData(value: 3),
        ]);
      });
      test('peek', () async {
        await reference
            .peek(entity, 'abcdef')
            .then((model) => expect(model?.value, 1));
        for (Model localModel in localModels) {
          final Model? remoteModel =
              await reference.peek(entity, localModel.id);
          expect(remoteModel?.value, localModel.value);
        }
      });
      test('peekAll', () async {
        final List<Model> models =
            await reference.peekAll(entity, Filter.empty());
        expect(models.length, 3);
      });
      test('peekAllKeys', () async {
        final List<String> keys = await reference.peekAllKeys(entity);
        expect(keys.length, 3);
      });
      test('pull', () async {
        await reference
            .pull(entity, 'abcdef')
            .first
            .then((model) => expect(model?.value, 1));
        for (Model localModel in localModels) {
          final Model? remoteModel =
              await reference.pull(entity, localModel.id).first;
          expect(remoteModel?.value, localModel.value);
        }
      });
      test('pullAll', () async {
        final List<Model> models =
            await reference.pullAll(entity, Filter.empty()).first;
        expect(models.length, 3);
      });
    });
    test('pushAll', () async {
      await reference.pushAll(entity, [
        Model(id: 'ghijkl', value: 2),
        Model(id: 'mnopqr', value: 3),
      ]);
    });
    group('pushAll (post)', () {
      setUp(() async {
        await reference.push(entity, Model(id: 'abcdef', value: 1));
        await reference.pushAll(entity, [
          Model(id: 'ghijkl', value: 2),
          Model(id: 'mnopqr', value: 3),
        ]);
      });
      test('peek', () async {
        await reference
            .peek(entity, 'abcdef')
            .then((model) => expect(model?.value, 1));
        await reference
            .peek(entity, 'ghijkl')
            .then((model) => expect(model?.value, 2));
        await reference
            .peek(entity, 'mnopqr')
            .then((model) => expect(model?.value, 3));
      });
      test('peekAll', () async {
        final List<Model> models =
            await reference.peekAll(entity, Filter.empty());
        expect(models.length, 3);
        expect(models[0].id, 'abcdef');
        expect(models[1].id, 'ghijkl');
        expect(models[2].id, 'mnopqr');
      });
      test('peekAllKeys', () async {
        final List<String> keys = await reference.peekAllKeys(entity);
        expect(keys.length, 3);
        expect(keys[0], 'abcdef');
        expect(keys[1], 'ghijkl');
        expect(keys[2], 'mnopqr');
      });
      test('pull', () async {
        await reference
            .pull(entity, 'abcdef')
            .first
            .then((model) => expect(model?.value, 1));
        await reference
            .pull(entity, 'ghijkl')
            .first
            .then((model) => expect(model?.value, 2));
        await reference
            .pull(entity, 'mnopqr')
            .first
            .then((model) => expect(model?.value, 3));
      });
      test('pullAll', () async {
        final List<Model> models =
            await reference.pullAll(entity, Filter.empty()).first;
        expect(models.length, 3);
        expect(models[0].id, 'abcdef');
        expect(models[1].id, 'ghijkl');
        expect(models[2].id, 'mnopqr');
      });
    });
    test('popAll', () async {
      await reference.popAll(entity, const Filter.empty());
    });
    group('popAll (post)', () {
      setUp(() async {
        await reference.push(entity, Model(id: 'abcdef', value: 1));
        await reference.popAll(entity, const Filter.empty());
      });
      test('peek', () async {
        final Model? model = await reference.peek(entity, 'abcdef');
        expect(model, isNull);
      });
      test('peekAll', () async {
        final List<Model> models =
            await reference.peekAll(entity, Filter.empty());
        expect(models, isEmpty);
      });
      test('peekAllKeys', () async {
        final List<String> keys = await reference.peekAllKeys(entity);
        expect(keys, isEmpty);
      });
      test('pull', () async {
        final Model? model = await reference.pull(entity, 'abcdef').first;
        expect(model, isNull);
      });
      test('pullAll', () async {
        final List<Model> models =
            await reference.pullAll(entity, Filter.empty()).first;
        expect(models, isEmpty);
      });
    });
    test('pop: non-existing', () async {
      await reference.pop(entity, 'abcdef');
    });
    test('pop: existing', () async {
      await reference.push(entity, Model(id: 'abcdef', value: 42));
      await reference.pop(entity, 'abcdef');
      final Model? model = await reference.peek(entity, 'abcdef');
      expect(model?.value, null);
    });
    group('popKeys: non-existing', () {
      setUp(() async {
        await reference.popKeys(entity, ['abcdef', 'ghijkl']);
      });
      test('peek', () async {
        final Model? m1 = await reference.peek(entity, 'abcdef');
        expect(m1?.value, null);
        final Model? m2 = await reference.peek(entity, 'ghijkl');
        expect(m2?.value, null);
        final Model? m3 = await reference.peek(entity, 'mnopqr');
        expect(m3?.value, null);
      });
      test('peekAll', () async {
        final List<Model> models =
            await reference.peekAll(entity, Filter.empty());
        expect(models, isEmpty);
      });
      test('peekAllKeys', () async {
        final List<String> keys = await reference.peekAllKeys(entity);
        expect(keys, isEmpty);
      });
      test('pull', () async {
        final Model? m1 = await reference.pull(entity, 'abcdef').first;
        expect(m1?.value, null);
        final Model? m2 = await reference.pull(entity, 'ghijkl').first;
        expect(m2?.value, null);
        final Model? m3 = await reference.pull(entity, 'mnopqr').first;
        expect(m3?.value, null);
      });
      test('pullAll', () async {
        final List<Model> models =
            await reference.pullAll(entity, Filter.empty()).first;
        expect(models, isEmpty);
      });
    });
    group('popKeys: existing, partial', () {
      setUp(() async {
        await reference.push(entity, Model(id: 'abcdef', value: 1));
        await reference.push(entity, Model(id: 'mnopqr', value: 3));
        await reference.popKeys(entity, ['abcdef', 'ghijkl']);
      });
      test('peek', () async {
        final Model? m1 = await reference.peek(entity, 'abcdef');
        expect(m1?.value, null);
        final Model? m2 = await reference.peek(entity, 'ghijkl');
        expect(m2?.value, null);
        final Model? m3 = await reference.peek(entity, 'mnopqr');
        expect(m3?.value, 3);
      });
      test('peekAll', () async {
        final List<Model> models =
            await reference.peekAll(entity, Filter.empty());
        expect(models.length, 1);
        expect(models[0].id, 'mnopqr');
      });
      test('peekAllKeys', () async {
        final List<String> keys = await reference.peekAllKeys(entity);
        expect(keys.length, 1);
        expect(keys[0], 'mnopqr');
      });
      test('pull', () async {
        final Model? m1 = await reference.pull(entity, 'abcdef').first;
        expect(m1?.value, null);
        final Model? m2 = await reference.pull(entity, 'ghijkl').first;
        expect(m2?.value, null);
        final Model? m3 = await reference.pull(entity, 'mnopqr').first;
        expect(m3?.value, 3);
      });
      test('pullAll', () async {
        final List<Model> models =
            await reference.pullAll(entity, Filter.empty()).first;
        expect(models.length, 1);
        expect(models[0].id, 'mnopqr');
      });
    });
    group('popKeys: existing, complete', () {
      setUp(() async {
        await reference.push(entity, Model(id: 'abcdef', value: 1));
        await reference.push(entity, Model(id: 'ghijkl', value: 2));
        await reference.push(entity, Model(id: 'mnopqr', value: 3));
        await reference.popKeys(entity, ['abcdef', 'ghijkl', 'mnopqr']);
      });
      test('peek', () async {
        final Model? m1 = await reference.peek(entity, 'abcdef');
        expect(m1?.value, null);
        final Model? m2 = await reference.peek(entity, 'ghijkl');
        expect(m2?.value, null);
        final Model? m3 = await reference.peek(entity, 'mnopqr');
        expect(m3?.value, null);
      });
      test('peekAll', () async {
        final List<Model> models =
            await reference.peekAll(entity, Filter.empty());
        expect(models, isEmpty);
      });
      test('peekAllKeys', () async {
        final List<String> keys = await reference.peekAllKeys(entity);
        expect(keys, isEmpty);
      });
      test('peek', () async {
        final Model? m1 = await reference.pull(entity, 'abcdef').first;
        expect(m1?.value, null);
        final Model? m2 = await reference.pull(entity, 'ghijkl').first;
        expect(m2?.value, null);
        final Model? m3 = await reference.pull(entity, 'mnopqr').first;
        expect(m3?.value, null);
      });
    });
    test('purge', () async {
      await reference.purge(entity);
    });
    group('purge (post)', () {
      setUp(() async {
        await reference.push(entity, Model(id: 'abc', value: 42));
        await reference.purge(entity);
      });
      test('peek', () async {
        final Model? model = await reference.peek(entity, 'abcdef');
        expect(model, isNull);
      });
      test('peekAll', () async {
        final List<Model> models =
            await reference.peekAll(entity, Filter.empty());
        expect(models, isEmpty);
      });
      test('peekAllKeys', () async {
        final List<String> keys = await reference.peekAllKeys(entity);
        expect(keys, isEmpty);
      });
      test('pull', () async {
        final Model? model = await reference.pull(entity, 'abcdef').first;
        expect(model, isNull);
      });
      test('pullAll', () async {
        final List<Model> models =
            await reference.pullAll(entity, Filter.empty()).first;
        expect(models, isEmpty);
      });
    });
    test('patch: non-existing, writing', () async {
      await reference.patch(entity, 'abcdef', (_) {
        return Model(id: 'abcdef', value: 42);
      });
      final Model? model = await reference.peek(entity, 'abcdef');
      expect(model?.value, 42);
    });
    test('patch: non-existing, deleting', () async {
      await reference.patch(entity, 'abcdef', (_) => null);
      final Model? model = await reference.peek(entity, 'abcdef');
      expect(model?.value, null);
    });
    test('patch: existing, writing', () async {
      await reference.push(entity, Model(id: 'abcdef', value: 42));
      await reference.patch(entity, 'abcdef', (model) {
        return Model(id: model?.id ?? 'abcdef', value: 43);
      });
      final Model? model = await reference.peek(entity, 'abcdef');
      expect(model?.value, 43);
    });
    test('patch: existing, deleting', () async {
      await reference.push(entity, Model(id: 'abcdef', value: 42));
      await reference.patch(entity, 'abcdef', (_) => null);
      final Model? model = await reference.peek(entity, 'abcdef');
      expect(model?.value, null);
    });
  });
  group('filtering', () {
    group('empty', () {
      setUp(() async {
        await reference.pushAll(entity, [
          Model(id: 'abcdef', value: 2),
          Model(id: 'ghijkl', value: 4),
          Model(id: 'mnopqr', value: 8),
        ]);
      });
      test('peekAll', () async {
        final List<Model> models =
            await reference.peekAll(entity, Filter.empty());
        expect(models.length, 3);
      });
      test('pullAll', () async {
        final List<Model> models =
            await reference.pullAll(entity, Filter.empty()).first;
        expect(models.length, 3);
      });
      test('popAll', () async {
        await reference.popAll(entity, Filter.empty());
        final List<Model> models =
            await reference.peekAll(entity, Filter.empty());
        expect(models.length, 0);
      });
    });
    group('value', () {
      setUp(() async {
        await reference.pushAll(entity, [
          Model(id: 'abcdef', value: 2),
          Model(id: 'ghijkl', value: 4),
          Model(id: 'mnopqr', value: 8),
        ]);
      });
      test('peekAll', () async {
        List<Model> models;
        models = await reference.peekAll(entity, Filter.value(0, key: 'value'));
        expect(models.length, 0);
        models = await reference.peekAll(entity, Filter.value(4, key: 'value'));
        expect(models.length, 1);
      });
      test('pullAll', () async {
        List<Model> models;
        models = await reference
            .pullAll(entity, Filter.value(0, key: 'value'))
            .first;
        expect(models.length, 0);
        models = await reference
            .pullAll(entity, Filter.value(4, key: 'value'))
            .first;
        expect(models.length, 1);
      });
      test('popAll: non-existing', () async {
        await reference.popAll(entity, Filter.value(0, key: 'value'));
        final List<Model> models =
            await reference.peekAll(entity, Filter.empty());
        expect(models.length, 3);
      });
      test('popAll: existing', () async {
        await reference.popAll(entity, Filter.value(4, key: 'value'));
        final List<Model> models =
            await reference.peekAll(entity, Filter.empty());
        expect(models.length, 2);
      });
    });
  });
}
