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

  Q accept(Q query);
}

class _EmptyFilter<Q extends BaseQuery<Q>> implements BaseFilter<Q> {
  const _EmptyFilter();

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
  Q accept(Q query) => query.whereDate(field.columnName, value, unit);
}

abstract class _RangeFilter<R, Q extends BaseQuery<Q>>
    implements BaseFilter<Q> {
  final FieldSchema field;
  final FilterRange<R> range;

  const _RangeFilter(this.range, {required this.field});

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
