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
import 'package:analyzer/dart/element/visitor.dart';
import 'package:dorm_annotations/dorm_annotations.dart';
import 'package:meta/meta.dart';
import 'package:source_gen/source_gen.dart';

import 'custom_types.dart';
import 'orm_node.dart';

abstract class NodeParser<DormAnnotation, Node, DartElement extends Element>
    extends SimpleElementVisitor<Node?> {
  const NodeParser();

  @nonVirtual
  Type get annotation => DormAnnotation;

  Node? parseElement(Element element) {
    if (element is! DartElement) return null;
    final TypeChecker checker = TypeChecker.fromRuntime(annotation);
    final DartObject? object = () {
      final DartObject? fieldAnnotation = checker.firstAnnotationOf(element);
      if (fieldAnnotation != null) return fieldAnnotation;
      final Element? child = _annotateFrom(element);
      if (child == null) return null;
      return checker.firstAnnotationOf(child);
    }();
    if (object == null) return null;
    if (!_validate(element)) return null;
    final ConstantReader reader = ConstantReader(object);
    return _convert(_parse(element, reader), element);
  }

  bool _validate(DartElement element) => true;

  DormAnnotation _parse(DartElement element, ConstantReader reader);

  Node _convert(DormAnnotation annotation, DartElement element);

  Element? _annotateFrom(DartElement element);
}

abstract class ClassNodeParser<DormAnnotation> extends NodeParser<
    DormAnnotation, ClassOrmNode<DormAnnotation>, ClassElement> {
  const ClassNodeParser();

  List<FieldNodeParser<Field>> get _fieldParsers;

  @override
  Element _annotateFrom(ClassElement element) => element;

  @override
  ClassOrmNode<DormAnnotation>? visitClassElement(ClassElement element) {
    return parseElement(element);
  }

  @override
  @nonVirtual
  ClassOrmNode<DormAnnotation> _convert(
    DormAnnotation annotation,
    ClassElement element,
  ) {
    final Map<String, FieldOrmNode> fields = {};
    for (FieldElement fieldElement in element.fields) {
      for (FieldNodeParser<Field> fieldParser in _fieldParsers) {
        final FieldOrmNode? fieldNode = fieldParser.parseElement(fieldElement);
        if (fieldNode == null) continue;
        fields[fieldElement.name] = fieldNode;
        break;
      }
    }
    return _convertWithFields(annotation, element, fields);
  }

  ClassOrmNode<DormAnnotation> _convertWithFields(
    DormAnnotation annotation,
    ClassElement element,
    Map<String, FieldOrmNode> fields,
  );
}

abstract class FieldNodeParser<DormAnnotation extends Field>
    extends NodeParser<DormAnnotation, FieldOrmNode, FieldElement> {
  const FieldNodeParser();

  @override
  Element? _annotateFrom(FieldElement element) => element.getter;

  @override
  FieldOrmNode? visitFieldElement(FieldElement element) {
    return parseElement(element);
  }

  @override
  FieldOrmNode _convert(Field annotation, FieldElement element) {
    return FieldOrmNode(
      annotation: annotation,
      type: element.type.getDisplayString(withNullability: true),
      required: element.type.nullabilitySuffix == NullabilitySuffix.none,
    );
  }
}

class PolymorphicDataParser extends ClassNodeParser<PolymorphicData> {
  const PolymorphicDataParser();

  @override
  final List<FieldNodeParser<Field>> _fieldParsers = const [
    ModelFieldParser(),
    ForeignFieldParser(),
    FieldParser(),
  ];

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
  PolymorphicData _parse(ClassElement element, ConstantReader reader) {
    return PolymorphicData(
      name: reader.read('name').stringValue,
      as: $Symbol(reader: reader.read('as')),
    );
  }

  @override
  PolymorphicDataOrmNode _convertWithFields(
    PolymorphicData annotation,
    ClassElement element,
    Map<String, FieldOrmNode> fields,
  ) {
    return PolymorphicDataOrmNode(
      annotation: annotation,
      fields: fields,
    );
  }
}

class DataParser extends ClassNodeParser<Data> {
  const DataParser();

  @override
  final List<FieldNodeParser<Field>> _fieldParsers = const [
    ModelFieldParser(),
    FieldParser(),
  ];

  @override
  DataOrmNode _convertWithFields(
    Data annotation,
    ClassElement element,
    Map<String, FieldOrmNode> fields,
  ) {
    return DataOrmNode(
      annotation: annotation,
      fields: fields,
    );
  }

  @override
  Data _parse(ClassElement element, ConstantReader reader) => const Data();
}

class ModelParser extends ClassNodeParser<Model> {
  const ModelParser();

  @override
  final List<FieldNodeParser<Field>> _fieldParsers = const [
    ModelFieldParser(),
    ForeignFieldParser(),
    PolymorphicFieldParser(),
    QueryFieldParser(),
    FieldParser(),
  ];

  @override
  Model _parse(ClassElement element, ConstantReader reader) {
    return Model(
      name: reader.read('name').stringValue,
      as: $Symbol(reader: reader.read('as')),
      primaryKeyGenerator: switch (reader.read('primaryKeyGenerator')) {
        ConstantReader(isNull: true) => null,
        ConstantReader reader => (_, __) => reader.functionName,
      },
    );
  }

  @override
  ModelOrmNode _convertWithFields(
    Model annotation,
    ClassElement element,
    Map<String, FieldOrmNode> fields,
  ) {
    return ModelOrmNode(
      annotation: annotation,
      fields: fields,
    );
  }
}

class FieldParser extends FieldNodeParser<Field> {
  const FieldParser();

  @override
  Field _parse(FieldElement element, ConstantReader reader) {
    late final ConstantReader? defaultValueReader;
    try {
      defaultValueReader = reader.read('defaultValue');
    } on FormatException {
      defaultValueReader = null;
    }
    return Field(
      name: reader.read('name').stringValue,
      defaultValue: defaultValueReader,
    );
  }
}

class ForeignFieldParser extends FieldNodeParser<ForeignField> {
  const ForeignFieldParser();

  @override
  ForeignField _parse(FieldElement element, ConstantReader reader) {
    return ForeignField(
      name: reader.read('name').stringValue,
      referTo: $Type(reader: reader.read('referTo')),
    );
  }
}

class ModelFieldParser extends FieldNodeParser<ModelField> {
  const ModelFieldParser();

  @override
  ModelField _parse(FieldElement element, ConstantReader reader) {
    return ModelField(
      name: reader.read('name').stringValue,
      referTo: $Type(reader: reader.read('referTo')),
    );
  }
}

class QueryFieldParser extends FieldNodeParser<QueryField> {
  const QueryFieldParser();

  @override
  QueryField _parse(FieldElement element, ConstantReader reader) {
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
  PolymorphicField _parse(FieldElement element, ConstantReader reader) {
    return PolymorphicField(
      name: reader.read('name').stringValue,
      pivotName: reader.read('pivotName').stringValue,
      pivotAs: $Symbol(reader: reader.read('pivotAs')),
    );
  }
}
