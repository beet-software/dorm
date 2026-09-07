import 'dart:io';

import 'package:dorm_framework/dorm_framework.dart';
import 'package:dorm_mysql_database/dorm_mysql_database.dart';
import 'package:dorm_test/dorm_test.dart';
import 'package:mysql_client/mysql_client.dart';
import 'package:test/test.dart';

class _MySqlAdapter implements EngineTestAdapter<Query> {
  _MySqlAdapter(this.config);

  final _MySqlConfig config;

  @override
  String get name => 'MySQL';

  @override
  Future<EngineTestSession<Query>> open() async {
    final MySQLConnection connection = await MySQLConnection.createConnection(
      host: config.host,
      port: config.port,
      userName: config.username,
      password: config.password,
    );
    await connection.connect();
    await connection.execute('USE ${config.database}');
    await connection.execute('''
      CREATE TABLE IF NOT EXISTS dorm_compliance_items (
        id CHAR(36) PRIMARY KEY,
        name VARCHAR(255) NOT NULL,
        value INTEGER NOT NULL,
        active BOOLEAN NOT NULL
      )
    ''');
    await connection.execute('''
      CREATE TABLE IF NOT EXISTS dorm_compliance_parents (
        id CHAR(36) PRIMARY KEY,
        name VARCHAR(255) NOT NULL,
        profile_id CHAR(36) NOT NULL
      )
    ''');
    await connection.execute('''
      CREATE TABLE IF NOT EXISTS dorm_compliance_profiles (
        id CHAR(36) PRIMARY KEY,
        label VARCHAR(255) NOT NULL
      )
    ''');
    await connection.execute('''
      CREATE TABLE IF NOT EXISTS dorm_compliance_children (
        id CHAR(36) PRIMARY KEY,
        parent_id CHAR(36) NOT NULL,
        label VARCHAR(255) NOT NULL
      )
    ''');
    await connection.execute('''
      CREATE TABLE IF NOT EXISTS dorm_compliance_links (
        id CHAR(36) PRIMARY KEY,
        parent_id CHAR(36) NOT NULL,
        profile_id CHAR(36) NOT NULL
      )
    ''');
    await connection.execute('''
      CREATE TABLE IF NOT EXISTS dorm_compliance_composites (
        tenant VARCHAR(255) NOT NULL,
        number INTEGER NOT NULL,
        value VARCHAR(255) NOT NULL,
        PRIMARY KEY (tenant, number)
      )
    ''');
    return _MySqlSession(connection);
  }
}

class _MySqlSession implements EngineTestSession<Query> {
  _MySqlSession(this.connection) : _engine = Engine(connection);

  final MySQLConnection connection;
  final Engine _engine;

  @override
  BaseEngine<Query, OffsetPageRequest> get engine => _engine;

  @override
  EngineCapabilities get capabilities =>
      const EngineCapabilities(compositeIdentities: true);

  @override
  Future<void> reset() async {
    for (final String table in _tables) {
      await connection.execute('DELETE FROM $table');
    }
  }

  @override
  Future<void> close() => connection.close();

  static const List<String> _tables = [
    'dorm_compliance_items',
    'dorm_compliance_parents',
    'dorm_compliance_profiles',
    'dorm_compliance_children',
    'dorm_compliance_links',
    'dorm_compliance_composites',
  ];
}

class _MySqlConfig {
  const _MySqlConfig({
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

  static _MySqlConfig? fromEnvironment() {
    final String? host = Platform.environment['MYSQL_HOST'];
    final String? port = Platform.environment['MYSQL_PORT'];
    final String database = Platform.environment['MYSQL_DATABASE'] ?? 'test';
    final String? username = Platform.environment['MYSQL_USERNAME'];
    final String? password = Platform.environment['MYSQL_PASSWORD'];
    if ([host, port, username, password].any((value) => value == null)) {
      return null;
    }
    return _MySqlConfig(
      host: host!,
      port: int.parse(port!),
      database: database,
      username: username!,
      password: password!,
    );
  }
}

void main() {
  final _MySqlConfig? config = _MySqlConfig.fromEnvironment();
  if (config == null) {
    test(
      'MySQL compliance requires environment variables',
      () {},
      skip:
          'Set MYSQL_HOST, MYSQL_PORT, MYSQL_USERNAME, and MYSQL_PASSWORD. '
          'MYSQL_DATABASE defaults to test.',
    );
    return;
  }
  defineEngineComplianceTests(_MySqlAdapter(config));
}
