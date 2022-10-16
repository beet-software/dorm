import 'package:dorm/dorm.dart';

import 'query.dart';

class FilterRange<T> {
  final T? from;
  final T? to;

  const FilterRange({this.from, this.to});
}

class DateFilterRange implements FilterRange<String> {
  static String? _convert(DateTime? dt, {DateFilterUnit? unit}) {
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

  final DateTime? _from;
  final DateTime? _to;
  final DateFilterUnit? unit;

  const DateFilterRange({
    DateTime? from,
    DateTime? to,
    this.unit,
  })  : _from = from,
        _to = to;

  @override
  String? get from => _convert(_from, unit: unit);

  @override
  String? get to => _convert(_to, unit: unit);
}

abstract class Filter {
  static String normalizeText(String text) {
    const t0 = 'ÀÁÂÃÄÅàáâãäåÒÓÔÕÕÖØòóôõöøÈÉÊËèéêëðÇçÐÌÍÎÏìíîïÙÚÛÜùúûüÑñŠšŸÿýŽž';
    const t1 = 'AAAAAAaaaaaaOOOOOOOooooooEEEEeeeeeCcDIIIIiiiiUUUUuuuuNnSsYyyZz';

    String result = text;
    for (int i = 0; i < t0.length; i++) {
      result = result.replaceAll(t0[i], t1[i]);
    }
    result = result.toUpperCase();
    result = result.replaceAll(RegExp('[^A-Z]'), '');
    return result;
  }

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
    DateFilterUnit? unit,
  }) = _DateFilter;

  const Filter._();

  Query apply(Query reference);

  Filter limit(int value) => _LimitFilter(this, count: value);
}

class _EmptyFilter extends Filter {
  const _EmptyFilter() : super._();

  @override
  Query apply(Query reference) => reference;
}

class _ValueFilter extends Filter {
  final String key;
  final Object? value;

  const _ValueFilter(this.value, {required this.key}) : super._();

  @override
  Query apply(Query reference) {
    return reference.orderByChild(key).equalTo(value);
  }
}

class _TextFilter extends Filter {
  final String key;
  final String text;
  final bool normalized;

  const _TextFilter(
    this.text, {
    required this.key,
    this.normalized = false,
  }) : super._();

  @override
  Query apply(Query reference) {
    final String text = this.text;
    final String value = normalized ? Filter.normalizeText(text) : text;
    return reference.orderByChild(key).startAt(value).endAt('$value\uf8ff');
  }
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
  final DateFilterUnit? unit;

  const _DateFilter(this.value, {required this.key, this.unit}) : super._();

  @override
  Query apply(Query reference) {
    final String? value = DateFilterRange._convert(this.value, unit: unit);
    if (value == null) return reference;
    return Filter.text(value, key: key).apply(reference);
  }
}

abstract class _RangeFilter<T> extends Filter {
  final String key;
  final FilterRange<T> range;

  const _RangeFilter(this.range, {required this.key}) : super._();

  @override
  Query apply(Query reference) {
    final T? from = range.from;
    final T? to = range.to;

    Query ref = reference;
    if (from == null && to == null) return ref;

    ref = ref.orderByChild(key);
    if (from != null) ref = ref.startAt(from);
    if (to != null) ref = ref.endAt(to);
    return ref;
  }
}

class _TextRangeFilter extends _RangeFilter<String?> {
  const _TextRangeFilter(super.range, {required super.key});
}

class _NumericRangeFilter extends _RangeFilter<double?> {
  const _NumericRangeFilter(super.range, {required super.key});
}

class _DateRangeFilter extends _RangeFilter<String?> {
  const _DateRangeFilter(DateFilterRange range, {required super.key})
      : super(range);
}

class _LimitFilter extends Filter {
  final Filter filter;
  final int count;

  const _LimitFilter(this.filter, {required this.count}) : super._();

  @override
  Query apply(Query reference) {
    final Query result = filter.apply(reference);
    if (count < 0) return result.limitToLast(count.abs());
    if (count > 0) return result.limitToFirst(count);
    return result;
  }
}
