import 'query.dart';

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
  static String _normalizeText(String text) {
    const t0 = 'ÀÁÂÃÄÅàáâãäåÒÓÔÕÕÖØòóôõöøÈÉÊËèéêëðÇçÐÌÍÎÏìíîïÙÚÛÜùúûüÑñŠšŸÿýŽž';
    const t1 = 'AAAAAAaaaaaaOOOOOOOooooooEEEEeeeeeCcDIIIIiiiiUUUUuuuuNnSsYyyZz';

    String result = text;
    result = result.replaceAll(" ", "");
    for (int i = 0; i < t0.length; i++) {
      result = result.replaceAll(t0[i], t1[i]);
    }
    result = result.toUpperCase();
    return result;
  }

  final String key;
  final String text;

  const _TextFilter(this.text, {required this.key}) : super._();

  @override
  Query apply(Query reference) {
    final String text = _normalizeText(this.text);
    return reference.orderByChild(key).startAt(text).endAt('$text\uf8ff');
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

  const _DateFilter(
    this.value, {
    required this.key,
    this.unit,
  }) : super._();

  @override
  Query apply(Query reference) {
    final String value = () {
      // yyyy-MM-ddTHH:mm:ss.mmmuuuZ
      final String value = this.value.toIso8601String();
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
    }();
    return Filter.text(value, key: key).apply(reference);
  }
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
