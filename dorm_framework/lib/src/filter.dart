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

import 'schema.dart';
import 'query.dart';

class FilterRange<T> {
  final T? from;
  final T? to;

  const FilterRange({this.from, this.to});
}

class DateFilterRange extends FilterRange<DateTime> {
  final DateFilterUnit unit;

  const DateFilterRange({
    super.from,
    super.to,
    this.unit = DateFilterUnit.milliseconds,
  });
}

sealed class FilterExpression {
  const FilterExpression();
}

final class EmptyFilterExpression extends FilterExpression {
  const EmptyFilterExpression();
}

final class ValueFilterExpression extends FilterExpression {
  final String field;
  final Object? value;

  const ValueFilterExpression(this.field, this.value);
}

final class TextFilterExpression extends FilterExpression {
  final String field;
  final String prefix;

  const TextFilterExpression(this.field, this.prefix);
}

final class DateFilterExpression extends FilterExpression {
  final String field;
  final DateTime value;
  final DateFilterUnit unit;

  const DateFilterExpression(this.field, this.value, this.unit);
}

final class RangeFilterExpression<T> extends FilterExpression {
  final String field;
  final FilterRange<T> range;

  const RangeFilterExpression(this.field, this.range);
}

final class ComparisonFilterExpression extends FilterExpression {
  final String field;
  final FilterComparisonOperator operator;
  final Object? value;

  const ComparisonFilterExpression(this.field, this.operator, this.value);
}

final class SetFilterExpression extends FilterExpression {
  final String field;
  final List<Object?> values;
  final bool negated;

  const SetFilterExpression(this.field, this.values, {required this.negated});
}

final class NullFilterExpression extends FilterExpression {
  final String field;
  final bool isNull;

  const NullFilterExpression(this.field, {required this.isNull});
}

final class ContainsFilterExpression extends FilterExpression {
  final String field;
  final Object? value;

  const ContainsFilterExpression(this.field, this.value);
}

final class ContainsAnyFilterExpression extends FilterExpression {
  final String field;
  final List<Object?> values;

  const ContainsAnyFilterExpression(this.field, this.values);
}

final class AllFilterExpression extends FilterExpression {
  final List<FilterExpression> filters;

  const AllFilterExpression(this.filters);
}

final class AnyFilterExpression extends FilterExpression {
  final List<FilterExpression> filters;

  const AnyFilterExpression(this.filters);
}

final class NotFilterExpression extends FilterExpression {
  final FilterExpression filter;

  const NotFilterExpression(this.filter);
}

/// Represents a filter for rows.
abstract class BaseFilter<Q extends BaseQuery<Q>> {
  // Evaluates to true for all the rows in the table.
  const factory BaseFilter.empty() = _EmptyFilter;

  /// Evaluates to true for rows where the persisted [field] is equal to
  /// [value].
  const factory BaseFilter.value(Object? value, {required FieldSchema field}) =
      ValueFilter;

  /// Evaluates to true for rows where the persisted [field] starts with
  /// [text].
  const factory BaseFilter.text(String text, {required FieldSchema field}) =
      _TextFilter;

  /// Evaluates to true for rows where the persisted [field] is lexicographically
  /// between [FilterRange.from] and [FilterRange.to], provided by [range].
  const factory BaseFilter.textRange(
    FilterRange<String> range, {
    required FieldSchema field,
  }) = _TextRangeFilter;

  /// Evaluates to true for rows where the persisted [field] is numerically
  /// between [FilterRange.from] and [FilterRange.to], provided by [range].
  const factory BaseFilter.numericRange(
    FilterRange<double> range, {
    required FieldSchema field,
  }) = _NumericRangeFilter;

  /// Evaluates to true for rows where the persisted [field] is temporally
  /// between [FilterRange.from] and [FilterRange.to], provided by [range].
  const factory BaseFilter.dateRange(
    DateFilterRange range, {
    required FieldSchema field,
  }) = _DateRangeFilter;

  /// Evaluates to true for rows where the value of the persisted [field] is a
  /// [DateTime] or an ISO-8601 formatted [String], and matches [date] at a
  /// certain [unit].
  const factory BaseFilter.date(
    DateTime date, {
    required FieldSchema field,
    DateFilterUnit unit,
  }) = _DateFilter;

