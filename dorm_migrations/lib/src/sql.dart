import 'dart:convert';

import 'package:dorm_framework/dorm_framework.dart';

/// The SQL families supported by the portable SQL adapter.
enum SqlMigrationDialect { mysql, postgresql, sqlite }

/// Adds physical type overrides for SQL dialects to a logical field.
final class SqlMigrationFieldDefinition extends MigrationFieldDefinition {
  const SqlMigrationFieldDefinition({
    required super.fieldName,
    required super.columnName,
    required super.type,
    super.nullable,
    super.hasDefault,
    super.defaultValue,
    this.typeOverrides = const <SqlMigrationDialect, String>{},
  });

  final Map<SqlMigrationDialect, String> typeOverrides;
}

/// The minimal database access required by [SqlMigrationAdapter].
abstract interface class SqlMigrationBackend {
  Future<List<Map<String, Object?>>> query(
    String sql, [
    Object? parameters = const [],
  ]);

  Future<void> execute(String sql, [Object? parameters = const []]);

  Future<T> lock<T>(Future<T> Function() action);
}

/// SQL backend access with a transaction boundary for migration work.
abstract interface class TransactionalSqlMigrationBackend
    implements SqlMigrationBackend, TransactionalMigrationAdapter {}

/// A SQL statement emitted by [SqlMigrationAdapter.preview].
final class SqlMigrationStatement {
  const SqlMigrationStatement({
    required this.migrationVersion,
    required this.migrationName,
    required this.operationIndex,
    required this.sql,
    this.parameters = const <Object?>[],
  });

  final int migrationVersion;
  final String migrationName;
  final int operationIndex;
  final String sql;
  final Object? parameters;
}

/// A deterministic SQL preview that has not been executed.
final class SqlMigrationScript {
  const SqlMigrationScript({required this.dialect, required this.statements});

  final SqlMigrationDialect dialect;
  final List<SqlMigrationStatement> statements;

  /// Returns statements separated by semicolons for review or saving.
  String get sql => statements
      .map((statement) => '${statement.sql};')
      .join(String.fromCharCode(10));
}

