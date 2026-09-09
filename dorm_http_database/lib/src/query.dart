import 'package:dorm_framework/dorm_framework.dart';

sealed class QueryCondition {
  const QueryCondition();
}

final class ValueCondition extends QueryCondition {
  final String key;
  final Object? value;

  const ValueCondition(this.key, this.value);
}

final class TextCondition extends QueryCondition {
  final String key;
  final String prefix;

  const TextCondition(this.key, this.prefix);
}

final class DateCondition extends QueryCondition {
  final String key;
  final DateTime date;
  final DateFilterUnit unit;

  const DateCondition(this.key, this.date, this.unit);
}

final class RangeCondition extends QueryCondition {
  final String key;
  final Object? from;
  final Object? to;
  final DateFilterUnit? unit;

  const RangeCondition(this.key, this.from, this.to, [this.unit]);
}

final class SortCondition extends QueryCondition {
  final String key;
  final bool ascending;

  const SortCondition(this.key, {this.ascending = true});
}

final class LimitCondition extends QueryCondition {
  final int count;

  const LimitCondition(this.count);
}

final class OffsetCondition extends QueryCondition {
  final int count;

  const OffsetCondition(this.count);
}

/// A query represented as ordered, composable HTTP conditions.
class Query implements BaseQuery<Query> {
  final List<QueryCondition> conditions;
  final EntitySchema? schema;

  const Query({this.conditions = const [], this.schema});

  Query _add(QueryCondition condition) {
    return Query(conditions: [...conditions, condition], schema: schema);
  }

  @override
  Query whereValue(String key, Object? value) =>
      _add(ValueCondition(key, value));

  @override
  Query whereText(String key, String prefix) =>
      _add(TextCondition(key, prefix));

  @override
  Query whereDate(String key, DateTime date, DateFilterUnit unit) =>
      _add(DateCondition(key, date, unit));

  @override
  Query whereRange<R>(String key, FilterRange<R> range) => _add(
    RangeCondition(
      key,
      range.from,
      range.to,
      range is DateFilterRange ? (range as DateFilterRange).unit : null,
    ),
  );

  @override
  Query limit(int count) {
    if (count == 0) return this;
    return _add(LimitCondition(count));
  }

  @override
  Query offset(int count) {
    if (count < 0) {
      throw ArgumentError.value(count, 'count', 'Offset must be non-negative.');
    }
    if (count == 0) return this;
    return _add(OffsetCondition(count));
  }

  @override
  Query sorted(String key, {bool ascending = true}) =>
      _add(SortCondition(key, ascending: ascending));
}
