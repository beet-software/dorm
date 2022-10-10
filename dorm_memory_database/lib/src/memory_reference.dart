import 'package:dorm/dorm.dart';
import 'package:uuid/uuid.dart';

import 'memory_instance.dart';
import 'param_type.dart';

class MemoryQuery implements Query {
  @override
  final String path;
  final MemoryInstance _instance;
  final Set<ParamType> params;

  MemoryQuery._(
    this._instance, {
    required this.path,
    required this.params,
  });

  @override
  Query limitToFirst(int limit) {
    if (limit < 0) {
      throw ArgumentError.value(
          limit, 'limit', 'must be a non-negative integer');
    }
    params.add(ParamType.limitToFirst(limit));
    return this;
  }

  @override
  Query limitToLast(int limit) {
    if (limit < 0) {
      throw ArgumentError.value(
          limit, 'limit', 'must be a non-negative integer');
    }
    params.add(ParamType.limitToLast(limit));
    return this;
  }

  @override
  Query startAt(Object? value) {
    if (value == null) return this;
    params.add(ParamType.startAt(value));
    return this;
  }

  @override
  Query endAt(Object? value) {
    if (value == null) return this;
    params.add(ParamType.endAt(value));
    return this;
  }

  @override
  Query equalTo(Object? value) {
    if (value == null) return this;
    params.add(ParamType.equalTo(value));
    return this;
  }

  @override
  Query orderByChild(String key) {
    params.add(ParamType.orderByChild(key));
    return this;
  }

  @override
  Future<Object?> get() async => _instance.get(params, path);

  @override
  Stream<Object?> get onValue => _instance.listen(params, path);

  @override
  Future<Map<String, Object>> getChildren() => throw UnimplementedError();

  @override
  Stream<Map<String, Object>> get onChildren => throw UnimplementedError();
}

class MemoryReference extends MemoryQuery with Reference {
  MemoryReference(
    MemoryInstance instance, {
    required String path,
    required Set<ParamType> params,
  }) : super._(instance, path: path, params: params);

  @override
  Reference child(String key) {
    final String path = this.path.isEmpty ? key : '${this.path}/$key';
    return MemoryReference(_instance, path: path, params: params);
  }

  @override
  String? get key => path.split('/').last;

  @override
  Reference push() => child(const Uuid().v4());

  @override
  Future<void> remove() async => _instance.remove(path);

  @override
  Future<void> set(Object? value) async => _instance.set(path, value);

  @override
  Future<void> update(Map<String, Object?> value) async =>
      _instance.update(path, value);

  @override
  Future<List<String>> shallow() async => _instance.shallow(path);
}
