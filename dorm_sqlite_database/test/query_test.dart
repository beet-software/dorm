import 'package:dorm_framework/dorm_framework.dart';
import 'package:dorm_sqlite_database/src/query.dart';
import 'package:test/test.dart';

void main() {
  const EntitySchema schema = EntitySchema(
    tableName: 'users',
    primaryKeys: [FieldSchema(fieldName: 'id', columnName: 'id')],
    derivedFields: [
      DerivedFieldSchema(
        fieldName: 'searchName',
        columnName: '_query/name',
        path: ['_query', 'name'],
        storageName: '_query',
      ),
    ],
  );

  test('builds SQLite filters with positional parameters', () {
    final Query query = const Query(
      'SELECT * FROM "users"',
      schema: schema,
    ).whereValue('active', true).whereText('name', 'Al');

    expect(
      query.query,
      'SELECT * FROM "users" WHERE "active" = ? AND "name" LIKE ? || \'%\'',
    );
    expect(query.params, [true, 'Al']);
  });

  test('translates derived paths to json_extract', () {
    final Query query = const Query(
      'SELECT * FROM "users"',
      schema: schema,
    ).whereText('_query/name', 'ada');

    expect(
      query.query,
      'SELECT * FROM "users" WHERE json_extract("_query", \'\$.name\') LIKE ? || \'%\'',
    );
    expect(query.params, ['ada']);
  });

  test('builds dates, ranges, sorting, limits, and offsets', () {
    final Query query = const Query('SELECT * FROM "events"')
        .whereDate(
          'created_at',
          DateTime(2025, 3, 4, 12, 30),
          DateFilterUnit.day,
        )
        .whereRange('value', const FilterRange<double>(from: 10, to: 20))
        .sorted('value', ascending: false)
        .limit(5)
        .offset(10);

    expect(query.query, contains('BETWEEN ? AND ?'));
    expect(query.query, contains('"value" BETWEEN ? AND ?'));
    expect(query.query, endsWith('ORDER BY "value" DESC LIMIT 5 OFFSET 10'));
    expect(query.params.length, 4);
    expect(() => const Query('SELECT 1').offset(-1), throwsArgumentError);
  });
}
