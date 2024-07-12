import 'dart:async';

import 'package:dorm_framework/dorm_framework.dart';
import 'package:dorm_mysql_database/src/engine.dart';
import 'package:dorm_mysql_database/src/filter.dart';
import 'package:dotenv/dotenv.dart';
import 'package:mysql_client/mysql_client.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

class IntegerData {
  final int value;

  const IntegerData({required this.value});
}

class Integer extends IntegerData {
  final String id;

  const Integer({required this.id, required super.value});
}

class IntegerDependency extends Dependency<IntegerData> {
  const IntegerDependency() : super.strong();
}

class IntegerEntity implements Entity<IntegerData, Integer> {
  const IntegerEntity();

  @override
  Integer convert(Integer model, IntegerData data) {
    return Integer(id: model.id, value: data.value);
  }

  @override
  Integer fromData(
    covariant Dependency<IntegerData> dependency,
    String id,
    IntegerData data,
  ) {
    return Integer(id: id, value: data.value);
  }

  @override
  Integer fromJson(String id, Map data) =>
      Integer(id: id, value: data['value']);

  @override
  String identify(Integer model) => model.id;

  @override
  final String tableName = 'Integers';

  @override
  Map<String, Object?> toJson(IntegerData data) => {'value': data.value};
}

class DateData {
  final DateTime value;

  const DateData({required this.value});
}

class Date extends DateData {
  final String id;

  const Date({required this.id, required super.value});
}

class DateDependency extends Dependency<DateData> {
  const DateDependency() : super.strong();
}

class DateEntity implements Entity<DateData, Date> {
  const DateEntity();

  @override
  Date convert(Date model, DateData data) {
    return Date(id: model.id, value: data.value);
  }

  @override
  Date fromData(
    covariant Dependency<DateData> dependency,
    String id,
    DateData data,
  ) {
    return Date(id: id, value: data.value);
  }

  @override
  Date fromJson(String id, Map data) =>
      Date(id: id, value: DateTime.parse(data['value']));

  @override
  String identify(Date model) => model.id;

  @override
  final String tableName = 'Dates';

  @override
  Map<String, Object?> toJson(DateData data) => {'value': data.value};
}

class TextData {
  final String value;

  const TextData({required this.value});
}

class Text extends TextData {
  final String id;

  const Text({required this.id, required super.value});
}

class TextDependency extends Dependency<TextData> {
  const TextDependency() : super.strong();
}

class TextEntity implements Entity<TextData, Text> {
  const TextEntity();

  @override
  Text convert(Text model, TextData data) {
    return Text(id: model.id, value: data.value);
  }

  @override
  Text fromData(
    covariant Dependency<TextData> dependency,
    String id,
    TextData data,
  ) {
    return Text(id: id, value: data.value);
  }

  @override
  Text fromJson(String id, Map data) => Text(id: id, value: data['value']);

  @override
  String identify(Text model) => model.id;

  @override
  final String tableName = 'Texts';

  @override
  Map<String, Object?> toJson(TextData data) => {'value': data.value};
}

