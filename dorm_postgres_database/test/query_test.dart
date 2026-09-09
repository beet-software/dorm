import 'package:dorm_framework/dorm_framework.dart';
import 'package:dorm_postgres_database/src/query.dart';
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

  test('translates PostgreSQL derived paths', () {
    final Query query = const Query(
      'SELECT * FROM users',
      schema: schema,
    ).whereText('_query/name', 'ada');

    expect(
      query.query,
      "SELECT * FROM users WHERE _query ->> 'name' LIKE (@p0 || '%')",
    );
    expect(query.params, {'p0': 'ada'});
  });

  test('adds named value parameters', () {
    final Query query = const Query(
      'SELECT * FROM users',
    ).whereValue('active', true);

    expect(query.query, 'SELECT * FROM users WHERE active = @p0');
    expect(query.params, {'p0': true});
  });

  test('combines filters without replacing existing parameters', () {
    final Query query = const Query(
      'SELECT * FROM users',
    ).whereValue('active', true).whereText('name', 'Al');

    expect(
      query.query,
      'SELECT * FROM users WHERE active = @p0 AND name LIKE (@p1 || \'%\')',
    );
    expect(query.params, {'p0': true, 'p1': 'Al'});
  });

  test('builds bounded numeric ranges', () {
    final Query query = const Query(
      'SELECT * FROM products',
    ).whereRange('price', const FilterRange<double>(from: 10, to: 20));

    expect(
      query.query,
      'SELECT * FROM products WHERE price BETWEEN @p0 AND @p1',
    );
    expect(query.params, {'p0': 10, 'p1': 20});
  });

  test('builds date bounds for a date unit', () {
    final Query query = const Query(
      'SELECT * FROM events',
    ).whereDate('created-at', DateTime(2025, 3, 4, 12, 30), DateFilterUnit.day);

    expect(
      query.query,
      'SELECT * FROM events WHERE created-at BETWEEN @p0 AND @p1',
    );
    expect(query.params['p0'], DateTime(2025, 3, 4));
    expect(query.params['p1'], DateTime(2025, 3, 4, 23, 59, 59, 999));
  });

  test('adds sort and limit clauses', () {
    final Query query = const Query(
      'SELECT * FROM products',
    ).sorted('price').limit(5);

    expect(query.query, 'SELECT * FROM products ORDER BY price ASC LIMIT 5');
  });

  test('adds descending sort and offset clauses', () {
    final Query query = const Query(
      'SELECT * FROM products',
    ).sorted('price', ascending: false).limit(5).offset(10);

    expect(
      query.query,
      'SELECT * FROM products ORDER BY price DESC LIMIT 5 OFFSET 10',
    );
  });

  test('rejects negative PostgreSQL limits', () {
    expect(
      () => const Query('SELECT * FROM products').limit(-1),
      throwsArgumentError,
    );
  });

  test('builds parameterized composite filters', () {
    const FieldSchema field = FieldSchema(
      fieldName: 'value',
      columnName: 'value',
    );
    final Query query = BaseFilter.anyOf<Query>([
      BaseFilter.greaterThan<Query>(10, field: field),
      BaseFilter.isNull<Query>(field: field),
    ]).accept(const Query('SELECT * FROM users'));

    expect(query.query, contains(' OR '));
    expect(query.query, contains('value > @p0'));
    expect(query.query, contains('value IS NULL'));
    expect(query.params, {'p0': 10});
  });
}
