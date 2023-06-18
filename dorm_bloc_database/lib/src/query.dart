import 'package:dorm/dorm.dart';

typedef QueryFilter = Map<String, Map<String, Object?>> Function(
  Map<String, Map<String, Object?>> data,
);

class Query implements BaseQuery<Query> {
  final QueryFilter filter;

  const Query(this.filter);

  Query _where(QueryFilter filter) {
    return Query((data) => filter(this.filter(data)));
  }

  @override
  Query whereValue(String key, Object? value) {
    return _where((data) {
      return Map.fromEntries(
        data.entries.where((entry) => entry.value[key] == value),
      );
    });
  }

  @override
  Query whereText(String key, String prefix) {
    return _where((data) {
      return Map.fromEntries(data.entries.where((entry) {
        final Object? value = entry.value[key];
        if (value is! String) return false;
        return value.startsWith(prefix);
      }));
    });
  }

  @override
  Query whereDate(String key, DateTime date, DateFilterUnit unit) {
    return _where((data) {
      return Map.fromEntries(data.entries.where((entry) {
        final Object? value = entry.value[key];
        if (value is! DateTime) return false;
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
        return condition;
      }));
    });
  }

  @override
  Query whereRange<T>(String key, FilterRange<T> range) {
    final T? from = range.from;
    final T? to = range.to;
    if (from == null && to == null) return this;
    return _where((data) {
      return Map.fromEntries(data.entries.where((entry) {
        final Object? value = entry.value[key];
        if (value is! Comparable<T>) return false;
        if (from != null && value.compareTo(from) < 0) return false;
        if (to != null && value.compareTo(to) > 0) return false;
        return true;
      }));
    });
  }

  @override
  Query limit(int count) {
    if (count == 0) return this;
    return _where((data) {
      return Map.fromEntries(count > 0
          ? data.entries.take(count)
          : data.entries.toList().reversed.take(count.abs()));
    });
  }
}
