import 'package:dorm_framework/dorm_framework.dart';
import 'package:dorm_mongo_database/src/query.dart';
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

  test('maps a derived field path to a MongoDB dotted field name', () {
    final Query query = const Query(
      schema: schema,
    ).whereText('_query/name', 'a.b');

    expect(query.filter.keys, contains(r'_query.name'));
    final Object? value = query.filter[r'_query.name'];
    expect(value, isA<RegExp>());
    expect((value! as RegExp).pattern, r'^a\.b');
  });

  test('builds equality filters', () {
    final Query query = const Query().whereValue('active', true);

    expect(query.filter, {'active': true});
  });

  test('combines filters cumulatively with an and selector', () {
    final Query query = const Query()
        .whereValue('active', true)
        .whereText('name', 'Al');

    expect(query.filter[r'$and'], [
      {'active': true},
      {'name': RegExp(r'^Al')},
    ]);
  });

  test('builds numeric range filters', () {
    final Query query = const Query().whereRange(
      'price',
      const FilterRange<double>(from: 10, to: 20),
    );

    expect(query.filter, {
      'price': {r'$gte': 10, r'$lte': 20},
    });
  });

  test('builds date bounds for a date unit', () {
    final Query query = const Query().whereDate(
      'created-at',
      DateTime(2025, 3, 4, 12, 30),
      DateFilterUnit.day,
    );

    expect(query.filter['created-at'], {
      r'$gte': DateTime(2025, 3, 4),
      r'$lte': DateTime(2025, 3, 4, 23, 59, 59, 999),
    });
  });

  test('adds ascending sort and limit', () {
    final Query query = const Query().sorted('price').limit(5);

    expect(query.sort, {'price': 1});
    expect(query.limitCount, 5);
  });

  test('stores descending sort and offset', () {
    final Query query = const Query()
        .sorted('price', ascending: false)
        .limit(5)
        .offset(10);

    expect(query.sort, {'price': -1});
    expect(query.limitCount, 5);
    expect(query.offsetCount, 10);
  });

  test('rejects negative limits', () {
    expect(() => const Query().limit(-1), throwsArgumentError);
  });

  test('builds comparison, logical, negation, and collection selectors', () {
    const FieldSchema value = FieldSchema(
      fieldName: 'value',
      columnName: 'value',
    );
    final Query any = BaseFilter.anyOf<Query>([
      BaseFilter.greaterThan<Query>(10, field: value),
      BaseFilter.inValues<Query>(const [1, 2], field: value),
    ]).accept(const Query());
    expect(any.filter, {
      r'$or': [
        {
          'value': {r'$gt': 10},
        },
        {
          'value': {
            r'$in': [1, 2],
          },
        },
      ],
    });

    final Query negated = BaseFilter.not<Query>(
      BaseFilter.value(true, field: value),
    ).accept(const Query());
    expect(negated.filter, {
      r'$nor': [
        {'value': true},
      ],
    });

    final Query collection = BaseFilter.containsAny<Query>(const [
      'dart',
      'sql',
    ], field: value).accept(const Query());
    expect(collection.filter, {
      'value': {
        r'$in': ['dart', 'sql'],
      },
    });
  });
}
