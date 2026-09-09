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

class Query
    implements
        ComparisonQuery<Query>,
        LogicalQuery<Query>,
        NegationQuery<Query>,
        CollectionQuery<Query> {
  final Map<String, Object?> filter;
  final Map<String, Object> sort;
  final int offsetCount;
  final int? limitCount;
  final EntitySchema? schema;

  const Query({
    this.filter = const {},
    this.sort = const {},
    this.offsetCount = 0,
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
      offsetCount: offsetCount,
      limitCount: limitCount,
      schema: schema,
    );
  }

  Query _or(Iterable<Query> queries) {
    final List<Map<String, Object?>> expressions = queries
        .map((query) => query.filter)
        .where((filter) => filter.isNotEmpty)
        .toList(growable: false);
    if (expressions.isEmpty) return this;
    return _where({r'$or': expressions});
  }

  Map<String, Object?> _fieldExpression(String key, Object? value) {
    return {_field(key): value};
  }

  @override
  Query whereValue(String key, Object? value) {
    return _where(_fieldExpression(key, value));
  }

  @override
  Query whereComparison(
    String key,
    FilterComparisonOperator operator,
    Object? value,
  ) {
    final String name = _field(key);
    final String symbol = switch (operator) {
      FilterComparisonOperator.notEqual => r'$ne',
      FilterComparisonOperator.lessThan => r'$lt',
      FilterComparisonOperator.lessThanOrEqual => r'$lte',
      FilterComparisonOperator.greaterThan => r'$gt',
      FilterComparisonOperator.greaterThanOrEqual => r'$gte',
    };
    return _where({
      name: {symbol: value},
    });
  }

  @override
  Query whereSet(
    String key,
    Iterable<Object?> values, {
    required bool negated,
  }) {
    return _where({
      _field(key): {negated ? r'$nin' : r'$in': values.toList()},
    });
  }

  @override
  Query whereNull(String key, {required bool isNull}) {
    return _where({
      _field(key): isNull ? null : {r'$ne': null},
    });
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
    final Query empty = Query(schema: schema);
    return _or(filters.map((filter) => filter.accept(empty) as Query));
  }

  @override
  Query whereNot(BaseFilter filter) {
    final Query empty = Query(schema: schema);
    return _where({
      r'$nor': [(filter.accept(empty) as Query).filter],
    });
  }

  @override
  Query whereContains(String key, Object? value) {
    return _where({
      _field(key): {
        r'$elemMatch': {r'$eq': value},
      },
    });
  }

  @override
  Query whereContainsAny(String key, Iterable<Object?> values) {
    return _where({
      _field(key): {r'$in': values.toList()},
    });
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
    if (count < 0) {
      throw ArgumentError.value(
        count,
        'count',
        'MongoDB limits must be non-negative.',
      );
    }
    if (count == 0) return this;
    return Query(
      filter: filter,
      sort: sort,
      offsetCount: offsetCount,
      limitCount: count,
      schema: schema,
    );
  }

  @override
  Query offset(int count) {
    if (count < 0) {
      throw ArgumentError.value(
        count,
        'count',
        'MongoDB offsets must be non-negative.',
      );
    }
    if (count == 0) return this;
    return Query(
      filter: filter,
      sort: sort,
      offsetCount: count,
      limitCount: limitCount,
      schema: schema,
    );
  }

  @override
  Query sorted(String key, {bool ascending = true}) {
    return Query(
      filter: filter,
      sort: {...sort, _field(key): ascending ? 1 : -1},
      offsetCount: offsetCount,
      limitCount: limitCount,
      schema: schema,
    );
  }
}
