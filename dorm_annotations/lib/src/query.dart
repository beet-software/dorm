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

/// Common transformations available to derived-field callbacks.
class DerivedTransformations {
  /// Creates the transformations helper.
  const DerivedTransformations();

  /// Normalizes text for matching.
  String? text(String? value) => $normalizeText(value);

  /// Normalizes an enum-like value for matching.
  String? enumeration(Object? value) => $normalizeEnum(value);

  /// Formats a date as `YYYYMMDD`.
  String? date(DateTime? value) => $normalizeDate(value);

  /// Formats a local date and time as `YYYYMMDDHHmmssSSS`.
  String? datetime(DateTime? value) => $normalizeDateTime(value);
}

/// Defines a persisted value produced by a derived-field callback.
@Target({TargetKind.method})
class DerivedField extends Field {
  /// Creates a [DerivedField] by its attributes.
  const DerivedField({super.name});
}
