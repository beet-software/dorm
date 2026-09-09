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

  Query _filterQuery(BaseFilter filter) {
    return filter.accept(Query('', params: params, schema: schema)) as Query;
  }

  String _filterExpression(Query query) {
    final int where = query.query.indexOf(' WHERE ');
    if (where < 0) return '1 = 1';
    return query.query.substring(where + ' WHERE '.length);
  }

  Iterable<Object?> _newParameters(Query query) {
    return query.params.skip(params.length);
  }

  @override
  Query whereValue(String key, Object? value) =>
      _append('${_field(key)} = ?', [value]);

  @override
  Query whereComparison(
    String key,
    FilterComparisonOperator operator,
    Object? value,
  ) {
    final String symbol = switch (operator) {
      FilterComparisonOperator.notEqual => '<>',
      FilterComparisonOperator.lessThan => '<',
      FilterComparisonOperator.lessThanOrEqual => '<=',
      FilterComparisonOperator.greaterThan => '>',
      FilterComparisonOperator.greaterThanOrEqual => '>=',
    };
    return _append('${_field(key)} $symbol ?', [value]);
  }

  @override
  Query whereSet(
    String key,
    Iterable<Object?> values, {
    required bool negated,
  }) {
    final List<Object?> list = values.toList(growable: false);
    if (list.isEmpty) return _append(negated ? '1 = 1' : '1 = 0', const []);
    final String placeholders = List<String>.filled(
      list.length,
      '?',
    ).join(', ');
    return _append(
      '${_field(key)} ${negated ? 'NOT ' : ''}IN ($placeholders)',
      list,
    );
  }

  @override
  Query whereNull(String key, {required bool isNull}) {
    return _append('${_field(key)} IS ${isNull ? '' : 'NOT '}NULL', const []);
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
    if (queries.isEmpty) return _append('1 = 0', const []);
    final List<Object?> values = <Object?>[];
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
