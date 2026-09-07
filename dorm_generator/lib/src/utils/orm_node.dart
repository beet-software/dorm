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

import 'custom_types.dart';

abstract class OrmNode<T> {
  final T annotation;

  const OrmNode({required this.annotation});
}

abstract class ClassOrmNode<T> extends OrmNode<T> {
  const ClassOrmNode({required super.annotation});
}

class FieldedOrmNode<T> extends ClassOrmNode<ClassOrmNode<T>> {
  final Map<String, FieldOrmNode> _fields;

  const FieldedOrmNode({
    required super.annotation,
    required Map<String, FieldOrmNode> fields,
  }) : _fields = fields;

  Map<String, FieldOrmNode> get fields => Map.fromEntries(
    _fields.entries.expand((entry) sync* {
      final Field field = entry.value.annotation;
      if (field is PolymorphicField) {
        final $ConcreteSymbol pivotSymbol = field.pivotAs as $ConcreteSymbol;
        final String pivotKey = field.pivotName;
        yield MapEntry(
          pivotSymbol.name,
          FieldOrmNode(
            annotation: Field(name: pivotKey),
            required: true,
            type: '${entry.value.type.substring(1)}Type',
          ),
        );
      }
      yield entry;
    }),
  );
}

class DataOrmNode extends ClassOrmNode<Data> {
  const DataOrmNode({required super.annotation});
}

class ModelOrmNode extends ClassOrmNode<Model> {
  const ModelOrmNode({required super.annotation});
}

class PolymorphicDataTag {
  final String value;
  final bool isSealed;

  const PolymorphicDataTag({required this.value, required this.isSealed});

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

class PolymorphicDataOrmNode extends ClassOrmNode<PolymorphicData> {
  final PolymorphicDataTag tag;

  const PolymorphicDataOrmNode({required super.annotation, required this.tag});
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
