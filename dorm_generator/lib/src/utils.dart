import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:source_gen/source_gen.dart';

class $Type implements Type {
  final ConstantReader reader;

  const $Type({required this.reader});

  String get name => reader.typeValue.getDisplayString(withNullability: false);

  @override
  String toString() => '\$Type($name);';
}

class $Function<T> {
  static String name(ConstantReader reader) {
    final DartObject obj = reader.objectValue;
    final ExecutableElement element = obj.toFunctionValue()!;

    final String name = element.name;
    assert(element.isStatic);
    final String? className = element.enclosingElement2.name;
    final String prefix = className == null ? '' : '$className.';
    return '$prefix$name';
  }

  final ConstantReader reader;

  const $Function({required this.reader});

  Object call(T value) => reader;

  @override
  String toString() => '\$Function($name);';
}
