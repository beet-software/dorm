import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:args/args.dart';
import 'package:path/path.dart' as p;
import 'package:source_gen/source_gen.dart';
import 'package:yaml/yaml.dart';

import 'generator.dart';
import 'migration_schema.dart';

Future<int> runMigrationCli(List<String> arguments) async {
  final ArgParser parser = ArgParser()
    ..addCommand(
      'initialize',
      ArgParser()
        ..addOption('input', mandatory: true)
        ..addOption('snapshot', defaultsTo: 'migrations/schema.json')
        ..addOption('config', defaultsTo: 'dorm.yaml')
        ..addFlag('force'),
    )
    ..addCommand(
      'diff',
      ArgParser()
        ..addOption('input', mandatory: true)
        ..addOption('name', mandatory: true)
        ..addOption('snapshot', defaultsTo: 'migrations/schema.json')
        ..addOption('output', defaultsTo: 'migrations')
        ..addOption('index', defaultsTo: 'migrations/index.dart')
        ..addOption('config', defaultsTo: 'dorm.yaml')
        ..addFlag('from-empty')
        ..addFlag('allow-destructive')
        ..addFlag('dry-run'),
    )
    ..addCommand(
      'index',
      ArgParser()
        ..addOption('output', defaultsTo: 'migrations')
        ..addOption('index', defaultsTo: 'migrations/index.dart'),
    );

  try {
    final ArgResults results = parser.parse(arguments);
    final ArgResults? command = results.command;
    if (command == null) {
      throw const FormatException('Choose initialize, diff, or index.');
    }
    return switch (command.name) {
      'initialize' => await _initialize(command),
      'diff' => await _diff(command),
      'index' => await _index(command),
      _ => throw FormatException('Unknown command: ${command.name}'),
    };
  } on FormatException catch (error) {
    stderr.writeln('Migration CLI error: $error');
    return 64;
  } on MigrationSchemaException catch (error) {
    stderr.writeln(error);
    return 1;
  } on Object catch (error, stackTrace) {
    stderr.writeln('Migration CLI failed: $error');
    stderr.writeln(stackTrace);
    return 1;
  }
}

Future<int> _initialize(ArgResults args) async {
  final File snapshot = File(args['snapshot'] as String);
  if (snapshot.existsSync() && !(args['force'] as bool)) {
    throw MigrationSchemaException(
      'Snapshot ${snapshot.path} already exists. Use --force to replace it.',
    );
  }
  final SchemaSnapshot schema = await _analyze(
    args['input'] as String,
    config: _readConfig(args['config'] as String),
  );
  await _writeAtomic(snapshot, '${schema.encode()}\n');
  stdout.writeln('Initialized schema snapshot at ${snapshot.path}.');
  return 0;
}

Future<int> _diff(ArgResults args) async {
  final File snapshot = File(args['snapshot'] as String);
  final bool fromEmpty = args['from-empty'] as bool;
  if (!fromEmpty && !snapshot.existsSync()) {
    throw MigrationSchemaException(
      'Snapshot ${snapshot.path} does not exist. Run initialize first or use --from-empty.',
    );
  }
  final MigrationConfig config = _readConfig(args['config'] as String);
  final SchemaSnapshot current = await _analyze(
    args['input'] as String,
    config: config,
  );
  final SchemaSnapshot previous = fromEmpty
      ? const SchemaSnapshot(entities: [])
      : SchemaSnapshot.fromJson(await snapshot.readAsString());
  final List<_Change> changes = _diffSchemas(
    previous,
    current,
    allowDestructive: args['allow-destructive'] as bool,
  );
  if (changes.isEmpty) {
    stdout.writeln('No schema changes found.');
    return 0;
  }
  final Directory output = Directory(args['output'] as String);
  final int version = _nextVersion(output);
  final String name = args['name'] as String;
  final File migration = File(
    '${output.path}${Platform.pathSeparator}'
    '${version.toString().padLeft(3, '0')}_${_slug(name)}.dart',
  );
  if (migration.existsSync()) {
    throw MigrationSchemaException(
      'Migration file ${migration.path} already exists.',
    );
  }
  final String source = _generateMigration(
    version: version,
    name: name,
    changes: changes,
  );
  if (args['dry-run'] as bool) {
    stdout.write(source);
    return 0;
  }
  final File index = File(args['index'] as String);
  final String indexSource = _generateMigrationIndex(
    output,
    index,
    additional: migration,
  );
  await _writeAtomic(migration, source);
  await _writeAtomic(index, indexSource);
  await _writeAtomic(snapshot, '${current.encode()}\n');
  stdout.writeln('Generated ${migration.path}.');
  stdout.writeln('Updated ${index.path}.');
  stdout.writeln('Updated ${snapshot.path}.');
  if (changes.any((change) => change.reviewNote != null)) {
    stdout.writeln(
      'Review required: inspect the generated migration comments before applying it.',
    );
  }
  return 0;
}

