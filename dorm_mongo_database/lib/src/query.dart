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

Map<String, Object?> _and(
  Map<String, Object?> left,
  Map<String, Object?> right,
) {
  if (left.isEmpty) return {...right};
  if (right.isEmpty) return {...left};
  return {
    r'$and': [left, right],
  };
}

class Query implements BaseQuery<Query> {
  final Map<String, Object?> filter;
  final Map<String, Object> sort;
  final int? limitCount;
  final EntitySchema? schema;

  const Query({
    this.filter = const {},
    this.sort = const {},
    this.limitCount,
    this.schema,
  });

  String _field(String key) {
    for (final DerivedFieldSchema field in schema?.derivedFields ?? const []) {
      if (field.columnName == key) {
        return field.path.length == 1
            ? field.storageName
            : field.path.join('.');
      }
    }
    return key;
  }

  Query _where(Map<String, Object?> expression) {
    return Query(
      filter: _and(filter, expression),
      sort: sort,
      limitCount: limitCount,
      schema: schema,
    );
  }

  Map<String, Object?> _fieldExpression(String key, Object? value) {
    return {_field(key): value};
  }

  @override
  Query whereValue(String key, Object? value) {
    return _where(_fieldExpression(key, value));
  }

  @override
  Query whereText(String key, String prefix) {
    return _where(_fieldExpression(key, RegExp('^${RegExp.escape(prefix)}')));
  }

  @override
  Query whereDate(String key, DateTime date, DateFilterUnit unit) {
    return whereRange(key, DateFilterRange(from: date, to: date, unit: unit));
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
    final Map<String, Object?> expression = {};
    if (from != null) expression[r'$gte'] = from;
    if (to != null) expression[r'$lte'] = to;
    return _where(_fieldExpression(key, expression));
  }

  @override
  Query limit(int count) {
    if (count == 0) return this;
    if (count < 0) {
      throw ArgumentError.value(
        count,
        'count',
        'MongoDB limits must be non-negative.',
      );
    }
    return Query(filter: filter, sort: sort, limitCount: count, schema: schema);
  }

  @override
  Query sorted(String key) {
    return Query(
      filter: filter,
      sort: {...sort, _field(key): 1},
      limitCount: limitCount,
      schema: schema,
    );
  }
}
