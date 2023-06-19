import 'package:dorm/dorm.dart';

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

abstract class Filter {
  const factory Filter.empty() = _EmptyFilter;

  const factory Filter.value(
    Object value, {
    required String key,
  }) = _ValueFilter;

  const factory Filter.text(
    String text, {
    required String key,
  }) = _TextFilter;

  const factory Filter.textRange(
    FilterRange<String> range, {
    required String key,
  }) = _TextRangeFilter;

  const factory Filter.numericRange(
    FilterRange<double> range, {
    required String key,
  }) = _NumericRangeFilter;

  const factory Filter.dateRange(
    DateFilterRange range, {
    required String key,
  }) = _DateRangeFilter;

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
}

class _ValueFilter extends Filter {
  final String key;
  final Object? value;

  const _ValueFilter(this.value, {required this.key}) : super._();

  @override
  T accept<T>(BaseQuery<T> query) => query.whereValue(key, value);
}

class _TextFilter extends Filter {
  final String key;
  final String text;

  const _TextFilter(this.text, {required this.key}) : super._();

  @override
  T accept<T>(BaseQuery<T> query) => query.whereText(key, text);
}

enum DateFilterUnit {
  year,
  month,
  day,
  hour,
  minute,
  second,
  milliseconds,
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
