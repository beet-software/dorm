import 'dart:async';
import 'dart:collection';

import 'package:collection/collection.dart';
import 'package:dorm_memory_database/src/memory_reference.dart';

import 'param_type.dart';

Map<String, Object> splat(Map<String, Object> data, [String separator = '/']) {
  final Map<String, Object> tree = {};
  for (MapEntry<String, Object> entry in data.entries) {
    final String key = entry.key;
    if (key.contains(separator)) {
      final List<String> segments = key.split(separator);
      final String tail = segments.removeLast();

      Map<String, Object> subTree = tree;
      for (String segment in segments) {
        final Map<String, Object> subLeaf =
            subTree[segment] as Map<String, Object>? ?? {};

        subTree[segment] = subLeaf;
        subTree = subLeaf;
      }
      subTree[tail] = entry.value;
    } else {
      tree[key] = entry.value;
    }
  }
  return tree;
}

class QueryData {
  final String? path;
  final Iterable<ParamType> params;

  const QueryData({required this.path, required this.params});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QueryData &&
          runtimeType == other.runtimeType &&
          path == other.path &&
          const IterableEquality().equals(params, other.params);

  @override
  int get hashCode => path.hashCode ^ params.hashCode;
}

class MemoryListener extends MapBase<String, Object> {
  final Map<String, Object> _data;
  final Map<QueryData, StreamController<Object?>> _controllers = {};
  final Map<QueryData, int> _subscriptionCounter = {};

  MemoryListener._(this._data);

  Object? once(QueryData query) {
    final Map<String, Object> flattenedData = {};

    final String? path = query.path;
    if (path == null) {
      flattenedData.addAll(_data);
    } else {
      for (MapEntry<String, Object> entry in _data.entries) {
        final String key = entry.key;
        final Object value = entry.value;
        if (key == query.path) return value;

        if (!key.startsWith('$path/')) continue;
        final String subKey = key.substring(path.length + 1);
        flattenedData[subKey] = value;
      }
    }

    Map<String, Object> data = splat(flattenedData);
    Object? Function(MapEntry<String, Object> entry)? getter;
    for (ParamType param in query.params) {
      data = param.when<Map<String, Object>>(
        orderBy: (key) {
          final List<String> segments = key.split('/');
          final List<MapEntry<String, Object>> entries = data.entries.toList();

          Object? _getter(MapEntry<String, Object> entry) {
            final Map<String, Object> data = entry.value as Map<String, Object>;
            if (segments.length == 1) return data[segments.single];

            final List<String> middle = List.of(segments);
            final String head = middle.removeAt(0);
            final String tail = middle.removeLast();
            Map<String, Object> childData = data[head] as Map<String, Object>;
            for (String segment in middle) {
              childData = childData[segment] as Map<String, Object>;
            }
            return childData[tail];
          }

          getter = _getter;

          entries.sort((e0, e1) {
            final Object? o0 = _getter(e0);
            final Object? o1 = _getter(e1);
            if (o0 == null) return -1;
            if (o1 == null) return 1;
            if (o0 is Comparable<Object?>) return o0.compareTo(o1);
            return 0;
          });
          return Map.fromEntries(entries);
        },
        limitToFirst: (count) => Map.fromEntries(data.entries.take(count)),
        limitToLast: (count) =>
            Map.fromEntries(data.entries.toList().reversed.take(count)),
        startAt: (expectedValue) {
          final Map<String, Object> result = {};
          for (MapEntry<String, Object> entry in data.entries) {
            final _getter = getter;
            final Object? actualValue =
                _getter == null ? entry.value : _getter(entry);

            final bool include;
            if (expectedValue is num && actualValue is num) {
              include = actualValue >= expectedValue;
            } else if (expectedValue is String && actualValue is String) {
              include = actualValue.startsWith(expectedValue);
            } else {
              include = false;
            }
            if (!include) continue;
            result[entry.key] = entry.value;
          }
          return result;
        },
        endAt: (expectedValue) {
          final Map<String, Object> result = {};
          for (MapEntry<String, Object> entry in data.entries) {
            final _getter = getter;
            final Object? actualValue =
                _getter == null ? entry.value : _getter(entry);

            final bool include;
            if (expectedValue is num && actualValue is num) {
              include = actualValue <= expectedValue;
            } else if (expectedValue is String && actualValue is String) {
              include = actualValue.endsWith(expectedValue);
            } else {
              include = false;
            }
            if (!include) continue;
            result[entry.key] = entry.value;
          }
          return result;
        },
        equalTo: (expectedValue) {
          final Map<String, Object> result = {};
          for (MapEntry<String, Object> entry in data.entries) {
            final _getter = getter;
            final Object? actualValue =
                _getter == null ? entry.value : _getter(entry);

            if (expectedValue != actualValue) continue;
            result[entry.key] = entry.value;
          }
          return result;
        },
      );
    }
    return data;
  }

