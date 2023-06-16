import 'package:dorm_annotations/dorm_annotations.dart';

abstract class OrmNode<T> {
  final T annotation;

  const OrmNode({required this.annotation});
}

abstract class ClassOrmNode<T> extends OrmNode<T> {
  const ClassOrmNode({required super.annotation});
}

class FieldedOrmNode<T> extends ClassOrmNode<ClassOrmNode<T>> {
  final Map<String, FieldOrmNode> fields;

  const FieldedOrmNode({
    required super.annotation,
    required this.fields,
  });
}

class ModelOrmNode extends ClassOrmNode<Model> {
  const ModelOrmNode({
    required super.annotation,
  });
}

class PolymorphicDataOrmNode extends ClassOrmNode<PolymorphicData> {
  final String tag;

  const PolymorphicDataOrmNode({
    required super.annotation,
    required this.tag,
  });
}

class FieldOrmNode extends OrmNode<Field> {
  final String type;
  final bool required;

  const FieldOrmNode({
    required super.annotation,
    required this.type,
    required this.required,
  });
}
