import 'dependency.dart';
import 'entity.dart';
import 'filter.dart';

/// Represents how to operate rows within a given database engine.
abstract class BaseReference {
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

  /// Defines how the database engine reads multiple models, given a [filter].
  Future<List<Model>> peekAll<Data, Model extends Data>(
    Entity<Data, Model> entity,
    Filter filter,
  );

  /// Defines how the database engine listen to the changes of multiple models,
  /// given a [filter].
  Stream<List<Model>> pullAll<Data, Model extends Data>(
    Entity<Data, Model> entity,
    Filter filter,
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
  Future<void> popAll<Data, Model extends Data>(
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
}
