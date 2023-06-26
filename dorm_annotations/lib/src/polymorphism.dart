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

import 'field.dart';

/// Associates a composite object to a [PolymorphicField].
@Target({TargetKind.classType})
class PolymorphicData {
  /// Name of the discriminator value on the pivot column associated with this
  /// data.
  final String name;

  /// Name for the Dart enum value associated with this data.
  final Symbol? as;

  /// Creates a [PolymorphicData] by its attributes.
  const PolymorphicData({required this.name, this.as});
}

/// Links a database composite column and a pivot column to a Dart field within
/// a model class.
@Target({TargetKind.getter})
class PolymorphicField extends Field {
  /// Name of the pivot column in the underlying database.
  final String pivotName;

  /// Name for the pivot Dart field.
  final Symbol? pivotAs;

  /// Creates a [PolymorphicField] by its attributes.
  const PolymorphicField({
    required super.name,
    required this.pivotName,
    this.pivotAs,
  });
}
