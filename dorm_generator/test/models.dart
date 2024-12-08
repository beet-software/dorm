import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';

class InvalidElement implements Exception {
  final Object? value;

  const InvalidElement(this.value);

  @override
  String toString() {
    return 'InvalidElement($value: ${value.runtimeType})';
  }
}

sealed class CodeToken {
  factory CodeToken.from(Object? value) {
    if (value is CodeToken) {
      return value;
    }
    if (value is Element) {
      return ElementToken(value: value);
    }
    if (value is DartType) {
      return TypeToken(value: value);
    }
    if (value is ElementAnnotation) {
      return AnnotationToken(value: value);
    }
    throw InvalidElement(value);
  }

  String? get name;

  List<ElementAnnotation> get annotations;
}

class ElementToken implements CodeToken {
  final Element value;

  const ElementToken({required this.value});

  @override
  String? get name => value.name;

  @override
  List<ElementAnnotation> get annotations => value.metadata;

  @override
  String toString() => 'ElementToken($name, :${value.runtimeType})';
}

class TypeToken implements CodeToken {
  final DartType value;

  const TypeToken({required this.value});

  @override
  String? get name => value.getDisplayString();

  @override
  final List<ElementAnnotation> annotations = const [];

  @override
  String toString() => 'TypeToken($name)';
}

class AnnotationToken implements CodeToken {
  final ElementAnnotation value;

  const AnnotationToken({required this.value});

  @override
  String? get name => value.computeConstantValue()?.type?.getDisplayString();

  @override
  final List<ElementAnnotation> annotations = const [];

  @override
  String toString() => 'AnnotationToken($name)';
}
