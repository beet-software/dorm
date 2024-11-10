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
import 'package:source_gen/source_gen.dart';

import 'utils/node_parser.dart';
import 'utils/orm_node.dart';

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
///   '_User': ModelOrmNode(
///     annotation: Model(name: 'user', as: #users),
///     fields: {/* ... */},
///   ),
///   '_Post': ModelOrmNode(
///     annotation: Model(name: 'post'),
///     fields: {/* ... */},
///   ),
///   '_Message': ModelOrmNode(
///     annotation: Model(name: 'message', as: #messages),
///     fields: {/* ... */},
///   ),
/// }
/// ```
Map<String, ClassOrmNode<Object>> parseLibrary(LibraryReader reader) {
  const List<ClassNodeParser<Object>> classParsers = [
    ModelParser(),
    PolymorphicDataParser(),
    DataParser(),
  ];

  final Map<String, ClassOrmNode<Object>> nodes = {};
  for (ClassElement classElement in reader.classes) {
    for (ClassNodeParser<Object> classParser in classParsers) {
      final ClassOrmNode<Object>? classNode =
          classParser.parseElement(classElement);
      if (classNode == null) continue;
      nodes[classElement.name] = classNode;
    }
  }
  return nodes;
}
