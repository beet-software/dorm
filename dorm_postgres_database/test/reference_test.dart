import 'dart:io';

import 'package:dorm_framework/dorm_framework.dart';
import 'package:dorm_postgres_database/dorm_postgres_database.dart';
import 'package:dorm_postgres_database/src/reference.dart';
import 'package:postgres/postgres.dart';
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
    tableName: 'dorm_postgres_test_items',
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

class _PostgresConfig {
  final String host;
  final int port;
  final String database;
  final String username;
  final String password;

  const _PostgresConfig({
    required this.host,
    required this.port,
    required this.database,
    required this.username,
    required this.password,
  });

  static _PostgresConfig? fromEnvironment() {
    final String? host = Platform.environment['POSTGRES_HOST'];
    final String? port = Platform.environment['POSTGRES_PORT'];
    final String? database = Platform.environment['POSTGRES_DATABASE'];
    final String? username = Platform.environment['POSTGRES_USERNAME'];
    final String? password = Platform.environment['POSTGRES_PASSWORD'];
    if ([
      host,
      port,
      database,
      username,
      password,
    ].any((value) => value == null)) {
      return null;
    }
    return _PostgresConfig(
      host: host!,
      port: int.parse(port!),
      database: database!,
      username: username!,
      password: password!,
    );
  }
}

class _NoopExecutor implements SessionExecutor {
  @override
  Future<R> run<R>(
    Future<R> Function(Session session) fn, {
    SessionSettings? settings,
  }) => Future.error(UnimplementedError());

  @override
  Future<R> runTx<R>(
    Future<R> Function(TxSession session) fn, {
    TransactionSettings? settings,
  }) => Future.error(UnimplementedError());

  @override
  Future<void> close({bool force = false}) => Future.value();
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
    tableName: 'dorm_postgres_test_composite_items',
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
  test('rejects put for composite identities before executor access', () {
    final Reference reference = Reference(_NoopExecutor());
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

  final _PostgresConfig? config = _PostgresConfig.fromEnvironment();
  group(
    'PostgreSQL reference integration',
    () {
      late Connection connection;
      late BaseReference<Query> reference;
      const _ItemEntity entity = _ItemEntity();

      setUpAll(() async {
        connection = await Connection.open(
          Endpoint(
            host: config!.host,
            port: config.port,
            database: config.database,
            username: config.username,
            password: config.password,
          ),
        );
        reference = Engine(connection).createReference();
        await connection.execute(
          'CREATE TABLE IF NOT EXISTS dorm_postgres_test_items '
          '(id TEXT PRIMARY KEY, title TEXT NOT NULL, value INTEGER NOT NULL)',
        );
        await connection.execute(
          'CREATE TABLE IF NOT EXISTS dorm_postgres_test_composite_items '
          '(first TEXT NOT NULL, second INTEGER NOT NULL, value TEXT NOT NULL, '
          'PRIMARY KEY (first, second))',
        );
        await connection.execute('TRUNCATE TABLE dorm_postgres_test_items');
        await connection.execute(
          'TRUNCATE TABLE dorm_postgres_test_composite_items',
        );
      });

      tearDown(() async {
        await connection.execute('TRUNCATE TABLE dorm_postgres_test_items');
        await connection.execute(
          'TRUNCATE TABLE dorm_postgres_test_composite_items',
        );
      });

      tearDownAll(() => connection.close());

      test('puts and reads a generated model', () async {
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

      test('pushes an existing model with upsert semantics', () async {
        const _Item first = _Item(id: 'fixed', title: 'first', value: 1);
        const _Item second = _Item(id: 'fixed', title: 'second', value: 2);

        await reference.push(entity, first);
        await reference.push(entity, second);

        expect(await reference.peek(entity, 'fixed'), second);
      });

      test('puts and reads an explicitly identified composite model', () async {
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
      });

      test('filters, sorts, and limits rows', () async {
        await reference.pushAll(entity, const [
          _Item(id: 'a', title: 'alpha', value: 3),
          _Item(id: 'b', title: 'beta', value: 1),
          _Item(id: 'c', title: 'alphabet', value: 2),
        ]);

        final List<_Item> result = await reference.peekAll(
          entity,
          Filter.text('alph', key: 'title').sort(key: 'value').limit(1),
        );

        expect(result.map((item) => item.id), ['c']);
      });

      test(
        'patches and removes a model inside the adapter operation',
        () async {
          await reference.push(
            entity,
            const _Item(id: 'patch', title: 'old', value: 1),
          );

          await reference.patch(entity, 'patch', (model) {
            final _Item current = model!;
            return _Item(
              id: current.id,
              title: 'new',
              value: current.value + 1,
            );
          });
          expect((await reference.peek(entity, 'patch'))?.title, 'new');

          await reference.patch(entity, 'patch', (_) => null);
          expect(await reference.peek(entity, 'patch'), isNull);
        },
      );
    },
    skip: config == null
        ? 'Set POSTGRES_HOST, POSTGRES_PORT, POSTGRES_DATABASE, '
              'POSTGRES_USERNAME, and POSTGRES_PASSWORD to run integration tests.'
        : false,
  );
}
