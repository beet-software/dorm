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

import 'dart:collection';

import 'package:dorm_framework/dorm_framework.dart';
import 'package:meta/meta.dart';

import 'reference.dart';

/// Row of the underlying database table.
///
/// Equivalent to a JSON object.
typedef TableRow = Map<String, Object?>;

/// Operates on the underlying database table.
typedef TableOperator = Map<String, TableRow> Function(
  Map<String, TableRow> table,
);

enum DateTimeUnit {
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

  const DateTimeUnit(this.access);
}

abstract class Filter implements BaseFilter<Reference> {
  const factory Filter.combined(List<Filter> filters) = _CombinedFilter;

  const factory Filter.empty() = _EmptyFilter;

  const factory Filter.value(
    Object? value, {
    required String key,
  }) = _ValueFilter;

  const factory Filter.text(
    String value, {
    required String key,
  }) = _TextFilter;

  const factory Filter.date(
    DateTime date, {
    DateTimeUnit unit,
    required String key,
  }) = _DateFilter;

  const factory Filter.range(
    Range<Object?> range, {
    required String key,
  }) = _RangeFilter;

  const factory Filter.sorted({required String key}) = _SortedFilter;

  const factory Filter.limit(int count) = _LimitFilter;

  TableOperator accept(TableOperator operator);
}

class _EmptyFilter implements Filter {
  const _EmptyFilter();

  @override
  TableOperator accept(TableOperator operator) {
    return (rows) => rows;
  }
}

abstract class _MapOpFilter implements Filter {
  const _MapOpFilter();

  @override
  @nonVirtual
  TableOperator accept(TableOperator operator) {
    return (rows) => operator(operate(rows));
  }

  Map<String, TableRow> operate(Map<String, TableRow> rows);
}

abstract class _WhereOpFilter extends _MapOpFilter {
  const _WhereOpFilter();

  @override
  @nonVirtual
  Map<String, TableRow> operate(Map<String, TableRow> rows) {
    return {
      for (MapEntry<String, TableRow> entry in rows.entries)
        if (filter(entry.value)) entry.key: entry.value,
    };
  }

  bool filter(TableRow row);
}

class _CombinedFilter implements Filter {
  final List<Filter> filters;

  const _CombinedFilter(this.filters);

  @override
  TableOperator accept(TableOperator operator) {
    return filters.fold(operator, (acc, filter) => filter.accept(acc));
  }
}

class _ValueFilter extends _WhereOpFilter {
  final Object? value;
  final String key;

  const _ValueFilter(this.value, {required this.key});

  @override
  bool filter(TableRow row) {
    return row[key] == value;
  }
}

class _TextFilter extends _WhereOpFilter {
  final String text;
  final String key;

  const _TextFilter(this.text, {required this.key});

  @override
  bool filter(TableRow row) {
    final Object? value = row[key];
    if (value is! String) return false;
    return value.contains(text);
  }
}

class _DateFilter extends _WhereOpFilter {
  final DateTime date;
  final DateTimeUnit unit;
  final String key;

  const _DateFilter(
    this.date, {
    this.unit = DateTimeUnit.milliseconds,
    required this.key,
  });

  @override
  bool filter(TableRow row) {
    final Object? value = row[key];
    if (value is! DateTime) return false;
    return DateTimeUnit.values
        .takeWhile((currentUnit) => currentUnit.index != unit.index + 1)
        .map((unit) => unit.access)
        .every((accessor) => accessor(value) == accessor(date));
  }
}

class Range<T> {
  final T? from;
  final T? to;

  const Range({this.from, this.to});
}

class _RangeFilter<T> extends _WhereOpFilter {
  final Range<T> range;
  final String key;

  const _RangeFilter(
    this.range, {
    required this.key,
  });

  @override
  bool filter(TableRow row) {
    final T? from = range.from;
    final T? to = range.to;
    if (from == null && to == null) return true;

    final Object? value = row[key];
    if (value is! Comparable<T>) return false;
    if (from != null && value.compareTo(from) < 0) return false;
    if (to != null && value.compareTo(to) > 0) return false;
    return true;
  }
}

class _LimitFilter extends _MapOpFilter {
  final int count;

  const _LimitFilter(this.count);

  @override
  Map<String, TableRow> operate(Map<String, TableRow> rows) {
    if (count == 0) return rows;
    return Map.fromEntries(count > 0
        ? rows.entries.take(count)
        : rows.entries.toList().reversed.take(count.abs()));
  }
}

class _SortedFilter extends _MapOpFilter {
  final String key;

  const _SortedFilter({required this.key});

  @override
  Map<String, TableRow> operate(Map<String, TableRow> rows) {
    return LinkedHashMap.fromEntries(rows.entries.toList()
      ..sort((e0, e1) {
        final Object? v0 = e0.value[key];
        final Object? v1 = e1.value[key];
        return Comparable.compare(
          v0 is Comparable<Object> ? v0 : 0,
          v1 is Comparable<Object> ? v1 : 0,
        );
      }));
  }
}
