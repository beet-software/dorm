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
      "LIKE CONCAT(:prefix, '%')",
    );
    expect(query.params, {'prefix': 'ada'});
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
}
