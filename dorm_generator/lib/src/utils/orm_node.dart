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

abstract class OrmNode<T> {
  final T annotation;

  const OrmNode({required this.annotation});
}

abstract class ClassOrmNode<T> extends OrmNode<T> {
  const ClassOrmNode({required super.annotation});
}

class FieldedOrmNode<T> extends ClassOrmNode<ClassOrmNode<T>> {
  final Map<String, FieldOrmNode> fields;

  const FieldedOrmNode({
    required super.annotation,
    required this.fields,
  });
}

class DataOrmNode extends ClassOrmNode<Data> {
  const DataOrmNode({required super.annotation});
}

class ModelOrmNode extends ClassOrmNode<Model> {
  const ModelOrmNode({
    required super.annotation,
  });
}

class PolymorphicDataOrmNode extends ClassOrmNode<PolymorphicData> {
  final String tag;

  const PolymorphicDataOrmNode({
    required super.annotation,
    required this.tag,
  });
}

class FieldOrmNode extends OrmNode<Field> {
  final String type;
  final bool required;

  const FieldOrmNode({
    required super.annotation,
    required this.type,
    required this.required,
  });
}
