import 'package:dorm_framework/dorm_framework.dart';
import 'package:dorm_http_database/dorm_http_database.dart';
import 'package:test/test.dart';

void main() {
  const EntitySchema schema = EntitySchema(
    tableName: 'users',
    primaryKeys: [FieldSchema(fieldName: 'id', columnName: 'id')],
  );

  test('encodes REST filters and modifiers', () {
    final Query query = const Filter.value(true, key: 'active')
        .accept(const Query(schema: schema))
        .whereText('name', 'Al')
        .whereRange('score', const FilterRange<double>(from: 1, to: 3))
        .sorted('name', ascending: false)
        .limit(10);

    final Map<String, String> parameters = const DefaultHttpQueryCodec().encode(
      query,
      schema,
    );

    expect(parameters, {
      'active': 'true',
      'name__startsWith': 'Al',
      'score__gte': '1.0',
      'score__lte': '3.0',
      'sort': '-name',
      'limit': '10',
    });
  });

  test('encodes an offset condition', () {
    final Query query = const Query(schema: schema).offset(20);

    final Map<String, String> parameters = const DefaultHttpQueryCodec().encode(
      query,
      schema,
    );

    expect(parameters, {'offset': '20'});
  });

  test('encodes date filters as ISO-8601 bounds', () {
    final Query query = const Query(
      schema: schema,
    ).whereDate('created-at', DateTime(2025, 3, 4, 12, 30), DateFilterUnit.day);

    final Map<String, String> parameters = const DefaultHttpQueryCodec().encode(
      query,
      schema,
    );

    expect(parameters['created-at__gte'], '2025-03-04T00:00:00.000');
    expect(parameters['created-at__lte'], '2025-03-04T23:59:59.999');
  });
}
