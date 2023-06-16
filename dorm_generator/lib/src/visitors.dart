import 'package:analyzer/dart/element/element.dart';
import 'package:dorm_annotations/dorm_annotations.dart';
import 'package:source_gen/source_gen.dart';

import 'utils/node_parser.dart';
import 'utils/orm_node.dart';

const Map<ClassNodeParser<Object>, List<FieldNodeParser<Field>>> _visiting = {
  ModelParser(): [
    ModelFieldParser(),
    ForeignFieldParser(),
    PolymorphicFieldParser(),
    QueryFieldParser(),
    FieldParser(),
  ],
  PolymorphicDataParser(): [FieldParser()],
};

Map<String, FieldedOrmNode<Object>> parseLibrary(LibraryReader reader) {
  final Map<String, FieldedOrmNode<Object>> nodes = {};
  for (ClassElement classElement in reader.classes) {
    for (MapEntry<ClassNodeParser<Object>, List<FieldNodeParser<Field>>> entry
        in _visiting.entries) {
      final ClassNodeParser<Object> classParser = entry.key;
      final ClassOrmNode<Object>? classNode =
          classParser.parseElement(classElement);
      if (classNode == null) continue;

      final Map<String, FieldOrmNode> fields = {};
      for (FieldElement fieldElement in classElement.fields) {
        for (FieldNodeParser<Field> fieldParser in entry.value) {
          final FieldOrmNode? fieldNode =
              fieldParser.parseElement(fieldElement);
          if (fieldNode == null) continue;
          fields[fieldElement.name] = fieldNode;
          break;
        }
      }
      nodes[classElement.name] = FieldedOrmNode(
        annotation: classNode,
        fields: fields,
      );
    }
  }
  return nodes;
}
