import 'package:dorm_framework/dorm_framework.dart';

enum _QueryType {  limit, sorted }

class Query implements BaseQuery<Query> {
  final String query;
  final Map<String, Object?> params;

  const Query(this.query, {this.params = const {}});

  @override
  Query limit(int count) {
    return Query(
      '$query LIMIT $count',
      params: {...params},
    );
  }

  @override
  Query sorted(String key, {bool ascending = true}) {
    return Query(
      '$query SORT BY $key ${ascending ? '' : 'DESC'}',
      params: {...params},
    );
  }

  @override
  Query whereDate(String key, DateTime date, DateFilterUnit unit) {
    // TODO: implement whereDate
    throw UnimplementedError();
  }

  @override
  Query whereRange<R>(String key, FilterRange<R> range) {
    if (range is DateFilterRange) {

    } else {

    }
  }

  @override
  Query whereText(String key, String prefix) {
    return Query(
      '$query WHERE $key LIKE CONCAT(:prefix, \'%\')',
      params: {...params, 'prefix': prefix},
    );
  }

  @override
  Query whereValue(String key, Object? value) {
    return Query(
      '$query WHERE $key = :value',
      params: {...params, 'value': value},
    );
  }
}
