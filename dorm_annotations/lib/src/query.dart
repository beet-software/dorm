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

/// Defines how a value to be included in a query should be transformed.
enum QueryType {
  /// Applies the [$normalizeText] transformation.
  ///
  /// This type of query type should only be applied in [String]s.
  ///
  /// This should replace diacritics with their ASCII representations, remove
  /// spaces and remove capitalization (all uppercase or all lowercase).
  text,

  /// Applies the [$normalizeEnum] transformation.
  ///
  /// This type of query type can be applied in any value, but it's optimized
  /// for [Enum]s and objects whose [Object.toString] representation is
  /// formatted as `ClassName.value`.
  enumeration,
}

/// Links a database index to a Dart field within a model class.
@Target({TargetKind.getter})
class QueryField extends Field {
  /// Query tokens that the field is combined of.
  final List<QueryToken> referTo;

  /// String by which the query tokens will be joined by.
  final String joinBy;

  /// Creates a [QueryField] by its attributes.
  const QueryField({
    required super.name,
    required this.referTo,
    this.joinBy = '_',
  });
}

/// Part of a query value.
class QueryToken {
  /// Name of the getter annotated with [Field] or [ForeignField] that this
  /// token refers to.
  final Symbol field;

  /// Type of the query of this token.
  final QueryType? type;

  /// Creates a [QueryToken] by its attribute.
  const QueryToken(this.field, [this.type]);
}
