import 'package:dorm_framework/dorm_framework.dart';

class Query implements BaseQuery<Query> {
  @override
  Query limit(int count) {
    throw UnimplementedError();
  }

  @override
  Query sorted(String key) {
    throw UnimplementedError();
  }

  @override
  Query whereDate(String key, DateTime date, DateFilterUnit unit) {
    throw UnimplementedError();
  }

  @override
  Query whereRange<R>(String key, FilterRange<R> range) {
    throw UnimplementedError();
  }

  @override
  Query whereText(String key, String prefix) {
    throw UnimplementedError();
  }

  @override
  Query whereValue(String key, Object? value) {
    throw UnimplementedError();
  }
}
