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

import 'package:dorm_annotations/dorm_annotations.dart';

sealed class OrmNode {}

class PolymorphicGroupOrmNode implements OrmNode {
  final bool isSealed;
  final Map<String, PolymorphicDataOrmNode> children;

  const PolymorphicGroupOrmNode({
    required this.isSealed,
    required this.children,
  });
}

/// Represents a Dart element annotated with a object of type [DormAnnotation],
/// where [DormAnnotation] is a type exported by `dorm_annotations`.
///
/// There are two direct implementations of this class:
///
/// - a [ClassOrmNode], which is a Dart class annotated with a type [DormAnnotation]
/// - a [FieldOrmNode], which is a Dart getter annotated with a type [Field]
sealed class AnnotatedOrmNode<DormAnnotation> implements OrmNode {
  final DormAnnotation annotation;

  const AnnotatedOrmNode({required this.annotation});
}

/// Represents a Dart class annotated with a type [DormAnnotation], where [DormAnnotation] is a type
/// exported by `dorm_annotations`.
sealed class ClassOrmNode<DormAnnotation>
    extends AnnotatedOrmNode<DormAnnotation> {
  final Map<String, FieldOrmNode> fields;

  const ClassOrmNode({
    required super.annotation,
    required this.fields,
  });
}

sealed class MonomorphicOrmNode<DormAnnotation>
    extends ClassOrmNode<DormAnnotation> {
  const MonomorphicOrmNode({
    required super.annotation,
    required super.fields,
  });
}

/// Represents a Dart class annotated with [Data].
class DataOrmNode extends MonomorphicOrmNode<Data> {
  const DataOrmNode({
    required super.annotation,
    required super.fields,
  });
}

/// Represents a Dart class annotated with [Model].
class ModelOrmNode extends MonomorphicOrmNode<Model> {
  const ModelOrmNode({
    required super.annotation,
    required super.fields,
  });
}

/// Represents a Dart class annotated with [PolymorphicData].
class PolymorphicDataOrmNode extends ClassOrmNode<PolymorphicData> {
  const PolymorphicDataOrmNode({
    required super.annotation,
    required super.fields,
  });
}

/// Represents a Dart getter annotated with [Field] or its subclasses
/// ([ModelField], [ForeignField], [QueryField]).
class FieldOrmNode extends AnnotatedOrmNode<Field> {
  final String type;
  final bool required;

  const FieldOrmNode({
    required super.annotation,
    required this.type,
    required this.required,
  });
}
