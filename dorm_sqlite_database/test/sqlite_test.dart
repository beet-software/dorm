import 'dart:io';

import 'package:dorm_framework/dorm_framework.dart';
import 'package:dorm_migrations/dorm_migrations.dart';
import 'package:dorm_sqlite_database/dorm_sqlite_database.dart';
import 'package:sqlite_async/sqlite_async.dart';
import 'package:test/test.dart';

class _GeneratedData {
  const _GeneratedData(this.name);

  final String name;
}

class _GeneratedModel extends _GeneratedData {
  const _GeneratedModel({required this.id, required String name}) : super(name);

  final int id;
}

class _GeneratedDependency extends Dependency<_GeneratedData> {
  const _GeneratedDependency() : super.strong();
}

class _GeneratedEntity
    extends
        Entity<
          _GeneratedData,
          _GeneratedModel,
          int,
          Creation<_GeneratedData, int>
        > {
  @override
  EntitySchema get schema => const EntitySchema(
    tableName: 'generated_values',
    primaryKeys: [FieldSchema(fieldName: 'id', columnName: 'id')],
    fields: [FieldSchema(fieldName: 'name', columnName: 'name')],
  );

  @override
  IdentityGenerationStrategy get identityGeneration =>
      IdentityGenerationStrategy.database;

  @override
  PrimaryKeyCodec<int> get primaryKeyCodec =>
      const SinglePrimaryKeyCodec<int>();

  @override
  _GeneratedModel fromJson(int id, Map data) {
    return _GeneratedModel(id: id, name: data['name'] as String);
  }

  @override
  Map<String, Object?> toJson(_GeneratedData data) => {'name': data.name};

  @override
  _GeneratedModel convert(_GeneratedModel model, _GeneratedData data) {
    return _GeneratedModel(id: model.id, name: data.name);
  }

  @override
  _GeneratedModel fromData(ResolvedCreation<_GeneratedData, int> creation) {
    return _GeneratedModel(id: creation.id, name: creation.data.name);
  }

  @override
  int identify(_GeneratedModel model) => model.id;
}

void main() {
  late Directory directory;
  late SqliteDatabase database;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('dorm-sqlite-test-');
    database = SqliteDatabase(path: '${directory.path}\\test.db');
  });

  tearDown(() async {
    await database.close();
    await directory.delete(recursive: true);
  });

  test('supports asynchronous SQLite reads and writes', () async {
    await database.execute(
      'CREATE TABLE values_table (id TEXT PRIMARY KEY, active BOOLEAN)',
    );
    await database.execute(
      'INSERT INTO values_table (id, active) VALUES (?, ?)',
      ['one', true],
    );

    final result = await database.getAll('SELECT * FROM values_table');
    expect(result.single['id'], 'one');
    expect(result.single['active'], 1);
  });

  test('provides a write transaction context', () async {
    await database.execute('CREATE TABLE values_table (value INTEGER)');
    await database.writeTransaction((tx) async {
      await tx.execute('INSERT INTO values_table (value) VALUES (?)', [1]);
      await tx.execute('INSERT INTO values_table (value) VALUES (?)', [2]);
    });

    final result = await database.getAll('SELECT value FROM values_table');
    expect(result.map((row) => row['value']), [1, 2]);
  });

  test('uses SQLite rowid for database-generated identities', () async {
    await database.execute('''
      CREATE TABLE generated_values (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL
      )
    ''');

    final BaseReference<Query, OffsetPageRequest> reference = Engine(
      database,
    ).createReference();
    final _GeneratedModel model = await reference
        .put<
          _GeneratedData,
          _GeneratedModel,
          int,
          Creation<_GeneratedData, int>
        >(
          _GeneratedEntity(),
          Creation.auto(
            dependency: const _GeneratedDependency(),
            data: const _GeneratedData('value'),
          ),
        );

    expect(model.id, greaterThan(0));
    expect((await reference.peek(_GeneratedEntity(), model.id))?.name, 'value');
  });
  test('applies and records SQLite migrations', () async {
    final Migration migration = Migration(
      version: 1,
      name: 'create-users',
      operations: [
        CreateEntityOperation(
          entity: const MigrationEntityDefinition(
            entityName: 'users',
            tableName: 'users',
            fields: [
              MigrationFieldDefinition(
                fieldName: 'id',
                columnName: 'id',
                type: MigrationValueType.integer,
                nullable: false,
              ),
              MigrationFieldDefinition(
                fieldName: 'name',
                columnName: 'name',
                type: MigrationValueType.text,
                nullable: false,
              ),
            ],
            primaryKeys: ['id'],
          ),
        ),
      ],
    );
    final MigrationRunner runner = MigrationRunner(
      Engine(database).migrationAdapter,
    );

    await runner.run([migration]);
    final result = await database.getAll('SELECT * FROM users');
    final MigrationRunResult retry = await runner.run([migration]);

    expect(result, isEmpty);
    expect(retry.applied, isEmpty);
    expect(retry.skipped.single.version, 1);
  });
}
