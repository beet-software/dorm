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

/// Represents a Dart element annotated with a object of type [DormAnnotation],
/// where [DormAnnotation] is a type exported by `dorm_annotations`.
///
/// There are two direct implementations of this class:
///
/// - a [ClassOrmNode], which is a Dart class annotated with a type [DormAnnotation]
/// - a [FieldOrmNode], which is a Dart getter annotated with a type [Field]
sealed class OrmNode<DormAnnotation> {
  final DormAnnotation annotation;

  const OrmNode({required this.annotation});
}

/// Represents a Dart class annotated with a type [DormAnnotation], where [DormAnnotation] is a type
/// exported by `dorm_annotations`.
sealed class ClassOrmNode<DormAnnotation> extends OrmNode<DormAnnotation> {
  final Map<String, FieldOrmNode> fields;

  const ClassOrmNode({
    required super.annotation,
    required this.fields,
  });
}

/// Represents a Dart class annotated with [Data].
class DataOrmNode extends ClassOrmNode<Data> {
  const DataOrmNode({
    required super.annotation,
    required super.fields,
  });
}

/// Represents a Dart class annotated with [Model].
class ModelOrmNode extends ClassOrmNode<Model> {
  const ModelOrmNode({
    required super.annotation,
    required super.fields,
  });
}

/// Represents a Dart class annotated with [PolymorphicData].
class PolymorphicDataOrmNode extends ClassOrmNode<PolymorphicData> {
  final PolymorphicDataTag tag;

  const PolymorphicDataOrmNode({
    required super.annotation,
    required super.fields,
    required this.tag,
  });
}

/// Represents a Dart getter annotated with [Field] or its subclasses
/// ([ModelField], [ForeignField], [QueryField]).
class FieldOrmNode extends OrmNode<Field> {
  final String type;
  final bool required;

  const FieldOrmNode({
    required super.annotation,
    required this.type,
    required this.required,
  });
}

class PolymorphicDataTag {
  final String value;
  final bool isSealed;

  const PolymorphicDataTag({
    required this.value,
    required this.isSealed,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PolymorphicDataTag &&
          runtimeType == other.runtimeType &&
          value == other.value &&
          isSealed == other.isSealed;

  @override
  int get hashCode => value.hashCode ^ isSealed.hashCode;
}
