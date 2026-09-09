import 'package:dorm_framework/dorm_framework.dart';
import 'package:dorm_mysql_database/src/query.dart';
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

  test('translates MySQL derived paths', () {
    final Query query = const Query(
      'SELECT * FROM users',
      schema: schema,
    ).whereText('_query/name', 'ada');

    expect(
      query.query,
      "SELECT * FROM users WHERE JSON_UNQUOTE(JSON_EXTRACT(_query, '\$.name')) "
      "LIKE CONCAT(:p0, '%')",
    );
    expect(query.params, {'p0': 'ada'});
  });

  test('adds ordering and offset clauses', () {
    final Query query = const Query(
      'SELECT * FROM users',
    ).sorted('created-at', ascending: false).limit(10).offset(20);

    expect(
      query.query,
      'SELECT * FROM users ORDER BY created-at DESC LIMIT 10 OFFSET 20',
    );
  });

  test('builds parameterized comparisons, sets, nulls, and disjunctions', () {
    const FieldSchema field = FieldSchema(
      fieldName: 'value',
      columnName: 'value',
    );
    final Query query = BaseFilter.anyOf<Query>([
      BaseFilter.greaterThan<Query>(10, field: field),
      BaseFilter.isNull<Query>(field: field),
    ]).accept(const Query('SELECT * FROM users'));

    expect(query.query, contains('(value > :p0) OR (value IS NULL)'));
    expect(query.params, {'p0': 10});

    final Query set = BaseFilter.notInValues<Query>(const [
      1,
      2,
    ], field: field).accept(const Query('SELECT * FROM users'));
    expect(set.query, contains('value NOT IN (:p0, :p1)'));
    expect(set.params, {'p0': 1, 'p1': 2});
  });
}
