import 'package:dorm_migrations/dorm_migrations.dart';
import 'package:sqlite3/common.dart' as sqlite;
import 'package:sqlite_async/sqlite_async.dart';

/// Migration support for a `sqlite_async` database.
final class SqliteMigrationAdapter extends SqlMigrationAdapter {
  factory SqliteMigrationAdapter(
    SqliteDatabase database, {
    String historyTable = '__dorm_migrations',
  }) {
    final _SqliteMigrationBackend backend = _SqliteMigrationBackend(database);
    return SqliteMigrationAdapter._(backend, historyTable: historyTable);
  }

  SqliteMigrationAdapter._(
    super.backend, {
    super.historyTable = '__dorm_migrations',
  }) : super(dialect: SqlMigrationDialect.sqlite);
}

final class _SqliteMigrationBackend
    implements TransactionalSqlMigrationBackend {
  _SqliteMigrationBackend(this.database);

  final SqliteDatabase database;
  SqliteWriteContext? _context;

  @override
  MigrationTransactionMode get transactionMode =>
      MigrationTransactionMode.migration;

  @override
  Future<T> transaction<T>(Future<T> Function() action) {
    if (_context != null) {
      return action();
    }
    return database.writeTransaction((context) async {
      _context = context;
      try {
        return await action();
      } finally {
        _context = null;
      }
    });
  }

  SqliteReadContext get _readContext => _context ?? database;
  SqliteWriteContext get _writeContext => _context ?? database;

  @override
  Future<List<Map<String, Object?>>> query(
    String sql, [
    Object? parameters = const [],
  ]) async {
    final Object? values = parameters;
    final sqlite.ResultSet result = await _readContext.getAll(
      sql,
      values is List ? List<Object?>.from(values) : const [],
    );
    return [
      for (final sqlite.Row row in result)
        {for (final String key in row.keys) key: row[key]},
    ];
  }

  @override
  Future<void> execute(String sql, [Object? parameters = const []]) async {
    await _writeContext.execute(
      sql,
      parameters is List ? List<Object?>.from(parameters) : const [],
    );
  }

  @override
  Future<T> lock<T>(Future<T> Function() action) {
    return database.writeTransaction((context) async {
      _context = context;
      try {
        return await action();
      } finally {
        _context = null;
      }
    });
  }
}
