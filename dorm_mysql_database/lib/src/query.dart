import 'package:dartx/dartx.dart';
import 'package:dorm_framework/dorm_framework.dart';

enum _BoundType { start, end }

String _toSqlDateFormat(
  DateTime dt, {
  required DateFilterUnit unit,
  required _BoundType type,
}) {
  int clamp(DateFilterUnit selfUnit, int min, int max) {
    if (selfUnit.index <= unit.index) {
      return selfUnit.access(dt);
    }
    return switch (type) {
      _BoundType.start => min,
      _BoundType.end => max,
    };
  }

  final DateTime date = DateTime(
    dt.year,
    clamp(DateFilterUnit.month, DateTime.january, DateTime.december),
    clamp(DateFilterUnit.day, dt.firstDayOfMonth.day, dt.lastDayOfMonth.day),
    clamp(DateFilterUnit.hour, 0, 23),
    clamp(DateFilterUnit.minute, 0, 59),
    clamp(DateFilterUnit.second, 0, 59),
    clamp(DateFilterUnit.milliseconds, 0, 999),
  );
  // https://stackoverflow.com/a/14104364/9997212
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
      '$query ORDER BY $key ${ascending ? '' : 'DESC'}',
      params: {...params},
    );
  }

  @override
  Query whereDate(String key, DateTime date, DateFilterUnit unit) {
    return Query(
      '$query WHERE $key '
      'BETWEEN \'${_toSqlDateFormat(date, unit: unit, type: _BoundType.start)}\' '
      'AND \'${_toSqlDateFormat(date, unit: unit, type: _BoundType.end)}\'',
      params: {...params},
    );
  }

  @override
  Query whereRange<R>(String key, FilterRange<R> range) {
    const String toArgParameterPrefix = 'toArg';
    const String fromArgParameterPrefix = 'fromArg';

    // Avoid clashes with previous filters
    int toArgParameterCount = 0;
    int fromArgParameterCount = 0;
    for (String alreadyUsedParameterKey in params.keys) {
      if (alreadyUsedParameterKey.startsWith(toArgParameterPrefix)) {
        toArgParameterCount++;
      }
      if (alreadyUsedParameterKey.startsWith(fromArgParameterPrefix)) {
        fromArgParameterCount++;
      }
    }
    final String toArgParameterName = toArgParameterCount == 0
        ? toArgParameterPrefix
        : '$toArgParameterPrefix${toArgParameterCount + 1}';
    final String fromArgParameterName = fromArgParameterCount == 0
        ? fromArgParameterPrefix
        : '$fromArgParameterPrefix${fromArgParameterCount + 1}';

    final Object? fromArg;
    final Object? toArg;
    if (range is DateFilterRange) {
      final DateFilterRange r = range as DateFilterRange;
      final DateTime? from = r.from;
      final DateTime? to = r.to;
      fromArg = from == null
          ? null
          : _toSqlDateFormat(from, unit: r.unit, type: _BoundType.start);
      toArg = to == null
          ? null
          : _toSqlDateFormat(to, unit: r.unit, type: _BoundType.end);
    } else if (range is FilterRange<int> ||
        range is FilterRange<double> ||
        range is FilterRange<String>) {
      fromArg = range.from;
      toArg = range.to;
    } else {
      throw UnimplementedError('invalid range type: $R');
    }
    if (fromArg == null) {
      if (toArg == null) {
        return this;
      }
      return Query(
        '$query WHERE $key <= :$toArgParameterName',
        params: {
          ...params,
          toArgParameterName: toArg,
        },
      );
    }
    if (toArg == null) {
      return Query(
        '$query WHERE $key >= :$fromArgParameterName',
        params: {
          ...params,
          fromArgParameterName: fromArg,
        },
      );
    }
    return Query(
      '$query WHERE $key '
      'BETWEEN :$fromArgParameterName '
      'AND :$toArgParameterName',
      params: {
        ...params,
        fromArgParameterName: fromArg,
        toArgParameterName: toArg,
      },
    );
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
