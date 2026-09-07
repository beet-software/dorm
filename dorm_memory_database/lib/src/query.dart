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

typedef TableRow = Map<String, Object?>;
typedef TableOperator<I extends Object> =
    Map<I, TableRow> Function(Map<I, TableRow> table);
typedef RowPredicate = bool Function(TableRow row);

/// An in-memory [BaseQuery] implementation.
class Query<I extends Object> implements BaseQuery<Query<I>> {
  static Map<I, TableRow> _defaultTableOperator<I extends Object>(
    Map<I, TableRow> rows,
  ) {
    return rows;
  }

  final TableOperator<I> operator;

  const Query() : this._(_defaultTableOperator);

  const Query._(this.operator);

  Query<I> _where(RowPredicate predicate) {
    return _operate((rows) {
      return {
        for (final MapEntry<I, TableRow> entry in rows.entries)
          if (predicate(entry.value)) entry.key: entry.value,
      };
    });
  }

  Query<I> _operate(TableOperator<I> operation) {
    return Query<I>._((data) => operation(operator(data)));
  }

  @override
  Query<I> whereValue(String key, Object? value) {
    return _where((row) => row[key] == value);
  }

  @override
  Query<I> whereText(String key, String prefix) {
    return _where((row) {
      final Object? value = row[key];
      return value is String && value.startsWith(prefix);
    });
  }

  @override
  Query<I> whereDate(String key, DateTime date, DateFilterUnit unit) {
    return _where((row) {
      final Object? value = row[key];
      if (value is! DateTime) return false;
      return DateFilterUnit.values
          .takeWhile((current) => current.index != unit.index + 1)
          .map((current) => current.access)
          .every((accessor) => accessor(value) == accessor(date));
    });
  }

  @override
  Query<I> whereRange<T>(String key, FilterRange<T> range) {
    final T? from = range.from;
    final T? to = range.to;
    if (from == null && to == null) return this;
    return _where((row) {
      final Object? value = row[key];
      if (value is! Comparable<T>) return false;
      if (from != null && value.compareTo(from) < 0) return false;
      if (to != null && value.compareTo(to) > 0) return false;
      return true;
    });
  }

  @override
  Query<I> limit(int count) {
    if (count == 0) return this;
    return _operate((table) {
      return Map.fromEntries(
        count > 0
            ? table.entries.take(count)
            : table.entries.toList().reversed.take(count.abs()),
      );
    });
  }

  @override
  Query<I> sorted(String key) {
    return _operate((table) {
      return LinkedHashMap.fromEntries(
        table.entries.toList()..sort((left, right) {
          final Object? leftValue = left.value[key];
          final Object? rightValue = right.value[key];
          return Comparable.compare(
            leftValue is Comparable<Object> ? leftValue : 0,
            rightValue is Comparable<Object> ? rightValue : 0,
          );
        }),
      );
    });
  }
}
