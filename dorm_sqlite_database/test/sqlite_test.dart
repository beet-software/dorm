import 'dart:io';

import 'package:sqlite_async/sqlite_async.dart';
import 'package:test/test.dart';

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
}