  /// Creates a scalar inequality filter.
  static BaseFilter<Q> notEqual<Q extends ComparisonQuery<Q>>(
    Object? value, {
    required FieldSchema field,
  }) => _ComparisonFilter<Q>(
    value,
    field: field,
    operator: FilterComparisonOperator.notEqual,
  );

  /// Creates a strict lower-bound filter.
  static BaseFilter<Q> lessThan<Q extends ComparisonQuery<Q>>(
    Object? value, {
    required FieldSchema field,
  }) => _ComparisonFilter<Q>(
    value,
    field: field,
    operator: FilterComparisonOperator.lessThan,
  );

  /// Creates an inclusive lower-bound filter.
  static BaseFilter<Q> lessThanOrEqual<Q extends ComparisonQuery<Q>>(
    Object? value, {
    required FieldSchema field,
  }) => _ComparisonFilter<Q>(
    value,
    field: field,
    operator: FilterComparisonOperator.lessThanOrEqual,
  );

  /// Creates a strict upper-bound filter.
  static BaseFilter<Q> greaterThan<Q extends ComparisonQuery<Q>>(
    Object? value, {
    required FieldSchema field,
  }) => _ComparisonFilter<Q>(
    value,
    field: field,
    operator: FilterComparisonOperator.greaterThan,
  );

  /// Creates an inclusive upper-bound filter.
  static BaseFilter<Q> greaterThanOrEqual<Q extends ComparisonQuery<Q>>(
    Object? value, {
    required FieldSchema field,
  }) => _ComparisonFilter<Q>(
    value,
    field: field,
    operator: FilterComparisonOperator.greaterThanOrEqual,
  );

  /// Creates a set-membership filter.
  static BaseFilter<Q> inValues<Q extends ComparisonQuery<Q>>(
    Iterable<Object?> values, {
    required FieldSchema field,
  }) => _SetFilter<Q>(values, field: field, negated: false);

  /// Creates a negative set-membership filter.
  static BaseFilter<Q> notInValues<Q extends ComparisonQuery<Q>>(
    Iterable<Object?> values, {
    required FieldSchema field,
  }) => _SetFilter<Q>(values, field: field, negated: true);

  /// Creates a filter for a null value.
  static BaseFilter<Q> isNull<Q extends ComparisonQuery<Q>>({
    required FieldSchema field,
  }) => _NullFilter<Q>(field: field, isNull: true);

  /// Creates a filter for a non-null value.
  static BaseFilter<Q> isNotNull<Q extends ComparisonQuery<Q>>({
    required FieldSchema field,
  }) => _NullFilter<Q>(field: field, isNull: false);

  /// Creates a conjunction of filters.
  static BaseFilter<Q> allOf<Q extends LogicalQuery<Q>>(
    Iterable<BaseFilter<Q>> filters,
  ) {
    final List<BaseFilter<Q>> values = List<BaseFilter<Q>>.unmodifiable(
      filters,
    );
    if (values.isEmpty) return _EmptyFilter<Q>();
    return _AllFilter<Q>(values);
  }

  /// Creates a disjunction of filters.
  static BaseFilter<Q> anyOf<Q extends LogicalQuery<Q>>(
    Iterable<BaseFilter<Q>> filters,
  ) {
    final List<BaseFilter<Q>> values = List<BaseFilter<Q>>.unmodifiable(
      filters,
    );
    if (values.isEmpty) {
      throw ArgumentError.value(
        filters,
        'filters',
        'At least one filter is required.',
      );
    }
    return _AnyFilter<Q>(values);
  }

  /// Creates a negated filter.
  static BaseFilter<Q> not<Q extends NegationQuery<Q>>(BaseFilter<Q> filter) {
    return _NotFilter<Q>(filter);
  }

  /// Creates a filter for a collection containing [value].
  static BaseFilter<Q> contains<Q extends CollectionQuery<Q>>(
    Object? value, {
    required FieldSchema field,
  }) => _ContainsFilter<Q>(value, field: field);

  /// Creates a filter for a collection containing at least one value in
  /// [values].
  static BaseFilter<Q> containsAny<Q extends CollectionQuery<Q>>(
    Iterable<Object?> values, {
    required FieldSchema field,
  }) => _ContainsAnyFilter<Q>(values, field: field);

  FilterExpression get expression;

  Q accept(Q query);
}

class _EmptyFilter<Q extends BaseQuery<Q>> implements BaseFilter<Q> {
  const _EmptyFilter();