  Stream<Object?> listen(QueryData query) {
    late final StreamController<Object?> controller;
    controller = _controllers[query] ??
        StreamController.broadcast(
          onListen: () {
            _subscriptionCounter[query] =
                (_subscriptionCounter[query] ?? 0) + 1;
            controller.add(once(query));
          },
          onCancel: () async {
            final StreamController<Object?>? controller = _controllers[query];
            final int? subscriptionCount = _subscriptionCounter[query];
            if (subscriptionCount != null && subscriptionCount > 1) return;
            await controller?.close();
            _controllers.remove(query);
            _subscriptionCounter.remove(query);
          },
        );
    return controller.stream;
  }

  void _onDataChange() {
    for (MapEntry<QueryData, StreamController<Object?>> entry
        in _controllers.entries) {
      final QueryData query = entry.key;
      final StreamController<Object?> controller = entry.value;
      controller.add(once(query));
    }
  }

  @override
  Object? operator [](Object? key) => _data[key];

  @override
  void operator []=(String key, Object value) {
    _data[key] = value;
    _onDataChange();
  }

  @override
  Object? remove(Object? key) {
    final Object? value = _data.remove(key);
    _onDataChange();
    return value;
  }

  @override
  void clear() {
    _data.clear();
    _onDataChange();
  }

  @override
  Iterable<String> get keys => _data.keys;
}

class MemoryInstance {
  final MemoryListener _listener;

  MemoryInstance([Map<String, Object>? data])
      : _listener = MemoryListener._(data ?? {});

  MemoryReference get ref {
    final Set<ParamType> params = LinkedHashSet(
      equals: (p0, p1) => p0.runtimeType == p1.runtimeType,
      hashCode: (param) => param.runtimeType.hashCode,
    );
    params.add(ParamType.orderByKey());
    return MemoryReference(this, path: '', params: params);
  }

  Object? get([Iterable<ParamType> params = const [], String? path]) =>
      _listener.once(QueryData(path: path, params: params));

  Stream<Object?> listen(
          [Iterable<ParamType> params = const [], String? path]) =>
      _listener.listen(QueryData(path: path, params: params));

  void set(String path, Object? value) {
    if (value is Map<String, Object?>) {
      for (MapEntry<String, Object?> entry in value.entries) {
        final String innerPath = '$path/${entry.key}';
        set(innerPath, entry.value);
      }
    } else if (value is List<Object?>) {
      for (int i = 0; i < value.length; i++) {
        final String innerPath = '$path/$i';
        set(innerPath, value[i]);
      }
    } else if (value == null) {
      _listener.remove(path);
    } else {
      _listener[path] = value;
    }
  }

  void update(String path, Map<String, Object?> value) {
    for (MapEntry<String, Object?> entry in value.entries) {
      final Object? value = entry.value;
      if (value == null) continue;

      _listener['$path/${entry.key}'] = value;
    }
  }

  void remove(String path) => set(path, null);

  List<String> shallow(String path) {
    final List<String> keys = [];
    for (MapEntry<String, Object> entry in _listener.entries) {
      final String key = entry.key;
      if (!key.startsWith('$path/')) continue;
      keys.add(key.substring(path.length + 1));
    }
    return keys;
  }
}
