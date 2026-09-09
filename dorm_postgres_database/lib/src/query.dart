// dORM
// Copyright (C) 2023  Beet Software
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

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

class Query
    implements
        ComparisonQuery<Query>,
        LogicalQuery<Query>,
        NegationQuery<Query> {
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

  Query _filterQuery(BaseFilter filter) {
    return filter.accept(
          Query(
            '',
            params: params,
            schema: schema,
            nextParameter: _nextParameter,
          ),
        )
        as Query;
  }

  String _filterExpression(Query query) {
    final int where = query.query.indexOf(' WHERE ');
    if (where < 0) return 'TRUE';
    return query.query.substring(where + ' WHERE '.length);
  }

  Map<String, Object?> _newParameters(Query query) {
    return Map<String, Object?>.fromEntries(
      query.params.entries.where((entry) => !params.containsKey(entry.key)),
    );
  }

  @override
  Query whereValue(String key, Object? value) {
    final String name = _parameterName(0);
    return _append('${_field(key)} = @$name', {name: value});
  }

  @override
  Query whereComparison(
    String key,
    FilterComparisonOperator operator,
    Object? value,
  ) {
    final String name = _parameterName(0);
    final String symbol = switch (operator) {
      FilterComparisonOperator.notEqual => '<>',
      FilterComparisonOperator.lessThan => '<',
      FilterComparisonOperator.lessThanOrEqual => '<=',
      FilterComparisonOperator.greaterThan => '>',
      FilterComparisonOperator.greaterThanOrEqual => '>=',
    };
    return _append('${_field(key)} $symbol @$name', {name: value});
  }

  @override
  Query whereSet(
    String key,
    Iterable<Object?> values, {
    required bool negated,
  }) {
    final List<Object?> list = values.toList(growable: false);
    if (list.isEmpty) return _append(negated ? 'TRUE' : 'FALSE', const {});
    final Map<String, Object?> params = <String, Object?>{};
    final List<String> names = <String>[];
    for (int index = 0; index < list.length; index++) {
      final String name = _parameterName(index);
      names.add('@$name');
      params[name] = list[index];
    }
    return _append(
      '${_field(key)} ${negated ? 'NOT ' : ''}IN (${names.join(', ')})',
      params,
    );
  }

  @override
  Query whereNull(String key, {required bool isNull}) {
    return _append('${_field(key)} IS ${isNull ? '' : 'NOT '}NULL', const {});
  }

  @override
  Query whereAll(Iterable<BaseFilter> filters) {
    Query result = this;
    for (final BaseFilter filter in filters) {
      result = filter.accept(result) as Query;
    }
    return result;
  }

  @override
  Query whereAny(Iterable<BaseFilter> filters) {
    final List<Query> queries = filters
        .map(_filterQuery)
        .toList(growable: false);
    if (queries.isEmpty) return _append('FALSE', const {});
    final Map<String, Object?> values = <String, Object?>{};
    final List<String> expressions = <String>[];
    for (final Query child in queries) {
      expressions.add('(${_filterExpression(child)})');
      values.addAll(_newParameters(child));
    }
    return _append(expressions.join(' OR '), values);
  }

  @override
  Query whereNot(BaseFilter filter) {
    final Query child = _filterQuery(filter);
    return _append('NOT (${_filterExpression(child)})', _newParameters(child));
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
