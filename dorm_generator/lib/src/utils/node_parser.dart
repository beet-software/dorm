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

abstract class NodeParser<A, T, E extends Element> {
  const NodeParser();

  Type get annotation => A;

  T? parseElement(Element element) {
    if (element is! E) return null;
    final TypeChecker checker = TypeChecker.fromRuntime(annotation);
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
}

abstract class ClassNodeParser<A>
    extends NodeParser<A, ClassOrmNode<A>, ClassElement> {
  const ClassNodeParser();

  @override
  Element? _childOf(ClassElement element) => element;
}

abstract class FieldNodeParser<A extends Field>
    extends NodeParser<A, FieldOrmNode, FieldElement> {
  const FieldNodeParser();

  @override
  Element? _childOf(FieldElement element) => element.getter;

  @override
  FieldOrmNode _convert(Field annotation, FieldElement element) {
    return FieldOrmNode(
      annotation: annotation,
      type: element.type.getDisplayString(withNullability: true),
      required: element.type.nullabilitySuffix == NullabilitySuffix.none,
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

  UidType? _decodeUidType(ConstantReader reader) {
    if (reader.isNull) return null;
    final String? uidTypeName =
        reader.objectValue.type?.getDisplayString(withNullability: false);
    if (uidTypeName == null) return null;

    switch (uidTypeName) {
      case '_SimpleUidType':
        return const UidType.simple();
      case '_CompositeUidType':
        return const UidType.composite();
      case '_SameAsUidType':
        final Type type = $Type(reader: reader.read('type'));
        return UidType.sameAs(type);
      case '_CustomUidType':
        return UidType.custom((_) => $CustomUidValue(reader.read('builder')));
    }
    return null;
  }

  @override
  Model _parse(ConstantReader reader) {
    return Model(
      name: reader.read('name').stringValue,
      as: $Symbol(reader: reader.read('as')),
      uidType: _decodeUidType(reader.read('uidType')) ?? UidType.simple(),
    );
  }

  @override
  ModelOrmNode _convert(Model annotation, ClassElement element) {
    return ModelOrmNode(annotation: annotation);
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
          .map((type) => type.getDisplayString(withNullability: false))
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
    final InterfaceType supertypeType =
        element.allSupertypes.singleWhere((type) => !type.isDartCoreObject);

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
        value: supertypeType.getDisplayString(withNullability: false),
        isSealed: isSealed,
      ),
    );
  }
}

class FieldParser extends FieldNodeParser<Field> {
  const FieldParser();

  @override
  Field _parse(ConstantReader reader) {
    return Field(
      name: reader.read('name').stringValue,
      defaultValue: reader.read('defaultValue').literalValue,
    );
  }
}

class ForeignFieldParser extends FieldNodeParser<ForeignField> {
  const ForeignFieldParser();

  @override
  ForeignField _parse(ConstantReader reader) {
    return ForeignField(
      name: reader.read('name').stringValue,
      referTo: $Type(reader: reader.read('referTo')),
    );
  }
}

class ModelFieldParser extends FieldNodeParser<ModelField> {
  const ModelFieldParser();

  @override
  ModelField _parse(ConstantReader reader) {
    return ModelField(
      name: reader.read('name').stringValue,
      referTo: $Type(reader: reader.read('referTo')),
    );
  }
}

class QueryFieldParser extends FieldNodeParser<QueryField> {
  const QueryFieldParser();

  @override
  QueryField _parse(ConstantReader reader) {
    return QueryField(
      name: reader.read('name').stringValue,
      referTo: reader.read('referTo').listValue.map((obj) {
        final ConstantReader reader = ConstantReader(obj);
        return QueryToken(
          $Symbol(reader: reader.read('field')),
          reader.read('type').enumValueFrom(QueryType.values),
        );
      }).toList(),
      joinBy: reader.read('joinBy').stringValue,
    );
  }
}

class PolymorphicFieldParser extends FieldNodeParser<PolymorphicField> {
  const PolymorphicFieldParser();

  @override
  PolymorphicField _parse(ConstantReader reader) {
    return PolymorphicField(
      name: reader.read('name').stringValue,
      pivotName: reader.read('pivotName').stringValue,
      pivotAs: $Symbol(reader: reader.read('pivotAs')),
    );
  }
}
