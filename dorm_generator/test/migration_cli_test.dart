import 'dart:convert';
import 'dart:io';

import 'package:dorm_generator/src/migration_cli.dart';
import 'package:test/test.dart';

void main() {
  test('generates an add/remove candidate for a rename without YAML', () async {
    final Directory root = _repositoryRoot();
    final Directory temporary = await Directory.systemTemp.createTemp(
      'dorm_migration_cli_',
    );
    addTearDown(() => temporary.delete(recursive: true));

    final File snapshot = File(
      '${temporary.path}${Platform.pathSeparator}schema.json',
    );
    final File input = File(
      '${root.path}${Platform.pathSeparator}dorm_generator${Platform.pathSeparator}test${Platform.pathSeparator}fixtures${Platform.pathSeparator}migration_models.dart',
    );
    expect(
      await runMigrationCli([
        'initialize',
        '--input',
        input.path,
        '--snapshot',
        snapshot.path,
        '--config',
        '${temporary.path}${Platform.pathSeparator}missing.yaml',
      ]),
      0,
    );

    final Map<String, Object?> schema = _readObject(snapshot);
    final Map<String, Object?> entity = _firstEntityWithField(schema);
    final List<Object?> fields = entity['fields']! as List<Object?>;
    final Map<String, Object?> field =
        fields.firstWhere(
              (value) =>
                  value is Map<String, Object?> &&
                  !(entity['primaryKeys']! as List<Object?>).contains(
                    value['columnName'],
                  ),
            )
            as Map<String, Object?>;
    final String oldName = field['columnName']! as String;
    field['columnName'] = 'legacy_$oldName';
    field['name'] = 'legacy_${field['name']}';
    await snapshot.writeAsString(jsonEncode(schema));

    final Directory output = Directory(
      '${temporary.path}${Platform.pathSeparator}rename_migrations',
    );
    expect(
      await runMigrationCli([
        'diff',
        '--input',
        input.path,
        '--snapshot',
        snapshot.path,
        '--output',
        output.path,
        '--index',
        '${temporary.path}${Platform.pathSeparator}rename_migrations${Platform.pathSeparator}index.dart',
        '--config',
        '${temporary.path}${Platform.pathSeparator}missing.yaml',
        '--allow-destructive',
        '--name',
        'review-rename',
      ]),
      0,
    );

    final File migration = output.listSync().whereType<File>().firstWhere(
      (file) => !file.path.endsWith('index.dart'),
    );
    final String source = await migration.readAsString();
    expect(source, contains('Review required:'));
    expect(source, contains('AddFieldOperation'));
    expect(source, contains('RemoveFieldOperation'));
    expect(source, isNot(contains('    RenameFieldOperation(')));
  });

  test(
    'generates a nullable review phase for a required field without YAML',
    () async {
      final Directory root = _repositoryRoot();
      final Directory temporary = await Directory.systemTemp.createTemp(
        'dorm_migration_cli_',
      );
      addTearDown(() => temporary.delete(recursive: true));

      final File snapshot = File(
        '${temporary.path}${Platform.pathSeparator}schema.json',
      );
      final File input = File(
        '${root.path}${Platform.pathSeparator}dorm_generator${Platform.pathSeparator}test${Platform.pathSeparator}fixtures${Platform.pathSeparator}migration_models.dart',
      );
      expect(
        await runMigrationCli([
          'initialize',
          '--input',
          input.path,
          '--snapshot',
          snapshot.path,
          '--config',
          '${temporary.path}${Platform.pathSeparator}missing.yaml',
        ]),
        0,
      );

      final Map<String, Object?> schema = _readObject(snapshot);
      final Map<String, Object?> entity = _firstEntityWithRequiredNonKey(
        schema,
      );
      final List<Object?> fields = entity['fields']! as List<Object?>;
      final Map<String, Object?> requiredField =
          fields.firstWhere(
                (value) =>
                    value is Map<String, Object?> &&
                    value['nullable'] == false &&
                    !(entity['primaryKeys']! as List<Object?>).contains(
                      value['columnName'],
                    ),
              )
              as Map<String, Object?>;
      final String fieldName = requiredField['columnName']! as String;
      fields.removeWhere(
        (value) =>
            value is Map<String, Object?> && value['columnName'] == fieldName,
      );
      await snapshot.writeAsString(jsonEncode(schema));

      final Directory output = Directory(
        '${temporary.path}${Platform.pathSeparator}required_migrations',
      );
      expect(
        await runMigrationCli([
          'diff',
          '--input',
          input.path,
          '--snapshot',
          snapshot.path,
          '--output',
          output.path,
          '--index',
          '${temporary.path}${Platform.pathSeparator}required_migrations${Platform.pathSeparator}index.dart',
          '--config',
          '${temporary.path}${Platform.pathSeparator}missing.yaml',
          '--name',
          'review-backfill',
        ]),
        0,
      );

      final File migration = output.listSync().whereType<File>().firstWhere(
        (file) => !file.path.endsWith('index.dart'),
      );
      final String source = await migration.readAsString();
      expect(source, contains('Review required:'));
      expect(source, contains('AddFieldOperation'));
      expect(source, contains('nullable: true'));
      expect(source, isNot(contains('    BackfillFieldOperation(')));
    },
  );
  test('generates a deterministic migration index', () async {
    final Directory temporary = await Directory.systemTemp.createTemp(
      'dorm_migration_index_',
    );
    addTearDown(() => temporary.delete(recursive: true));

    final Directory output = Directory(
      '${temporary.path}${Platform.pathSeparator}migrations',
    )..createSync();
    await File(
      '${output.path}${Platform.pathSeparator}002_second.dart',
    ).writeAsString('// second');
    await File(
      '${output.path}${Platform.pathSeparator}001_first.dart',
    ).writeAsString('// first');
    final File index = File(
      '${output.path}${Platform.pathSeparator}index.dart',
    );

    expect(
      await runMigrationCli([
        'index',
        '--output',
        output.path,
        '--index',
        index.path,
      ]),
      0,
    );
    final String first = await index.readAsString();
    expect(first, contains("import '001_first.dart' as migration_001_first;"));
    expect(
      first,
      contains("import '002_second.dart' as migration_002_second;"),
    );
    expect(
      first.indexOf('migration_001_first.migration'),
      lessThan(first.indexOf('migration_002_second.migration')),
    );

    expect(
      await runMigrationCli([
        'index',
        '--output',
        output.path,
        '--index',
        index.path,
      ]),
      0,
    );
    expect(await index.readAsString(), first);
  });

  test('rejects copy and remove value settings in dorm.yaml', () async {
    final Directory root = _repositoryRoot();
    final Directory temporary = await Directory.systemTemp.createTemp(
      'dorm_migration_config_',
    );
    addTearDown(() => temporary.delete(recursive: true));

    final String inputPath =
        root.path +
        Platform.pathSeparator +
        'dorm_generator' +
        Platform.pathSeparator +
        'test' +
        Platform.pathSeparator +
        'fixtures' +
        Platform.pathSeparator +
        'migration_models.dart';
    for (final String key in ['copyFields', 'removeValues']) {
      final File config = File(
        temporary.path + Platform.pathSeparator + key + '.yaml',
      );
      final String value = key == 'copyFields'
          ? 'migrations:\n  copyFields:\n    users:\n      display: name\n'
          : 'migrations:\n  removeValues:\n    users:\n      - legacy\n';
      await config.writeAsString(value);

      expect(
        await runMigrationCli([
          'initialize',
          '--input',
          inputPath,
          '--snapshot',
          temporary.path + Platform.pathSeparator + key + '.json',
          '--config',
          config.path,
        ]),
        1,
      );
    }
  });
  test('rejects a Dart file outside the migration naming convention', () async {
    final Directory temporary = await Directory.systemTemp.createTemp(
      'dorm_migration_index_invalid_',
    );
    addTearDown(() => temporary.delete(recursive: true));

    final Directory output = Directory(
      '${temporary.path}${Platform.pathSeparator}migrations',
    )..createSync();
    await File(
      '${output.path}${Platform.pathSeparator}notes.dart',
    ).writeAsString('// not a migration');
    final File index = File(
      '${output.path}${Platform.pathSeparator}index.dart',
    );

    expect(
      await runMigrationCli([
        'index',
        '--output',
        output.path,
        '--index',
        index.path,
      ]),
      1,
    );
    expect(index.existsSync(), isFalse);
  });
  test('upgrades from a historical schema snapshot', () async {
    final Directory root = _repositoryRoot();
    final Directory temporary = await Directory.systemTemp.createTemp(
      'dorm_migration_upgrade_',
    );
    addTearDown(() => temporary.delete(recursive: true));

    final File snapshot = File(
      '${temporary.path}${Platform.pathSeparator}schema.json',
    );
    final File input = File(
      '${root.path}${Platform.pathSeparator}dorm_generator${Platform.pathSeparator}test${Platform.pathSeparator}fixtures${Platform.pathSeparator}migration_models.dart',
    );
    expect(
      await runMigrationCli([
        'initialize',
        '--input',
        input.path,
        '--snapshot',
        snapshot.path,
        '--config',
        '${temporary.path}${Platform.pathSeparator}missing.yaml',
      ]),
      0,
    );

    final Map<String, Object?> historical = _readObject(snapshot);
    for (final Object? value in historical['entities']! as List<Object?>) {
      final Map<String, Object?> entity = value! as Map<String, Object?>;
      (entity['fields']! as List<Object?>).removeWhere(
        (field) =>
            field is Map<String, Object?> && field['columnName'] == 'active',
      );
    }
    await snapshot.writeAsString(jsonEncode(historical));

    final Directory output = Directory(
      '${temporary.path}${Platform.pathSeparator}migrations',
    );
    expect(
      await runMigrationCli([
        'diff',
        '--input',
        input.path,
        '--snapshot',
        snapshot.path,
        '--output',
        output.path,
        '--index',
        '${output.path}${Platform.pathSeparator}index.dart',
        '--config',
        '${temporary.path}${Platform.pathSeparator}missing.yaml',
        '--name',
        'upgrade-from-v1',
      ]),
      0,
    );

    final File migration = output.listSync().whereType<File>().firstWhere(
      (file) => !file.path.endsWith('index.dart'),
    );
    expect(await migration.readAsString(), contains("fieldName: 'active'"));
    final Map<String, Object?> updated = _readObject(snapshot);
    final bool hasActive = (updated['entities']! as List<Object?>).any(
      (value) =>
          value is Map<String, Object?> &&
          (value['fields']! as List<Object?>).any(
            (field) =>
                field is Map<String, Object?> &&
                field['columnName'] == 'active',
          ),
    );
    expect(hasActive, isTrue);
  });
}

