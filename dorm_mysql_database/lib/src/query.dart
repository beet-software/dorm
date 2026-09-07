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
  final EntitySchema? schema;

  const Query(this.query, {this.params = const {}, this.schema});

  String _field(String key) {
    final DerivedFieldSchema? derived = schema?.derivedFields
        .where((field) => field.columnName == key)
        .firstOrNull;
    if (derived == null || derived.path.length == 1) return key;
    return "JSON_UNQUOTE(JSON_EXTRACT(${derived.storageName}, '\$.${derived.path[1]}'))";
  }

  @override
  Query limit(int count) {
    if (count == 0) return this;
    return Query('$query LIMIT $count', params: {...params}, schema: schema);
  }

  @override
  Query offset(int count) {
    if (count < 0) {
      throw ArgumentError.value(count, 'count', 'Offset must be non-negative.');
    }
    if (count == 0) return this;
    final String sql =
        RegExp(r'\bLIMIT\b', caseSensitive: false).hasMatch(query)
        ? '$query OFFSET $count'
        : '$query LIMIT 18446744073709551615 OFFSET $count';
    return Query(sql, params: {...params}, schema: schema);
  }

  @override
  Query sorted(String key, {bool ascending = true}) {
    final String separator =
        RegExp(r'\bORDER\s+BY\b', caseSensitive: false).hasMatch(query)
        ? ', '
        : ' ORDER BY ';
    return Query(
      '$query$separator${_field(key)} ${ascending ? '' : 'DESC'}',
      params: {...params},
      schema: schema,
    );
  }

  @override
  Query whereDate(String key, DateTime date, DateFilterUnit unit) {
    return Query(
      '$query WHERE ${_field(key)} '
      'BETWEEN \'${_toSqlDateFormat(date, unit: unit, type: _BoundType.start)}\' '
      'AND \'${_toSqlDateFormat(date, unit: unit, type: _BoundType.end)}\'',
      params: {...params},
      schema: schema,
    );
  }

  @override
  Query whereRange<R>(String key, FilterRange<R> range) {
    const String toArgParameterName = 'toArg';
    const String fromArgParameterName = 'fromArg';
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
    } else {
      fromArg = range.from;
      toArg = range.to;
    }
    if (fromArg == null) {
      if (toArg == null) {
        return this;
      }
      return Query(
        '$query WHERE ${_field(key)} <= :$toArgParameterName',
        params: {...params, toArgParameterName: toArg},
        schema: schema,
      );
    }
    if (toArg == null) {
      return Query(
        '$query WHERE ${_field(key)} >= :$fromArgParameterName',
        params: {...params, fromArgParameterName: fromArg},
        schema: schema,
      );
    }
    return Query(
      '$query WHERE ${_field(key)} '
      'BETWEEN :$fromArgParameterName '
      'AND :$toArgParameterName',
      params: {
        ...params,
        fromArgParameterName: fromArg,
        toArgParameterName: toArg,
      },
      schema: schema,
    );
  }

  @override
  Query whereText(String key, String prefix) {
    return Query(
      '$query WHERE ${_field(key)} LIKE CONCAT(:prefix, \'%\')',
      params: {...params, 'prefix': prefix},
      schema: schema,
    );
  }

  @override
  Query whereValue(String key, Object? value) {
    return Query(
      '$query WHERE ${_field(key)} = :value',
      params: {...params, 'value': value},
      schema: schema,
    );
  }
}
