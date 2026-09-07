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
}
