import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:source_gen/source_gen.dart';

extension AdditionalReads on ConstantReader {
  T? enumValueFrom<T extends Enum>(List<T> values) {
    if (isNull) return null;
    return values[objectValue.getField('index')!.toIntValue()!];
  }

  String get functionName {
    final DartObject obj = objectValue;
    final ExecutableElement element = obj.toFunctionValue()!;

    final String name = element.name;
    assert(element.isStatic);
    final String? className = element.enclosingElement2.name;
    final String prefix = className == null ? '' : '$className.';
    return '$prefix$name';
  }
}

class $Type implements Type {
  final ConstantReader reader;

  const $Type({required this.reader});

  String get name => reader.typeValue.getDisplayString(withNullability: false);

  @override
  String toString() => '\$Type($name);';
}
