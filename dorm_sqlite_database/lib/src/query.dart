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
  final List<Object?> params;
  final EntitySchema? schema;

  const Query(this.query, {this.params = const [], this.schema});

  String _field(String key) {
    for (final DerivedFieldSchema field in schema?.derivedFields ?? const []) {
      if (field.columnName == key && field.path.length > 1) {
        return "json_extract(\"${field.storageName.replaceAll('"', '""')}\", '\$.${field.path[1]}')";
      }
    }
    return '"${key.replaceAll('"', '""')}"';
  }

  Query _append(String expression, Iterable<Object?> values) {
    final String separator =
        RegExp(r'\bWHERE\b', caseSensitive: false).hasMatch(query)
        ? ' AND '
        : ' WHERE ';
    return Query(
      '$query$separator$expression',
      params: [...params, ...values],
      schema: schema,
    );
  }

  @override
  Query whereValue(String key, Object? value) =>
      _append('${_field(key)} = ?', [value]);

  @override
  Query whereText(String key, String prefix) =>
      _append('${_field(key)} LIKE ? || \'%\'', [prefix]);

  @override
  Query whereDate(String key, DateTime date, DateFilterUnit unit) =>
      _append('${_field(key)} BETWEEN ? AND ?', [
        _startOf(date, unit).toIso8601String(),
        _endOf(date, unit).toIso8601String(),
      ]);

  @override
  Query whereRange<R>(String key, FilterRange<R> range) {
    Object? from = range.from;
    Object? to = range.to;
    if (range is DateFilterRange) {
      final DateFilterRange dateRange = range as DateFilterRange;
      from = from == null
          ? null
          : _startOf(from as DateTime, dateRange.unit).toIso8601String();
      to = to == null
          ? null
          : _endOf(to as DateTime, dateRange.unit).toIso8601String();
    }
    if (from == null && to == null) return this;
    if (from == null) return _append('${_field(key)} <= ?', [to]);
    if (to == null) return _append('${_field(key)} >= ?', [from]);
    return _append('${_field(key)} BETWEEN ? AND ?', [from, to]);
  }

  @override
  Query limit(int count) {
    if (count == 0) return this;
    if (count < 0) {
      return Query(
        '$query LIMIT ${count.abs()}',
        params: params,
        schema: schema,
      );
    }
    return Query('$query LIMIT $count', params: params, schema: schema);
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
        : '$query LIMIT -1 OFFSET $count';
    return Query(sql, params: params, schema: schema);
  }

  @override
  Query sorted(String key, {bool ascending = true}) {
    final String separator =
        RegExp(r'\bORDER\s+BY\b', caseSensitive: false).hasMatch(query)
        ? ', '
        : ' ORDER BY ';
    return Query(
      '$query$separator${_field(key)} ${ascending ? 'ASC' : 'DESC'}',
      params: params,
      schema: schema,
    );
  }
}