  @override
  FilterExpression get expression => const EmptyFilterExpression();

  @override
  Q accept(Q query) => query;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _EmptyFilter && runtimeType == other.runtimeType;

  @override
  int get hashCode => 0;
}

/// A filter that compares one field with a value.
///
/// Engines may inspect this structured value instead of parsing a generated
/// query string when planning a batch operation or a relationship.
class ValueFilter<Q extends BaseQuery<Q>> implements BaseFilter<Q> {
  final Object? value;
  final FieldSchema field;

  const ValueFilter(this.value, {required this.field});

  @override
  FilterExpression get expression =>
      ValueFilterExpression(field.columnName, value);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ValueFilter &&
          runtimeType == other.runtimeType &&
          field == other.field &&
          value == other.value;

  @override
  int get hashCode => field.hashCode ^ value.hashCode;

  @override
  Q accept(Q query) => query.whereValue(field.columnName, value);
}

class _TextFilter<Q extends BaseQuery<Q>> implements BaseFilter<Q> {
  final FieldSchema field;
  final String text;

  const _TextFilter(this.text, {required this.field});

  @override
  FilterExpression get expression =>
      TextFilterExpression(field.columnName, text);

  @override
  Q accept(Q query) => query.whereText(field.columnName, text);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _TextFilter &&
          runtimeType == other.runtimeType &&
          field == other.field &&
          text == other.text;

  @override
  int get hashCode => field.hashCode ^ text.hashCode;
}

enum DateFilterUnit {
  year(_yearAccessor),
  month(_monthAccessor),
  day(_dayAccessor),
  hour(_hourAccessor),
  minute(_minuteAccessor),
  second(_secondAccessor),
  milliseconds(_millisecondsAccessor);

  static int _yearAccessor(DateTime dt) => dt.year;

  static int _monthAccessor(DateTime dt) => dt.month;

  static int _dayAccessor(DateTime dt) => dt.day;

  static int _hourAccessor(DateTime dt) => dt.hour;

  static int _minuteAccessor(DateTime dt) => dt.minute;

  static int _secondAccessor(DateTime dt) => dt.second;

  static int _millisecondsAccessor(DateTime dt) => dt.millisecond;

  final int Function(DateTime dt) access;

  const DateFilterUnit(this.access);
}

class _DateFilter<Q extends BaseQuery<Q>> implements BaseFilter<Q> {
  final FieldSchema field;
  final DateTime value;
  final DateFilterUnit unit;

  const _DateFilter(
    this.value, {
    required this.field,
    this.unit = DateFilterUnit.milliseconds,
  });

  @override
  FilterExpression get expression =>
      DateFilterExpression(field.columnName, value, unit);

  @override
  Q accept(Q query) => query.whereDate(field.columnName, value, unit);
}

class _ComparisonFilter<Q extends ComparisonQuery<Q>> implements BaseFilter<Q> {
  final Object? value;
  final FieldSchema field;
  final FilterComparisonOperator operator;

  const _ComparisonFilter(
    this.value, {
    required this.field,
    required this.operator,
  });

  @override
  FilterExpression get expression =>
      ComparisonFilterExpression(field.columnName, operator, value);

  @override
  Q accept(Q query) => query.whereComparison(field.columnName, operator, value);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _ComparisonFilter &&
          field == other.field &&
          value == other.value &&
          operator == other.operator;

  @override
  int get hashCode => Object.hash(field, value, operator);
}

class _SetFilter<Q extends ComparisonQuery<Q>> implements BaseFilter<Q> {
  final List<Object?> values;
  final FieldSchema field;
  final bool negated;

  _SetFilter(
    Iterable<Object?> values, {
    required this.field,
    required this.negated,
  }) : values = List<Object?>.unmodifiable(values);

  @override
  FilterExpression get expression =>
      SetFilterExpression(field.columnName, values, negated: negated);

  @override
  Q accept(Q query) =>
      query.whereSet(field.columnName, values, negated: negated);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _SetFilter &&
          field == other.field &&
          negated == other.negated &&
          _iterableEquals(values, other.values);

  @override
  int get hashCode => Object.hash(field, negated, Object.hashAll(values));
}

class _NullFilter<Q extends ComparisonQuery<Q>> implements BaseFilter<Q> {
  final FieldSchema field;
  final bool isNull;

