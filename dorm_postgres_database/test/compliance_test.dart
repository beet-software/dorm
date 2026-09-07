import 'dart:io';

import 'package:dorm_framework/dorm_framework.dart';
import 'package:dorm_postgres_database/dorm_postgres_database.dart';
import 'package:dorm_test/dorm_test.dart';
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

class _PostgresAdapter implements EngineTestAdapter<Query> {
  _PostgresAdapter(this.config);

  final _PostgresConfig config;

  @override
  String get name => 'PostgreSQL';

  @override
  Future<EngineTestSession<Query>> open() async {
    final Connection connection = await Connection.open(
      Endpoint(
        host: config.host,
        port: config.port,
        database: config.database,
        username: config.username,
        password: config.password,
      ),
    );
    for (final String sql in [
      '''
      CREATE TABLE IF NOT EXISTS dorm_compliance_items (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        value INTEGER NOT NULL,
        active BOOLEAN NOT NULL
      )''',
      '''
      CREATE TABLE IF NOT EXISTS dorm_compliance_parents (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        profile_id TEXT NOT NULL
      )''',
      '''
      CREATE TABLE IF NOT EXISTS dorm_compliance_profiles (
        id TEXT PRIMARY KEY,
        label TEXT NOT NULL
      )''',
      '''
      CREATE TABLE IF NOT EXISTS dorm_compliance_children (
        id TEXT PRIMARY KEY,
        parent_id TEXT NOT NULL,
        label TEXT NOT NULL
      )''',
      '''
      CREATE TABLE IF NOT EXISTS dorm_compliance_links (
        id TEXT PRIMARY KEY,
        parent_id TEXT NOT NULL,
        profile_id TEXT NOT NULL
      )''',
      '''
      CREATE TABLE IF NOT EXISTS dorm_compliance_composites (
        tenant TEXT NOT NULL,
        number INTEGER NOT NULL,
        value TEXT NOT NULL,
        PRIMARY KEY (tenant, number)
      )''',
    ]) {
      await connection.execute(sql);
    }
    return _PostgresSession(connection);
  }
}

class _PostgresSession implements EngineTestSession<Query> {
  _PostgresSession(this.connection) : _engine = Engine(connection);

  final Connection connection;
  final Engine _engine;

  @override
  BaseEngine<Query, OffsetPageRequest> get engine => _engine;

  @override
  EngineCapabilities get capabilities =>
      const EngineCapabilities(compositeIdentities: true);

  @override
  Future<void> reset() async {
    await connection.execute(
      'TRUNCATE TABLE dorm_compliance_items, dorm_compliance_parents, '
      'dorm_compliance_profiles, dorm_compliance_children, '
      'dorm_compliance_links, dorm_compliance_composites',
    );
  }

  @override
  Future<void> close() => connection.close();
}

class _PostgresConfig {
  const _PostgresConfig({
    required this.host,
    required this.port,
    required this.database,
    required this.username,
    required this.password,
  });

  final String host;
  final int port;
  final String database;
  final String username;
  final String password;

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

void main() {
  final _PostgresConfig? config = _PostgresConfig.fromEnvironment();
  if (config == null) {
    test(
      'PostgreSQL compliance requires environment variables',
      () {},
      skip:
          'Set POSTGRES_HOST, POSTGRES_PORT, POSTGRES_DATABASE, '
          'POSTGRES_USERNAME, and POSTGRES_PASSWORD.',
    );
    return;
  }
  defineEngineComplianceTests(_PostgresAdapter(config));
}