Map<String, Object?> _readObject(File file) =>
    (jsonDecode(file.readAsStringSync()) as Map).cast<String, Object?>();

Map<String, Object?> _firstEntityWithField(Map<String, Object?> schema) =>
    (schema['entities']! as List<Object?>)
        .cast<Map<String, Object?>>()
        .firstWhere((entity) => (entity['fields']! as List).isNotEmpty);

Map<String, Object?> _firstEntityWithRequiredNonKey(
  Map<String, Object?> schema,
) => (schema['entities']! as List<Object?>)
    .cast<Map<String, Object?>>()
    .firstWhere(
      (entity) => (entity['fields']! as List).any(
        (value) =>
            value is Map<String, Object?> &&
            value['nullable'] == false &&
            !(entity['primaryKeys']! as List<Object?>).contains(
              value['columnName'],
            ),
      ),
    );

Directory _repositoryRoot() {
  Directory directory = Directory.current.absolute;
  while (directory.parent.path != directory.path) {
    if (File(
          '${directory.path}${Platform.pathSeparator}pubspec.yaml',
        ).existsSync() &&
        Directory(
          '${directory.path}${Platform.pathSeparator}dorm_generator',
        ).existsSync()) {
      return directory;
    }
    directory = directory.parent;
  }
  throw StateError('Could not locate the dORM repository root.');
}
