import 'dependency.dart';
import 'entity.dart';
import 'filter.dart';
import 'reference.dart';
import 'relationship.dart';

abstract class SingleReadOperation<Model> {
  /// Selects a model in this table, given its [id].
  ///
  /// The difference between this method and [peekAll] is the download size:
  ///
  /// ```
  /// const String id = 'some-id';
  ///
  /// // Downloads ALL the models to the client
  /// final List<Model> models = await peekAll();
  /// final Model? model = models.where((model) => model.id == id).singleOrNull;
  ///
  /// // Downloads ONLY the given model to the client
  /// final Model? model = await peek(id);
  /// ```
  ///
  /// If there is no model with the given [id], this method will return null.
  Future<Model?> peek(String id);

  /// Listens for a model in this table, given íts [id].
  ///
  /// If there is no model with the given [id], this method will yield null.
  Stream<Model?> pull(String id);
}

abstract class BatchReadOperation<Model> {
  /// Selects all the models in this table.
  ///
  /// If there are no models, this method will return an empty list.
  Future<List<Model>> peekAll([Filter filter = const Filter.empty()]);

  /// Listens for all the models in this table and their changes.
  ///
  /// If there are no models, this method will yield an empty list.
  Stream<List<Model>> pullAll([Filter filter = const Filter.empty()]);
}

/// Represents the operations available for a [Model] in a database.
abstract class ModelRepository<Model> implements Mergeable<Model> {
  /// Selects all the ids from the models of this table.
  ///
  /// The difference between this method and [peekAll] is the download size:
  ///
  /// ```
  /// // Downloads ALL the models (including attributes) to the client
  /// final List<Model> models = await peekAll();
  /// final List<String> ids = models.map((model) => model.id).toList();
  ///
  /// // Download ONLY the ids of the models (does not include attributes)
  /// final List<String> ids = await peekAllKeys();
  /// ```
  ///
  /// If there are no models, this method will return an empty list.
  Future<List<String>> peekAllKeys();

  /// Deletes a model in this table, given its [id].
  ///
  /// If there is no model with the given [id], this method will do nothing.
  Future<void> pop(String id);

  /// Deletes all the models in this table with the given [ids].
  ///
  /// The difference between this and [pop] is the size of the API calls:
  ///
  /// ```
  /// const List<String> ids = ['id-0', 'id-1', 'id-2'];
  ///
  /// // Calls the API N times, sequentially
  /// for (String id in ids) await pop(id);
  ///
  /// // Calls the API N times, in parallel
  /// Future.wait(ids.map((id) => pop(id)));
  ///
  /// // Calls the API once
  /// popAll(ids);
  /// ```
  ///
  /// If there are no models with the given [ids], this method will do nothing.
  Future<void> popAll(Iterable<String> ids);

  /// Inserts a [model] into this table.
  ///
  /// If there is a model in the table with the same id as the one being
  /// inserted, the existing model will be overwritten by [model].
  Future<void> push(Model model);

  /// Inserts all [models] into this table.
  ///
  /// The difference between this and [push] is the size of the API calls:
  ///
  /// ```
  /// const List<Model> models = [ /* ... */ ];
  ///
  /// // Calls the API N times, sequentially
  /// for (Model model in models) await push(model);
  ///
  /// // Calls the API N times, in parallel
  /// Future.wait(models.map((model) => push(model)));
  ///
  /// // Calls the API once
  /// pushAll(models);
  /// ```
  ///
  /// If there are any models in the table with the same id as any of the ones
  /// being inserted, the existing models will be overwritten by those on [models].
  Future<void> pushAll(List<Model> models);
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
  Future<List<Model>> peekAll([Filter filter = const Filter.empty()]) {
    return filter //
        .apply(_ref)
        .getChildren()
        .then((values) {
      if (values.isEmpty) return [];
      return values.entries.map((entry) {
        final String key = entry.key;
        final Map value = entry.value as Map;
        return entity.fromJson(key, value);
      }).toList();
    });
  }

  @override
  Future<List<String>> peekAllKeys() {
    return _ref.shallow();
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
  Stream<List<Model>> pullAll([Filter filter = const Filter.empty()]) {
    return filter //
        .apply(_ref)
        .onChildren
        .map((values) {
      if (values.isEmpty) return [];
      return values.entries.map((entry) {
        final String key = entry.key;
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
