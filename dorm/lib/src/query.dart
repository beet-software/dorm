import 'filter.dart';

abstract class BaseQuery<T> {
  T whereValue(String key, Object? value);

  T whereText(String key, String prefix);

  T whereDate(String key, DateTime date, DateFilterUnit unit);

  T whereRange<R>(String key, FilterRange<R> range);

  T limit(int count);
}
