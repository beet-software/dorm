import 'package:dorm_migrations/dorm_migrations.dart';
import 'package:postgres/postgres.dart';

/// Migration support for PostgreSQL session executors.
final class PostgresMigrationAdapter extends SqlMigrationAdapter {
  PostgresMigrationAdapter(
    SessionExecutor executor, {
    super.historyTable = '__dorm_migrations',
  }) : super(
         _PostgresMigrationBackend(executor),
         dialect: SqlMigrationDialect.postgresql,
       );
}

final class _PostgresMigrationBackend
    implements TransactionalSqlMigrationBackend {
  _PostgresMigrationBackend(this.executor);

  final SessionExecutor executor;
  bool _locked = false;
  Session? _session;

  @override
  MigrationTransactionMode get transactionMode =>
      MigrationTransactionMode.migration;

  @override
  Future<T> transaction<T>(Future<T> Function() action) {
    final Session? session = _session;
    if (session == null) {
      return executor.runTx((transaction) async {
        final Session? previous = _session;
        _session = transaction;
        try {
          return await action();
        } finally {
          _session = previous;
        }
      });
    }
    return _transactionOnSession(session, action);
  }

  Future<T> _transactionOnSession<T>(
    Session session,
    Future<T> Function() action,
  ) async {
    await session.execute(
      Sql('BEGIN;'),
      ignoreRows: true,
      queryMode: QueryMode.simple,
    );
    try {
      final T result = await action();
      await session.execute(
        Sql('COMMIT;'),
        ignoreRows: true,
        queryMode: QueryMode.simple,
      );
      return result;
    } catch (_) {
      await session.execute(
        Sql('ROLLBACK;'),
        ignoreRows: true,
        queryMode: QueryMode.simple,
      );
      rethrow;
    }
  }

  @override
  Future<List<Map<String, Object?>>> query(
    String sql, [
    Object? parameters = const {},
  ]) async {
    final Result result = await _run(sql, parameters);
    return [for (final ResultRow row in result) row.toColumnMap()];
  }

  @override
  Future<void> execute(String sql, [Object? parameters = const {}]) async {
    await _run(sql, parameters, ignoreRows: true);
  }

  @override
  Future<T> lock<T>(Future<T> Function() action) async {
    if (_locked) {
      throw StateError(
        'Another PostgreSQL migration run already holds the lock.',
      );
    }
    _locked = true;
    return executor.run((session) async {
      _session = session;
      try {
        await _run('SELECT pg_advisory_lock(hashtext(@p0))', {
          'p0': 'dorm_migrations',
        }, ignoreRows: true);
        try {
          return await action();
        } finally {
          await _run('SELECT pg_advisory_unlock(hashtext(@p0))', {
            'p0': 'dorm_migrations',
          }, ignoreRows: true);
        }
      } finally {
        _session = null;
        _locked = false;
      }
    });
  }

  Future<Result> _run(
    String sql,
    Object? parameters, {
    bool ignoreRows = false,
  }) {
    final Session? session = _session;
    if (session != null) {
      return session.execute(
        Sql.named(sql),
        parameters: parameters is Map ? parameters : const {},
        ignoreRows: ignoreRows,
      );
    }
    return executor.run(
      (session) => session.execute(
        Sql.named(sql),
        parameters: parameters is Map ? parameters : const {},
        ignoreRows: ignoreRows,
      ),
    );
  }
}
