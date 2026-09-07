import 'package:dorm_framework/dorm_framework.dart';

DateTime _startOf(DateTime value, DateFilterUnit unit) {
  return switch (unit) {
    DateFilterUnit.year => DateTime(value.year),
    DateFilterUnit.month => DateTime(value.year, value.month),
    DateFilterUnit.day => DateTime(value.year, value.month, value.day),
    DateFilterUnit.hour => DateTime(
      value.year,
      value.month,
      value.day,
      value.hour,
    ),
    DateFilterUnit.minute => DateTime(
      value.year,
      value.month,
      value.day,
      value.hour,
      value.minute,
    ),
    DateFilterUnit.second => DateTime(
      value.year,
      value.month,
      value.day,
      value.hour,
      value.minute,
      value.second,
    ),
    DateFilterUnit.milliseconds => value,
  };
}

DateTime _endOf(DateTime value, DateFilterUnit unit) {
  return switch (unit) {
    DateFilterUnit.year => DateTime(
      value.year + 1,
    ).subtract(const Duration(milliseconds: 1)),
    DateFilterUnit.month => DateTime(
      value.year,
      value.month + 1,
    ).subtract(const Duration(milliseconds: 1)),
    DateFilterUnit.day => DateTime(
      value.year,
      value.month,
      value.day + 1,
    ).subtract(const Duration(milliseconds: 1)),
    DateFilterUnit.hour => DateTime(
      value.year,
      value.month,
      value.day,
      value.hour + 1,
    ).subtract(const Duration(milliseconds: 1)),
    DateFilterUnit.minute => DateTime(
      value.year,
      value.month,
      value.day,
      value.hour,
      value.minute + 1,
    ).subtract(const Duration(milliseconds: 1)),
    DateFilterUnit.second => DateTime(
      value.year,
      value.month,
      value.day,
      value.hour,
      value.minute,
      value.second + 1,
    ).subtract(const Duration(milliseconds: 1)),
    DateFilterUnit.milliseconds => value,
  };
}

class Query implements BaseQuery<Query> {
  final String query;
  final Map<String, Object?> params;
  final EntitySchema? schema;
  final int _nextParameter;

  const Query(
    this.query, {
    this.params = const {},
    this.schema,
    int nextParameter = 0,
  }) : _nextParameter = nextParameter;

  String _field(String key) {
    DerivedFieldSchema? derived;
    for (final DerivedFieldSchema field in schema?.derivedFields ?? const []) {
      if (field.columnName == key) {
        derived = field;
        break;
      }
    }
    if (derived == null || derived.path.length == 1) return key;
    return '${derived.storageName} ->> \'${derived.path[1]}\'';
  }

  Query _append(String expression, Map<String, Object?> values) {
    final String separator =
        RegExp(r'\bWHERE\b', caseSensitive: false).hasMatch(query)
        ? ' AND '
        : ' WHERE ';
    return Query(
      '$query$separator$expression',
      params: {...params, ...values},
      nextParameter: _nextParameter + values.length,
      schema: schema,
    );
  }

  String _parameterName(int offset) => 'p${_nextParameter + offset}';

  @override
  Query whereValue(String key, Object? value) {
    final String name = _parameterName(0);
    return _append('${_field(key)} = @$name', {name: value});
  }

  @override
  Query whereText(String key, String prefix) {
    final String name = _parameterName(0);
    return _append("${_field(key)} LIKE (@$name || '%')", {name: prefix});
  }

  @override
  Query whereDate(String key, DateTime date, DateFilterUnit unit) {
    final String start = _parameterName(0);
    final String end = _parameterName(1);
    return _append('${_field(key)} BETWEEN @$start AND @$end', {
      start: _startOf(date, unit),
      end: _endOf(date, unit),
    });
  }

  @override
  Query whereRange<R>(String key, FilterRange<R> range) {
    Object? from = range.from;
    Object? to = range.to;
    if (range is DateFilterRange) {
      final DateFilterRange dateRange = range as DateFilterRange;
      from = from == null ? null : _startOf(from as DateTime, dateRange.unit);
      to = to == null ? null : _endOf(to as DateTime, dateRange.unit);
    }
    if (from == null && to == null) return this;
    if (from == null) {
      final String name = _parameterName(0);
      return _append('${_field(key)} <= @$name', {name: to});
    }
    if (to == null) {
      final String name = _parameterName(0);
      return _append('${_field(key)} >= @$name', {name: from});
    }
    final String fromName = _parameterName(0);
    final String toName = _parameterName(1);
    return _append('${_field(key)} BETWEEN @$fromName AND @$toName', {
      fromName: from,
      toName: to,
    });
  }

  @override
  Query limit(int count) {
    if (count < 0) {
      throw ArgumentError.value(
        count,
        'count',
        'PostgreSQL limits must be non-negative.',
      );
    }
    if (count == 0) return this;
    return Query('$query LIMIT $count', params: {...params}, schema: schema);
  }

  @override
  Query offset(int count) {
    if (count < 0) {
      throw ArgumentError.value(
        count,
        'count',
        'PostgreSQL offsets must be non-negative.',
      );
    }
    if (count == 0) return this;
    return Query('$query OFFSET $count', params: {...params}, schema: schema);
  }

  @override
  Query sorted(String key, {bool ascending = true}) {
    final String separator =
        RegExp(r'\bORDER\s+BY\b', caseSensitive: false).hasMatch(query)
        ? ', '
        : ' ORDER BY ';
    return Query(
      '$query$separator${_field(key)} ${ascending ? 'ASC' : 'DESC'}',
      params: {...params},
      nextParameter: _nextParameter,
      schema: schema,
    );
  }
}
