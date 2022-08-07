import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/visitor.dart';
import 'package:dorm_annotations/dorm_annotations.dart';
import 'package:source_gen/source_gen.dart';

import 'utils/annotation_parser.dart';

abstract class ModelDescriptor {
  factory ModelDescriptor.describe(Element element) {
    final _ModelVisitor visitor = _ModelVisitor();
    element.visitChildren(visitor);
    return visitor;
  }

  Map<FieldElement, Field> get allFields;

  Map<FieldElement, ForeignField> get foreignFields;

  Map<FieldElement, Field> get ownFields;
}

class _ModelVisitor extends SimpleElementVisitor<void>
    implements ModelDescriptor {
  final Map<FieldElement, Field> _fields = {};

  @override
  Map<FieldElement, Field> get allFields => Map.unmodifiable(_fields);

  @override
  Map<FieldElement, ForeignField> get foreignFields => Map.unmodifiable({
        for (MapEntry<FieldElement, Field> entry in _fields.entries)
          if (entry.value is ForeignField) entry.key: entry.value,
      });

  @override
  Map<FieldElement, Field> get ownFields => Map.unmodifiable({
        for (MapEntry<FieldElement, Field> entry in _fields.entries)
          if (entry.value is! ForeignField) entry.key: entry.value,
      });

  T? _checkFor<T>(AnnotationParser<T> parser, FieldElement element) {
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

  @override
  void visitFieldElement(FieldElement element) {
    final List<AnnotationParser<Object>> parsers = [
      ForeignFieldParser(),
      FieldParser(),
    ];
    for (AnnotationParser<Object> parser in parsers) {
      final Object? parsed = _checkFor<Object>(parser, element);
      if (parsed == null) continue;
      _fields[element] = parsed as Field;
      break;
    }
  }
}
