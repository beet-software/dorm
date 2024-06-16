import 'package:dartx/dartx.dart';
import 'package:dorm_framework/dorm_framework.dart';

enum _QueryType { limit, sorted }

class Query implements BaseQuery<Query> {
  final String query;
  final Map<String, Object?> params;

  const Query(this.query, {this.params = const {}});

  @override
  Query limit(int count) {
    if (count == 0) {
      return this;
    }
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
    String format(DateTime date) {
      return (StringBuffer()
            ..write('${date.year}'.padLeft(4, '0'))
            ..write('-')
            ..write('${date.month}'.padLeft(2, '0'))
            ..write('-')
            ..write('${date.day}'.padLeft(2, '0'))
            ..write(' ')
            ..write('${date.hour}'.padLeft(2, '0'))
            ..write(':')
            ..write('${date.minute}'.padLeft(2, '0'))
            ..write(':')
            ..write('${date.second}'.padLeft(2, '0'))
            ..write('.')
            ..write('${date.millisecond}'.padLeft(3, '0')))
          .toString();
    }

    DateTime firstTimeOfDay(DateTime date) {
      return date.date;
    }

    DateTime lastTimeOfDay(DateTime date) {
      return date.date
          .add(const Duration(days: 1))
          .subtract(const Duration(microseconds: 1));
    }

    final DateTime startDate;
    final DateTime endDate;
    switch (unit) {
      case DateFilterUnit.year:
        startDate = date.firstDayOfYear;
        endDate = lastTimeOfDay(date.lastDayOfYear);
      case DateFilterUnit.month:
        startDate = date.firstDayOfMonth;
        endDate = lastTimeOfDay(date.lastDayOfMonth);
      case DateFilterUnit.day:
        startDate = firstTimeOfDay(date);
        endDate = lastTimeOfDay(date);
      case DateFilterUnit.hour:
        startDate = firstTimeOfDay(date).copyWith(
          hour: date.hour,
        );
        endDate = lastTimeOfDay(date).copyWith(
          hour: date.hour,
        );
      case DateFilterUnit.minute:
        startDate = firstTimeOfDay(date).copyWith(
          hour: date.hour,
          minute: date.minute,
        );
        endDate = lastTimeOfDay(date).copyWith(
          hour: date.hour,
          minute: date.minute,
        );
      case DateFilterUnit.second:
        startDate = firstTimeOfDay(date).copyWith(
          hour: date.hour,
          minute: date.minute,
          second: date.second,
        );
        endDate = lastTimeOfDay(date).copyWith(
          hour: date.hour,
          minute: date.minute,
          second: date.second,
        );
      case DateFilterUnit.milliseconds:
        startDate = firstTimeOfDay(date).copyWith(
          hour: date.hour,
          minute: date.minute,
          second: date.second,
          millisecond: date.millisecond,
        );
        endDate = lastTimeOfDay(date).copyWith(
          hour: date.hour,
          minute: date.minute,
          second: date.second,
          millisecond: date.millisecond,
        );
    }
    // https://stackoverflow.com/a/14104364/9997212
    return Query(
      '$query WHERE $key BETWEEN \'${format(startDate)}\' AND \'${format(endDate)}\'',
      params: {...params},
    );
  }

  @override
  Query whereRange<R>(String key, FilterRange<R> range) {
    // TODO: implement whereDate
    throw UnimplementedError();
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
