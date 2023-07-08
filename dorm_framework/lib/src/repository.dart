// dORM
// Copyright (C) 2023  Beet Software
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

import 'dependency.dart';
import 'entity.dart';
import 'filter.dart';
import 'reference.dart';
import 'relationship.dart';

/// Represents reading a single model from the database engine.
abstract class SingleReadOperation<Model> {
  /// Selects a model in this table, given its [id].
  ///
  /// This method should retrieve *only* the accessed model:
  ///
  /// ```dart
  /// const String id = '7a3ee40b4a6b';
  ///
  /// // DON'T: Downloads all the models to the client
  /// final List<Model> models = await peekAll();
  /// final Model? model = models.where((model) => model.id == id).singleOrNull;
  ///
  /// // DO: Downloads only the given model to the client
  /// final Model? model = await peek(id);
  /// ```
  ///
  /// If there is no model with the given [id], this method will return null.
  Future<Model?> peek(String id);

  /// Listens for a model in this table, given íts [id].
  ///
  /// As soon as this stream is listened, an event should be emitted containing
  /// the actual state of the model. Subsequent events should be emitted
  /// whenever a change occurs on the model.
  ///
  /// If there is no model with the given [id], this method will yield null.
  Stream<Model?> pull(String id);
}

/// Represents reading multiple models from the database engine.
abstract class BatchReadOperation<Model> {
  /// Selects all the models matching [filter] in this table.
  ///
  /// If there are no models, this method will return an empty list.
  Future<List<Model>> peekAll([Filter filter = const Filter.empty()]);

  /// Listens for all the models in this table matching [filter] and their changes.
  ///
  /// As soon as this stream is listened, an event should be emitted containing
  /// the actual state of the query. Subsequent events should be emitted
  /// whenever a change occurs on the query.
  ///
  /// If there are no models, this method will yield an empty list.
  Stream<List<Model>> pullAll([Filter filter = const Filter.empty()]);
}

/// Represents the operations available for a [Model] in a database.
abstract class ModelRepository<Model> implements Readable<Model> {
  /// Selects all the ids from the models of this table.
  ///
  /// This method should retrieve *only* the ids:
  ///
  /// ```dart
  /// // DON'T: Downloads all the models (including attributes) to the client
  /// final List<Model> models = await peekAll();
  /// final List<String> ids = models.map((model) => model.id).toList();
  ///
  /// // DO: Download only the ids of the models (does not include attributes)
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
  /// This method should be atomic:
  ///
  /// ```dart
  /// const List<String> ids = ['f0b44d79a39c', '9d223f993f08', 'e7b608870ad0'];
  ///
  /// // DON'T: Calls the database engine 3 times, sequentially
  /// for (String id in ids) await pop(id);
  ///
  /// // DON'T: Calls the database engine 3 times, in parallel
  /// Future.wait(ids.map((id) => pop(id)));
  ///
  /// // DO: Calls the database engine once
  /// await popAll(ids);
  /// ```
  ///
  /// If there are no models with the given [ids], this method will do nothing.
  Future<void> popKeys(Iterable<String> ids);

  /// Deletes all the models in this table matching the given [filter].
  ///
  /// If [filter] is an instance of [Filter.empty], this method will delete
  /// *all* the rows in the table. However, for this intent, call [purge].
  ///
  /// This method should be atomic:
  ///
  /// ```dart
  /// const Filter filter = /* ... */;
  ///
  /// // DON'T: Calls the database engine twice
  /// final List<Model> models = await peekAll(filter);
  /// await popKeys(models.map((model) => model.id));
  ///
  /// // DO: Calls the database engine once
  /// await popAll(ids);
  /// ```
  ///
  /// If there are no rows matching [filter] in the table, this method will do
  /// nothing.
  Future<void> popAll(Filter filter);

  /// Inserts a [model] into its respective table on the database engine.
  ///
  /// If there is a model in the table with the same id as the one being
  /// inserted, the existing model will be overwritten by [model].
  Future<void> push(Model model);

  /// Inserts all [models] into this table.
  ///
  /// This method should be atomic:
  ///
  /// ```dart
  /// const List<Model> models = [ /* ... */ ];
  ///
  /// // DON'T: Calls the database engine N times, sequentially
  /// for (Model model in models) await push(model);
  ///
  /// // DON'T: Calls the database engine N times, in parallel
  /// await Future.wait(models.map((model) => push(model)));
  ///
  /// // DO: Calls the database engine once
  /// await pushAll(models);
  /// ```
  ///
  /// If there are any models in the table with the same id as any of the ones
  /// being inserted, the existing models will be overwritten by those on [models].
  Future<void> pushAll(List<Model> models);

