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

import 'package:analyzer/dart/element/element.dart';
import 'package:dorm_annotations/dorm_annotations.dart';
import 'package:source_gen/source_gen.dart';

import 'utils/node_parser.dart';
import 'utils/orm_node.dart';

const Map<ClassNodeParser<Object>, List<FieldNodeParser<Field>>> _visiting = {
  ModelParser(): [
    ModelFieldParser(),
    ForeignFieldParser(),
    PolymorphicFieldParser(),
    DerivedFieldParser(),
    FieldParser(),
  ],
  PolymorphicDataParser(): [
    ModelFieldParser(),
    ForeignFieldParser(),
    FieldParser(),
  ],
  DataParser(): [ModelFieldParser(), FieldParser()],
};

/// Calculates the structure of a *models.dart* file.
///
/// Assuming the *models.dart* file has the following contents,
///
/// ```none
/// @Model(name: 'user', as: #users)
/// abstract class _User {/* ... */}
///
/// @Model(name: 'post')
/// abstract class _Post {/* ... */}
///
/// @Model(name: 'message', as: #messages)
/// abstract class _Message {/* ... */}
/// ```
///
/// calling this function will evaluate a map equivalent to
///
/// ```none
/// {
///   '_User': FieldedOrmNode<Model>(
///     annotation: ModelOrmNode(annotation: Model(name: 'user', as: #users)),
///     fields: {/* ... */},
///   ),
///   '_Post': FieldedOrmNode<Model>(
///     annotation: ModelOrmNode(annotation: Model(name: 'post')),
///     fields: {/* ... */},
///   ),
///   '_Message': FieldedOrmNode<Model>(
///     annotation: ModelOrmNode(annotation: Model(name: 'message', as: #messages)),
///     fields: {/* ... */},
///   ),
/// }
/// ```
Map<String, FieldedOrmNode<Object>> parseLibrary(LibraryReader reader) {
  for (final TopLevelFunctionElement function
      in reader.element.topLevelFunctions) {
    if (function.name!.startsWith(dormDerivedMethodPrefix)) {
      throw StateError(
        '${function.name} must be declared as a static method on the '
        'annotated model class and annotated with DerivedField.',
      );
    }
  }

  final Map<String, FieldedOrmNode<Object>> nodes = {};
  for (ClassElement classElement in reader.classes) {
    for (MapEntry<ClassNodeParser<Object>, List<FieldNodeParser<Field>>> entry
        in _visiting.entries) {
      final ClassNodeParser<Object> classParser = entry.key;
      final ClassOrmNode<Object>? classNode = classParser.parseElement(
        classElement,
      );
      if (classNode == null) continue;

      final Map<String, FieldOrmNode> fields = {};
      for (FieldElement fieldElement in classElement.fields) {
        for (FieldNodeParser<Field> fieldParser in entry.value) {
          final FieldOrmNode? fieldNode = fieldParser.parseElement(
            fieldElement,
          );
          if (fieldNode == null) continue;
          fields[fieldElement.name!] = fieldNode;
          break;
        }
      }
      if (classNode is ModelOrmNode) {
        for (final ExecutableElement inheritedMember
            in classElement.inheritedMembers.values) {
          if (inheritedMember is MethodElement &&
              inheritedMember.name!.startsWith(dormDerivedMethodPrefix)) {
            throw StateError(
              '${classElement.name}.${inheritedMember.name} is inherited. '
              'DerivedField callbacks must be declared directly on the '
              'annotated model class.',
            );
          }
        }
        const DerivedMethodParser methodParser = DerivedMethodParser();
        for (final MethodElement methodElement in classElement.methods) {
          final FieldOrmNode? methodNode = methodParser.parseElement(
            methodElement,
          );
          final bool isReserved = methodElement.name!.startsWith(
            dormDerivedMethodPrefix,
          );
          if (methodNode == null) {
            if (isReserved) {
              throw StateError(
                '${classElement.name}.${methodElement.name} must be '
                'annotated with DerivedField.',
              );
            }
            continue;
          }
          if (!isReserved) {
            fields[methodElement.name!] = methodNode;
            continue;
          }
          final String derivedName = methodElement.name!.substring(
            dormDerivedMethodPrefix.length,
          );
          if (fields.containsKey(derivedName)) {
            throw StateError(
              '${classElement.name}.${methodElement.name} conflicts with '
              'the generated field or getter $derivedName.',
            );
          }
          fields[derivedName] = methodNode;
        }
      }
      nodes[classElement.name!] = FieldedOrmNode(
        annotation: classNode,
        fields: fields,
      );
    }
  }
  return nodes;
}