Future<int> _index(ArgResults args) async {
  final Directory output = Directory(args['output'] as String);
  final File index = File(args['index'] as String);
  await _writeAtomic(index, _generateMigrationIndex(output, index));
  stdout.writeln('Generated ${index.path}.');
  return 0;
}

String _generateMigrationIndex(
  Directory directory,
  File index, {
  File? additional,
}) {
  final List<File> files = [];
  if (directory.existsSync()) {
    for (final FileSystemEntity entity in directory.listSync()) {
      if (entity is! File || p.extension(entity.path) != '.dart') continue;
      if (_samePath(entity.path, index.path)) continue;
      files.add(entity);
    }
  }
  if (additional != null &&
      !files.any((file) => _samePath(file.path, additional.path))) {
    files.add(additional);
  }

  final RegExp pattern = RegExp(r'^(\d+)_([a-z0-9][a-z0-9_]*)\.dart$');
  final List<_MigrationFile> migrations = [];
  for (final File file in files) {
    final String name = p.basename(file.path);
    final RegExpMatch? match = pattern.firstMatch(name);
    if (match == null) {
      throw MigrationSchemaException(
        'Migration source ${file.path} does not follow the '
        'NNN_name.dart naming convention.',
      );
    }
    migrations.add(
      _MigrationFile(
        file: file,
        version: int.parse(match.group(1)!),
        alias: 'migration_${p.basenameWithoutExtension(name)}',
      ),
    );
  }
  migrations.sort((left, right) {
    final int version = left.version.compareTo(right.version);
    return version == 0
        ? p.basename(left.file.path).compareTo(p.basename(right.file.path))
        : version;
  });

  for (int position = 1; position < migrations.length; position++) {
    if (migrations[position - 1].version == migrations[position].version) {
      throw MigrationSchemaException(
        'Migration version ${migrations[position].version} is declared more than once.',
      );
    }
  }

  final StringBuffer source = StringBuffer()
    ..writeln('// GENERATED CODE - DO NOT MODIFY BY HAND.')
    ..writeln()
    ..writeln("import 'package:dorm_migrations/dorm_migrations.dart';");
  for (final _MigrationFile migration in migrations) {
    final String importPath = p
        .relative(migration.file.path, from: index.parent.path)
        .replaceAll(r'\', '/');
    source
      ..writeln()
      ..writeln("import '$importPath' as ${migration.alias};");
  }
  source
    ..writeln()
    ..writeln('final List<Migration> migrations = [');
  for (final _MigrationFile migration in migrations) {
    source.writeln('  ${migration.alias}.migration,');
  }
  source
    ..writeln('];')
    ..writeln();
  return source.toString();
}

bool _samePath(String left, String right) =>
    p.normalize(p.absolute(left)) == p.normalize(p.absolute(right));

final class _MigrationFile {
  const _MigrationFile({
    required this.file,
    required this.version,
    required this.alias,
  });

  final File file;
  final int version;
  final String alias;
}

Future<SchemaSnapshot> _analyze(
  String input, {
  required MigrationConfig config,
}) async {
  final File file = File(input);
  if (!file.existsSync()) {
    throw MigrationSchemaException('Input file does not exist: ${file.path}');
  }
  final String path = file.absolute.path;
  final AnalysisContextCollection contexts = AnalysisContextCollection(
    includedPaths: [path],
  );
  try {
    final SomeResolvedLibraryResult result = await contexts
        .contextFor(path)
        .currentSession
        .getResolvedLibrary(path);
    if (result is! ResolvedLibraryResult) {
      throw MigrationSchemaException(
        'Could not resolve ${input}. Check imports and package configuration.',
      );
    }
    return buildMigrationSchema(LibraryReader(result.element), config: config);
  } finally {
    await contexts.dispose();
  }
}

MigrationConfig _readConfig(String path) {
  final File file = File(path);
  if (!file.existsSync()) return const MigrationConfig();
  final Object? loaded = loadYaml(file.readAsStringSync());
  if (loaded is! YamlMap) {
    throw MigrationSchemaException('${path} must contain a YAML object.');
  }

  final Map<String, Map<String, Map<String, String>>> overrides = {};
  final Object? schema = loaded['schema'];
  final Object? typeOverrides = schema is YamlMap
      ? schema['typeOverrides']
      : null;
  if (typeOverrides is YamlMap) {
    for (final MapEntry<Object?, Object?> entity in typeOverrides.entries) {
      if (entity.value is! YamlMap) {
        throw MigrationSchemaException(
          'Type overrides for ${entity.key} must be a map.',
        );
      }
      overrides['${entity.key}'] = {
        for (final MapEntry<Object?, Object?> field
            in (entity.value as YamlMap).entries)
          '${field.key}': {
            if (field.value is YamlMap)
              for (final MapEntry<Object?, Object?> backend
                  in (field.value as YamlMap).entries)
                '${backend.key}': '${backend.value}',
          },
      };
    }
  }

  final Object? migrations = loaded['migrations'];
  if (migrations is YamlMap) {
    for (final String key in ['copyFields', 'removeValues']) {
      if (migrations.containsKey(key)) {
        throw MigrationSchemaException(
          'migrations.' +
              key +
              ' is no longer supported. Add the corresponding '
                  'operation directly to the generated Dart migration.',
        );
      }
    }
  }
  return MigrationConfig(typeOverrides: overrides);
}

List<_Change> _diffSchemas(
  SchemaSnapshot previous,
  SchemaSnapshot current, {
  required bool allowDestructive,
}) {
  final Map<String, SchemaEntity> oldEntities = {
    for (final SchemaEntity entity in previous.entities)
      entity.tableName: entity,
  };
  final Map<String, SchemaEntity> newEntities = {
    for (final SchemaEntity entity in current.entities)
      entity.tableName: entity,
  };
  final List<_Change> changes = [];

  for (final SchemaEntity entity in current.entities) {
    final SchemaEntity? old = oldEntities[entity.tableName];
    if (old == null) {
      changes.add(_Change.create(entity));
    } else {
      if (!_sameKeys(old.primaryKeys, entity.primaryKeys)) {
        throw MigrationSchemaException(
          'Primary-key changes for ${entity.tableName} must be written manually.',
        );
      }
      changes.addAll(
        _diffFields(old, entity, allowDestructive: allowDestructive),
      );
    }
  }
  for (final SchemaEntity entity in previous.entities) {
    if (newEntities.containsKey(entity.tableName)) continue;
    if (!allowDestructive) {
      throw MigrationSchemaException(
        'Removing entity ${entity.tableName} is destructive. Use --allow-destructive.',
      );
    }
    changes.add(_Change.drop(entity.tableName));
  }
  return changes;
}

List<_Change> _diffFields(
  SchemaEntity old,
  SchemaEntity current, {
  required bool allowDestructive,
}) {
  final Map<String, SchemaField> oldFields = {
    for (final SchemaField field in old.fields) field.columnName: field,
  };
  final Map<String, SchemaField> newFields = {
    for (final SchemaField field in current.fields) field.columnName: field,
  };
  final List<String> removedCandidates = [
    for (final String field in oldFields.keys)
      if (!newFields.containsKey(field)) field,
  ];
  final Set<String> matched = {};
  final List<_Change> changes = [];

  for (final SchemaField field in current.fields) {
    final SchemaField? previous = oldFields[field.columnName];
    if (previous == null) {
      final List<String> reviewNotes = [];
      if (removedCandidates.isNotEmpty) {
        reviewNotes.add(
          'An existing field was removed in this diff. If this new field is '
          'a rename, replace the generated add/remove pair with '
          'RenameFieldOperation.',
        );
      }
      if (!field.nullable) {
        reviewNotes.add(
          'This field is required. Add a BackfillFieldOperation and an '
          'AlterFieldOperation after reviewing the existing data.',
        );
        changes.add(
          _Change.add(
            current.tableName,
            field.copyWith(nullable: true),
            reviewNote: reviewNotes.join(' '),
          ),
        );
      } else {
        changes.add(
          _Change.add(
            current.tableName,
            field,
            reviewNote: reviewNotes.isEmpty ? null : reviewNotes.join(' '),
          ),
        );
      }
      continue;
    }
    matched.add(previous.columnName);
    if (previous.foreignTable != field.foreignTable ||
        previous.foreignField != field.foreignField ||
        previous.unique != field.unique) {
      throw MigrationSchemaException(
        'Relationship metadata changes for ${current.tableName}.${field.columnName} '
        'must be written manually.',
      );
    }
    if (previous.logicalType != field.logicalType ||
        previous.nullable != field.nullable ||
        !_sameStringMap(previous.typeOverrides, field.typeOverrides)) {
      changes.add(_Change.alter(current.tableName, field));
    }
  }

  for (final SchemaField field in old.fields) {
    if (matched.contains(field.columnName) ||
        newFields.containsKey(field.columnName)) {
      continue;
    }
    if (!allowDestructive) {
      throw MigrationSchemaException(
        'Removing field ${old.tableName}.${field.columnName} is destructive. '
        'Use --allow-destructive.',
      );
    }
    changes.add(_Change.remove(old.tableName, field.columnName));
  }
  return changes;
}

bool _sameStringMap(Map<String, String> left, Map<String, String> right) =>
    left.length == right.length &&
    left.entries.every((entry) => right[entry.key] == entry.value);
bool _sameKeys(List<String> left, List<String> right) =>
    left.length == right.length &&
    {...left}.containsAll(right) &&
    {...right}.containsAll(left);

int _nextVersion(Directory output) {
  if (!output.existsSync()) return 1;
  final RegExp pattern = RegExp(r'^(\d+)_.*\.dart$');
  int maximum = 0;
  for (final FileSystemEntity entity in output.listSync()) {
    final String name = entity.uri.pathSegments.last;
    final RegExpMatch? match = pattern.firstMatch(name);
    if (match == null) continue;
    final int value = int.parse(match.group(1)!);
    if (value > maximum) maximum = value;
  }
  return maximum + 1;
}

String _slug(String name) {
  final String slug = name.trim().toLowerCase().replaceAll(
    RegExp(r'[^a-z0-9]+'),
    '_',
  );
  if (slug.isEmpty)
    throw const FormatException('Migration name cannot be empty.');
  return slug.replaceAll(RegExp(r'^_|_$'), '');
}

Future<void> _writeAtomic(File file, String content) async {
  await file.parent.create(recursive: true);
  final File temporary = File('${file.path}.tmp');
  await temporary.writeAsString(content);
  if (file.existsSync()) await file.delete();
  await temporary.rename(file.path);
}

final class _Change {
  const _Change._(
    this.kind,
    this.entity, {
    this.field,
    this.from,

    this.entityDefinition,
    this.reviewNote,
  });

  final String kind;
  final String entity;
  final SchemaField? field;
  final String? from;

  final SchemaEntity? entityDefinition;
  final String? reviewNote;

  factory _Change.create(SchemaEntity entity) =>
      _Change._('create', entity.tableName, entityDefinition: entity);
  factory _Change.drop(String entity) => _Change._('drop', entity);
  factory _Change.add(String entity, SchemaField field, {String? reviewNote}) =>
      _Change._('add', entity, field: field, reviewNote: reviewNote);
  factory _Change.remove(String entity, String field) =>
      _Change._('remove', entity, from: field);
  factory _Change.alter(String entity, SchemaField field) =>
      _Change._('alter', entity, field: field);
}

String _generateMigration({
  required int version,
  required String name,
  required List<_Change> changes,
}) {
  final StringBuffer output = StringBuffer()
    ..writeln("import 'package:dorm_migrations/dorm_migrations.dart';")
    ..writeln()
    ..writeln('final migration = Migration(')
    ..writeln('  version: ${version},')
    ..writeln('  name: ${_dartLiteral(name)},')
    ..writeln('  operations: [');
  for (final _Change change in changes) {
    output.writeln(_operationSource(change));
  }
  output
    ..writeln('  ],')
    ..writeln(');')
    ..writeln();
  return output.toString();
}

String _operationSource(_Change change) {
  final String operation = switch (change.kind) {
    'create' => _createSource(change.entityDefinition!),
    'drop' =>
      '    DropEntityOperation(entityName: ${_dartLiteral(change.entity)}),',
    'add' => _fieldOperation('AddFieldOperation', change),
    'alter' => _fieldOperation('AlterFieldOperation', change),
    'remove' =>
      '    RemoveFieldOperation(entityName: ${_dartLiteral(change.entity)}, field: ${_dartLiteral(change.from!)}),',
    _ => throw StateError('Unknown migration change ${change.kind}'),
  };
  final String? reviewNote = change.reviewNote;
  if (reviewNote == null) return operation;
  return '    // Review required: $reviewNote\n$operation';
}

String _createSource(SchemaEntity entity) {
  final StringBuffer output = StringBuffer()
    ..writeln('    CreateEntityOperation(')
    ..writeln('      entity: MigrationEntityDefinition(')
    ..writeln('        entityName: ${_dartLiteral(entity.name)},')
    ..writeln('        tableName: ${_dartLiteral(entity.tableName)},')
    ..writeln('        primaryKeys: ${_dartLiteral(entity.primaryKeys)},')
    ..writeln('        fields: [');
  for (final SchemaField field in entity.fields) {
    output.writeln('${_definitionSource(field, indent: 10)},');
  }
  output
    ..writeln('        ],')
    ..writeln('      ),')
    ..writeln('    ),');
  return output.toString();
}

String _fieldOperation(String operation, _Change change) =>
    '    ${operation}(entityName: ${_dartLiteral(change.entity)}, '
    'field: ${_definitionSource(change.field!, indent: 0).trim()}),';

String _definitionSource(SchemaField field, {required int indent}) {
  final String padding = ' ' * indent;
  final String type = switch (field.logicalType) {
    'text' => 'MigrationValueType.text',
    'integer' => 'MigrationValueType.integer',
    'real' => 'MigrationValueType.real',
    'boolean' => 'MigrationValueType.boolean',
    'dateTime' => 'MigrationValueType.dateTime',
    'json' => 'MigrationValueType.json',
    'binary' => 'MigrationValueType.binary',
    _ => throw StateError('Unknown logical type ${field.logicalType}'),
  };
  final String className = field.typeOverrides.isEmpty
      ? 'MigrationFieldDefinition'
      : 'SqlMigrationFieldDefinition';
  final StringBuffer output = StringBuffer()
    ..write('${padding}${className}(')
    ..write('fieldName: ${_dartLiteral(field.name)}, ')
    ..write('columnName: ${_dartLiteral(field.columnName)}, ')
    ..write('type: ${type}, ')
    ..write('nullable: ${field.nullable}');
  if (field.typeOverrides.isNotEmpty) {
    output.write(', typeOverrides: {');
    for (final MapEntry<String, String> entry in field.typeOverrides.entries) {
      output.write(
        'SqlMigrationDialect.${entry.key}: ${_dartLiteral(entry.value)}, ',
      );
    }
    output.write('}');
  }
  output.write(')');
  return output.toString();
}

String _dartLiteral(Object? value) {
  if (value == null) return 'null';
  if (value is String) {
    return "'${value.replaceAll(r'\', r'\\').replaceAll("'", r"\'")}'";
  }
  if (value is bool || value is num) return '$value';
  if (value is List) return '[${value.map(_dartLiteral).join(', ')}]';
  if (value is Map) {
    return '{${value.entries.map((entry) => '${_dartLiteral(entry.key)}: ${_dartLiteral(entry.value)}').join(', ')}}';
  }
  throw MigrationSchemaException('Cannot emit Dart literal for $value.');
}
