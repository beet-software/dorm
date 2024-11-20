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

import 'package:dorm_framework/dorm_framework.dart';

/// Represents how to operate rows within a given database engine.
abstract class BaseReference<Q extends BaseQuery<Q>> {
  /// Defines how the database engine reads a single model, given its [id].
  Future<Model?> peek<Data, Model extends Data>(
    Entity<Data, Model> entity,
    String id,
  );

  /// Defines how the database engine listen to the changes of a single model,
  /// given its [id].
  Stream<Model?> pull<Data, Model extends Data>(
    Entity<Data, Model> entity,
    String id,
  );

  /// Defines how the database engine reads multiple models matching a [filter].
  Future<List<Model>> peekAll<Data, Model extends Data>(
    Entity<Data, Model> entity,
    BaseFilter<Q> filter,
  );

  /// Defines how the database engine listen to the changes of multiple models
  /// matching a [filter].
  Stream<List<Model>> pullAll<Data, Model extends Data>(
    Entity<Data, Model> entity,
    BaseFilter<Q> filter,
  );

  /// Defines how the database engine reads all the keys from the table.
  Future<List<String>> peekAllKeys<Data, Model extends Data>(
    Entity<Data, Model> entity,
  );

  /// Defines how the database engine deletes a single model, given its [id].
  Future<void> pop<Data, Model extends Data>(
    Entity<Data, Model> entity,
    String id,
  );

  /// Defines how the database engine deletes multiple models, given their [ids].
  Future<void> popKeys<Data, Model extends Data>(
    Entity<Data, Model> entity,
    Iterable<String> ids,
  );

  /// Defines how the database engine updates a single [model].
  Future<void> push<Data, Model extends Data>(
    Entity<Data, Model> entity,
    Model model,
  );

  /// Defines how the database engine updates multiple [models].
  Future<void> pushAll<Data, Model extends Data>(
    Entity<Data, Model> entity,
    List<Model> models,
  );

  /// Defines how the database engine deletes multiple models matching a [filter].
  Future<void> popAll<Data, Model extends Data>(
    Entity<Data, Model> entity,
    BaseFilter<Q> filter,
  );

  /// Defines how the database engine updates a single model using [update],
  /// given its [id].
  Future<void> patch<Data, Model extends Data>(
    Entity<Data, Model> entity,
    String id,
    Model? Function(Model?) update,
  );

  /// Defines how the database engine creates a single model, given a
  /// [dependency] and its [data].
  Future<Model> put<Data, Model extends Data>(
    Entity<Data, Model> entity,
    Dependency<Data> dependency,
    Data data,
  );

  /// Defines how the database engine creates multiple models, given a
  /// [dependency] and their [data].
  Future<List<Model>> putAll<Data, Model extends Data>(
    Entity<Data, Model> entity,
    Dependency<Data> dependency,
    List<Data> datum,
  );

  /// Defines how the database engine drops a table.
  Future<void> purge<Data, Model extends Data>(Entity<Data, Model> entity);
}
