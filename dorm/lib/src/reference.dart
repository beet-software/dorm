import 'dependency.dart';
import 'entity.dart';
import 'filter.dart';

abstract class BaseReference {
  Future<Model?> peek<Data, Model extends Data>(
      Entity<Data, Model> entity, String id);

  Stream<Model?> pull<Data, Model extends Data>(
    Entity<Data, Model> entity,
    String id,
  );

  Future<List<Model>> peekAll<Data, Model extends Data>(
    Entity<Data, Model> entity,
    Filter filter,
  );

  Stream<List<Model>> pullAll<Data, Model extends Data>(
    Entity<Data, Model> entity,
    Filter filter,
  );

  Future<List<String>> peekAllKeys<Data, Model extends Data>(
    Entity<Data, Model> entity,
  );

  Future<void> pop<Data, Model extends Data>(
    Entity<Data, Model> entity,
    String id,
  );

  Future<void> popAll<Data, Model extends Data>(
    Entity<Data, Model> entity,
    Iterable<String> ids,
  );

  Future<void> push<Data, Model extends Data>(
    Entity<Data, Model> entity,
    Model model,
  );

  Future<void> pushAll<Data, Model extends Data>(
    Entity<Data, Model> entity,
    List<Model> models,
  );

  Future<Model> put<Data, Model extends Data>(
    Entity<Data, Model> entity,
    Dependency<Data> dependency,
    Data data,
  );

  Future<List<Model>> putAll<Data, Model extends Data>(
    Entity<Data, Model> entity,
    Dependency<Data> dependency,
    List<Data> datum,
  );
}
