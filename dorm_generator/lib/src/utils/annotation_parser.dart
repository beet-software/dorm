import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:dorm_annotations/dorm_annotations.dart';
import 'package:source_gen/source_gen.dart';

import 'custom_types.dart';

abstract class AnnotationParser<A, T, E extends Element> {
  const AnnotationParser();

  Type get annotation => A;

  T? parseElement(Element element) {
    if (element is! E) return null;
    if (!_validate(element)) return null;
    final TypeChecker checker = TypeChecker.fromRuntime(annotation);
    final DartObject? object = () {
      final DartObject? fieldAnnotation = checker.firstAnnotationOf(element);
      if (fieldAnnotation != null) return fieldAnnotation;
      final Element? child = childOf(element);
      if (child == null) return null;
      return checker.firstAnnotationOf(child);
    }();
    if (object == null) return null;
    final ConstantReader reader = ConstantReader(object);
    return convert(parse(reader), element);
  }

  bool _validate(E element) => true;

  A parse(ConstantReader reader);

  T convert(A annotation, E element);

  Element? childOf(E element);
}

abstract class ClassAnnotationParser<A>
    extends AnnotationParser<A, ClassData, ClassElement> {
  const ClassAnnotationParser();

  @override
  Element? childOf(ClassElement element) => element;
}

abstract class FieldAnnotationParser<A extends Field>
    extends AnnotationParser<A, FieldAnnotationData, FieldElement> {
  const FieldAnnotationParser();

  @override
  Element? childOf(FieldElement element) => element.getter;

  @override
  FieldAnnotationData convert(Field annotation, FieldElement element) {
    return FieldAnnotationData(
      annotation: annotation,
      type: element.type.getDisplayString(withNullability: true),
      required: element.type.nullabilitySuffix == NullabilitySuffix.none,
    );
  }
}

class ModelParser extends ClassAnnotationParser<Model> {
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

  @override
  ModelClassAnnotationData convert(Model annotation, ClassElement element) {
    return ModelClassAnnotationData(
      annotation: annotation,
      name: annotation.name,
      as: annotation.as as $Symbol?,
    );
  }
}

class PolymorphicDataParser extends ClassAnnotationParser<PolymorphicData> {
  const PolymorphicDataParser();

  @override
  final Type annotation = PolymorphicData;

  @override
  bool _validate(ClassElement element) {
    final List<InterfaceType> supertypes = element.allSupertypes;
    if (supertypes.length != 2) {
      final String suffix;
      if (supertypes.length < 2) {
        suffix = 'none';
      } else {
        suffix = supertypes
            .map((type) => type.getDisplayString(withNullability: false))
            .join(', ');
      }
      throw StateError(
        'the ${element.name} class annotated with PolymorphicData should '
        'contain a single supertype, found $suffix',
      );
    }
    return true;
  }

  @override
  PolymorphicData parse(ConstantReader reader) {
    return PolymorphicData(
      name: reader.read('name').stringValue,
      as: $Symbol(reader: reader.read('as')),
    );
  }

  @override
  ClassData convert(PolymorphicData annotation, ClassElement element) {
    return ClassData(
      annotation: annotation,
      name: annotation.name,
      as: annotation.as as $Symbol?,
    );
  }
}

class FieldParser extends FieldAnnotationParser<Field> {
  const FieldParser();

  @override
  Field parse(ConstantReader reader) {
    return Field(
      name: reader.read('name').stringValue,
      defaultValue: reader.read('defaultValue').literalValue,
    );
  }
}

class ForeignFieldParser extends FieldAnnotationParser<ForeignField> {
  const ForeignFieldParser();

  @override
  ForeignField parse(ConstantReader reader) {
    return ForeignField(
      name: reader.read('name').stringValue,
      referTo: $Type(reader: reader.read('referTo')),
    );
  }
}

class ModelFieldParser extends FieldAnnotationParser<ModelField> {
  const ModelFieldParser();

  @override
  ModelField parse(ConstantReader reader) {
    return ModelField(
      name: reader.read('name').stringValue,
      referTo: $Type(reader: reader.read('referTo')),
    );
  }
}

class QueryFieldParser extends FieldAnnotationParser<QueryField> {
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

class PolymorphicFieldParser extends FieldAnnotationParser<PolymorphicField> {
  const PolymorphicFieldParser();

  @override
  PolymorphicField parse(ConstantReader reader) {
    return PolymorphicField(
      name: reader.read('name').stringValue,
      pivotName: reader.read('pivotName').stringValue,
      pivotAs: $Symbol(reader: reader.read('pivotAs')),
    );
  }
}