/// Applies logical migration operations using SQL DDL and DML.
class SqlMigrationAdapter
    implements
        MigrationAdapter,
        MigrationHistoryCompactionAdapter,
        TransactionalMigrationAdapter,
        MigrationSchemaInspector {
  SqlMigrationAdapter(
    this.backend, {
    required this.dialect,
    this.historyTable = '__dorm_migrations',
  });

  final SqlMigrationBackend backend;
  final SqlMigrationDialect dialect;
  final String historyTable;
  bool _historyReady = false;

  @override
  MigrationTransactionMode get transactionMode => switch (backend) {
    final TransactionalSqlMigrationBackend value => value.transactionMode,
    _ => MigrationTransactionMode.none,
  };

  @override
  Future<T> transaction<T>(Future<T> Function() action) => switch (backend) {
    final TransactionalSqlMigrationBackend value => value.transaction(action),
    _ => action(),
  };

  /// Reads tables, fields, nullability, defaults, and primary keys from SQL.
  ///
  /// The result uses logical dORM types. Provider-specific physical types that
  /// cannot be classified safely cause [MigrationUnsupportedException].
  @override
  Future<MigrationSchemaSnapshot> inspectSchema() async {
    final List<String> tables = await _tableNames();
    final List<MigrationEntityDefinition> entities = [];
    for (final String table in tables) {
      final List<MigrationFieldDefinition> fields = await _fields(table);
      final List<String> primaryKeys = await _primaryKeys(table);
      entities.add(
        MigrationEntityDefinition(
          entityName: table,
          tableName: table,
          fields: fields,
          primaryKeys: primaryKeys,
        ),
      );
    }
    return MigrationSchemaSnapshot(entities: List.unmodifiable(entities));
  }

  Future<List<String>> _tableNames() async {
    final List<Map<String, Object?>> rows = switch (dialect) {
      SqlMigrationDialect.mysql => await backend.query(
        'SELECT table_name FROM information_schema.tables '
        'WHERE table_schema = DATABASE() AND table_type = :p0',
        _parameters(['BASE TABLE']),
      ),
      SqlMigrationDialect.postgresql => await backend.query(
        'SELECT table_name FROM information_schema.tables '
        'WHERE table_schema = current_schema() AND table_type = @p0',
        _parameters(['BASE TABLE']),
      ),
      SqlMigrationDialect.sqlite => await backend.query(
        "SELECT name FROM sqlite_master WHERE type = 'table' "
        "AND name NOT LIKE 'sqlite_%'",
      ),
    };
    return [
      for (final Map<String, Object?> row in rows)
        if ('${row['table_name'] ?? row['name']}' != historyTable)
          '${row['table_name'] ?? row['name']}',
    ];
  }

  Future<List<MigrationFieldDefinition>> _fields(String table) async {
    final List<Map<String, Object?>> rows = switch (dialect) {
      SqlMigrationDialect.mysql => await backend.query(
        'SELECT column_name, data_type, column_type, is_nullable, column_default '
        'FROM information_schema.columns '
        'WHERE table_schema = DATABASE() AND table_name = :p0 '
        'ORDER BY ordinal_position',
        _parameters([table]),
      ),
      SqlMigrationDialect.postgresql => await backend.query(
        'SELECT column_name, data_type, is_nullable, column_default '
        'FROM information_schema.columns '
        'WHERE table_schema = current_schema() AND table_name = @p0 '
        'ORDER BY ordinal_position',
        _parameters([table]),
      ),
      SqlMigrationDialect.sqlite => await backend.query(
        'PRAGMA table_info(${_identifier(table)})',
      ),
    };
    return [for (final Map<String, Object?> row in rows) _fieldFromRow(row)];
  }

  MigrationFieldDefinition _fieldFromRow(Map<String, Object?> row) {
    final String column = '${row['column_name'] ?? row['name']}';
    final Object? physicalType =
        row['column_type'] ?? row['data_type'] ?? row['type'];
    final Object? nullableValue = row['is_nullable'] ?? row['notnull'];
    final bool nullable = switch (nullableValue) {
      num value => value == 0,
      String value => value.toUpperCase() != 'NO' && value != '1',
      _ => true,
    };
    final Object? defaultValue = row['column_default'] ?? row['dflt_value'];
    return MigrationFieldDefinition(
      fieldName: column,
      columnName: column,
      type: _logicalType('$physicalType'),
      nullable: nullable,
      hasDefault: defaultValue != null,
      defaultValue: defaultValue,
    );
  }

  Future<List<String>> _primaryKeys(String table) async {
    final List<Map<String, Object?>> rows = switch (dialect) {
      SqlMigrationDialect.mysql => await backend.query(
        'SELECT kcu.column_name, kcu.ordinal_position '
        'FROM information_schema.table_constraints tc '
        'JOIN information_schema.key_column_usage kcu '
        'ON tc.constraint_name = kcu.constraint_name '
        'AND tc.table_schema = kcu.table_schema '
        'AND tc.table_name = kcu.table_name '
        'WHERE tc.table_schema = DATABASE() AND tc.table_name = :p0 '
        "AND tc.constraint_type = 'PRIMARY KEY' "
        'ORDER BY kcu.ordinal_position',
        _parameters([table]),
      ),
      SqlMigrationDialect.postgresql => await backend.query(
        'SELECT kcu.column_name, kcu.ordinal_position '
        'FROM information_schema.table_constraints tc '
        'JOIN information_schema.key_column_usage kcu '
        'ON tc.constraint_name = kcu.constraint_name '
        'AND tc.table_schema = kcu.table_schema '
        'AND tc.table_name = kcu.table_name '
        'WHERE tc.table_schema = current_schema() AND tc.table_name = @p0 '
        "AND tc.constraint_type = 'PRIMARY KEY' "
        'ORDER BY kcu.ordinal_position',
        _parameters([table]),
      ),
      SqlMigrationDialect.sqlite => await backend.query(
        'PRAGMA table_info(${_identifier(table)})',
      ),
    };
    final List<(int, String)> keys = [];
    for (final Map<String, Object?> row in rows) {
      final String? name = (row['column_name'] ?? row['name'])?.toString();
      final int? position = switch (row['ordinal_position'] ?? row['pk']) {
        num value => value.toInt(),
        Object? value => int.tryParse('$value'),
      };
      if (name != null && position != null && position > 0) {
        keys.add((position, name));
      }
    }
    keys.sort((a, b) => a.$1.compareTo(b.$1));
    return [for (final (_, name) in keys) name];
  }

  MigrationValueType _logicalType(String physicalType) {
    final String type = physicalType.toLowerCase();
    if (type == 'tinyint(1)' || type == 'bool' || type == 'boolean') {
      return MigrationValueType.boolean;
    }
    if (type.isEmpty ||
        type.contains('char') ||
        type.contains('text') ||
        type.contains('clob') ||
        type == 'enum' ||
        type == 'uuid') {
      return MigrationValueType.text;
    }
    if (type.contains('int') || type == 'serial' || type == 'bigserial') {
      return MigrationValueType.integer;
    }
    if (type.contains('real') ||
        type.contains('double') ||
        type.contains('float') ||
        type.contains('decimal') ||
        type.contains('numeric')) {
      return MigrationValueType.real;
    }
    if (type.contains('date') || type.contains('time')) {
      return MigrationValueType.dateTime;
    }
    if (type.contains('json')) return MigrationValueType.json;
    if (type.contains('blob') ||
        type.contains('binary') ||
        type.contains('bytea')) {
      return MigrationValueType.binary;
    }
    throw MigrationUnsupportedException(
      'Cannot classify SQL type "$physicalType" as a portable migration type.',
    );
  }

  @override
  Future<List<MigrationHistoryEntry>> appliedMigrations() async {
    await _ensureHistory();
    final List<Map<String, Object?>> rows = await backend.query(
      'SELECT version, name, checksum FROM ${_identifier(historyTable)} '
      'ORDER BY version',
    );
    return [
      for (final Map<String, Object?> row in rows)
        MigrationHistoryEntry(
          version: int.parse('${row['version']}'),
          name: '${row['name']}',
          checksum: row['checksum']?.toString(),
        ),
    ];
  }

  @override
  Future<T> lock<T>(Future<T> Function() action) async {
    try {
      return await backend.lock(action);
    } catch (_) {
      _historyReady = false;
      rethrow;
    }
  }

  @override
  Future<void> apply(MigrationOperation operation) {
    return switch (operation) {
      CreateEntityOperation() => _create(operation),
      DropEntityOperation() => _drop(operation),
      AddFieldOperation() => _addField(operation),
      RemoveFieldOperation() => _removeField(operation),
      RenameFieldOperation() => _renameField(operation),
      AlterFieldOperation() => _alterField(operation),
      CreateIndexOperation() => _createIndex(operation),
      DropIndexOperation() => _dropIndex(operation),
      CreateUniqueConstraintOperation() => _createUniqueConstraint(operation),
      DropUniqueConstraintOperation() => _dropUniqueConstraint(operation),
      ProviderMigrationOperation() => _provider(operation),
      CreateSequenceOperation() => _createSequence(operation),
      DropSequenceOperation() => _dropSequence(operation),
      CreateTriggerOperation() => _createTrigger(operation),
      DropTriggerOperation() => _dropTrigger(operation),
      CreateViewOperation() => _createView(operation),
      DropViewOperation() => _dropView(operation),
      CreateCheckConstraintOperation() => _createCheckConstraint(operation),
      DropCheckConstraintOperation() => _dropCheckConstraint(operation),
      CreateForeignKeyOperation() => _createForeignKey(operation),
      DropForeignKeyOperation() => _dropForeignKey(operation),
      BackfillFieldOperation() => _backfill(operation),
      CopyFieldOperation() => _copyField(operation),
      RemoveFieldValueOperation() => _removeValue(operation),
      TransformFieldOperation() => _transformField(operation),
    };
  }

  /// Generates the SQL that each operation would send to this dialect.
  ///
  /// The preview uses no provider connection. It returns placeholders and
  /// parameters separately, so the result must be reviewed before execution.
  Future<SqlMigrationScript> preview(Iterable<Migration> source) async {
    final List<Migration> migrations = MigrationGraph.order(source);
    final _SqlMigrationScriptBackend scriptBackend =
        _SqlMigrationScriptBackend();
    final SqlMigrationAdapter previewAdapter = SqlMigrationAdapter(
      scriptBackend,
      dialect: dialect,
      historyTable: historyTable,
    );
    for (final Migration migration in migrations) {
      for (final (index, operation) in migration.operations.indexed) {
        scriptBackend.migrationVersion = migration.version;
        scriptBackend.migrationName = migration.name;
        scriptBackend.operationIndex = index;
        await previewAdapter.apply(operation);
      }
    }
    return SqlMigrationScript(
      dialect: dialect,
      statements: List.unmodifiable(scriptBackend.statements),
    );
  }

  @override
  Future<void> record(Migration migration, {required String checksum}) async {
    await _ensureHistory();
    final String sql = switch (dialect) {
      SqlMigrationDialect.mysql =>
        'INSERT INTO ${_identifier(historyTable)} '
            '(version, name, checksum) VALUES (:p0, :p1, :p2) '
            'ON DUPLICATE KEY UPDATE name = VALUES(name), '
            'checksum = VALUES(checksum)',
      SqlMigrationDialect.postgresql =>
        'INSERT INTO ${_identifier(historyTable)} '
            '(version, name, checksum) VALUES (@p0, @p1, @p2) '
            'ON CONFLICT (version) DO UPDATE SET name = EXCLUDED.name, '
            'checksum = EXCLUDED.checksum',
      SqlMigrationDialect.sqlite =>
        'INSERT INTO ${_identifier(historyTable)} '
            '(version, name, checksum) VALUES (?, ?, ?) '
            'ON CONFLICT(version) DO UPDATE SET name = excluded.name, '
            'checksum = excluded.checksum',
    };
    await backend.execute(
      sql,
      _parameters([migration.version, migration.name, checksum]),
    );
  }

  @override
  Future<void> compactHistory(
    Migration migration, {
    required int through,
    required String checksum,
  }) async {
    await transaction<void>(() async {
      await _ensureHistory();
      await backend.execute(
        'DELETE FROM ${_identifier(historyTable)} WHERE version <= ${_placeholder(0)}',
        _parameters([through]),
      );
      await record(migration, checksum: checksum);
    });
  }

  Future<void> _ensureHistory() async {
    if (_historyReady) return;
    await backend.execute(
      'CREATE TABLE IF NOT EXISTS ${_identifier(historyTable)} '
      '(version INTEGER PRIMARY KEY, name TEXT NOT NULL, checksum TEXT, '
      'applied_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP)',
    );
    if (!await _hasColumn(historyTable, 'checksum')) {
      await backend.execute(
        'ALTER TABLE ${_identifier(historyTable)} ADD COLUMN checksum TEXT',
      );
    }
    _historyReady = true;
  }

  Future<void> _create(CreateEntityOperation operation) {
    final MigrationEntityDefinition entity = operation.entity;
    if (entity.fields.isEmpty) {
      throw const MigrationUnsupportedException(
        'An entity must declare at least one field.',
      );
    }
    final List<String> fields = [
      for (final MigrationFieldDefinition field in entity.fields)
        _definition(field),
      if (entity.primaryKeys.isNotEmpty)
        'PRIMARY KEY (${entity.primaryKeys.map(_identifier).join(', ')})',
    ];
    return backend.execute(
      'CREATE TABLE IF NOT EXISTS ${_identifier(entity.tableName)} '
      '(${fields.join(', ')})',
    );
  }

  Future<void> _drop(DropEntityOperation operation) => backend.execute(
    'DROP TABLE IF EXISTS ${_identifier(operation.entityName)}',
  );

  Future<void> _addField(AddFieldOperation operation) async {
    if (await _hasColumn(operation.entityName, operation.field.columnName)) {
      return;
    }
    final String clause = switch (dialect) {
      SqlMigrationDialect.mysql || SqlMigrationDialect.postgresql =>
        'ADD COLUMN IF NOT EXISTS ${_definition(operation.field)}',
      SqlMigrationDialect.sqlite =>
        'ADD COLUMN ${_definition(operation.field)}',
    };
    await backend.execute(
      'ALTER TABLE ${_identifier(operation.entityName)} $clause',
    );
  }

  Future<void> _removeField(RemoveFieldOperation operation) async {
    if (!await _hasColumn(operation.entityName, operation.field)) return;
    final String clause = switch (dialect) {
      SqlMigrationDialect.mysql || SqlMigrationDialect.postgresql =>
        'DROP COLUMN IF EXISTS ${_identifier(operation.field)}',
      SqlMigrationDialect.sqlite =>
        'DROP COLUMN ${_identifier(operation.field)}',
    };
    await backend.execute(
      'ALTER TABLE ${_identifier(operation.entityName)} $clause',
    );
  }

  Future<void> _renameField(RenameFieldOperation operation) async {
    final bool hasFrom = await _hasColumn(operation.entityName, operation.from);
    final bool hasTo = await _hasColumn(operation.entityName, operation.to);
    if (!hasFrom && hasTo) return;
    if (!hasFrom) {
      throw StateError(
        'Cannot rename missing column ${operation.from} in '
        '${operation.entityName}.',
      );
    }
    if (hasTo) {
      throw StateError(
        'Cannot rename ${operation.from}: target ${operation.to} already exists.',
      );
    }
    await backend.execute(
      'ALTER TABLE ${_identifier(operation.entityName)} RENAME COLUMN '
      '${_identifier(operation.from)} TO ${_identifier(operation.to)}',
    );
  }

  Future<bool> _hasColumn(String table, String column) async {
    final List<Map<String, Object?>> rows = switch (dialect) {
      SqlMigrationDialect.mysql => await backend.query(
        'SELECT 1 AS present FROM information_schema.columns '
        'WHERE table_schema = DATABASE() AND table_name = :p0 '
        'AND column_name = :p1',
        _parameters([table, column]),
      ),
      SqlMigrationDialect.postgresql => await backend.query(
        'SELECT 1 AS present FROM information_schema.columns '
        'WHERE table_schema = current_schema() AND table_name = @p0 '
        'AND column_name = @p1',
        _parameters([table, column]),
      ),
      SqlMigrationDialect.sqlite => await backend.query(
        'PRAGMA table_info(${_identifier(table)})',
      ),
    };
    return switch (dialect) {
      SqlMigrationDialect.sqlite => rows.any(
        (row) => '${row['name']}' == column,
      ),
      SqlMigrationDialect.mysql ||
      SqlMigrationDialect.postgresql => rows.isNotEmpty,
    };
  }

  Future<void> _alterField(AlterFieldOperation operation) async {
    if (dialect == SqlMigrationDialect.sqlite) {
      throw const MigrationUnsupportedException(
        'SQLite does not support portable ALTER COLUMN operations.',
      );
    }
    final String table = _identifier(operation.entityName);
    final String column = _identifier(operation.field.columnName);
    switch (dialect) {
      case SqlMigrationDialect.mysql:
        await backend.execute(
          'ALTER TABLE $table MODIFY COLUMN ${_definition(operation.field)}',
        );
      case SqlMigrationDialect.postgresql:
        await backend.execute(
          'ALTER TABLE $table ALTER COLUMN $column TYPE '
          '${_typeFor(operation.field)}',
        );
        await backend.execute(
          'ALTER TABLE $table ALTER COLUMN $column '
          '${operation.field.nullable ? 'DROP' : 'SET'} NOT NULL',
        );
        if (operation.field.hasDefault) {
          await backend.execute(
            'ALTER TABLE $table ALTER COLUMN $column SET DEFAULT '
            '${_literal(operation.field.defaultValue)}',
          );
        } else {
          await backend.execute(
            'ALTER TABLE $table ALTER COLUMN $column DROP DEFAULT',
          );
        }
      case SqlMigrationDialect.sqlite:
        throw const MigrationUnsupportedException(
          'SQLite does not support portable ALTER COLUMN operations.',
        );
    }
  }

  Future<void> _createIndex(CreateIndexOperation operation) async {
    if (operation.index.fields.isEmpty) {
      throw const MigrationUnsupportedException(
        'An index must declare at least one field.',
      );
    }
    if (await _hasIndex(operation.index.entityName, operation.index.name)) {
      return;
    }
    final String unique = operation.index.unique ? 'UNIQUE ' : '';
    await backend.execute(
      'CREATE ${unique}INDEX ${_identifier(operation.index.name)} ON '
      '${_identifier(operation.index.entityName)} '
      '(${operation.index.fields.map(_identifier).join(', ')})',
    );
  }

  Future<void> _dropIndex(DropIndexOperation operation) async {
    if (!await _hasIndex(operation.entityName, operation.indexName)) return;
    final String sql = switch (dialect) {
      SqlMigrationDialect.mysql =>
        'DROP INDEX ${_identifier(operation.indexName)} ON '
            '${_identifier(operation.entityName)}',
      SqlMigrationDialect.postgresql || SqlMigrationDialect.sqlite =>
        'DROP INDEX IF EXISTS ${_identifier(operation.indexName)}',
    };
    await backend.execute(sql);
  }

  Future<bool> _hasIndex(String table, String index) async {
    final List<Map<String, Object?>> rows = switch (dialect) {
      SqlMigrationDialect.mysql => await backend.query(
        'SELECT 1 AS present FROM information_schema.statistics '
        'WHERE table_schema = DATABASE() AND table_name = :p0 '
        'AND index_name = :p1',
        _parameters([table, index]),
      ),
      SqlMigrationDialect.postgresql => await backend.query(
        'SELECT 1 AS present FROM pg_indexes '
        'WHERE schemaname = current_schema() AND tablename = @p0 '
        'AND indexname = @p1',
        _parameters([table, index]),
      ),
      SqlMigrationDialect.sqlite => await backend.query(
        'PRAGMA index_list(${_identifier(table)})',
      ),
    };
    return switch (dialect) {
      SqlMigrationDialect.sqlite => rows.any(
        (row) => '${row['name']}' == index,
      ),
      SqlMigrationDialect.mysql ||
      SqlMigrationDialect.postgresql => rows.isNotEmpty,
    };
  }

  Future<void> _createUniqueConstraint(
    CreateUniqueConstraintOperation operation,
  ) async {
    if (operation.constraint.fields.isEmpty) {
      throw const MigrationUnsupportedException(
        'A unique constraint must declare at least one field.',
      );
    }
    if (dialect == SqlMigrationDialect.sqlite) {
      throw const MigrationUnsupportedException(
        'SQLite does not support portable unique constraint operations.',
      );
    }
    if (await _hasConstraint(
      operation.constraint.entityName,
      operation.constraint.name,
    )) {
      return;
    }
    await backend.execute(
      'ALTER TABLE ${_identifier(operation.constraint.entityName)} '
      'ADD CONSTRAINT ${_identifier(operation.constraint.name)} UNIQUE '
      '(${operation.constraint.fields.map(_identifier).join(', ')})',
    );
  }

  Future<void> _dropUniqueConstraint(
    DropUniqueConstraintOperation operation,
  ) async {
    if (dialect == SqlMigrationDialect.sqlite) {
      throw const MigrationUnsupportedException(
        'SQLite does not support portable unique constraint operations.',
      );
    }
    if (!await _hasConstraint(operation.entityName, operation.constraintName)) {
      return;
    }
    final String sql = switch (dialect) {
      SqlMigrationDialect.mysql =>
        'ALTER TABLE ${_identifier(operation.entityName)} DROP INDEX '
            '${_identifier(operation.constraintName)}',
      SqlMigrationDialect.postgresql =>
        'ALTER TABLE ${_identifier(operation.entityName)} DROP CONSTRAINT '
            '${_identifier(operation.constraintName)}',
      SqlMigrationDialect.sqlite => throw const MigrationUnsupportedException(
        'SQLite does not support portable unique constraint operations.',
      ),
    };
    await backend.execute(sql);
  }

  Future<bool> _hasConstraint(String table, String name) async {
    final List<Map<String, Object?>> rows = switch (dialect) {
      SqlMigrationDialect.mysql => await backend.query(
        'SELECT 1 AS present FROM information_schema.table_constraints '
        'WHERE table_schema = DATABASE() AND table_name = :p0 '
        'AND constraint_name = :p1 AND constraint_type = \'UNIQUE\'',
        _parameters([table, name]),
      ),
      SqlMigrationDialect.postgresql => await backend.query(
        'SELECT 1 AS present FROM information_schema.table_constraints '
        'WHERE table_schema = current_schema() AND table_name = @p0 '
        'AND constraint_name = @p1 AND constraint_type = \'UNIQUE\'',
        _parameters([table, name]),
      ),
      SqlMigrationDialect.sqlite => const <Map<String, Object?>>[],
    };
    return rows.isNotEmpty;
  }

  Future<void> _provider(ProviderMigrationOperation operation) async {
    if (operation.provider != dialect.name) {
      throw MigrationUnsupportedException(
        'Provider operation "${operation.name}" targets '
        '${operation.provider}, but this adapter uses ${dialect.name}.',
      );
    }
    if (operation.statement.trim().isEmpty) {
      throw const MigrationUnsupportedException(
        'A provider migration operation must declare a statement.',
      );
    }
    await backend.execute(operation.statement);
  }

  Future<void> _createSequence(CreateSequenceOperation operation) async {
    final MigrationSequenceDefinition sequence = operation.sequence;
    if (sequence.name.isEmpty || sequence.incrementBy == 0) {
      throw const MigrationUnsupportedException(
        'A sequence must declare a name and a non-zero increment.',
      );
    }
    if (dialect != SqlMigrationDialect.postgresql) {
      throw const MigrationUnsupportedException(
        'Only PostgreSQL supports portable sequence operations.',
      );
    }
    if (await _hasSequence(sequence.name)) return;
    await backend.execute(
      'CREATE SEQUENCE IF NOT EXISTS ${_identifier(sequence.name)} '
      'START WITH ${sequence.startWith} INCREMENT BY ${sequence.incrementBy}',
    );
  }

  Future<void> _dropSequence(DropSequenceOperation operation) async {
    if (dialect != SqlMigrationDialect.postgresql) {
      throw const MigrationUnsupportedException(
        'Only PostgreSQL supports portable sequence operations.',
      );
    }
    if (!await _hasSequence(operation.entityName)) return;
    await backend.execute(
      'DROP SEQUENCE IF EXISTS ${_identifier(operation.entityName)}',
    );
  }

  Future<bool> _hasSequence(String name) async {
    if (dialect != SqlMigrationDialect.postgresql) return false;
    final List<Map<String, Object?>> rows = await backend.query(
      'SELECT 1 AS present FROM information_schema.sequences '
      'WHERE sequence_schema = current_schema() AND sequence_name = @p0',
      _parameters([name]),
    );
    return rows.isNotEmpty;
  }

  Future<void> _createTrigger(CreateTriggerOperation operation) async {
    final MigrationTriggerDefinition trigger = operation.trigger;
    if (trigger.name.isEmpty || trigger.createStatement.trim().isEmpty) {
      throw const MigrationUnsupportedException(
        'A trigger must declare a name and create statement.',
      );
    }
    if (await _hasTrigger(trigger.name)) return;
    await backend.execute(trigger.createStatement);
  }

  Future<void> _dropTrigger(DropTriggerOperation operation) async {
    if (!await _hasTrigger(operation.triggerName)) return;
    final String sql = switch (dialect) {
      SqlMigrationDialect.mysql || SqlMigrationDialect.sqlite =>
        'DROP TRIGGER IF EXISTS ${_identifier(operation.triggerName)}',
      SqlMigrationDialect.postgresql =>
        'DROP TRIGGER IF EXISTS ${_identifier(operation.triggerName)} ON '
            '${_identifier(operation.entityName)}',
    };
    await backend.execute(sql);
  }

  Future<bool> _hasTrigger(String name) async {
    final List<Map<String, Object?>> rows = switch (dialect) {
      SqlMigrationDialect.mysql => await backend.query(
        'SELECT 1 AS present FROM information_schema.triggers '
        'WHERE trigger_schema = DATABASE() AND trigger_name = :p0',
        _parameters([name]),
      ),
      SqlMigrationDialect.postgresql => await backend.query(
        'SELECT 1 AS present FROM information_schema.triggers '
        'WHERE trigger_schema = current_schema() AND trigger_name = @p0',
        _parameters([name]),
      ),
      SqlMigrationDialect.sqlite => await backend.query(
        'SELECT 1 AS present FROM sqlite_master '
        'WHERE type = \'trigger\' AND name = ?',
        _parameters([name]),
      ),
    };
    return rows.isNotEmpty;
  }

  Future<void> _createView(CreateViewOperation operation) async {
    final MigrationViewDefinition view = operation.view;
    if (view.name.isEmpty || view.query.trim().isEmpty) {
      throw const MigrationUnsupportedException(
        'A view must declare a name and query.',
      );
    }
    if (await _hasView(view.name)) return;
    final String prefix = dialect == SqlMigrationDialect.sqlite
        ? 'CREATE VIEW IF NOT EXISTS'
        : 'CREATE VIEW';
    await backend.execute('$prefix ${_identifier(view.name)} AS ${view.query}');
  }

  Future<void> _dropView(DropViewOperation operation) async {
    if (!await _hasView(operation.entityName)) return;
    await backend.execute(
      'DROP VIEW IF EXISTS ${_identifier(operation.entityName)}',
    );
  }

  Future<bool> _hasView(String name) async {
    final List<Map<String, Object?>> rows = switch (dialect) {
      SqlMigrationDialect.mysql => await backend.query(
        'SELECT 1 AS present FROM information_schema.views '
        'WHERE table_schema = DATABASE() AND table_name = :p0',
        _parameters([name]),
      ),
      SqlMigrationDialect.postgresql => await backend.query(
        'SELECT 1 AS present FROM information_schema.views '
        'WHERE table_schema = current_schema() AND table_name = @p0',
        _parameters([name]),
      ),
      SqlMigrationDialect.sqlite => await backend.query(
        'SELECT 1 AS present FROM sqlite_master '
        'WHERE type = \'view\' AND name = ?',
        _parameters([name]),
      ),
    };
    return rows.isNotEmpty;
  }

  Future<void> _createCheckConstraint(
    CreateCheckConstraintOperation operation,
  ) async {
    final MigrationCheckConstraintDefinition constraint = operation.constraint;
    if (constraint.name.isEmpty || constraint.expression.trim().isEmpty) {
      throw const MigrationUnsupportedException(
        'A check constraint must declare a name and expression.',
      );
    }
    if (dialect == SqlMigrationDialect.sqlite) {
      throw const MigrationUnsupportedException(
        'SQLite does not support portable check constraint operations.',
      );
    }
    if (await _hasCheckConstraint(constraint.entityName, constraint.name)) {
      return;
    }
    await backend.execute(
      'ALTER TABLE ${_identifier(constraint.entityName)} '
      'ADD CONSTRAINT ${_identifier(constraint.name)} '
      'CHECK (${constraint.expression})',
    );
  }

  Future<void> _dropCheckConstraint(
    DropCheckConstraintOperation operation,
  ) async {
    if (dialect == SqlMigrationDialect.sqlite) {
      throw const MigrationUnsupportedException(
        'SQLite does not support portable check constraint operations.',
      );
    }
    if (!await _hasCheckConstraint(
      operation.entityName,
      operation.constraintName,
    )) {
      return;
    }
    final String sql = switch (dialect) {
      SqlMigrationDialect.mysql =>
        'ALTER TABLE ${_identifier(operation.entityName)} DROP CHECK '
            '${_identifier(operation.constraintName)}',
      SqlMigrationDialect.postgresql =>
        'ALTER TABLE ${_identifier(operation.entityName)} DROP CONSTRAINT '
            '${_identifier(operation.constraintName)}',
      SqlMigrationDialect.sqlite => throw const MigrationUnsupportedException(
        'SQLite does not support portable check constraint operations.',
      ),
    };
    await backend.execute(sql);
  }

  Future<bool> _hasCheckConstraint(String table, String name) async {
    final List<Map<String, Object?>> rows = switch (dialect) {
      SqlMigrationDialect.mysql => await backend.query(
        'SELECT 1 AS present FROM information_schema.table_constraints '
        'WHERE table_schema = DATABASE() AND table_name = :p0 '
        'AND constraint_name = :p1 AND constraint_type = \'CHECK\'',
        _parameters([table, name]),
      ),
      SqlMigrationDialect.postgresql => await backend.query(
        'SELECT 1 AS present FROM information_schema.table_constraints '
        'WHERE table_schema = current_schema() AND table_name = @p0 '
        'AND constraint_name = @p1 AND constraint_type = \'CHECK\'',
        _parameters([table, name]),
      ),
      SqlMigrationDialect.sqlite => const <Map<String, Object?>>[],
    };
    return rows.isNotEmpty;
  }

  Future<void> _createForeignKey(CreateForeignKeyOperation operation) async {
    final MigrationForeignKeyDefinition foreignKey = operation.foreignKey;
    if (foreignKey.fields.isEmpty || foreignKey.referencedFields.isEmpty) {
      throw const MigrationUnsupportedException(
        'A foreign key must declare local and referenced fields.',
      );
    }
    if (foreignKey.fields.length != foreignKey.referencedFields.length) {
      throw const MigrationUnsupportedException(
        'A foreign key must declare the same number of local and referenced fields.',
      );
    }
    if (dialect == SqlMigrationDialect.sqlite) {
      throw const MigrationUnsupportedException(
        'SQLite does not support portable foreign key operations.',
      );
    }
    if (await _hasForeignKey(foreignKey.entityName, foreignKey.name)) {
      return;
    }
    await backend.execute(
      'ALTER TABLE ${_identifier(foreignKey.entityName)} '
      'ADD CONSTRAINT ${_identifier(foreignKey.name)} FOREIGN KEY '
      '(${foreignKey.fields.map(_identifier).join(', ')}) REFERENCES '
      '${_identifier(foreignKey.referencedEntity)} '
      '(${foreignKey.referencedFields.map(_identifier).join(', ')}) '
      'ON DELETE ${_referentialAction(foreignKey.onDelete)} '
      'ON UPDATE ${_referentialAction(foreignKey.onUpdate)}',
    );
  }

  Future<void> _dropForeignKey(DropForeignKeyOperation operation) async {
    if (dialect == SqlMigrationDialect.sqlite) {
      throw const MigrationUnsupportedException(
        'SQLite does not support portable foreign key operations.',
      );
    }
    if (!await _hasForeignKey(operation.entityName, operation.foreignKeyName)) {
      return;
    }
    final String sql = switch (dialect) {
      SqlMigrationDialect.mysql =>
        'ALTER TABLE ${_identifier(operation.entityName)} DROP FOREIGN KEY '
            '${_identifier(operation.foreignKeyName)}',
      SqlMigrationDialect.postgresql =>
        'ALTER TABLE ${_identifier(operation.entityName)} DROP CONSTRAINT '
            '${_identifier(operation.foreignKeyName)}',
      SqlMigrationDialect.sqlite => throw const MigrationUnsupportedException(
        'SQLite does not support portable foreign key operations.',
      ),
    };
    await backend.execute(sql);
  }

  Future<bool> _hasForeignKey(String table, String name) async {
    final List<Map<String, Object?>> rows = switch (dialect) {
      SqlMigrationDialect.mysql => await backend.query(
        'SELECT 1 AS present FROM information_schema.table_constraints '
        'WHERE table_schema = DATABASE() AND table_name = :p0 '
        'AND constraint_name = :p1 AND constraint_type = \'FOREIGN KEY\'',
        _parameters([table, name]),
      ),
      SqlMigrationDialect.postgresql => await backend.query(
        'SELECT 1 AS present FROM information_schema.table_constraints '
        'WHERE table_schema = current_schema() AND table_name = @p0 '
        'AND constraint_name = @p1 AND constraint_type = \'FOREIGN KEY\'',
        _parameters([table, name]),
      ),
      SqlMigrationDialect.sqlite => const <Map<String, Object?>>[],
    };
    return rows.isNotEmpty;
  }

  String _referentialAction(MigrationReferentialAction action) =>
      switch (action) {
        MigrationReferentialAction.noAction => 'NO ACTION',
        MigrationReferentialAction.restrict => 'RESTRICT',
        MigrationReferentialAction.cascade => 'CASCADE',
        MigrationReferentialAction.setNull => 'SET NULL',
      };

  Future<void> _transformField(TransformFieldOperation operation) {
    final List<Object?> parameters = [];
    final String filter = _filterSql(operation.filter, parameters);
    final String target = _identifier(operation.field);
    final String missing = operation.onlyMissing ? ' AND $target IS NULL' : '';
    final String value = switch (operation.transform) {
      CopyMigrationValue(:final sourceField) => _identifier(sourceField),
      TextMigrationValue(:final sourceField, :final operation) =>
        switch (operation) {
          MigrationTextTransform.trim => 'TRIM(${_identifier(sourceField)})',
          MigrationTextTransform.lowerCase =>
            'LOWER(${_identifier(sourceField)})',
          MigrationTextTransform.upperCase =>
            'UPPER(${_identifier(sourceField)})',
        },
      ConvertMigrationValue(:final sourceField, :final outputType) =>
        'CAST(${_identifier(sourceField)} AS ${_type(outputType)})',
    };
    return backend.execute(
      'UPDATE ${_identifier(operation.entityName)} SET $target = $value '
      'WHERE ($filter)$missing',
      _parameters(parameters),
    );
  }

  String _filterSql(FilterExpression expression, List<Object?> parameters) {
    return switch (expression) {
      EmptyFilterExpression() => '1 = 1',
      ValueFilterExpression(:final field, :final value) =>
        value == null
            ? '${_identifier(field)} IS NULL'
            : '${_identifier(field)} = ${_parameter(value, parameters)}',
      TextFilterExpression(:final field, :final prefix) =>
        '${_identifier(field)} LIKE ${_parameter('$prefix%', parameters)}',
      DateFilterExpression() => throw const MigrationUnsupportedException(
        'SQL transformation filters do not support date-part comparisons.',
      ),
      RangeFilterExpression(:final field, :final range) => _rangeSql(
        field,
        range,
        parameters,
      ),
      ComparisonFilterExpression(:final field, :final operator, :final value) =>
        value == null
            ? throw const MigrationUnsupportedException(
                'SQL transformation comparisons require a non-null value.',
              )
            : '${_identifier(field)} ${_comparisonOperator(operator)} '
                  '${_parameter(value, parameters)}',
      SetFilterExpression(:final field, :final values, :final negated) =>
        _setSql(field, values, negated, parameters),
      NullFilterExpression(:final field, :final isNull) =>
        '${_identifier(field)} IS ${isNull ? '' : 'NOT '}NULL',
      ContainsFilterExpression() => throw const MigrationUnsupportedException(
        'SQL transformation filters do not support collection membership.',
      ),
      ContainsAnyFilterExpression() =>
        throw const MigrationUnsupportedException(
          'SQL transformation filters do not support collection membership.',
        ),
      AllFilterExpression(:final filters) =>
        filters.isEmpty
            ? '1 = 1'
            : filters
                  .map((filter) => '(${_filterSql(filter, parameters)})')
                  .join(' AND '),
      AnyFilterExpression(:final filters) =>
        filters.isEmpty
            ? '1 = 0'
            : filters
                  .map((filter) => '(${_filterSql(filter, parameters)})')
                  .join(' OR '),
      NotFilterExpression(:final filter) =>
        'NOT (${_filterSql(filter, parameters)})',
    };
  }

  String _rangeSql(
    String field,
    FilterRange<dynamic> range,
    List<Object?> parameters,
  ) {
    final List<String> clauses = [];
    if (range.from != null) {
      clauses.add(
        '${_identifier(field)} >= ${_parameter(range.from, parameters)}',
      );
    }
    if (range.to != null) {
      clauses.add(
        '${_identifier(field)} <= ${_parameter(range.to, parameters)}',
      );
    }
    return clauses.isEmpty ? '1 = 1' : clauses.join(' AND ');
  }

  String _setSql(
    String field,
    List<Object?> values,
    bool negated,
    List<Object?> parameters,
  ) {
    if (values.isEmpty) return negated ? '1 = 1' : '1 = 0';
    final String placeholders = [
      for (final Object? value in values) _parameter(value, parameters),
    ].join(', ');
    return '${_identifier(field)} ${negated ? 'NOT ' : ''}IN ($placeholders)';
  }

  String _parameter(Object? value, List<Object?> parameters) {
    final String placeholder = _placeholder(parameters.length);
    parameters.add(value);
    return placeholder;
  }

  String _comparisonOperator(FilterComparisonOperator operator) =>
      switch (operator) {
        FilterComparisonOperator.notEqual => '<>',
        FilterComparisonOperator.lessThan => '<',
        FilterComparisonOperator.lessThanOrEqual => '<=',
        FilterComparisonOperator.greaterThan => '>',
        FilterComparisonOperator.greaterThanOrEqual => '>=',
      };
  Future<void> _backfill(BackfillFieldOperation operation) {
    final String field = _identifier(operation.field);
    final String where = operation.onlyMissing ? ' WHERE $field IS NULL' : '';
    return backend.execute(
      'UPDATE ${_identifier(operation.entityName)} SET $field = ${_placeholder(0)}$where',
      _parameters([operation.value]),
    );
  }

  Future<void> _copyField(CopyFieldOperation operation) {
    final String target = _identifier(operation.to);
    final String where = operation.onlyMissing ? ' WHERE $target IS NULL' : '';
    return backend.execute(
      'UPDATE ${_identifier(operation.entityName)} SET $target = '
      '${_identifier(operation.from)}$where',
    );
  }

  Future<void> _removeValue(RemoveFieldValueOperation operation) =>
      backend.execute(
        'UPDATE ${_identifier(operation.entityName)} SET '
        '${_identifier(operation.field)} = NULL',
      );

  String _definition(MigrationFieldDefinition field) {
    final String nullable = field.nullable ? '' : ' NOT NULL';
    final String defaultValue = field.hasDefault
        ? ' DEFAULT ${_literal(field.defaultValue)}'
        : '';
    return '${_identifier(field.columnName)} ${_typeFor(field)}'
        '$nullable$defaultValue';
  }

  String _typeFor(MigrationFieldDefinition field) {
    final SqlMigrationFieldDefinition? sqlField =
        field is SqlMigrationFieldDefinition ? field : null;
    return sqlField?.typeOverrides[dialect] ?? _type(field.type);
  }

  String _type(MigrationValueType type) {
    return switch ((dialect, type)) {
      (SqlMigrationDialect.mysql, MigrationValueType.text) => 'TEXT',
      (SqlMigrationDialect.postgresql, MigrationValueType.text) => 'TEXT',
      (SqlMigrationDialect.sqlite, MigrationValueType.text) => 'TEXT',
      (SqlMigrationDialect.mysql, MigrationValueType.integer) => 'BIGINT',
      (SqlMigrationDialect.postgresql, MigrationValueType.integer) => 'BIGINT',
      (SqlMigrationDialect.sqlite, MigrationValueType.integer) => 'INTEGER',
      (SqlMigrationDialect.mysql, MigrationValueType.real) => 'DOUBLE',
      (SqlMigrationDialect.postgresql, MigrationValueType.real) =>
        'DOUBLE PRECISION',
      (SqlMigrationDialect.sqlite, MigrationValueType.real) => 'REAL',
      (_, MigrationValueType.boolean) => 'BOOLEAN',
      (_, MigrationValueType.dateTime) => 'TIMESTAMP',
      (_, MigrationValueType.json) => 'JSON',
      (_, MigrationValueType.binary) => 'BLOB',
    };
  }

  String _literal(Object? value) {
    if (value == null) return 'NULL';
    if (value is bool) return value ? 'TRUE' : 'FALSE';
    if (value is num) return '$value';
    if (value is DateTime) return "'${value.toIso8601String()}'";
    if (value is Map || value is Iterable) {
      return "'${jsonEncode(value).replaceAll("'", "''")}'";
    }
    return "'${'$value'.replaceAll("'", "''")}'";
  }

  String _placeholder(int index) => switch (dialect) {
    SqlMigrationDialect.postgresql => '@p$index',
    SqlMigrationDialect.mysql => ':p$index',
    SqlMigrationDialect.sqlite => '?',
  };

  Object _parameters(List<Object?> values) => switch (dialect) {
    SqlMigrationDialect.sqlite => values,
    SqlMigrationDialect.mysql || SqlMigrationDialect.postgresql => {
      for (final (index, value) in values.indexed) 'p$index': value,
    },
  };
  String _identifier(String value) {
    final String escaped = value.replaceAll('`', '``').replaceAll('"', '""');
    return dialect == SqlMigrationDialect.postgresql
        ? '"$escaped"'
        : '`$escaped`';
  }
}

final class _SqlMigrationScriptBackend implements SqlMigrationBackend {
  final List<SqlMigrationStatement> statements = [];
  int migrationVersion = 0;
  String migrationName = '';
  int operationIndex = 0;

  @override
  Future<List<Map<String, Object?>>> query(
    String sql, [
    Object? parameters = const [],
  ]) async => const [];

  @override
  Future<void> execute(String sql, [Object? parameters = const []]) async {
    statements.add(
      SqlMigrationStatement(
        migrationVersion: migrationVersion,
        migrationName: migrationName,
        operationIndex: operationIndex,
        sql: sql,
        parameters: parameters,
      ),
    );
  }

  @override
  Future<T> lock<T>(Future<T> Function() action) => action();
}
