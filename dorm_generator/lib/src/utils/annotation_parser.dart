import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:dorm_annotations/dorm_annotations.dart';
import 'package:source_gen/source_gen.dart';

import 'custom_types.dart';

abstract class AnnotationParser<T> {
  const AnnotationParser();

  Type get annotation => T;

  T parse(ConstantReader reader);

  T? parseElement(Element element) {
    final DartObject? obj =
        TypeChecker.fromRuntime(annotation).firstAnnotationOfExact(element);
    if (obj == null) return null;

    final ConstantReader reader = ConstantReader(obj);
    return parse(reader);
  }
}

class ModelParser extends AnnotationParser<Model> {
  const ModelParser();

  UidType? _decodeUidType(ConstantReader reader) {
    if (reader.isNull) return null;
    final String? uidTypeName =
        reader.objectValue.type?.getDisplayString(withNullability: false);
    if (uidTypeName == null) return null;

    switch (uidTypeName) {
      case '_SimpleUidType':
        return const UidType.simple();
      case '_CompositeUidType':
        return const UidType.composite();
      case '_SameAsUidType':
        final Type type = $Type(reader: reader.read('type'));
        return UidType.sameAs(type);
      case '_CustomUidType':
        return UidType.custom((_) => $CustomUidValue(reader.read('builder')));
    }
    return null;
  }

  @override
  Model parse(ConstantReader reader) {
    return Model(
      name: reader.read('name').stringValue,
      as: $Symbol(reader: reader.read('as')),
      uidType: _decodeUidType(reader.read('uidType')) ?? UidType.simple(),
    );
  }
}

class FieldParser extends AnnotationParser<Field> {
  const FieldParser();

  @override
  Field parse(ConstantReader reader) {
    return Field(
      name: reader.read('name').stringValue,
      defaultValue: reader.read('defaultValue').literalValue,
    );
  }
}

class ForeignFieldParser extends AnnotationParser<ForeignField> {
  const ForeignFieldParser();

  @override
  ForeignField parse(ConstantReader reader) {
    return ForeignField(
      name: reader.read('name').stringValue,
      referTo: $Type(reader: reader.read('referTo')),
    );
  }
}

class ModelFieldParser extends AnnotationParser<ModelField> {
  const ModelFieldParser();

  @override
  ModelField parse(ConstantReader reader) {
    return ModelField(
      name: reader.read('name').stringValue,
      referTo: $Type(reader: reader.read('referTo')),
    );
  }
}

class PolymorphicFieldParser extends AnnotationParser<PolymorphicField> {
  const PolymorphicFieldParser();

  @override
  PolymorphicField parse(ConstantReader reader) {
    return PolymorphicField(
      name: reader.read('name').stringValue,
      pivotName: reader.read('pivotName').stringValue,
    );
  }
}

class QueryFieldParser extends AnnotationParser<QueryField> {
  const QueryFieldParser();

  @override
  QueryField parse(ConstantReader reader) {
    return QueryField(
      name: reader.read('name').stringValue,
      referTo: reader.read('referTo').listValue.map((obj) {
        final ConstantReader reader = ConstantReader(obj);
        return QueryToken(
          $Symbol(reader: reader.read('field')),
          reader.read('type').isNull
              ? null
              : reader.read('type').enumValueFrom(QueryType.values),
        );
      }).toList(),
      joinBy: reader.read('joinBy').stringValue,
    );
  }
}

class PolymorphicDataParser extends AnnotationParser<PolymorphicData> {
  const PolymorphicDataParser();

  @override
  final Type annotation = PolymorphicData;

  @override
  PolymorphicData parse(ConstantReader reader) {
    return PolymorphicData(
      name: reader.read('name').stringValue,
    );
  }
}