  /// Updates a model using a [update] function, given its [id].
  ///
  /// If [update] receives null, this means there is no model with the given
  /// [id] on the table. If [update] returns null, the existing model will be
  /// deleted from the table.
  ///
  /// Changing the received model's id inside [update] will not have any effects.
  ///
  /// This method should be atomic:
  ///
  /// ```dart
  /// const String id = '7a3ee40b4a6b';
  /// Model? _update(Model? model) { /* ... */ }
  ///
  /// // DON'T: Calls the database engine twice
  /// final Model model = await peek(id);
  /// final Model? updatedModel = _update(model);
  /// if (updatedModel == null) {
  ///   await pop(id);
  /// } else {
  ///   await push(updatedModel);
  /// }
  ///
  /// // DO: Calls the database engine once
  /// await patch(id, _update);
  /// ```
  Future<void> patch(String id, Model? Function(Model?) update);

  /// Removes all models from this table.
  ///
  /// This method should be more efficient than calling [popAll] passing
  /// [Filter.empty] as argument.
  Future<void> purge();
}

/// Represents creating models into the database engine.
abstract class DataRepository<Data, Model extends Data>
    implements ModelRepository<Model> {
  /// Convert a [data] into a model and inserts it into its respective table on
  /// the database engine.
  ///
  /// The id of the model may be defined by [dependency], through its
  /// [Dependency.key] method. If there is a model in the table with the same id
  /// as the one being created, the existing model will be overwritten.
  Future<Model> put(Dependency<Data> dependency, Data data);

  /// Convert a sequence of [datum] into models and inserts them into their
  /// respective table on the database engine.
  ///
  /// /// The id of the model may be defined by [dependency], through its
  /// [Dependency.key] method. If there are any models in the table with the
  /// same id as any of the ones being inserted, the existing models will be
  /// overwritten.
  Future<List<Model>> putAll(Dependency<Data> dependency, List<Data> datum);
}

/// Represents the controller of the underlying database engine.
class Repository<Data, Model extends Data>
    implements DataRepository<Data, Model> {
  final BaseReference _reference;
  final Entity<Data, Model> _entity;

  /// Creates a repository by its attributes.
  const Repository({
    required BaseReference reference,
    required BaseRelationship relationship,
    required Entity<Data, Model> entity,
  })  : _reference = reference,
        _entity = entity;

  @override
  Future<Model?> peek(String id) {
    return _reference.peek(_entity, id);
  }

  @override
  Future<List<Model>> peekAll([Filter filter = const Filter.empty()]) {
    return _reference.peekAll(_entity, filter);
  }

  @override
  Future<List<String>> peekAllKeys() {
    return _reference.peekAllKeys(_entity);
  }

  @override
  Future<void> pop(String id) async {
    return _reference.pop(_entity, id);
  }

  @override
  Future<void> popKeys(Iterable<String> ids) {
    return _reference.popKeys(_entity, ids);
  }

  @override
  Future<void> popAll(Filter filter) {
    return _reference.popAll(_entity, filter);
  }

  @override
  Stream<Model?> pull(String id) {
    return _reference.pull(_entity, id);
  }

  @override
  Stream<List<Model>> pullAll([Filter filter = const Filter.empty()]) {
    return _reference.pullAll(_entity, filter);
  }

  @override
  Future<Model> put(Dependency<Data> dependency, Data data) async {
    return _reference.put(_entity, dependency, data);
  }

  @override
  Future<List<Model>> putAll(Dependency<Data> dependency, List<Data> datum) {
    return _reference.putAll(_entity, dependency, datum);
  }

  @override
  Future<void> push(Model model) async {
    return _reference.push(_entity, model);
  }

  @override
  Future<void> pushAll(List<Model> models) async {
    return _reference.pushAll(_entity, models);
  }

  @override
  Future<void> patch(String id, Model? Function(Model?) update) {
    return _reference.patch(_entity, id, update);
  }

  @override
  Future<void> purge() {
    return _reference.purge(_entity);
  }
}
