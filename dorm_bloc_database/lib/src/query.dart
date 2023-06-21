import 'package:dorm/dorm.dart';

typedef TableRow = Map<String, Object?>;
typedef TableOperator = Map<String, TableRow> Function(
  Map<String, TableRow> table,
);
typedef RowPredicate = bool Function(TableRow row);

class Query implements BaseQuery<Query> {
  static Map<String, TableRow> _defaultTableOperator(
      Map<String, TableRow> rows) {
    return rows;
  }

  final TableOperator operator;

  const Query() : this._(_defaultTableOperator);

  const Query._(this.operator);

  Query _where(RowPredicate predicate) {
    return _operate((rows) {
      return {
        for (MapEntry<String, TableRow> entry in rows.entries)
          if (predicate(entry.value)) entry.key: entry.value,
      };
    });
  }

  Query _operate(TableOperator operator) {
    return Query._((data) => operator(this.operator(data)));
  }

  @override
  Query whereValue(String key, Object? value) {
    return _where((row) => row[key] == value);
  }

  @override
  Query whereText(String key, String prefix) {
    return _where((row) {
      final Object? value = row[key];
      if (value is! String) return false;
      return value.startsWith(prefix);
    });
  }

  @override
  Query whereDate(String key, DateTime date, DateFilterUnit unit) {
    return _where((row) {
      final Object? value = row[key];
      if (value is! DateTime) return false;
      return DateFilterUnit.values
          .takeWhile((currentUnit) => currentUnit != unit)
          .map((unit) => unit.access)
          .every((accessor) => accessor(value) == accessor(date));
    });
  }

  @override
  Query whereRange<T>(String key, FilterRange<T> range) {
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
  Query limit(int count) {
    if (count == 0) return this;
    return _operate((table) {
      return Map.fromEntries(count > 0
          ? table.entries.take(count)
          : table.entries.toList().reversed.take(count.abs()));
    });
  }
}
