import 'dependency.dart';

abstract class Entity<Data, Model extends Data> {
  String get tableName;

  Model fromJson(String id, Map json);

  Model fromData(covariant Dependency<Data> dependency, String id, Data data);

  Map<String, Object?> toJson(Data data);

  String identify(Model model);
}
