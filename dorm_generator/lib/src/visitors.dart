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
    QueryFieldParser(),
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
  final Map<String, FieldedOrmNode<Object>> nodes = {};
  for (ClassElement classElement in reader.classes) {
    for (MapEntry<ClassNodeParser<Object>, List<FieldNodeParser<Field>>> entry
        in _visiting.entries) {
      final ClassNodeParser<Object> classParser = entry.key;
      final ClassOrmNode<Object>? classNode =
          classParser.parseElement(classElement);
      if (classNode == null) continue;

      final Map<String, FieldOrmNode> fields = {};
      for (FieldElement fieldElement in classElement.fields) {
        for (FieldNodeParser<Field> fieldParser in entry.value) {
          final FieldOrmNode? fieldNode =
              fieldParser.parseElement(fieldElement);
          if (fieldNode == null) continue;
          fields[fieldElement.name] = fieldNode;
          break;
        }
      }
      nodes[classElement.name] = FieldedOrmNode(
        annotation: classNode,
        fields: fields,
      );
    }
  }
  return nodes;
}