  const _NullFilter({required this.field, required this.isNull});

  @override
  FilterExpression get expression =>
      NullFilterExpression(field.columnName, isNull: isNull);

  @override
  Q accept(Q query) => query.whereNull(field.columnName, isNull: isNull);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _NullFilter && field == other.field && isNull == other.isNull;

  @override
  int get hashCode => Object.hash(field, isNull);
}

class _AllFilter<Q extends LogicalQuery<Q>> implements BaseFilter<Q> {
  final List<BaseFilter<Q>> filters;

  const _AllFilter(this.filters);

  @override
  FilterExpression get expression =>
      AllFilterExpression(filters.map((filter) => filter.expression).toList());

  @override
  Q accept(Q query) => query.whereAll(filters);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _AllFilter && _iterableEquals(filters, other.filters);

  @override
  int get hashCode => Object.hashAll(filters);
}

class _AnyFilter<Q extends LogicalQuery<Q>> implements BaseFilter<Q> {
  final List<BaseFilter<Q>> filters;

  const _AnyFilter(this.filters);

  @override
  FilterExpression get expression =>
      AnyFilterExpression(filters.map((filter) => filter.expression).toList());

  @override
  Q accept(Q query) => query.whereAny(filters);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _AnyFilter && _iterableEquals(filters, other.filters);

  @override
  int get hashCode => Object.hashAll(filters);
}

class _NotFilter<Q extends NegationQuery<Q>> implements BaseFilter<Q> {
  final BaseFilter<Q> filter;

  const _NotFilter(this.filter);

  @override
  FilterExpression get expression => NotFilterExpression(filter.expression);

  @override
  Q accept(Q query) => query.whereNot(filter);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is _NotFilter && filter == other.filter;

  @override
  int get hashCode => filter.hashCode;
}

class _ContainsFilter<Q extends CollectionQuery<Q>> implements BaseFilter<Q> {
  final Object? value;
  final FieldSchema field;

  const _ContainsFilter(this.value, {required this.field});

  @override
  FilterExpression get expression =>
      ContainsFilterExpression(field.columnName, value);

  @override
  Q accept(Q query) => query.whereContains(field.columnName, value);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _ContainsFilter && field == other.field && value == other.value;

  @override
  int get hashCode => Object.hash(field, value);
}

class _ContainsAnyFilter<Q extends CollectionQuery<Q>>
    implements BaseFilter<Q> {
  final List<Object?> values;
  final FieldSchema field;

  _ContainsAnyFilter(Iterable<Object?> values, {required this.field})
    : values = List<Object?>.unmodifiable(values);

  @override
  FilterExpression get expression =>
      ContainsAnyFilterExpression(field.columnName, values);

  @override
  Q accept(Q query) => query.whereContainsAny(field.columnName, values);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _ContainsAnyFilter &&
          field == other.field &&
          _iterableEquals(values, other.values);

  @override
  int get hashCode => Object.hash(field, Object.hashAll(values));
}

bool _iterableEquals(Iterable<Object?> left, Iterable<Object?> right) {
  final Iterator<Object?> leftIterator = left.iterator;
  final Iterator<Object?> rightIterator = right.iterator;
  while (leftIterator.moveNext()) {
    if (!rightIterator.moveNext() ||
        leftIterator.current != rightIterator.current) {
      return false;
    }
  }
  return !rightIterator.moveNext();
}

abstract class _RangeFilter<R, Q extends BaseQuery<Q>>
    implements BaseFilter<Q> {
  final FieldSchema field;
  final FilterRange<R> range;

  const _RangeFilter(this.range, {required this.field});

  @override
  FilterExpression get expression =>
      RangeFilterExpression(field.columnName, range);

  @override
  Q accept(Q query) => query.whereRange(field.columnName, range);
}

class _TextRangeFilter<Q extends BaseQuery<Q>>
    extends _RangeFilter<String?, Q> {
  const _TextRangeFilter(super.range, {required super.field});
}

class _NumericRangeFilter<Q extends BaseQuery<Q>>
    extends _RangeFilter<double?, Q> {
  const _NumericRangeFilter(super.range, {required super.field});
}

class _DateRangeFilter<Q extends BaseQuery<Q>>
    extends _RangeFilter<DateTime?, Q> {
  const _DateRangeFilter(super.range, {required super.field});
}
