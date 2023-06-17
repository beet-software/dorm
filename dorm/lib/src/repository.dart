import 'package:dorm/dorm.dart';

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
  final BaseReference _root;
  final Entity<Data, Model> _entity;

  const Repository({
    required BaseReference root,
    required Entity<Data, Model> entity,
  })  : _root = root,
        _entity = entity;

  @override
  Future<Model?> peek(String id) {
    return _root.peek(_entity, id);
  }

  @override
  Future<List<Model>> peekAll([Filter filter = const Filter.empty()]) {
    return _root.peekAll(_entity, filter);
  }

  @override
  Future<List<String>> peekAllKeys() {
    return _root.peekAllKeys(_entity);
  }

  @override
  Future<void> pop(String id) async {
    return _root.pop(_entity, id);
  }

  @override
  Future<void> popAll(Iterable<String> ids) {
    return _root.popAll(_entity, ids);
  }

  @override
  Stream<Model?> pull(String id) {
    return _root.pull(_entity, id);
  }

  @override
  Stream<List<Model>> pullAll([Filter filter = const Filter.empty()]) {
    return _root.pullAll(_entity, filter);
  }

  @override
  Future<Model> put(Dependency<Data> dependency, Data data) async {
    return _root.put(_entity, dependency, data);
  }

  @override
  Future<List<Model>> putAll(Dependency<Data> dependency, List<Data> datum) {
    return _root.putAll(_entity, dependency, datum);
  }

  @override
  Future<void> push(Model model) async {
    return _root.push(_entity, model);
  }

  @override
  Future<void> pushAll(List<Model> models) async {
    return _root.pushAll(_entity, models);
  }
}
