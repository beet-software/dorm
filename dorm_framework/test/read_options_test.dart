import 'package:dorm_framework/dorm_framework.dart';
import 'package:test/test.dart';

class _Query extends BaseQuery<_Query> {
  final List<String> operations;

  _Query([this.operations = const []]);

  _Query _add(String value) => _Query([...operations, value]);

  @override
  _Query whereValue(String key, Object? value) => _add('value:$key');

  @override
  _Query whereText(String key, String prefix) => _add('text:$key');

  @override
  _Query whereDate(String key, DateTime date, DateFilterUnit unit) =>
      _add('date:$key');

  @override
  _Query whereRange<R>(String key, FilterRange<R> range) => _add('range:$key');

  @override
  _Query limit(int count) => _add('limit:$count');

  @override
  _Query offset(int count) => _add('offset:$count');

  @override
  _Query sorted(String key, {bool ascending = true}) =>
      _add('sort:$key:${ascending ? 'asc' : 'desc'}');
}

void main() {
  test('query options apply ordering, limit, and offset', () {
    final _Query query = const QueryOptions(
      orderBy: [
        OrderBy('createdAt'),
        OrderBy('name', direction: SortDirection.descending),
      ],
      limit: 11,
      offset: 20,
    ).apply(_Query());

    expect(query.operations, [
      'sort:createdAt:asc',
      'sort:name:desc',
      'limit:11',
      'offset:20',
    ]);
  });

  test('page requests validate their window', () {
    expect(() => OffsetPageRequest(size: 0), throwsA(isA<AssertionError>()));
    expect(
      () => OffsetPageRequest(size: 1, offset: -1),
      throwsA(isA<AssertionError>()),
    );
  });
}