void main() async {
  final DotEnv env = DotEnv();
  env.load();

  // Shall run
  // ```sql
  // CREATE TABLE IF NOT EXISTS Integers (
  //   id CHAR(36) NOT NULL,
  //   value INTEGER NOT NULL,
  //   PRIMARY KEY (id)
  // );
  // CREATE TABLE IF NOT EXISTS Dates (
  //   id CHAR(36) NOT NULL,
  //   value DATETIME(3) NOT NULL,
  //   PRIMARY KEY (id)
  // );
  // CREATE TABLE IF NOT EXISTS Texts (
  //   id CHAR(36) NOT NULL,
  //   value VARCHAR(100) NOT NULL,
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
  const IntegerEntity entity = IntegerEntity();
  const DateEntity dateEntity = DateEntity();
  const TextEntity textEntity = TextEntity();
  final RegExp uuidRegExp = RegExp(
      r'^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$');
  setUpAll(() async {
    await connection.execute("DELETE FROM Integers;");
    await connection.execute("DELETE FROM Dates;");
    await connection.execute("DELETE FROM Texts;");
  });
  tearDown(() async {
    await connection.execute("DELETE FROM Integers;");
    await connection.execute("DELETE FROM Dates;");
    await connection.execute("DELETE FROM Texts;");
  });

  group('querying', () {
    group('empty state', () {
      test('peek', () async {
        final Integer? model = await reference.peek(entity, 'abcdef');
        expect(model, isNull);
      });
      test('peekAll', () async {
        final List<Integer> models =
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
        final List<Integer> models =
            await reference.pullAll(entity, Filter.empty()).first;
        expect(models, isEmpty);
      });
    });
    test('put', () async {
      final Integer model = await reference.put(
        entity,
        IntegerDependency(),
        IntegerData(value: 42),
      );
      expect(model.id, matches(uuidRegExp));
      expect(model.value, 42);
    });
    group('put (post)', () {
      late Integer localModel;
      setUp(() async {
        localModel = await reference.put(
          entity,
          IntegerDependency(),
          IntegerData(value: 42),
        );
      });
      test('peek', () async {
        final Integer? model = await reference.peek(entity, localModel.id);
        expect(model, isNotNull);
        expect(model?.id, localModel.id);
        expect(model?.value, 42);
      });
      test('peekAll', () async {
        final List<Integer> model =
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
        final List<Integer> model =
            await reference.pullAll(entity, const Filter.empty()).first;
        expect(model, isNotEmpty);
        expect(model.length, 1);
        expect(model[0].id, localModel.id);
        expect(model[0].value, 42);
      });
    });
    test('push: non-existing', () async {
      await reference.push(entity, Integer(id: 'abcdef', value: 42));
    });
    test('push: existing', () async {
      await reference.push(entity, Integer(id: 'abcdef', value: 42));
      final Integer? m1 = await reference.peek(entity, 'abcdef');
      expect(m1?.value, 42);
      await reference.push(entity, Integer(id: 'abcdef', value: 43));
      final Integer? m2 = await reference.peek(entity, 'abcdef');
      expect(m2?.value, 43);
    });
    group('push (post)', () {
      final Integer localModel = Integer(id: 'abcdef', value: 42);
      setUp(() async {
        await reference.push(entity, localModel);
      });
      test('peek', () async {
        final Integer? model = await reference.peek(entity, localModel.id);
        expect(model, isNotNull);
        expect(model?.id, localModel.id);
        expect(model?.value, 42);
      });
      test('peekAll', () async {
        final List<Integer> model =
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
        final List<Integer> model =
            await reference.pullAll(entity, const Filter.empty()).first;
        expect(model, isNotEmpty);
        expect(model.length, 1);
        expect(model[0].id, localModel.id);
        expect(model[0].value, 42);
      });
    });
    test('putAll', () async {
      await reference.putAll(entity, const IntegerDependency(), [
        IntegerData(value: 2),
        IntegerData(value: 3),
      ]);
    });
    group('putAll (post)', () {
      late List<Integer> localModels;
      setUp(() async {
        await reference.push(entity, Integer(id: 'abcdef', value: 1));
        localModels =
            await reference.putAll(entity, const IntegerDependency(), [
          IntegerData(value: 2),
          IntegerData(value: 3),
        ]);
      });
      test('peek', () async {
        await reference
            .peek(entity, 'abcdef')
            .then((model) => expect(model?.value, 1));
        for (Integer localModel in localModels) {
          final Integer? remoteModel =
              await reference.peek(entity, localModel.id);
          expect(remoteModel?.value, localModel.value);
        }
      });
      test('peekAll', () async {
        final List<Integer> models =
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
        for (Integer localModel in localModels) {
          final Integer? remoteModel =
              await reference.pull(entity, localModel.id).first;
          expect(remoteModel?.value, localModel.value);
        }
      });
      test('pullAll', () async {
        final List<Integer> models =
            await reference.pullAll(entity, Filter.empty()).first;
        expect(models.length, 3);
      });
    });
    test('pushAll', () async {
      await reference.pushAll(entity, [
        Integer(id: 'ghijkl', value: 2),
        Integer(id: 'mnopqr', value: 3),
      ]);
    });
    group('pushAll (post)', () {
      setUp(() async {
        await reference.push(entity, Integer(id: 'abcdef', value: 1));
        await reference.pushAll(entity, [
          Integer(id: 'ghijkl', value: 2),
          Integer(id: 'mnopqr', value: 3),
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
        final List<Integer> models =
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
        final List<Integer> models =
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
        await reference.push(entity, Integer(id: 'abcdef', value: 1));
        await reference.popAll(entity, const Filter.empty());
      });
      test('peek', () async {
        final Integer? model = await reference.peek(entity, 'abcdef');
        expect(model, isNull);
      });
      test('peekAll', () async {
        final List<Integer> models =
            await reference.peekAll(entity, Filter.empty());
        expect(models, isEmpty);
      });
      test('peekAllKeys', () async {
        final List<String> keys = await reference.peekAllKeys(entity);
        expect(keys, isEmpty);
      });
      test('pull', () async {
        final Integer? model = await reference.pull(entity, 'abcdef').first;
        expect(model, isNull);
      });
      test('pullAll', () async {
        final List<Integer> models =
            await reference.pullAll(entity, Filter.empty()).first;
        expect(models, isEmpty);
      });
    });
    test('pop: non-existing', () async {
      await reference.pop(entity, 'abcdef');
    });
    test('pop: existing', () async {
      await reference.push(entity, Integer(id: 'abcdef', value: 42));
      await reference.pop(entity, 'abcdef');
      final Integer? model = await reference.peek(entity, 'abcdef');
      expect(model?.value, null);
    });
    group('popKeys: non-existing', () {
      setUp(() async {
        await reference.popKeys(entity, ['abcdef', 'ghijkl']);
      });
      test('peek', () async {
        final Integer? m1 = await reference.peek(entity, 'abcdef');
        expect(m1?.value, null);
        final Integer? m2 = await reference.peek(entity, 'ghijkl');
        expect(m2?.value, null);
        final Integer? m3 = await reference.peek(entity, 'mnopqr');
        expect(m3?.value, null);
      });
      test('peekAll', () async {
        final List<Integer> models =
            await reference.peekAll(entity, Filter.empty());
        expect(models, isEmpty);
      });
      test('peekAllKeys', () async {
        final List<String> keys = await reference.peekAllKeys(entity);
        expect(keys, isEmpty);
      });
      test('pull', () async {
        final Integer? m1 = await reference.pull(entity, 'abcdef').first;
        expect(m1?.value, null);
        final Integer? m2 = await reference.pull(entity, 'ghijkl').first;
        expect(m2?.value, null);
        final Integer? m3 = await reference.pull(entity, 'mnopqr').first;
        expect(m3?.value, null);
      });
      test('pullAll', () async {
        final List<Integer> models =
            await reference.pullAll(entity, Filter.empty()).first;
        expect(models, isEmpty);
      });
    });
    group('popKeys: existing, partial', () {
      setUp(() async {
        await reference.push(entity, Integer(id: 'abcdef', value: 1));
        await reference.push(entity, Integer(id: 'mnopqr', value: 3));
        await reference.popKeys(entity, ['abcdef', 'ghijkl']);
      });
      test('peek', () async {
        final Integer? m1 = await reference.peek(entity, 'abcdef');
        expect(m1?.value, null);
        final Integer? m2 = await reference.peek(entity, 'ghijkl');
        expect(m2?.value, null);
        final Integer? m3 = await reference.peek(entity, 'mnopqr');
        expect(m3?.value, 3);
      });
      test('peekAll', () async {
        final List<Integer> models =
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
        final Integer? m1 = await reference.pull(entity, 'abcdef').first;
        expect(m1?.value, null);
        final Integer? m2 = await reference.pull(entity, 'ghijkl').first;
        expect(m2?.value, null);
        final Integer? m3 = await reference.pull(entity, 'mnopqr').first;
        expect(m3?.value, 3);
      });
      test('pullAll', () async {
        final List<Integer> models =
            await reference.pullAll(entity, Filter.empty()).first;
        expect(models.length, 1);
        expect(models[0].id, 'mnopqr');
      });
    });
    group('popKeys: existing, complete', () {
      setUp(() async {
        await reference.push(entity, Integer(id: 'abcdef', value: 1));
        await reference.push(entity, Integer(id: 'ghijkl', value: 2));
        await reference.push(entity, Integer(id: 'mnopqr', value: 3));
        await reference.popKeys(entity, ['abcdef', 'ghijkl', 'mnopqr']);
      });
      test('peek', () async {
        final Integer? m1 = await reference.peek(entity, 'abcdef');
        expect(m1?.value, null);
        final Integer? m2 = await reference.peek(entity, 'ghijkl');
        expect(m2?.value, null);
        final Integer? m3 = await reference.peek(entity, 'mnopqr');
        expect(m3?.value, null);
      });
      test('peekAll', () async {
        final List<Integer> models =
            await reference.peekAll(entity, Filter.empty());
        expect(models, isEmpty);
      });
      test('peekAllKeys', () async {
        final List<String> keys = await reference.peekAllKeys(entity);
        expect(keys, isEmpty);
      });
      test('peek', () async {
        final Integer? m1 = await reference.pull(entity, 'abcdef').first;
        expect(m1?.value, null);
        final Integer? m2 = await reference.pull(entity, 'ghijkl').first;
        expect(m2?.value, null);
        final Integer? m3 = await reference.pull(entity, 'mnopqr').first;
        expect(m3?.value, null);
      });
    });
    test('purge', () async {
      await reference.purge(entity);
    });
    group('purge (post)', () {
      setUp(() async {
        await reference.push(entity, Integer(id: 'abc', value: 42));
        await reference.purge(entity);
      });
      test('peek', () async {
        final Integer? model = await reference.peek(entity, 'abcdef');
        expect(model, isNull);
      });
      test('peekAll', () async {
        final List<Integer> models =
            await reference.peekAll(entity, Filter.empty());
        expect(models, isEmpty);
      });
      test('peekAllKeys', () async {
        final List<String> keys = await reference.peekAllKeys(entity);
        expect(keys, isEmpty);
      });
      test('pull', () async {
        final Integer? model = await reference.pull(entity, 'abcdef').first;
        expect(model, isNull);
      });
      test('pullAll', () async {
        final List<Integer> models =
            await reference.pullAll(entity, Filter.empty()).first;
        expect(models, isEmpty);
      });
    });
    test('patch: non-existing, writing', () async {
      await reference.patch(entity, 'abcdef', (_) {
        return Integer(id: 'abcdef', value: 42);
      });
      final Integer? model = await reference.peek(entity, 'abcdef');
      expect(model?.value, 42);
    });
    test('patch: non-existing, deleting', () async {
      await reference.patch(entity, 'abcdef', (_) => null);
      final Integer? model = await reference.peek(entity, 'abcdef');
      expect(model?.value, null);
    });
    test('patch: existing, writing', () async {
      await reference.push(entity, Integer(id: 'abcdef', value: 42));
      await reference.patch(entity, 'abcdef', (model) {
        return Integer(id: model?.id ?? 'abcdef', value: 43);
      });
      final Integer? model = await reference.peek(entity, 'abcdef');
      expect(model?.value, 43);
    });
    test('patch: existing, deleting', () async {
      await reference.push(entity, Integer(id: 'abcdef', value: 42));
      await reference.patch(entity, 'abcdef', (_) => null);
      final Integer? model = await reference.peek(entity, 'abcdef');
      expect(model?.value, null);
    });
  });
  group('filtering', () {
    group('empty', () {
      setUp(() async {
        await reference.pushAll(entity, [
          Integer(id: 'abcdef', value: 2),
          Integer(id: 'ghijkl', value: 4),
          Integer(id: 'mnopqr', value: 8),
        ]);
      });
      test('peekAll', () async {
        final List<Integer> models =
            await reference.peekAll(entity, Filter.empty());
        expect(models.length, 3);
      });
      test('pullAll', () async {
        final List<Integer> models =
            await reference.pullAll(entity, Filter.empty()).first;
        expect(models.length, 3);
      });
      test('popAll', () async {
        await reference.popAll(entity, Filter.empty());
        final List<Integer> models =
            await reference.peekAll(entity, Filter.empty());
        expect(models.length, 0);
      });
    });
    group('value', () {
      setUp(() async {
        await reference.pushAll(entity, [
          Integer(id: 'abcdef', value: 2),
          Integer(id: 'ghijkl', value: 4),
          Integer(id: 'mnopqr', value: 8),
        ]);
      });
      test('peekAll', () async {
        List<Integer> models;
        models = await reference.peekAll(entity, Filter.value(0, key: 'value'));
        expect(models.length, 0);
        models = await reference.peekAll(entity, Filter.value(4, key: 'value'));
        expect(models.length, 1);
      });
      test('pullAll', () async {
        List<Integer> models;
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
        final List<Integer> models =
            await reference.peekAll(entity, Filter.empty());
        expect(models.length, 3);
      });
      test('popAll: existing', () async {
        await reference.popAll(entity, Filter.value(4, key: 'value'));
        final List<Integer> models =
            await reference.peekAll(entity, Filter.empty());
        expect(models.length, 2);
      });
    });
    group('text', () {
      setUp(() async {
        await reference.pushAll(textEntity, [
          Text(id: 'abc', value: 'anna'),
          Text(id: 'def', value: 'alpha'),
          Text(id: 'ghi', value: 'alphabet'),
          Text(id: 'jkl', value: 'beta'),
          Text(id: 'mno', value: 'bravo'),
          Text(id: 'pqr', value: 'beet'),
        ]);
      });
      test('peekAll', () async {
        List<Text> models;
        models = await reference.peekAll(
          textEntity,
          Filter.text('a', key: 'value'),
        );
        expect(models.length, 3);
        models = await reference.peekAll(
          textEntity,
          Filter.text('alpha', key: 'value'),
        );
        expect(models.length, 2);
        models = await reference.peekAll(
          textEntity,
          Filter.text('alphab', key: 'value'),
        );
        expect(models.length, 1);
        models = await reference.peekAll(
          textEntity,
          Filter.text('b', key: 'value'),
        );
        expect(models.length, 3);
        models = await reference.peekAll(
          textEntity,
          Filter.text('be', key: 'value'),
        );
        expect(models.length, 2);
        models = await reference.peekAll(
          textEntity,
          Filter.text('bet', key: 'value'),
        );
        expect(models.length, 1);
        models = await reference.peekAll(
          textEntity,
          Filter.text('charlie', key: 'value'),
        );
        expect(models.length, 0);
      });
      test('pullAll', () async {
        List<Text> models;
        models = await reference
            .pullAll(
              textEntity,
              Filter.text('a', key: 'value'),
            )
            .first;
        expect(models.length, 3);
        models = await reference
            .pullAll(
              textEntity,
              Filter.text('alpha', key: 'value'),
            )
            .first;
        expect(models.length, 2);
        models = await reference
            .pullAll(
              textEntity,
              Filter.text('alphab', key: 'value'),
            )
            .first;
        expect(models.length, 1);
        models = await reference
            .pullAll(
              textEntity,
              Filter.text('b', key: 'value'),
            )
            .first;
        expect(models.length, 3);
        models = await reference
            .pullAll(
              textEntity,
              Filter.text('be', key: 'value'),
            )
            .first;
        expect(models.length, 2);
        models = await reference
            .pullAll(
              textEntity,
              Filter.text('bet', key: 'value'),
            )
            .first;
        expect(models.length, 1);
        models = await reference
            .pullAll(
              textEntity,
              Filter.text('charlie', key: 'value'),
            )
            .first;
        expect(models.length, 0);
      });
      test('popAll: non-existing', () async {
        await reference.popAll(
            textEntity, Filter.text('charlie', key: 'value'));
        final List<Text> models =
            await reference.peekAll(textEntity, Filter.empty());
        expect(models.length, 6);
      });
      test('popAll: existing', () async {
        await reference.popAll(textEntity, Filter.text('al', key: 'value'));
        final List<Text> models =
            await reference.peekAll(textEntity, Filter.empty());
        expect(models.length, 4);
      });
    });
    group('limit', () {
      setUp(() async {
        await reference.pushAll(entity, [
          Integer(id: 'abcdef', value: 2),
          Integer(id: 'ghijkl', value: 2),
          Integer(id: 'mnopqr', value: 4),
          Integer(id: 'stuvwx', value: 6),
        ]);
      });
      test('peekAll', () async {
        List<Integer> models;
        final Filter filter = Filter.value(2, key: 'value');
        models = await reference.peekAll(entity, filter);
        expect(models.length, 2);
        models = await reference.peekAll(entity, filter.limit(1));
        expect(models.length, 1);
        models = await reference.peekAll(entity, filter.limit(2));
        expect(models.length, 2);
        models = await reference.peekAll(entity, filter.limit(3));
        expect(models.length, 2);
      });
      test('pullAll', () async {
        List<Integer> models;
        final Filter filter = Filter.value(2, key: 'value');
        models = await reference.pullAll(entity, filter).first;
        expect(models.length, 2);
        models = await reference.pullAll(entity, filter.limit(1)).first;
        expect(models.length, 1);
        models = await reference.pullAll(entity, filter.limit(2)).first;
        expect(models.length, 2);
        models = await reference.pullAll(entity, filter.limit(3)).first;
        expect(models.length, 2);
      });
      test('popAll: non-existing', () async {
        await reference.popAll(entity, Filter.value(0, key: 'value').limit(1));
        final List<Integer> models =
            await reference.peekAll(entity, Filter.empty());
        expect(models.length, 4);
      });
      test('popAll: existing', () async {
        await reference.popAll(entity, Filter.value(2, key: 'value').limit(1));
        final List<Integer> models =
            await reference.peekAll(entity, Filter.empty());
        expect(models.length, 3);
      });
    });
    group('date', () {
      setUp(() async {
        await reference.pushAll(dateEntity, [
          Date(id: 'abc', value: DateTime(2023, 6, 15)),
          Date(id: 'def', value: DateTime(2024, 3, 15)),
          Date(id: 'ghi', value: DateTime(2024, 9, 15)),
          Date(id: 'jkl', value: DateTime(2024, 9, 30)),
          Date(id: 'mno', value: DateTime(2024, 9, 30, 15)),
          Date(id: 'pqr', value: DateTime(2024, 9, 30, 15, 20)),
          Date(id: 'stu', value: DateTime(2024, 9, 30, 15, 20, 25)),
          Date(id: 'vwx', value: DateTime(2024, 9, 30, 15, 20, 25, 35)),
        ]);
      });
      test('peekAll', () async {
        List<Date> models;
        models = await reference.peekAll(
          dateEntity,
          Filter.date(
            DateTime(2023),
            key: 'value',
            unit: DateFilterUnit.year,
          ),
        );
        expect(models.length, 1);
        models = await reference.peekAll(
          dateEntity,
          Filter.date(
            DateTime(2024),
            key: 'value',
            unit: DateFilterUnit.year,
          ),
        );
        expect(models.length, 7);

        models = await reference.peekAll(
          dateEntity,
          Filter.date(
            DateTime(2024, 3),
            key: 'value',
            unit: DateFilterUnit.month,
          ),
        );
        expect(models.length, 1);
        models = await reference.peekAll(
          dateEntity,
          Filter.date(
            DateTime(2024, 9),
            key: 'value',
            unit: DateFilterUnit.month,
          ),
        );
        expect(models.length, 6);

        models = await reference.peekAll(
          dateEntity,
          Filter.date(
            DateTime(2024, 9, 15),
            key: 'value',
            unit: DateFilterUnit.day,
          ),
        );
        expect(models.length, 1);
        models = await reference.peekAll(
          dateEntity,
          Filter.date(
            DateTime(2024, 9, 30),
            key: 'value',
            unit: DateFilterUnit.day,
          ),
        );
        expect(models.length, 5);

        models = await reference.peekAll(
          dateEntity,
          Filter.date(
            DateTime(2024, 9, 30),
            key: 'value',
            unit: DateFilterUnit.hour,
          ),
        );
        expect(models.length, 1);
        models = await reference.peekAll(
          dateEntity,
          Filter.date(
            DateTime(2024, 9, 30, 15),
            key: 'value',
            unit: DateFilterUnit.hour,
          ),
        );
        expect(models.length, 4);

        models = await reference.peekAll(
          dateEntity,
          Filter.date(
            DateTime(2024, 9, 30, 15),
            key: 'value',
            unit: DateFilterUnit.minute,
          ),
        );
        expect(models.length, 1);
        models = await reference.peekAll(
          dateEntity,
          Filter.date(
            DateTime(2024, 9, 30, 15, 20),
            key: 'value',
            unit: DateFilterUnit.minute,
          ),
        );
        expect(models.length, 3);

        models = await reference.peekAll(
          dateEntity,
          Filter.date(
            DateTime(2024, 9, 30, 15, 20),
            key: 'value',
            unit: DateFilterUnit.second,
          ),
        );
        expect(models.length, 1);
        models = await reference.peekAll(
          dateEntity,
          Filter.date(
            DateTime(2024, 9, 30, 15, 20, 25),
            key: 'value',
            unit: DateFilterUnit.second,
          ),
        );
        expect(models.length, 2);

        models = await reference.peekAll(
          dateEntity,
          Filter.date(
            DateTime(2024, 9, 30, 15, 20, 25),
            key: 'value',
            unit: DateFilterUnit.milliseconds,
          ),
        );
        expect(models.length, 1);
        models = await reference.peekAll(
          dateEntity,
          Filter.date(
            DateTime(2024, 9, 30, 15, 20, 25, 35),
            key: 'value',
            unit: DateFilterUnit.milliseconds,
          ),
        );
        expect(models.length, 1);
      });
      test('pullAll', () async {
        List<Date> models;
        models = await reference
            .pullAll(
              dateEntity,
              Filter.date(
                DateTime(2023),
                key: 'value',
                unit: DateFilterUnit.year,
              ),
            )
            .first;
        expect(models.length, 1);
        models = await reference
            .pullAll(
              dateEntity,
              Filter.date(
                DateTime(2024),
                key: 'value',
                unit: DateFilterUnit.year,
              ),
            )
            .first;
        expect(models.length, 7);

        models = await reference
            .pullAll(
              dateEntity,
              Filter.date(
                DateTime(2024, 3),
                key: 'value',
                unit: DateFilterUnit.month,
              ),
            )
            .first;
        expect(models.length, 1);
        models = await reference
            .pullAll(
              dateEntity,
              Filter.date(
                DateTime(2024, 9),
                key: 'value',
                unit: DateFilterUnit.month,
              ),
            )
            .first;
        expect(models.length, 6);

        models = await reference
            .pullAll(
              dateEntity,
              Filter.date(
                DateTime(2024, 9, 15),
                key: 'value',
                unit: DateFilterUnit.day,
              ),
            )
            .first;
        expect(models.length, 1);
        models = await reference
            .pullAll(
              dateEntity,
              Filter.date(
                DateTime(2024, 9, 30),
                key: 'value',
                unit: DateFilterUnit.day,
              ),
            )
            .first;
        expect(models.length, 5);

        models = await reference
            .pullAll(
              dateEntity,
              Filter.date(
                DateTime(2024, 9, 30),
                key: 'value',
                unit: DateFilterUnit.hour,
              ),
            )
            .first;
        expect(models.length, 1);
        models = await reference
            .pullAll(
              dateEntity,
              Filter.date(
                DateTime(2024, 9, 30, 15),
                key: 'value',
                unit: DateFilterUnit.hour,
              ),
            )
            .first;
        expect(models.length, 4);

        models = await reference
            .pullAll(
              dateEntity,
              Filter.date(
                DateTime(2024, 9, 30, 15),
                key: 'value',
                unit: DateFilterUnit.minute,
              ),
            )
            .first;
        expect(models.length, 1);
        models = await reference
            .pullAll(
              dateEntity,
              Filter.date(
                DateTime(2024, 9, 30, 15, 20),
                key: 'value',
                unit: DateFilterUnit.minute,
              ),
            )
            .first;
        expect(models.length, 3);

        models = await reference
            .pullAll(
              dateEntity,
              Filter.date(
                DateTime(2024, 9, 30, 15, 20),
                key: 'value',
                unit: DateFilterUnit.second,
              ),
            )
            .first;
        expect(models.length, 1);
        models = await reference
            .pullAll(
              dateEntity,
              Filter.date(
                DateTime(2024, 9, 30, 15, 20, 25),
                key: 'value',
                unit: DateFilterUnit.second,
              ),
            )
            .first;
        expect(models.length, 2);

        models = await reference
            .pullAll(
              dateEntity,
              Filter.date(
                DateTime(2024, 9, 30, 15, 20, 25),
                key: 'value',
                unit: DateFilterUnit.milliseconds,
              ),
            )
            .first;
        expect(models.length, 1);
        models = await reference
            .pullAll(
              dateEntity,
              Filter.date(
                DateTime(2024, 9, 30, 15, 20, 25, 35),
                key: 'value',
                unit: DateFilterUnit.milliseconds,
              ),
            )
            .first;
        expect(models.length, 1);
      });
    });
    group('range', () {
      group('numeric', () {
        setUp(() async {
          await reference.pushAll(entity, [
            Integer(id: 'abc', value: 1),
            Integer(id: 'def', value: 2),
            Integer(id: 'ghi', value: 3),
            Integer(id: 'jkl', value: 4),
            Integer(id: 'mno', value: 5),
            Integer(id: 'pqr', value: 6),
            Integer(id: 'stu', value: 7),
            Integer(id: 'vwx', value: 8),
          ]);
        });
        test('peekAll', () async {
          List<Integer> models;
          models = await reference.peekAll(
            entity,
            Filter.numericRange(
              FilterRange(from: 3, to: 6),
              key: 'value',
            ),
          );
          expect(models.length, 4);
          models = await reference.peekAll(
            entity,
            Filter.numericRange(
              FilterRange(to: 3),
              key: 'value',
            ),
          );
          expect(models.length, 3);
          models = await reference.peekAll(
            entity,
            Filter.numericRange(
              FilterRange(from: 7),
              key: 'value',
            ),
          );
          expect(models.length, 2);
        });
        test('pullAll', () async {
          List<Integer> models;
          models = await reference
              .pullAll(
                entity,
                Filter.numericRange(
                  FilterRange(from: 3, to: 6),
                  key: 'value',
                ),
              )
              .first;
          expect(models.length, 4);
          models = await reference
              .pullAll(
                entity,
                Filter.numericRange(
                  FilterRange(to: 3),
                  key: 'value',
                ),
              )
              .first;
          expect(models.length, 3);
          models = await reference
              .pullAll(
                entity,
                Filter.numericRange(
                  FilterRange(from: 7),
                  key: 'value',
                ),
              )
              .first;
          expect(models.length, 2);
        });
      });
      group('text', () {
        setUp(() async {
          await reference.pushAll(textEntity, [
            Text(id: 'abc', value: 'alpha'),
            Text(id: 'def', value: 'bravo'),
            Text(id: 'ghi', value: 'charlie'),
            Text(id: 'jkl', value: 'delta'),
            Text(id: 'mno', value: 'echo'),
            Text(id: 'pqr', value: 'foxtrot'),
            Text(id: 'stu', value: 'golf'),
            Text(id: 'vwx', value: 'hotel'),
          ]);
        });
        test('peekAll', () async {
          List<Text> models;
          models = await reference.peekAll(
            textEntity,
            Filter.textRange(
              FilterRange(from: 'c', to: 'g'),
              key: 'value',
            ),
          );
          expect(models.length, 4);
          models = await reference.peekAll(
            textEntity,
            Filter.textRange(
              FilterRange(to: 'd'),
              key: 'value',
            ),
          );
          expect(models.length, 3);
          models = await reference.peekAll(
            textEntity,
            Filter.textRange(
              FilterRange(from: 'g'),
              key: 'value',
            ),
          );
          expect(models.length, 2);
        });
        test('pullAll', () async {
          List<Text> models;
          models = await reference
              .pullAll(
                textEntity,
                Filter.textRange(
                  FilterRange(from: 'c', to: 'g'),
                  key: 'value',
                ),
              )
              .first;
          expect(models.length, 4);
          models = await reference
              .pullAll(
                textEntity,
                Filter.textRange(
                  FilterRange(to: 'd'),
                  key: 'value',
                ),
              )
              .first;
          expect(models.length, 3);
          models = await reference
              .pullAll(
                textEntity,
                Filter.textRange(
                  FilterRange(from: 'g'),
                  key: 'value',
                ),
              )
              .first;
          expect(models.length, 2);
        });
      });
    });
    test('sorted', () async {
      await reference.pushAll(entity, [
        Integer(id: 'abc', value: 8),
        Integer(id: 'def', value: 2),
        Integer(id: 'ghi', value: 7),
        Integer(id: 'jkl', value: 1),
        Integer(id: 'mno', value: 5),
        Integer(id: 'pqr', value: 6),
        Integer(id: 'stu', value: 3),
        Integer(id: 'vwx', value: 4),
      ]);
      List<Integer> models;
      models = await reference.peekAll(entity, const Filter.empty());
      expect(models.map((m) => m.value).toList(), [8, 2, 7, 1, 5, 6, 3, 4]);
      models = await reference.peekAll(
          entity, const Filter.empty().sort(key: 'value'));
      expect(models.map((m) => m.value).toList(), [1, 2, 3, 4, 5, 6, 7, 8]);
    });
  });
}
