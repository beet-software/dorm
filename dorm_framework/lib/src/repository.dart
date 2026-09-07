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

import 'schema.dart';
import 'creation.dart';
import 'query.dart';
import 'entity.dart';
import 'filter.dart';
import 'reference.dart';
import 'relationship.dart';

/// Represents reading a single model from the database engine.
abstract class SingleReadOperation<Model, I extends Object> {
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
  Future<Model?> peek(I id);

  /// Listens for a model in this table, given Ã­ts [id].
  ///
  /// As soon as this stream is listened, an event should be emitted containing
  /// the actual state of the model. Subsequent events should be emitted
  /// whenever a change occurs on the model.
  ///
  /// If there is no model with the given [id], this method will yield null.
  Stream<Model?> pull(I id);
}

/// Represents reading multiple models from the database engine.
abstract class BatchReadOperation<Model, Q extends BaseQuery<Q>> {
  /// Selects all the models matching [filter] in this table.
  ///
  /// If there are no models, this method will return an empty list.
  Future<List<Model>> peekAll([
    BaseFilter<Q> filter = const BaseFilter.empty(),
  ]);

  /// Listens for all the models in this table matching [filter] and their changes.
  ///
  /// As soon as this stream is listened, an event should be emitted containing
  /// the actual state of the query. Subsequent events should be emitted
  /// whenever a change occurs on the query.
  ///
  /// If there are no models, this method will yield an empty list.
  Stream<List<Model>> pullAll([
    BaseFilter<Q> filter = const BaseFilter.empty(),
  ]);
}

/// Represents the operations available for a [Model] in a database.
abstract class ModelRepository<Model, I extends Object, Q extends BaseQuery<Q>>
    implements RelationSource<Model, I, Q> {
  @override
  RelationPlan<Model, I> get plan;

  @override
  EntitySchema? get schema;

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
  Future<List<I>> peekAllKeys();

  /// Deletes a model in this table, given its [id].
  ///
  /// If there is no model with the given [id], this method will do nothing.
  Future<void> pop(I id);

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
  Future<void> popKeys(Iterable<I> ids);

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
  Future<void> popAll(BaseFilter<Q> filter);

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
  Future<void> patch(I id, Model? Function(Model?) update);

  /// Removes all models from this table.
  ///
  /// This method should be more efficient than calling [popAll] passing
  /// [Filter.empty] as argument.
  Future<void> purge();
}

/// Represents creating models into the database engine.
abstract class DataRepository<
  Data,
  Model extends Data,
  I extends Object,
  Q extends BaseQuery<Q>,
  C extends Creation<Data, I>
>
    implements ModelRepository<Model, I, Q> {
  /// Converts [creation] into a model and inserts it into its respective table
  /// on the database engine.
  ///
  /// An explicit identity is required for composite primary keys.
  Future<Model> put(C creation);

  /// Converts each [creation] into a model and inserts the models into their
  /// respective table on the database engine.
  ///
  /// Each creation may provide its own dependency and identity request.
  Future<List<Model>> putAll(List<C> creations);
}

/// Represents the controller of the underlying database engine.
class Repository<
  Data,
  Model extends Data,
  I extends Object,
  Q extends BaseQuery<Q>,
  C extends Creation<Data, I>
>
    implements
        DataRepository<Data, Model, I, Q, C>,
        RelationSource<Model, I, Q> {
  final BaseReference<Q> _reference;
  final Entity<Data, Model, I, C> _entity;

  /// Creates a repository by its attributes.
  const Repository({
    required BaseReference<Q> reference,
    required BaseRelationship<Q> relationship,
    required Entity<Data, Model, I, C> entity,
  }) : _reference = reference,
       _entity = entity;

  /// The engine-independent schema of the repository's entity.
  @override
  EntitySchema get schema => _entity.schema;

  @override
  RelationPlan<Model, I> get plan => TableRelationPlan(
    schema: _entity.schema,
    fromJson: _entity.fromJson,
    primaryKeyCodec: _entity.primaryKeyCodec,
  );

  @override
  Future<Model?> peek(I id) {
    return _reference.peek<Data, Model, I>(_entity, id);
  }

  @override
  Future<List<Model>> peekAll([
    BaseFilter<Q> filter = const BaseFilter.empty(),
  ]) {
    return _reference.peekAll<Data, Model, I>(_entity, filter);
  }

  @override
  Future<List<I>> peekAllKeys() {
    return _reference.peekAllKeys<Data, Model, I>(_entity);
  }

  @override
  Future<void> pop(I id) async {
    return _reference.pop<Data, Model, I>(_entity, id);
  }

  @override
  Future<void> popKeys(Iterable<I> ids) {
    return _reference.popKeys<Data, Model, I>(_entity, ids);
  }

  @override
  Future<void> popAll(BaseFilter<Q> filter) {
    return _reference.popAll<Data, Model, I>(_entity, filter);
  }

  @override
  Stream<Model?> pull(I id) {
    return _reference.pull<Data, Model, I>(_entity, id);
  }

  @override
  Stream<List<Model>> pullAll([
    BaseFilter<Q> filter = const BaseFilter.empty(),
  ]) {
    return _reference.pullAll<Data, Model, I>(_entity, filter);
  }

  @override
  Future<Model> put(C creation) async {
    return _reference.put<Data, Model, I, C>(_entity, creation);
  }

  @override
  Future<List<Model>> putAll(List<C> creations) {
    return _reference.putAll<Data, Model, I, C>(_entity, creations);
  }

  @override
  Future<void> push(Model model) async {
    return _reference.push<Data, Model, I>(_entity, model);
  }

  @override
  Future<void> pushAll(List<Model> models) async {
    return _reference.pushAll<Data, Model, I>(_entity, models);
  }

  @override
  Future<void> patch(I id, Model? Function(Model?) update) {
    return _reference.patch<Data, Model, I>(_entity, id, update);
  }

  @override
  Future<void> purge() {
    return _reference.purge<Data, Model, I>(_entity);
  }
}
