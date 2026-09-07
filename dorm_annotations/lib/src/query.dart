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
import 'helpers.dart';

/// Defines how a derived value should be transformed.
enum DerivedTransform {
  /// Applies the [$normalizeText] transformation.
  ///
  /// This transformation should only be applied to [String]s.
  ///
  /// This should replace diacritics with their ASCII representations, remove
  /// spaces and remove capitalization (all uppercase or all lowercase).
  text,

  /// Applies the [$normalizeEnum] transformation.
  ///
  /// This transformation can be applied to any value, but it is optimized
  /// for [Enum]s and objects whose [Object.toString] representation is
  /// formatted as `ClassName.value`.
  enumeration,
}

/// Defines a persisted value derived from other fields in a model class.
@Target({TargetKind.getter})
class DerivedField extends Field {
  /// Tokens that are combined to produce the derived value.
  final List<DerivedToken> referTo;

  /// String by which the query tokens will be joined by.
  final String joinBy;

  /// Creates a [DerivedField] by its attributes.
  const DerivedField({
    super.name,
    required this.referTo,
    this.joinBy = '_',
  });
}

/// Part of a derived value.
class DerivedToken {
  /// Name of the getter annotated with [Field] or [ForeignField] that this
  /// token refers to.
  final Symbol field;

  /// Transformation applied to this token.
  final DerivedTransform? transform;

  /// Creates a [DerivedToken] by its attribute.
  const DerivedToken(this.field, [this.transform]);
}
