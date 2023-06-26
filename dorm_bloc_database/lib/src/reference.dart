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

import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:dorm_framework/dorm_framework.dart';
import 'package:uuid/uuid.dart';

import 'query.dart';

class _State {
  final Map<String, _EntityReference<Object, Object>> references;

  const _State(this.references);

  _EntityReference<Data, Model> access<Data, Model extends Data>(String key) {
    return references[key] as _EntityReference<Data, Model>;
  }
}

const Uuid _uuid = Uuid();

class _EntityState<Model> {
  final Map<String, Model> models;

  const _EntityState(this.models);
}

class _EntityReference<Data, Model extends Data>
    extends Cubit<_EntityState<Model>> {
  final Entity<Data, Model> entity;
  StreamSubscription<void>? _subscription;
  late final StreamController<Map<String, Model>> _controller;

  _EntityReference(this.entity) : super(const _EntityState({})) {
    _controller = StreamController.broadcast(
      onListen: () => _controller.add(state.models),
    );
    _subscription = stream.map((state) => state.models).listen(_controller.add);
  }

  Stream<Map<String, Model>> get dataStream => _controller.stream;

  R _emit<R>(R Function(Map<String, Model> models) action) {
    final Map<String, Model> models = Map.of(state.models);
    final R result = action(models);
    emit(_EntityState(models));
    return result;
  }

  void pop(String id) {
    _emit((models) => models.remove(id));
  }

  void popKeys(Iterable<String> ids) {
    _emit((models) => models.removeWhere((id, _) => ids.contains(id)));
  }

  void push(Model model) {
    _emit((models) => models[entity.identify(model)] = model);
  }

  void pushAll(List<Model> models) {
    _emit((current) {
      current.addAll({
        for (Model model in models) entity.identify(model): model,
      });
    });
  }

  void popAll(TableOperator operator) {
    _emit((models) {
      return operator(
        models.map((key, value) => MapEntry(key, entity.toJson(value))),
      );
    });
  }

  void patch(String id, Model? Function(Model?) update) {
    _emit((models) {
      final Model? model = update(models[id]);
      if (model == null) {
        models.remove(id);
      } else {
        models[id] = model;
      }
    });
  }

  Model put(Dependency<Data> dependency, Data data) {
    return _emit((models) {
      final Model model = entity.fromData(dependency, _uuid.v4(), data);
      models[entity.identify(model)] = model;
      return model;
    });
  }

  List<Model> putAll(Dependency<Data> dependency, List<Data> datum) {
    return _emit((current) {
      final List<Model> models = datum
          .map((data) => entity.fromData(dependency, _uuid.v4(), data))
          .toList();

      current.addAll({
        for (Model model in models) entity.identify(model): model,
      });
      return models;
    });
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}

/// A [BaseReference] implementation backed by a [Bloc].
class Reference extends Cubit<_State> implements BaseReference {
  Reference() : super(const _State({}));

  _EntityReference<Data, Model> _access<Data, Model extends Data>(
    Entity<Data, Model> entity,
  ) {
    final Map<String, _EntityReference<Object, Object>> blocs =
        Map.of(state.references);
    final _EntityReference<Object, Object>? current = blocs[entity.tableName];
    if (current != null) return current as _EntityReference<Data, Model>;
    final _EntityReference<Data, Model> bloc = _EntityReference(entity);
    blocs[entity.tableName] = bloc as _EntityReference<Object, Object>;
    emit(_State(blocs));
    return bloc;
  }

  @override
  Future<Model?> peek<Data, Model extends Data>(
    Entity<Data, Model> entity,
    String id,
  ) async {
    final _EntityReference<Data, Model> bloc = _access(entity);
    return bloc.state.models[id];
  }

  @override
  Future<List<Model>> peekAll<Data, Model extends Data>(
    Entity<Data, Model> entity,
    Filter filter,
  ) async {
    final _EntityReference<Data, Model> bloc = _access(entity);
    final Query query = filter.accept(const Query());
    return query
        .operator(bloc.state.models
            .map((key, value) => MapEntry(key, entity.toJson(value))))
        .entries
        .map((entry) => entity.fromJson(entry.key, entry.value))
        .toList();
  }

  @override
  Future<List<String>> peekAllKeys<Data, Model extends Data>(
    Entity<Data, Model> entity,
  ) async {
    final _EntityReference<Data, Model> bloc = _access(entity);
    return bloc.state.models.keys.toList();
  }

  @override
  Future<void> pop<Data, Model extends Data>(
    Entity<Data, Model> entity,
    String id,
  ) async {
    final _EntityReference<Data, Model> bloc = _access(entity);
    bloc.pop(id);
  }

  @override
  Future<void> popAll<Data, Model extends Data>(
    Entity<Data, Model> entity,
    Filter filter,
  ) async {
    final _EntityReference<Data, Model> bloc = _access(entity);
    final Query query = filter.accept(const Query());
    bloc.popAll(query.operator);
  }

  @override
  Future<void> popKeys<Data, Model extends Data>(
    Entity<Data, Model> entity,
    Iterable<String> ids,
  ) async {
    final _EntityReference<Data, Model> bloc = _access(entity);
    bloc.popKeys(ids.toSet());
  }

  @override
  Stream<Model?> pull<Data, Model extends Data>(
    Entity<Data, Model> entity,
    String id,
  ) {
    final _EntityReference<Data, Model> bloc = _access(entity);
    return bloc.dataStream.map((models) => models[id]);
  }

  @override
  Stream<List<Model>> pullAll<Data, Model extends Data>(
    Entity<Data, Model> entity,
    Filter filter,
  ) {
    final _EntityReference<Data, Model> bloc = _access(entity);
    final Query query = filter.accept(const Query());
    return bloc.dataStream.map((models) => query
        .operator(
            models.map((key, value) => MapEntry(key, entity.toJson(value))))
        .entries
        .map((entry) => entity.fromJson(entry.key, entry.value))
        .toList());
  }

  @override
  Future<void> patch<Data, Model extends Data>(
    Entity<Data, Model> entity,
    String id,
    Model? Function(Model?) update,
  ) async {
    final _EntityReference<Data, Model> bloc = _access(entity);
    bloc.patch(id, update);
  }

  @override
  Future<void> push<Data, Model extends Data>(
    Entity<Data, Model> entity,
    Model model,
  ) async {
    final _EntityReference<Data, Model> bloc = _access(entity);
    bloc.push(model);
  }

  @override
  Future<void> pushAll<Data, Model extends Data>(
    Entity<Data, Model> entity,
    List<Model> models,
  ) async {
    final _EntityReference<Data, Model> bloc = _access(entity);
    bloc.pushAll(models);
  }

  @override
  Future<Model> put<Data, Model extends Data>(
    Entity<Data, Model> entity,
    Dependency<Data> dependency,
    Data data,
  ) async {
    final _EntityReference<Data, Model> bloc = _access(entity);
    return bloc.put(dependency, data);
  }

  @override
  Future<List<Model>> putAll<Data, Model extends Data>(
    Entity<Data, Model> entity,
    Dependency<Data> dependency,
    List<Data> datum,
  ) async {
    final _EntityReference<Data, Model> bloc = _access(entity);
    return bloc.putAll(dependency, datum);
  }
}
