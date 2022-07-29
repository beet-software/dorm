import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/visitor.dart';
import 'package:dorm_annotations/dorm_annotations.dart';
import 'package:source_gen/source_gen.dart';

abstract class AnnotationParser<T> {
  Type get annotation;

  T parse(ConstantReader reader);
}

class FieldParser extends AnnotationParser<Field> {
  @override
  final Type annotation = Field;

  @override
  Field parse(ConstantReader reader) {
    return Field(
      name: reader.read('name').stringValue,
      queryBy: reader.read('queryBy').enumValueFrom(QueryType.values),
    );
  }
}

class ForeignReferrer implements Type {
  final String name;

  const ForeignReferrer({required this.name});

  @override
  String toString() => 'ForeignReferrer($name);';
}

class ForeignFieldParser extends AnnotationParser<ForeignField> {
  @override
  final Type annotation = ForeignField;

  @override
  ForeignField parse(ConstantReader reader) {
    return ForeignField(
      name: reader.read('name').stringValue,
      queryBy: reader.read('queryBy').enumValueFrom(QueryType.values),
      referTo: ForeignReferrer(
          name: reader
              .read('referTo')
              .typeValue
              .getDisplayString(withNullability: false)),
    );
  }
}

extension AdditionalReads on ConstantReader {
  T? enumValueFrom<T extends Enum>(List<T> values) {
    if (isNull) return null;
    return values[objectValue.getField('index')!.toIntValue()!];
  }
}

class ModelVisitor extends SimpleElementVisitor<void> {
  final Map<FieldElement, Field> _fields = {};

  Map<FieldElement, Field> get allFields => Map.unmodifiable(_fields);

  Map<FieldElement, ForeignField> get foreignFields => Map.unmodifiable({
        for (MapEntry<FieldElement, Field> entry in _fields.entries)
          if (entry.value is ForeignField) entry.key: entry.value,
      });

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
