part of '../dorm.dart';

abstract class ModelRepository<Model> {
  Stream<List<Model>> pullAll([Filter query = const Filter.empty()]);

  Stream<Model?> pull(String id);

  Future<List<Model>> peekAll([Filter query = const Filter.empty()]);

  Future<Model?> peek(String id);

  Future<void> popAll(Iterable<String> ids);

  Future<void> pop(String id);

  Future<void> pushAll(List<Model> models);

  Future<void> push(Model model);
}

abstract class DataRepository<Data, Model extends Data>
    implements ModelRepository<Model> {
  Future<Model> put(Dependency<Data> dependency, Data data);

  Future<List<Model>> putAll(Dependency<Data> dependency, List<Data> datum);
}

class Repository<Data, Model extends Data>
    implements DataRepository<Data, Model> {
  final Reference root;
  final Entity<Data, Model> entity;

  const Repository({required this.root, required this.entity});

  Reference get _ref => root.child(entity.tableName);

  @override
  Future<Model?> peek(String id) {
    return _ref //
        .child(id)
        .get()
        .then((value) =>
            value == null ? null : entity.fromJson(id, value as Map));
  }

  @override
  Future<List<Model>> peekAll([Filter query = const Filter.empty()]) {
    return query //
        .filter(_ref)
        .get()
        .then((value) {
      final Map? data = value as Map?;
      if (data == null) return [];
      if (data.isEmpty) return [];
      return data.entries.map((entry) {
        final String key = entry.key as String;
        final Map value = entry.value as Map;
        return entity.fromJson(key, value);
      }).toList();
    });
  }

  @override
  Future<void> pop(String id) async {
    _ref.child(id).remove();
  }

  @override
  Future<void> popAll(Iterable<String> ids) async {
    _ref.update({for (String id in ids) id: null});
  }

  @override
  Stream<Model?> pull(String id) {
    return _ref //
        .child(id)
        .onValue
        .map((value) =>
            value == null ? null : entity.fromJson(id, value as Map));
  }

  @override
  Stream<List<Model>> pullAll([Filter query = const Filter.empty()]) {
    return query //
        .filter(_ref)
        .onValue
        .map((value) {
      final Map? data = value as Map?;
      if (data == null) return [];
      if (data.isEmpty) return [];
      return data.entries.map((entry) {
        final String key = entry.key as String;
        final Map value = entry.value as Map;
        return entity.fromJson(key, value);
      }).toList();
    });
  }

  @override
  Future<Model> put(Dependency<Data> dependency, Data data) async {
    return putAll(dependency, [data]).then((models) => models.single);
  }

  @override
  Future<List<Model>> putAll(
    Dependency<Data> dependency,
    List<Data> datum,
  ) async {
    final List<Model> models = [];
    for (Data data in datum) {
      final Reference ref = _ref.push();
      final String id = ref.key as String;
      final Model model = entity.fromData(dependency, id, data);
      models.add(model);
    }
    _ref.update({
      for (Model model in models) entity.identify(model): entity.toJson(model),
    });
    return models;
  }

  @override
  Future<void> push(Model model) async {
    return pushAll([model]);
  }

  @override
  Future<void> pushAll(List<Model> models) async {
    _ref.update({
      for (Model model in models) entity.identify(model): entity.toJson(model),
    });
  }
}
