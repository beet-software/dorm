import 'package:dorm_annotations/dorm_annotations.dart';
import 'package:dorm_generator/src/utils/custom_types.dart';
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

class ForeignFieldParser extends AnnotationParser<ForeignField> {
  @override
  final Type annotation = ForeignField;

  @override
  ForeignField parse(ConstantReader reader) {
    return ForeignField(
      name: reader.read('name').stringValue,
      queryBy: reader.read('queryBy').enumValueFrom(QueryType.values),
      referTo: $Type(reader: reader.read('referTo')),
    );
  }
}
