import 'filter.dart';

abstract class BaseQuery<T> {
  T whereValue(String key, Object? value);

  T whereText(String key, String prefix);

  T whereDate(String key, DateTime date, DateFilterUnit unit);

  T whereRange<R>(String key, FilterRange<R> range);

  T limit(int count);
}


typedef MemoryQueryFilter = Iterable<Map<String, Object?>> Function(
  Iterable<Map<String, Object?>> data,
);

class MemoryQuery implements BaseQuery {
  final MemoryQueryFilter filter;

  const MemoryQuery(this.filter);

  MemoryQuery _where(MemoryQueryFilter filter) {
    return MemoryQuery((data) => filter(this.filter(data)));
  }

  @override
  MemoryQuery whereValue(String key, Object? value) {
    return _where((data) => data.where((child) => child[key] == value));
  }

  @override
  MemoryQuery whereText(String key, String prefix) {
    return _where((data) sync* {
      for (Map<String, Object?> child in data) {
        final Object? value = child[key];
        if (value is! String) continue;
        if (value.startsWith(prefix)) yield child;
      }
    });
  }

  @override
  MemoryQuery whereDate(String key, DateTime date, DateFilterUnit unit) {
    return _where((data) sync* {
      for (Map<String, Object?> child in data) {
        final Object? value = child[key];
        if (value is! DateTime) continue;
        final bool condition;
        switch (unit) {
          case DateFilterUnit.year:
            condition = value.year == date.year;
            break;
          case DateFilterUnit.month:
            condition = value.year == date.year && value.month == date.month;
            break;
          case DateFilterUnit.day:
            condition = value.year == date.year &&
                value.month == date.month &&
                value.day == date.day;
            break;
          case DateFilterUnit.hour:
            condition = value.year == date.year &&
                value.month == date.month &&
                value.day == date.day &&
                value.hour == date.hour;
            break;
          case DateFilterUnit.minute:
            condition = value.year == date.year &&
                value.month == date.month &&
                value.day == date.day &&
                value.hour == date.hour &&
                value.minute == date.minute;
            break;
          case DateFilterUnit.second:
            condition = value.year == date.year &&
                value.month == date.month &&
                value.day == date.day &&
                value.hour == date.hour &&
                value.minute == date.minute &&
                value.second == date.second;
            break;
          case DateFilterUnit.milliseconds:
            condition = value.year == date.year &&
                value.month == date.month &&
                value.day == date.day &&
                value.hour == date.hour &&
                value.minute == date.minute &&
                value.second == date.second &&
                value.millisecond == date.millisecond;
            break;
        }
        if (condition) yield child;
      }
    });
  }

  @override
  MemoryQuery whereRange<T>(String key, FilterRange<T> range) {
    final T? from = range.from;
    final T? to = range.to;
    if (from == null && to == null) return this;

    return _where((data) sync* {
      for (Map<String, Object?> child in data) {
        final Object? value = child[key];
        if (value is! Comparable<T>) continue;
        if (from != null && value.compareTo(from) < 0) continue;
        if (to != null && value.compareTo(to) > 0) continue;
        yield child;
      }
    });
  }

  @override
  MemoryQuery limit(int count) {
    if (count == 0) return this;
    return _where((data) => count > 0
        ? data.take(count)
        : data.toList().reversed.take(count.abs()));
  }
}
