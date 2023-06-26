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
abstract class Filter {
  /// Evaluates to true for all the rows in the table.
  const factory Filter.empty() = _EmptyFilter;

  /// Evaluates to true for rows where its [key] attribute is equal to [value].
  const factory Filter.value(
    Object value, {
    required String key,
  }) = _ValueFilter;

  /// Evaluates to true for rows where its [key] attribute starts with [text].
  const factory Filter.text(
    String text, {
    required String key,
  }) = _TextFilter;

  /// Evaluates to true for rows where its [key] attribute is lexicographically
  /// between [FilterRange.from] and [FilterRange.to], provided by [range].
  const factory Filter.textRange(
    FilterRange<String> range, {
    required String key,
  }) = _TextRangeFilter;

  /// Evaluates to true for rows where its [key] attribute is numerically
  /// between [FilterRange.from] and [FilterRange.to], provided by [range].
  const factory Filter.numericRange(
    FilterRange<double> range, {
    required String key,
  }) = _NumericRangeFilter;

  /// Evaluates to true for rows where its [key] attribute is temporally
  /// between [FilterRange.from] and [FilterRange.to], provided by [range].
  const factory Filter.dateRange(
    DateFilterRange range, {
    required String key,
  }) = _DateRangeFilter;

  /// Evaluates to true for rows where its [key] attribute is a [DateTime] or a
  /// ISO-8901 formatted [String], and matches [date] at a certain [unit].
  const factory Filter.date(
    DateTime date, {
    required String key,
    DateFilterUnit unit,
  }) = _DateFilter;

  const Filter._();

  T accept<T>(BaseQuery<T> query);

  Filter limit(int value) => _LimitFilter(this, count: value);
}

class _EmptyFilter extends Filter {
  const _EmptyFilter() : super._();

  @override
  T accept<T>(BaseQuery<T> query) => query.limit(0);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _EmptyFilter && runtimeType == other.runtimeType;

  @override
  int get hashCode => 0;
}

class _ValueFilter extends Filter {
  final String key;
  final Object? value;

  const _ValueFilter(this.value, {required this.key}) : super._();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _ValueFilter &&
          runtimeType == other.runtimeType &&
          key == other.key &&
          value == other.value;

  @override
  int get hashCode => key.hashCode ^ value.hashCode;

  @override
  T accept<T>(BaseQuery<T> query) => query.whereValue(key, value);
}

class _TextFilter extends Filter {
  final String key;
  final String text;

  const _TextFilter(this.text, {required this.key}) : super._();

  @override
  T accept<T>(BaseQuery<T> query) => query.whereText(key, text);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _TextFilter &&
          runtimeType == other.runtimeType &&
          key == other.key &&
          text == other.text;

  @override
  int get hashCode => key.hashCode ^ text.hashCode;
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

class _DateFilter extends Filter {
  final String key;
  final DateTime value;
  final DateFilterUnit unit;

  const _DateFilter(
    this.value, {
    required this.key,
    this.unit = DateFilterUnit.milliseconds,
  }) : super._();

  @override
  T accept<T>(BaseQuery<T> query) => query.whereDate(key, value, unit);
}

abstract class _RangeFilter<R> extends Filter {
  final String key;
  final FilterRange<R> range;

  const _RangeFilter(this.range, {required this.key}) : super._();

  @override
  T accept<T>(BaseQuery<T> query) => query.whereRange(key, range);
}

class _TextRangeFilter extends _RangeFilter<String?> {
  const _TextRangeFilter(super.range, {required super.key});
}

class _NumericRangeFilter extends _RangeFilter<double?> {
  const _NumericRangeFilter(super.range, {required super.key});
}

class _DateRangeFilter extends _RangeFilter<DateTime?> {
  const _DateRangeFilter(DateFilterRange range, {required super.key})
      : super(range);
}

class _LimitFilter extends Filter {
  final Filter filter;
  final int count;

  const _LimitFilter(this.filter, {required this.count}) : super._();

  @override
  T accept<T>(BaseQuery<T> query) => query.limit(count);
}
