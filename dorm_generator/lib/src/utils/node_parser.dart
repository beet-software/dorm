// dORM
// Copyright (C) 2023  Beet Software
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:dorm_annotations/dorm_annotations.dart';
import 'package:source_gen/source_gen.dart';

import 'custom_types.dart';
import 'orm_node.dart';

String? _optionalString(ConstantReader reader, String field) {
  final ConstantReader value = reader.read(field);
  return value.isNull ? null : value.stringValue;
}

abstract class NodeParser<A, T, E extends Element>
    implements ElementVisitor2<T?> {
  const NodeParser();

  Type get annotation => A;

  T? parseElement(Element element) {
    if (element is! E) return null;
    final TypeChecker checker = TypeChecker.typeNamed(annotation);
    final DartObject? object = () {
      final DartObject? fieldAnnotation = checker.firstAnnotationOf(element);
      if (fieldAnnotation != null) return fieldAnnotation;
      final Element? child = _childOf(element);
      if (child == null) return null;
      return checker.firstAnnotationOf(child);
    }();
    if (object == null) return null;
    if (!_validate(element)) return null;
    final ConstantReader reader = ConstantReader(object);
    return _convert(_parse(reader), element);
  }

  bool _validate(E element) => true;

  A _parse(ConstantReader reader);

  T _convert(A annotation, E element);

  Element? _childOf(E element);

  @override
  T? visitClassElement(ClassElement element) => null;

  @override
  T? visitConstructorElement(ConstructorElement element) => null;

  @override
  T? visitEnumElement(EnumElement element) => null;

  @override
  T? visitExtensionElement(ExtensionElement element) => null;

  @override
  T? visitExtensionTypeElement(ExtensionTypeElement element) => null;

  @override
  T? visitFieldElement(FieldElement element) => null;

  @override
  T? visitFieldFormalParameterElement(FieldFormalParameterElement element) =>
      null;

  @override
  T? visitFormalParameterElement(FormalParameterElement element) => null;

  @override
  T? visitGenericFunctionTypeElement(GenericFunctionTypeElement element) =>
      null;

  @override
  T? visitGetterElement(GetterElement element) => null;

  @override
  T? visitLabelElement(LabelElement element) => null;

  @override
  T? visitLibraryElement(LibraryElement element) => null;

  @override
  T? visitLocalFunctionElement(LocalFunctionElement element) => null;

  @override
  T? visitLocalVariableElement(LocalVariableElement element) => null;

  @override
  T? visitMethodElement(MethodElement element) => null;

  @override
  T? visitMixinElement(MixinElement element) => null;

  @override
  T? visitMultiplyDefinedElement(MultiplyDefinedElement element) => null;

  @override
  T? visitPrefixElement(PrefixElement element) => null;

  @override
  T? visitSetterElement(SetterElement element) => null;

  @override
  T? visitSuperFormalParameterElement(SuperFormalParameterElement element) =>
      null;

  @override
  T? visitTopLevelFunctionElement(TopLevelFunctionElement element) => null;

  @override
  T? visitTopLevelVariableElement(TopLevelVariableElement element) => null;

  @override
  T? visitTypeAliasElement(TypeAliasElement element) => null;

  @override
  T? visitTypeParameterElement(TypeParameterElement element) => null;
}

abstract class ClassNodeParser<A>
    extends NodeParser<A, ClassOrmNode<A>, ClassElement> {
  const ClassNodeParser();

  @override
  Element? _childOf(ClassElement element) => element;

  @override
  ClassOrmNode<A>? visitClassElement(ClassElement element) {
    return parseElement(element);
  }
}

abstract class FieldNodeParser<A extends Field>
    extends NodeParser<A, FieldOrmNode, FieldElement> {
  const FieldNodeParser();

  @override
  Element? _childOf(FieldElement element) => element.getter;

  @override
  FieldOrmNode? visitFieldElement(FieldElement element) {
    return parseElement(element);
  }

  @override
  FieldOrmNode _convert(Field annotation, FieldElement element) {
    return FieldOrmNode(
      annotation: annotation,
      type: element.type.getDisplayString(),
      required: element.type.nullabilitySuffix == NullabilitySuffix.none,
    );
  }
}

abstract class MethodFieldNodeParser<A extends Field>
    extends NodeParser<A, FieldOrmNode, MethodElement> {
  const MethodFieldNodeParser();

  @override
  Element? _childOf(MethodElement element) => element;

  @override
  FieldOrmNode? visitMethodElement(MethodElement element) {
    return parseElement(element);
  }

  @override
  FieldOrmNode _convert(A annotation, MethodElement element) {
    return FieldOrmNode(
      annotation: annotation,
      type: element.returnType.getDisplayString(),
      required: element.returnType.nullabilitySuffix == NullabilitySuffix.none,
      method: element,
    );
  }
}

class DataParser extends ClassNodeParser<Data> {
  const DataParser();

  @override
  DataOrmNode _convert(Data annotation, ClassElement element) {
    return DataOrmNode(annotation: annotation);
  }

  @override
  Data _parse(ConstantReader reader) => const Data();
}

class ModelParser extends ClassNodeParser<Model> {
  const ModelParser();

