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

import 'package:cloud_firestore/cloud_firestore.dart' as fs;
import 'package:dorm_framework/dorm_framework.dart';

import 'helpers.dart';

/// A [BaseQuery] backed by a Cloud Firestore query.
class Query
    implements
        ComparisonQuery<Query>,
        LogicalQuery<Query>,
        CollectionQuery<Query> {
  final fs.Query<Map<String, dynamic>> query;

  const Query(this.query);

  fs.Filter _and(Iterable<fs.Filter> filters) {
    final List<fs.Filter> values = filters.toList(growable: false);
    if (values.isEmpty) {
      throw ArgumentError.value(
        filters,
        'filters',
        'At least one filter is required.',
      );
    }
    fs.Filter result = values.first;
    for (final fs.Filter filter in values.skip(1)) {
      result = fs.Filter.and(result, filter);
    }
    return result;
  }

  fs.Filter _or(Iterable<fs.Filter> filters) {
    final List<fs.Filter> values = filters.toList(growable: false);
    if (values.isEmpty) {
      throw ArgumentError.value(
        filters,
        'filters',
        'At least one filter is required.',
      );
    }
    fs.Filter result = values.first;
    for (final fs.Filter filter in values.skip(1)) {
      result = fs.Filter.or(result, filter);
    }
    return result;
  }

  fs.Filter? _toFilter(FilterExpression expression) {
    return switch (expression) {
      EmptyFilterExpression() => null,
      ValueFilterExpression(:final field, :final value) => fs.Filter(
        field,
        isEqualTo: value,
      ),
      TextFilterExpression(:final field, :final prefix) => _and([
        fs.Filter(field, isGreaterThanOrEqualTo: prefix),
        fs.Filter(field, isLessThan: '$prefix\uf8ff'),
      ]),
      DateFilterExpression(:final field, :final value, :final unit) =>
        _toFilter(
          TextFilterExpression(field, firestoreDatePrefix(value, unit)),
        ),
      RangeFilterExpression(:final field, :final range) => _rangeFilter(
        field,
        range,
      ),
      ComparisonFilterExpression(:final field, :final operator, :final value) =>
        _comparisonFilter(field, operator, value),
      SetFilterExpression(:final field, :final values, :final negated) =>
        fs.Filter(
          field,
          whereIn: negated ? null : values,
          whereNotIn: negated ? values : null,
        ),
      NullFilterExpression(:final field, :final isNull) => fs.Filter(
        field,
        isNull: isNull,
      ),
      ContainsFilterExpression(:final field, :final value) => fs.Filter(
        field,
        arrayContains: value,
      ),
      ContainsAnyFilterExpression(:final field, :final values) => fs.Filter(
        field,
        arrayContainsAny: values,
      ),
      AllFilterExpression(:final filters) => _and(
        filters.map(_toFilter).whereType<fs.Filter>(),
      ),
      AnyFilterExpression(:final filters) => _or(
        filters.map(_toFilter).whereType<fs.Filter>(),
      ),
      NotFilterExpression() => throw UnsupportedError(
        'Cloud Firestore does not expose arbitrary filter negation.',
      ),
    };
  }

  fs.Filter _comparisonFilter(
    String field,
    FilterComparisonOperator operator,
    Object? value,
  ) => switch (operator) {
    FilterComparisonOperator.notEqual => fs.Filter(field, isNotEqualTo: value),
    FilterComparisonOperator.lessThan => fs.Filter(field, isLessThan: value),
    FilterComparisonOperator.lessThanOrEqual => fs.Filter(
      field,
      isLessThanOrEqualTo: value,
    ),
    FilterComparisonOperator.greaterThan => fs.Filter(
      field,
      isGreaterThan: value,
    ),
    FilterComparisonOperator.greaterThanOrEqual => fs.Filter(
      field,
      isGreaterThanOrEqualTo: value,
    ),
  };

  fs.Filter _rangeFilter<T>(String field, FilterRange<T> range) {
    Object? from = range.from;
    Object? to = range.to;
    final DateFilterUnit? unit = range is DateFilterRange
        ? (range as DateFilterRange).unit
        : null;
    if (from is DateTime && unit != null) {
      from = firestoreDatePrefix(from, unit);
    }
    if (to is DateTime && unit != null) {
      to = '${firestoreDatePrefix(to, unit)}\uf8ff';
    }
    final List<fs.Filter> filters = <fs.Filter>[];
    if (from != null) {
      filters.add(fs.Filter(field, isGreaterThanOrEqualTo: from));
    }
    if (to != null) {
      filters.add(fs.Filter(field, isLessThanOrEqualTo: to));
    }
    return _and(filters);
  }

  @override
  Query whereValue(String key, Object? value) =>
      Query(query.where(key, isEqualTo: value));

  @override
  Query whereComparison(
    String key,
    FilterComparisonOperator operator,
    Object? value,
  ) => Query(query.where(_comparisonFilter(key, operator, value)));

  @override
  Query whereSet(
    String key,
    Iterable<Object?> values, {
    required bool negated,
  }) => Query(
    query.where(
      fs.Filter(
        key,
        whereIn: negated ? null : values,
        whereNotIn: negated ? values : null,
      ),
    ),
  );

  @override
  Query whereNull(String key, {required bool isNull}) =>
      Query(query.where(fs.Filter(key, isNull: isNull)));

  @override
  Query whereAll(Iterable<BaseFilter> filters) {
    final List<fs.Filter> expressions = filters
        .map((filter) => _toFilter(filter.expression))
        .whereType<fs.Filter>()
        .toList(growable: false);
    if (expressions.isEmpty) return this;
    return Query(query.where(_and(expressions)));
  }

  @override
  Query whereAny(Iterable<BaseFilter> filters) {
    final List<BaseFilter> values = filters.toList(growable: false);
    if (values.any((filter) => filter.expression is EmptyFilterExpression)) {
      return this;
    }
    final List<fs.Filter> expressions = values
        .map((filter) => _toFilter(filter.expression))
        .whereType<fs.Filter>()
        .toList(growable: false);
    if (expressions.isEmpty) {
      throw ArgumentError.value(
        filters,
        'filters',
        'At least one filter is required.',
      );
    }
    return Query(query.where(_or(expressions)));
  }

  @override
  Query whereContains(String key, Object? value) =>
      Query(query.where(key, arrayContains: value));

  @override
  Query whereContainsAny(String key, Iterable<Object?> values) =>
      Query(query.where(key, arrayContainsAny: values));

  @override
  Query whereText(String key, String prefix) {
    return Query(
      query
          .where(key, isGreaterThanOrEqualTo: prefix)
          .where(key, isLessThan: '$prefix\uf8ff'),
    );
  }

  @override
  Query whereDate(String key, DateTime date, DateFilterUnit unit) {
    final String prefix = firestoreDatePrefix(date, unit);
    return whereText(key, prefix);
  }

  @override
  Query whereRange<T>(String key, FilterRange<T> range) {
    final Object? from = range.from;
    final Object? to = range.to;
    if (from == null && to == null) return this;

    final DateFilterUnit? unit = range is DateFilterRange
        ? (range as DateFilterRange).unit
        : null;
    final Object? lower = from is DateTime && unit != null
        ? firestoreDatePrefix(from, unit)
        : from == null
        ? null
        : firestoreComparableValue(from);
    final Object? upper = to is DateTime && unit != null
        ? '${firestoreDatePrefix(to, unit)}\uf8ff'
        : to == null
        ? null
        : firestoreComparableValue(to);

    fs.Query<Map<String, dynamic>> result = query;
    if (lower != null) {
      result = result.where(key, isGreaterThanOrEqualTo: lower);
    }
    if (upper != null) {
      result = result.where(key, isLessThanOrEqualTo: upper);
    }
    return Query(result);
  }

  @override
  Query limit(int count) {
    if (count == 0) return this;
    return Query(count > 0 ? query.limit(count) : query.limitToLast(-count));
  }

  @override
  Query offset(int count) {
    if (count < 0) {
      throw ArgumentError.value(count, 'count', 'Offset must be non-negative.');
    }
    if (count == 0) return this;
    throw UnsupportedError(
      'Cloud Firestore offset is applied by the dORM reference.',
    );
  }

  @override
  Query sorted(String key, {bool ascending = true}) =>
      Query(query.orderBy(key, descending: !ascending));
}
