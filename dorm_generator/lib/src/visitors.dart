import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/visitor.dart';
import 'package:dorm_annotations/dorm_annotations.dart';
import 'package:dorm_generator/src/generator.dart';
import 'package:source_gen/source_gen.dart';

import 'utils/annotation_parser.dart';
import 'utils/custom_types.dart';

class FieldVisitor extends SimpleElementVisitor<FieldData?> {
  final AnnotationParser parser;
  final List<AnnotationParser<Field>> children;

  const FieldVisitor(this.parser, {required this.children});

  static Field? _checkFor(
      AnnotationParser<Field> parser, FieldElement element) {
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

  bool canVisit(ClassElement element) {
    final DartObject? obj = TypeChecker.fromRuntime(parser.annotation)
        .firstAnnotationOfExact(element);
    return obj != null;
  }

  @override
  FieldData? visitFieldElement(FieldElement element) {
    for (AnnotationParser<Field> parser in children) {
      final Field? field = _checkFor(parser, element);
      if (field == null) continue;
      return FieldData(
        field: field,
        type: element.type.getDisplayString(withNullability: true),
        required: element.type.nullabilitySuffix == NullabilitySuffix.none,
      );
    }
    return null;
  }
}

const Map<AnnotationParser, List<AnnotationParser<Field>>> visiting = {
  ModelParser(): [
    ModelFieldParser(),
    ForeignFieldParser(),
    PolymorphicFieldParser(),
    QueryFieldParser(),
    FieldParser(),
  ],
  PolymorphicDataParser(): [FieldParser()],
};

void f(ClassElement element) {
  final Map<AnnotationParser, Map<String, FieldData>> parsers = {};
  for (MapEntry<AnnotationParser, List<AnnotationParser<Field>>> entry
      in visiting.entries) {
    final AnnotationParser parser = entry.key;
    final Map<String, FieldData> fields = {};
    for (Element child in element.children) {
      if (child is! FieldElement) continue;

      final FieldData? data = child.accept<FieldData?>(
        FieldVisitor(parser, children: entry.value),
      );
      if (data == null) continue;
      fields[child.name] = data;
    }
    parsers[parser] = fields;
  }
  return parsers;
}

class PolymorphicDataVisitor extends Visitor<PolymorphicData, Field> {
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

    final $PolymorphicData data = $PolymorphicData(
      name: annotation.name,
      as: annotation.as,
      fields: datum,
    );

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
      type: element.type.getDisplayString(withNullability: false),
      required: element.type.nullabilitySuffix == NullabilitySuffix.none,
    );
  }
}
