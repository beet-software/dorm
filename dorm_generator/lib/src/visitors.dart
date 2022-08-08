import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/visitor.dart';
import 'package:dorm_annotations/dorm_annotations.dart';
import 'package:dorm_generator/src/generator.dart';
import 'package:source_gen/source_gen.dart';

import 'utils/annotation_parser.dart';
import 'utils/custom_types.dart';

abstract class Visitor<C, F> extends SimpleElementVisitor<void> {
  const Visitor();

  Object? _checkFor(AnnotationParser<Object> parser, FieldElement element) {
    final TypeChecker checker = TypeChecker.fromRuntime(parser.annotation);
    final DartObject? object = () {
      final DartObject? fieldAnnotation = checker.firstAnnotationOf(element);
      if (fieldAnnotation != null) return fieldAnnotation;
      final PropertyAccessorElement? getter = element.getter;
      if (getter == null) return null;
      return checker.firstAnnotationOf(getter);
    }();
    if (object == null) return null;
    final ConstantReader reader = ConstantReader(object);
    return parser.parse(reader);
  }

  Iterable<AnnotationParser<Object>> get parsers;

  bool canVisit(ClassElement element) {
    final DartObject? obj =
        TypeChecker.fromRuntime(C).firstAnnotationOfExact(element);
    return obj != null;
  }

  void onVisit(OrmContext context, ClassElement element);

  void onVisitField(FieldElement element, F value);

  @override
  void visitFieldElement(FieldElement element) {
    for (AnnotationParser<Object> parser in parsers) {
      final Object? parsed = _checkFor(parser, element);
      if (parsed == null) continue;
      onVisitField(element, parsed as F);
      break;
    }
  }
}

class ModelVisitor extends Visitor<Model, Field> {
  final Map<String, $ModelField> _fields = {};

  @override
  Iterable<AnnotationParser<Object>> get parsers =>
      const [ForeignFieldParser(), PolymorphicFieldParser(), FieldParser()];

  @override
  void onVisit(OrmContext context, ClassElement element) {
    element.visitChildren(this);
    final Model? annotation = const ModelParser().parseElement(element);
    if (annotation == null) return;
    context.modelDatum[element.name] = $Model(
      name: annotation.name,
      repositoryName: annotation.repositoryName,
      uidType: annotation.uidType,
      fields: _fields,
    );
  }

  @override
  void onVisitField(FieldElement element, Field value) {
    _fields[element.name] = $ModelField(
      field: value,
      data: VariableData(
        type: element.type.getDisplayString(withNullability: true),
      ),
    );
  }
}

class PolymorphicDataVisitor extends Visitor<PolymorphicData, Field> {
  @override
  final Map<String, $PolymorphicDataField> datum = {};

  @override
  Iterable<AnnotationParser<Object>> get parsers => const [FieldParser()];

  @override
  bool canVisit(ClassElement element) {
    if (!super.canVisit(element)) return false;
    final List<InterfaceType> supertypes = element.allSupertypes;
    if (supertypes.length != 2) {
      final String suffix = supertypes.length < 2
          ? 'none'
          : supertypes
              .map((type) => type.getDisplayString(withNullability: false))
              .join(', ');

      throw StateError(
        'the ${element.name} class annotated with '
        'PolymorphicData should contain a single supertype, found $suffix',
      );
    }
    return true;
  }

  @override
  void onVisit(OrmContext context, ClassElement element) {
    final PolymorphicData? annotation =
        const PolymorphicDataParser().parseElement(element);
    if (annotation == null) return;

    element.visitChildren(this);

    final $PolymorphicData data =
        $PolymorphicData(name: annotation.name, fields: datum);

    final String supertypeName = element.allSupertypes
        .singleWhere((type) => !type.isDartCoreObject)
        .getDisplayString(withNullability: false);

    context.polymorphicDatum
        .putIfAbsent(supertypeName, () => {})[element.name] = data;
  }

  @override
  void onVisitField(FieldElement element, Field value) {
    datum[element.name] = $PolymorphicDataField(
      name: value.name,
      queryBy: value.queryBy,
      variable: VariableData(
        type: element.type.getDisplayString(withNullability: false),
      ),
    );
  }
}