  IdSpec _parseIdSpec(ConstantReader reader) {
    final String? typeName = reader.objectValue.type?.getDisplayString();
    switch (typeName) {
      case 'GeneratedIdSpec':
        return GeneratedIdSpec(
          as: $Symbol(reader: reader.read('as')),
          name: reader.read('name').stringValue,
          type: $Type(reader: reader.read('type')),
        );
      case 'DatabaseGeneratedIdSpec':
        return DatabaseGeneratedIdSpec(
          as: $Symbol(reader: reader.read('as')),
          name: reader.read('name').stringValue,
          type: $Type(reader: reader.read('type')),
        );
      case 'ExistingIdSpec':
        return ExistingIdSpec(referTo: $Symbol(reader: reader.read('referTo')));
      default:
        throw StateError(
          'Unsupported primary-key specification: ${typeName ?? 'unknown'}',
        );
    }
  }

  @override
  Model _parse(ConstantReader reader) {
    final ConstantReader primaryKeySpecsReader = reader.read('primaryKey');
    return Model(
      name: reader.read('name').stringValue,
      primaryKey: [
        for (final DartObject object in primaryKeySpecsReader.listValue)
          _parseIdSpec(ConstantReader(object)),
      ],
      as: $Symbol(reader: reader.read('as')),
    );
  }

  @override
  ModelOrmNode _convert(Model annotation, ClassElement element) {
    return ModelOrmNode(annotation: annotation, element: element);
  }
}

class PolymorphicDataParser extends ClassNodeParser<PolymorphicData> {
  const PolymorphicDataParser();

  @override
  final Type annotation = PolymorphicData;

  @override
  bool _validate(ClassElement element) {
    final List<InterfaceType> supertypes = element.allSupertypes;
    if (supertypes.length == 2) return true;

    final String suffix;
    if (supertypes.length < 2) {
      suffix = 'none';
    } else {
      suffix = supertypes
          .where((type) => !type.isDartCoreObject)
          .map((type) => type.getDisplayString())
          .join(', ');
    }
    throw StateError(
      'the ${element.name} class annotated with PolymorphicData should '
      'contain a single supertype, found $suffix',
    );
  }

  @override
  PolymorphicData _parse(ConstantReader reader) {
    return PolymorphicData(
      name: reader.read('name').stringValue,
      as: $Symbol(reader: reader.read('as')),
    );
  }

  @override
  PolymorphicDataOrmNode _convert(
    PolymorphicData annotation,
    ClassElement element,
  ) {
    final InterfaceType supertypeType = element.allSupertypes.singleWhere(
      (type) => !type.isDartCoreObject,
    );

    final bool isSealed;
    final InterfaceElement superTypeElement = supertypeType.element;
    if (superTypeElement is ClassElement) {
      isSealed = superTypeElement.isSealed;
    } else {
      isSealed = false;
    }

    return PolymorphicDataOrmNode(
      annotation: annotation,
      tag: PolymorphicDataTag(
        value: supertypeType.getDisplayString(),
        isSealed: isSealed,
      ),
    );
  }
}

class FieldParser extends FieldNodeParser<Field> {
  const FieldParser();

  @override
  Field _parse(ConstantReader reader) {
    late final ConstantReader? defaultValueReader;
    try {
      defaultValueReader = reader.read('defaultValue');
    } on FormatException {
      defaultValueReader = null;
    }
    return Field(
      name: _optionalString(reader, 'name'),
      defaultValue: defaultValueReader,
    );
  }
}

class ForeignFieldParser extends FieldNodeParser<ForeignField> {
  const ForeignFieldParser();

  @override
  ForeignField _parse(ConstantReader reader) {
    return ForeignField(
      name: _optionalString(reader, 'name'),
      referTo: $Type(reader: reader.read('referTo')),
      unique: reader.read('unique').boolValue,
      as: $Symbol(reader: reader.read('as')),
      inverseAs: $Symbol(reader: reader.read('inverseAs')),
    );
  }
}

class ModelFieldParser extends FieldNodeParser<ModelField> {
  const ModelFieldParser();

  @override
  ModelField _parse(ConstantReader reader) {
    return ModelField(
      name: _optionalString(reader, 'name'),
      referTo: $Type(reader: reader.read('referTo')),
      template: $ModelFieldTemplate(reader: reader.read('template')),
    );
  }
}

class DerivedFieldParser extends FieldNodeParser<DerivedField> {
  const DerivedFieldParser();

  @override
  DerivedField _parse(ConstantReader reader) {
    return DerivedField(name: _optionalString(reader, 'name'));
  }
}

class DerivedMethodParser extends MethodFieldNodeParser<DerivedField> {
  const DerivedMethodParser();

  @override
  DerivedField _parse(ConstantReader reader) {
    return DerivedField(name: _optionalString(reader, 'name'));
  }
}

class PolymorphicFieldParser extends FieldNodeParser<PolymorphicField> {
  const PolymorphicFieldParser();

  @override
  PolymorphicField _parse(ConstantReader reader) {
    return PolymorphicField(
      name: _optionalString(reader, 'name'),
      pivotName: reader.read('pivotName').stringValue,
      pivotAs: $ConcreteSymbol(
        reader: reader.read('pivotAs'),
        defaultName: 'type',
      ),
    );
  }
}

