import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:meta/meta.dart';
import 'package:source_gen/source_gen.dart';
import 'package:test/test.dart';

import 'matchers.dart';
import 'models.dart';

abstract class MatcherProxy<E, T> {
  Matcher get child;

  T access(E value);
}

class ProxyMatchValue<E, T> implements MatcherProxy<E, T> {
  final T Function(E) accessor;

  @override
  final Matcher child;

  const ProxyMatchValue(this.accessor, this.child);

  @override
  T access(E value) => accessor(value);
}

class HasSuperclass<E extends ClassElement>
    implements MatcherProxy<E, InterfaceType?> {
  final List<Matcher> children;

  const HasSuperclass(this.children);

  @override
  Matcher get child => children.isEmpty ? isNull : HasElement(children);

  @override
  InterfaceType? access(E value) {
    final InterfaceType? supertype = value.supertype;
    if (supertype == null) return null;
    if (supertype.isDartCoreObject) return null;
    return supertype;
  }
}

abstract class ProxyMatchChildren<E, R> implements MatcherProxy<E, List<R>> {
  final List<Matcher> children;

  const ProxyMatchChildren(this.children);

  @override
  @nonVirtual
  Matcher get child => HasValues(children, key: '$runtimeType');
}

class HasClasses extends ProxyMatchChildren<LibraryReader, ClassElement> {
  const HasClasses(super.children);

  @override
  List<ClassElement> access(LibraryReader value) {
    return value.classes.toList();
  }
}

class HasEnums extends ProxyMatchChildren<LibraryReader, EnumElement> {
  const HasEnums(super.children);

  @override
  List<EnumElement> access(LibraryReader value) {
    return value.enums.toList();
  }
}

class HasInterfaces extends ProxyMatchChildren<ClassElement, InterfaceType> {
  const HasInterfaces(super.children);

  @override
  List<InterfaceType> access(ClassElement value) {
    return value.interfaces;
  }
}

class HasExtensions
    extends ProxyMatchChildren<LibraryReader, ExtensionElement> {
  const HasExtensions(super.children);

  @override
  List<ExtensionElement> access(LibraryReader value) {
    return value.allElements.whereType<ExtensionElement>().toList();
  }
}

abstract class HasValuesFrom<E, R> extends ProxyMatchChildren<E, R> {
  final List<R> Function(E) accessor;

  const HasValuesFrom(this.accessor, super.children);

  @override
  List<R> access(E value) => accessor(value);
}

class HasAnnotations<E extends Element>
    extends ProxyMatchChildren<E, ElementAnnotation> {
  const HasAnnotations(super.children);

  @override
  List<ElementAnnotation> access(E value) => value.metadata;
}

class HasFields<E extends Element> extends ProxyMatchChildren<E, FieldElement> {
  const HasFields(super.children);

  @override
  List<FieldElement> access(E value) {
    final List<FieldElement> fields = switch (value) {
      ClassElement(:List<FieldElement> fields) => fields,
      EnumElement(:List<FieldElement> fields) => fields,
      _ => throw InvalidElement(value),
    };
    return fields.where((field) => !field.isSynthetic).toList();
  }
}

class HasMethods<E> extends ProxyMatchChildren<E, MethodElement> {
  const HasMethods(super.children);

  @override
  List<MethodElement> access(E value) {
    return switch (value) {
      ClassElement(:List<MethodElement> methods) => methods,
      ExtensionElement(:List<MethodElement> methods) => methods,
      _ => throw InvalidElement(value),
    };
  }
}

class HasConstructors<E extends ClassElement>
    extends ProxyMatchChildren<E, ConstructorElement> {
  const HasConstructors(super.children);

  @override
  List<ConstructorElement> access(E value) {
    return value.constructors;
  }
}

class HasAccessors<E extends ClassElement>
    extends ProxyMatchChildren<E, PropertyAccessorElement> {
  const HasAccessors(super.children);

  @override
  List<PropertyAccessorElement> access(E value) {
    return value.accessors.where((field) => !field.isSynthetic).toList();
  }
}
