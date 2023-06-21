import 'package:dorm/dorm.dart';
import 'package:firebase_database/firebase_database.dart' as fd;

class Query implements BaseQuery<Query> {
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

  static String? _dateAsPrefixQuery(DateTime? dt, {DateFilterUnit? unit}) {
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

  final fd.Query query;

  const Query(this.query);

  @override
  Query whereValue(String key, Object? value) {
    return Query(query.orderByChild(key).equalTo(value));
  }

  @override
  Query whereText(String key, String prefix) {
    final String value = prefix;
    return Query(query.orderByChild(key).startAt(value).endAt('$value\uf8ff'));
  }

  @override
  Query whereDate(String key, DateTime date, DateFilterUnit unit) {
    final String? prefix = _dateAsPrefixQuery(date, unit: unit);
    if (prefix == null) return this;
    return whereText(key, prefix);
  }

  @override
  Query whereRange<T>(String key, FilterRange<T> range) {
    final T? from = range.from;
    final T? to = range.to;

    if (from == null && to == null) return this;
    fd.Query ref = query.orderByChild(key);
    if (from != null) ref = ref.startAt(from);
    if (to != null) ref = ref.endAt(to);
    return Query(ref);
  }

  @override
  Query limit(int count) {
    if (count == 0) return this;
    if (count < 0) return Query(query.limitToLast(count.abs()));
    return Query(query.limitToFirst(count));
  }
}
