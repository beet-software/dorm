import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/visitor.dart';
import 'package:dartx/dartx.dart';
import 'package:dorm_annotations/dorm_annotations.dart';

import 'utils/annotation_parser.dart';
import 'utils/custom_types.dart';

class ClassVisitor extends SimpleElementVisitor<ClassAnnotationData?> {
  final ClassAnnotationParser<ClassAnnotationData> parser;

  const ClassVisitor(this.parser);

  @override
  ClassAnnotationData? visitClassElement(ClassElement element) {
    return parser.parseElement(element);
  }
}

class FieldVisitor extends SimpleElementVisitor<FieldAnnotationData?> {
  final List<FieldAnnotationParser<Field>> children;

  const FieldVisitor(this.children);

  @override
  FieldAnnotationData? visitFieldElement(FieldElement element) {
    return children
        .mapNotNull((parser) => parser.parseElement(element))
        .firstOrNull;
  }
}

const Map<ClassAnnotationParser<Object>, List<FieldAnnotationParser<Field>>> visiting = {
  ModelParser(): [
    ModelFieldParser(),
    ForeignFieldParser(),
    PolymorphicFieldParser(),
    QueryFieldParser(),
    FieldParser(),
  ],
  PolymorphicDataParser(): [FieldParser()],
};

Map<String, ClassAnnotationData<Object>> f(
  Map<ClassAnnotationParser<Object>, List<FieldAnnotationParser<Field>>>
      visiting,
  ClassElement element,
) {
  return visiting.mapValues((entry) => FieldVisitor(entry.value)).mapValues(
      (entry) => element.children
          .whereType<FieldElement>()
          .associateWith(
              (element) => element.accept<FieldAnnotationData?>(entry.value))
          .mapKeys((entry) => entry.key.name)
          .filterValues((data) => data != null)
          .mapValues((entry) => entry.value!));
}
