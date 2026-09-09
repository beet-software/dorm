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
    final DerivedFieldSchema? derived = schema?.derivedFields
        .where((field) => field.columnName == key)
        .firstOrNull;
    if (derived == null || derived.path.length == 1) return key;
    return "JSON_UNQUOTE(JSON_EXTRACT(${derived.storageName}, '\$.${derived.path[1]}'))";
  }

  String _parameterName(int offset) => 'p${_nextParameter + offset}';

  Query _append(String expression, Map<String, Object?> values) {
    final String separator =
        RegExp(r'\bWHERE\b', caseSensitive: false).hasMatch(query)
        ? ' AND '
        : ' WHERE ';
    return Query(
      '$query$separator$expression',
      params: {...params, ...values},
      schema: schema,
      nextParameter: _nextParameter + values.length,
    );
  }

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
  Query limit(int count) {
    if (count == 0) return this;
    return Query(
      '$query LIMIT $count',
      params: {...params},
      schema: schema,
      nextParameter: _nextParameter,
    );
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
    return Query(
      sql,
      params: {...params},
      schema: schema,
      nextParameter: _nextParameter,
    );
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
      nextParameter: _nextParameter,
    );
  }

  @override
  Query whereDate(String key, DateTime date, DateFilterUnit unit) {
    final String start = _parameterName(0);
    final String end = _parameterName(1);
    return _append('${_field(key)} BETWEEN :$start AND :$end', {
      start: _toSqlDateFormat(date, unit: unit, type: _BoundType.start),
      end: _toSqlDateFormat(date, unit: unit, type: _BoundType.end),
    });
  }

  @override
  Query whereRange<R>(String key, FilterRange<R> range) {
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
      final String name = _parameterName(0);
      return _append('${_field(key)} <= :$name', {name: toArg});
    }
    if (toArg == null) {
      final String name = _parameterName(0);
      return _append('${_field(key)} >= :$name', {name: fromArg});
    }
    final String fromName = _parameterName(0);
    final String toName = _parameterName(1);
    return _append('${_field(key)} BETWEEN :$fromName AND :$toName', {
      fromName: fromArg,
      toName: toArg,
    });
  }

  @override
  Query whereText(String key, String prefix) {
    final String name = _parameterName(0);
    return _append("${_field(key)} LIKE CONCAT(:$name, '%')", {name: prefix});
  }

  @override
  Query whereValue(String key, Object? value) {
    final String name = _parameterName(0);
    return _append('${_field(key)} = :$name', {name: value});
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
    return _append('${_field(key)} $symbol :$name', {name: value});
  }

  @override
  Query whereSet(
    String key,
    Iterable<Object?> values, {
    required bool negated,
  }) {
    final List<Object?> list = values.toList(growable: false);
    if (list.isEmpty) return _append(negated ? 'TRUE' : 'FALSE', const {});
    final Map<String, Object?> valuesByName = <String, Object?>{};
    final List<String> names = <String>[];
    for (int index = 0; index < list.length; index++) {
      final String name = _parameterName(index);
      names.add(':$name');
      valuesByName[name] = list[index];
    }
    return _append(
      '${_field(key)} ${negated ? 'NOT ' : ''}IN (${names.join(', ')})',
      valuesByName,
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
}
