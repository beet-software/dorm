abstract class ParamType {
  const factory ParamType.orderByKey() = _OrderByParamType.byKey;

  const factory ParamType.orderByValue() = _OrderByParamType.byValue;

  const factory ParamType.orderByChild(String key) = _OrderByParamType;

  const factory ParamType.limitToFirst(int count) = _LimitToFirstParamType;

  const factory ParamType.limitToLast(int count) = _LimitToLastParamType;

  const factory ParamType.startAt(Object value) = _StartAtParamType;

  const factory ParamType.endAt(Object value) = _EndAtParamType;

  const factory ParamType.equalTo(Object value) = _EqualToParamType;

  const ParamType._();

  R when<R>({
    required R Function(String key) orderBy,
    required R Function(int count) limitToFirst,
    required R Function(int count) limitToLast,
    required R Function(Object value) startAt,
    required R Function(Object value) endAt,
    required R Function(Object value) equalTo,
  });

  int get code => when(
        orderBy: (_) => 0,
        limitToFirst: (_) => 1,
        limitToLast: (_) => 2,
        startAt: (_) => 3,
        endAt: (_) => 4,
        equalTo: (_) => 5,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ParamType &&
          runtimeType == other.runtimeType &&
          code == other.code;

  @override
  int get hashCode => code.hashCode;
}

class _OrderByParamType extends ParamType {
  final String key;

  const _OrderByParamType(this.key) : super._();

  const _OrderByParamType.byKey() : this('\$key');

  const _OrderByParamType.byValue() : this('\$value');

  @override
  R when<R>({
    required R Function(String key) orderBy,
    required R Function(int count) limitToFirst,
    required R Function(int count) limitToLast,
    required R Function(Object value) startAt,
    required R Function(Object value) endAt,
    required R Function(Object value) equalTo,
  }) {
    return orderBy(key);
  }
}

class _LimitToFirstParamType extends ParamType {
  final int count;

  const _LimitToFirstParamType(this.count) : super._();

  @override
  R when<R>({
    required R Function(String key) orderBy,
    required R Function(int count) limitToFirst,
    required R Function(int count) limitToLast,
    required R Function(Object value) startAt,
    required R Function(Object value) endAt,
    required R Function(Object value) equalTo,
  }) {
    return limitToFirst(count);
  }
}

class _LimitToLastParamType extends ParamType {
  final int count;

  const _LimitToLastParamType(this.count) : super._();

  @override
  R when<R>({
    required R Function(String key) orderBy,
    required R Function(int count) limitToFirst,
    required R Function(int count) limitToLast,
    required R Function(Object value) startAt,
    required R Function(Object value) endAt,
    required R Function(Object value) equalTo,
  }) {
    return limitToLast(count);
  }
}

class _StartAtParamType extends ParamType {
  final Object value;

  const _StartAtParamType(this.value) : super._();

  @override
  R when<R>({
    required R Function(String key) orderBy,
    required R Function(int count) limitToFirst,
    required R Function(int count) limitToLast,
    required R Function(Object value) startAt,
    required R Function(Object value) endAt,
    required R Function(Object value) equalTo,
  }) {
    return startAt(value);
  }
}

class _EndAtParamType extends ParamType {
  final Object value;

  const _EndAtParamType(this.value) : super._();

  @override
  R when<R>({
    required R Function(String key) orderBy,
    required R Function(int count) limitToFirst,
    required R Function(int count) limitToLast,
    required R Function(Object value) startAt,
    required R Function(Object value) endAt,
    required R Function(Object value) equalTo,
  }) {
    return endAt(value);
  }
}

class _EqualToParamType extends ParamType {
  final Object value;

  const _EqualToParamType(this.value) : super._();

  @override
  R when<R>({
    required R Function(String key) orderBy,
    required R Function(int count) limitToFirst,
    required R Function(int count) limitToLast,
    required R Function(Object value) startAt,
    required R Function(Object value) endAt,
    required R Function(Object value) equalTo,
  }) {
    return equalTo(value);
  }
}
