import 'package:dorm_framework/dorm_framework.dart';
import 'package:firebase_database/firebase_database.dart' as fd;
import 'package:meta/meta.dart';

import 'reference.dart';

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

abstract class Filter implements BaseFilter<Reference> {
  static String normalizeText(String text) {
    const t0 = 'ÀÁÂÃÄÅàáâãäåÒÓÔÕÕÖØòóôõöøÈÉÊËèéêëðÇçÐÌÍÎÏìíîïÙÚÛÜùúûüÑñŠšŸÿýŽž';
    const t1 = 'AAAAAAaaaaaaOOOOOOOooooooEEEEeeeeeCcDIIIIiiiiUUUUuuuuNnSsYyyZz';

    String result = text;
    for (int i = 0; i < t0.length; i++) {
      result = result.replaceAll(t0[i], t1[i]);
    }
    result = result.toUpperCase();
    result = result.replaceAll(RegExp(r'[^A-Z]'), '');
    return result;
  }

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

  @protected
  fd.Query accept(fd.Query query);
}

extension FilterProperties on Filter {
  Filter limit(int value) => _LimitFilter(value);
}

class _EmptyFilter implements Filter {
  const _EmptyFilter();

  @override
  fd.Query accept(fd.Query query) => query;
}

class _ValueFilter implements Filter {
  final String key;
  final Object value;

  const _ValueFilter(this.value, {required this.key});

  @override
  fd.Query accept(fd.Query query) {
    return query.orderByChild(key).equalTo(value);
  }
}

class _TextFilter implements Filter {
  final String key;
  final String prefix;

  const _TextFilter(this.prefix, {required this.key});

  @override
  fd.Query accept(fd.Query query) {
    final String value = prefix;
    return query.orderByChild(key).startAt(value).endAt('$value\uf8ff');
  }
}

String? _dateAsPrefixQuery(DateTime? dt, {DateFilterUnit? unit}) {
  if (dt == null) return null;

  // yyyy-MM-ddTHH:mm:ss.mmmuuuZ
  final String value = dt.toIso8601String();
  switch (unit) {
    case null:
      return value;
    case DateFilterUnit.year:
      return value.substring(0, 4);
    case DateFilterUnit.month:
      return value.substring(0, 7);
    case DateFilterUnit.day:
      return value.substring(0, 10);
    case DateFilterUnit.hour:
      return value.substring(0, 13);
    case DateFilterUnit.minute:
      return value.substring(0, 16);
    case DateFilterUnit.second:
      return value.substring(0, 19);
    case DateFilterUnit.milliseconds:
      return value.substring(0, 23);
  }
}

class _DateFilter implements Filter {
  final String key;
  final DateTime value;
  final DateFilterUnit unit;

  const _DateFilter(
    this.value, {
    required this.key,
    this.unit = DateFilterUnit.milliseconds,
  });

  @override
  fd.Query accept(fd.Query query) {
    final String? prefix = _dateAsPrefixQuery(value, unit: unit);
    if (prefix == null) return query;
    return _TextFilter(prefix, key: key).accept(query);
  }
}

class _LimitFilter implements Filter {
  final int count;

  const _LimitFilter(this.count);

  @override
  fd.Query accept(fd.Query query) {
    if (count == 0) return query;
    if (count < 0) return query.limitToLast(count.abs());
    return query.limitToFirst(count);
  }
}

abstract class _RangeFilter<T> implements Filter {
  final String key;
  final FilterRange<T> range;

  const _RangeFilter(this.range, {required this.key});

  @override
  fd.Query accept(fd.Query query) {
    final T? from = range.from;
    final T? to = range.to;
    final DateFilterUnit? unit =
        range is DateFilterRange ? (range as DateFilterRange).unit : null;

    if (from == null && to == null) return query;
    fd.Query ref = query.orderByChild(key);
    if (from != null) {
      if (from is DateTime && unit != null) {
        ref = ref.startAt(_dateAsPrefixQuery(from, unit: unit));
      } else {
        ref = ref.startAt(from);
      }
    }
    if (to != null) {
      if (to is DateTime && unit != null) {
        ref = ref.endAt(_dateAsPrefixQuery(to, unit: unit));
      } else {
        ref = ref.endAt(to);
      }
    }
    return ref;
  }
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
