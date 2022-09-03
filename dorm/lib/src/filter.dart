import 'query.dart';

abstract class Filter {
  const factory Filter.empty() = _EmptyFilter;

  const factory Filter.value({
    required String key,
    required Object? value,
  }) = _ValueFilter;

  const factory Filter.text({
    required String key,
    required String text,
  }) = _TextFilter;

  const factory Filter.limit({
    required Filter query,
    required int limit,
  }) = _LimitFilter;

  const Filter._();

  Query filter(Query reference);
}

class _EmptyFilter extends Filter {
  const _EmptyFilter() : super._();

  @override
  Query filter(Query reference) => reference;
}

class _ValueFilter extends Filter {
  final String key;
  final Object? value;

  const _ValueFilter({required this.key, required this.value}) : super._();

  @override
  Query filter(Query reference) {
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

  const _TextFilter({required this.key, required this.text}) : super._();

  @override
  Query filter(Query reference) {
    final String text = _normalizeText(this.text);
    return reference.orderByChild(key).startAt(text).endAt('$text\uf8ff');
  }
}

class _LimitFilter extends Filter {
  final Filter query;
  final int limit;

  const _LimitFilter({required this.query, required this.limit}) : super._();

  @override
  Query filter(Query reference) {
    final Query result = query.filter(reference);
    if (limit < 0) return result.limitToLast(limit.abs());
    if (limit > 0) return result.limitToFirst(limit);
    return result;
  }
}
