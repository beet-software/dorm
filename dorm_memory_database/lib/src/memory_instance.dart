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

class MemoryInstance {
  final Map<String, Object> _data;

  MemoryInstance(this._data);

  MemoryReference get ref =>
      MemoryReference(this, path: '', params: {ParamType.orderByKey()});

  Object? get([Iterable<ParamType> params = const [], String? path]) {
    final Map<String, Object> result = {};
    if (path == null) {
      result.addAll(_data);
    } else {
      for (MapEntry<String, Object> entry in this._data.entries) {
        final String key = entry.key;
        final Object value = entry.value;
        if (key == path) return value;

        if (!key.startsWith('$path/')) continue;
        final String subKey = key.substring(path.length + 1);
        result[subKey] = value;
      }
    }

    Map<String, Object> data = splat(result);
    Object? Function(MapEntry<String, Object> entry)? getter;
    for (ParamType param in params) {
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
      _data.remove(path);
    } else {
      _data[path] = value;
    }
  }

  void update(String path, Map<String, Object?> value) {
    for (MapEntry<String, Object?> entry in value.entries) {
      final Object? value = entry.value;
      if (value == null) continue;

      _data['$path/${entry.key}'] = value;
    }
  }

  void remove(String path) => set(path, null);

  List<String> shallow() => throw UnimplementedError();
}
