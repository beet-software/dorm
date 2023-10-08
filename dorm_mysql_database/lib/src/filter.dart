import 'package:dorm_framework/dorm_framework.dart';

class Query implements BaseQuery<Query> {
  @override
  Query limit(int count) {
    // TODO: implement limit
    throw UnimplementedError();
  }

  @override
  Query sorted(String key) {
    // TODO: implement sorted
    throw UnimplementedError();
  }

  @override
  Query whereDate(String key, DateTime date, DateFilterUnit unit) {
    // TODO: implement whereDate
    throw UnimplementedError();
  }

  @override
  Query whereRange<R>(String key, FilterRange<R> range) {
    // TODO: implement whereRange
    throw UnimplementedError();
  }

  @override
  Query whereText(String key, String prefix) {
    // TODO: implement whereText
    throw UnimplementedError();
  }

  @override
  Query whereValue(String key, Object? value) {
    // TODO: implement whereValue
    throw UnimplementedError();
  }

}