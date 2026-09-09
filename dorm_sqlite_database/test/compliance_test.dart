import 'dart:io';

import 'package:dorm_framework/dorm_framework.dart';
import 'package:dorm_sqlite_database/dorm_sqlite_database.dart';
import 'package:dorm_test/dorm_test.dart';
import 'package:sqlite_async/sqlite_async.dart';

class _SqliteSession implements TransactionalEngineTestSession<Query> {
  _SqliteSession(this.directory, this.database) : _engine = Engine(database);

  final Directory directory;
  final SqliteDatabase database;
  final Engine _engine;

  @override
  BaseEngine<Query, OffsetPageRequest> get engine => _engine;

  @override
  TransactionalEngine<Query, OffsetPageRequest> get transactionalEngine =>
      _engine;

  @override
  EngineCapabilities get capabilities => const EngineCapabilities(
    compositeIdentities: true,
    reactiveStreams: true,
    atomicBatchWrites: true,
    atomicPatch: true,
    transactions: true,
    comparisonFilters: true,
    logicalFilters: true,
    negationFilters: true,
  );

  @override
  Future<void> reset() async {
    for (final String table in [
      'dorm_compliance_items',
      'dorm_compliance_parents',
      'dorm_compliance_profiles',
      'dorm_compliance_children',
      'dorm_compliance_links',
      'dorm_compliance_composites',
    ]) {
      await database.execute('DELETE FROM "$table"');
    }
  }

  @override
  Future<void> close() async {
    await database.close();
    await directory.delete(recursive: true);
  }
}

class _SqliteAdapter implements TransactionalEngineTestAdapter<Query> {
  @override
  String get name => 'SQLite';

  @override
  Future<TransactionalEngineTestSession<Query>> open() async {
    final Directory directory = await Directory.systemTemp.createTemp(
      'dorm-sqlite-compliance-',
    );
    final SqliteDatabase database = SqliteDatabase(
      path: '${directory.path}${Platform.pathSeparator}compliance.db',
    );
    for (final String sql in [
      'CREATE TABLE dorm_compliance_items (id TEXT PRIMARY KEY, name TEXT, value INTEGER, active BOOLEAN)',
      'CREATE TABLE dorm_compliance_parents (id TEXT PRIMARY KEY, name TEXT, profile_id TEXT)',
      'CREATE TABLE dorm_compliance_profiles (id TEXT PRIMARY KEY, label TEXT)',
      'CREATE TABLE dorm_compliance_children (id TEXT PRIMARY KEY, parent_id TEXT, label TEXT)',
      'CREATE TABLE dorm_compliance_links (id TEXT PRIMARY KEY, parent_id TEXT, profile_id TEXT)',
      'CREATE TABLE dorm_compliance_composites (tenant TEXT, number INTEGER, value TEXT, PRIMARY KEY (tenant, number))',
    ]) {
      await database.execute(sql);
    }
    return _SqliteSession(directory, database);
  }
}

void main() {
  defineEngineComplianceTests(_SqliteAdapter());
  defineEngineComparisonFilterTests(_SqliteAdapter());
  defineEngineLogicalFilterTests(_SqliteAdapter());
  defineEngineNegationFilterTests(_SqliteAdapter());
  defineEngineTransactionComplianceTests(_SqliteAdapter());
}
