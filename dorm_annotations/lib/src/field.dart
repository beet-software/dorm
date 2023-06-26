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

import 'package:meta/meta_meta.dart';

/// Links a database column to a Dart field within a model class.
@Target({TargetKind.getter})
class Field {
  /// Name of the column in the underlying database.
  final String? name;

  /// Optional default value for the field.
  ///
  /// If not explicitly set and and return type of the annotated getter is
  /// nullable, the field will default to null.
  final Object? defaultValue;

  /// Creates a [Field] by its attributes.
  const Field({this.name, this.defaultValue});
}

/// Links a database foreign key to a Dart field within a model class.
@Target({TargetKind.getter})
class ForeignField extends Field {
  /// The class annotated with [Model] that this field references.
  final Type referTo;

  /// Creates a [ForeignField] by its attributes.
  const ForeignField({required super.name, required this.referTo});
}

/// Links a database composite column to a Dart field within a model class.
@Target({TargetKind.getter})
class ModelField extends Field {
  /// The class annotated with [Model] or [Data] that should be represented
  /// within this field.
  final Type referTo;

  /// Creates a [ModelField] by its attributes.
  const ModelField({required super.name, required this.referTo});
}
