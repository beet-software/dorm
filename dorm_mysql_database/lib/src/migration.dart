import 'package:dorm_migrations/dorm_migrations.dart';
import 'package:mysql_client/mysql_client.dart';

/// Migration support for MySQL connections.
final class MySqlMigrationAdapter extends SqlMigrationAdapter {
  MySqlMigrationAdapter(
    MySQLConnection connection, {
    super.historyTable = '__dorm_migrations',
  }) : super(
         _MySqlMigrationBackend(connection),
         dialect: SqlMigrationDialect.mysql,
       );
}

final class _MySqlMigrationBackend implements TransactionalSqlMigrationBackend {
  _MySqlMigrationBackend(this.connection);

  final MySQLConnection connection;
  bool _locked = false;

  @override
  MigrationTransactionMode get transactionMode =>
      MigrationTransactionMode.operation;

  @override
  Future<T> transaction<T>(Future<T> Function() action) =>
      connection.transactional((_) => action());

  @override
  Future<List<Map<String, Object?>>> query(
    String sql, [
    Object? parameters = const {},
  ]) async {
    final IResultSet result = await connection.execute(
      sql,
      _parameters(parameters),
    );
    final List<ResultSetColumn> columns = result.cols.toList();
    return [
      for (final ResultSetRow row in result.rows)
        {
          for (final ResultSetColumn column in columns)
            column.name: row.colByName(column.name),
        },
    ];
  }

  @override
  Future<void> execute(String sql, [Object? parameters = const {}]) async {
    await connection.execute(sql, _parameters(parameters));
  }

  @override
  Future<T> lock<T>(Future<T> Function() action) async {
    if (_locked) {
      throw StateError('Another MySQL migration run already holds the lock.');
    }
    final IResultSet result = await connection.execute(
      "SELECT GET_LOCK('dorm_migrations', 30) AS acquired",
    );
    if (result.rows.isEmpty ||
        '${result.rows.first.colByName('acquired')}' != '1') {
      throw StateError('Could not acquire the MySQL migration lock.');
    }
    _locked = true;
    try {
      return await action();
    } finally {
      try {
        await connection.execute("SELECT RELEASE_LOCK('dorm_migrations')");
      } finally {
        _locked = false;
      }
    }
  }

  Map<String, dynamic>? _parameters(Object? parameters) {
    if (parameters is Map) {
      return {
        for (final MapEntry<Object?, Object?> entry in parameters.entries)
          '${entry.key}': entry.value,
      };
    }
    if (parameters == null) return null;
    throw ArgumentError.value(
      parameters,
      'parameters',
      'MySQL migrations use named parameters.',
    );
  }
}
