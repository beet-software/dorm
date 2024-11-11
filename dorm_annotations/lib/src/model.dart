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

/// Allows a class to be serialized.
@Target({TargetKind.classType})
class Data {
  /// Creates a [Data].
  const Data();
}

/// Links a database table to a Dart class.
@Target({TargetKind.classType})
class Model {
  /// Name of the table in the underlying database.
  final String? name;

  /// Name for the Dart repository accessor of this model.
  final Symbol? as;

  /// Unique identification type for this model.
  ///
  /// Should have the signature String Function(_AnnotatedClass, String), where
  /// `_AnnotatedClass` is the class annotated by this [Model] instance.
  final Function? primaryKeyGenerator;

  /// Creates a [Model] by its attributes.
  const Model({
    this.name,
    this.as,
    this.primaryKeyGenerator,
  });
}
