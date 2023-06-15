import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/visitor.dart';
import 'package:dartx/dartx.dart';
import 'package:dorm_annotations/dorm_annotations.dart';

import 'utils/annotation_parser.dart';
import 'utils/custom_types.dart';

class ClassVisitor extends SimpleElementVisitor<ClassData?> {
  final ClassAnnotationParser<ClassData> parser;

  const ClassVisitor(this.parser);

  @override
  ClassData? visitClassElement(ClassElement element) {
    return parser.parseElement(element);
  }
}

class FieldVisitor extends SimpleElementVisitor<FieldData?> {
  final List<FieldAnnotationParser<Field>> children;

  const FieldVisitor(this.children);

  @override
  FieldData? visitFieldElement(FieldElement element) {
    for (FieldAnnotationParser<Field> parser in children) {
      final FieldData? field = parser.parseElement(element);
      if (field == null) continue;
      return field;
    }
    return null;
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

Map<ClassAnnotationParser<Object>, Map<String, FieldData>> f(
  Map<ClassAnnotationParser<Object>, List<FieldAnnotationParser<Field>>> visiting,
  ClassElement element,
) {
  return visiting.mapValues((entry) => FieldVisitor(entry.value)).mapValues(
      (entry) => element.children
          .whereType<FieldElement>()
          .associateWith((element) => element.accept<FieldData?>(entry.value))
          .mapKeys((entry) => entry.key.name)
          .filterValues((data) => data != null)
          .mapValues((entry) => entry.value!));
}

// TODO
// final String supertypeName = element.allSupertypes
//     .singleWhere((type) => !type.isDartCoreObject)
//     .getDisplayString(withNullability: false);
//
// context.polymorphicDatum.putIfAbsent(supertypeName, () => {})[element.name] = data;
