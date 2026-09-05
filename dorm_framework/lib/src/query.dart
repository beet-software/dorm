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

import 'filter.dart';

Q f<Q extends BaseQuery<Q>>(Q query) {
  return query.whereValue('active', true).sorted('value');
}

/// Represents how to consider rows within a read or delete operation.
abstract class BaseQuery<Q extends BaseQuery<Q>> {
  /// Includes rows where the value of its attribute [key] is equal to [value].
  Q whereValue(String key, Object? value);

  /// Includes rows where the value of its the attribute [key] is a String and
  /// starts with [prefix].
  ///
  /// Note that this comparison is not guaranteed to be case-sensitive, so you
  /// should implement strategies to overcome this in engines that do not
  /// support it.
  Q whereText(String key, String prefix);

  /// Includes rows where the value of its attribute [key] is a DateTime and has
  /// the same value as [date] comparing by [unit].
  ///
  /// [unit] defines a unit of time that can be used for the comparison. When
  /// comparing two dates, the [DateFilterUnit] determines the level of
  /// granularity for the comparison. In the case where [unit] is set to
  /// [DateFilterUnit.year] and two dates have the same year, the comparison
  /// will evaluate to true. This means that the comparison considers only the
  /// year component of the dates and ignores any differences in the other
  /// units of time.
  ///
  /// Some database engines may not have DateTime as a data type, so it's
  /// allowed to alternatively accept ISO-8601 formatted Strings.
  Q whereDate(String key, DateTime date, DateFilterUnit unit);

  /// Includes rows where the value of its attribute [key] is inside [range].
  ///
  /// [range] defines the [FilterRange.from] and [FilterRange.to] components,
  /// that can be used to delimit the comparison.
  Q whereRange<R>(String key, FilterRange<R> range);

  /// From previous queries, includes only a [count] number of the rows.
  ///
  /// If [count] is positive, only the first [count] rows are included.
  /// If [count] is negative, only the last abs([count]) rows are included.
  /// If [count] is zero, no row is filtered (all rows are included).
  Q limit(int count);

  /// From previous queries, sorts the query by the field [key].
  Q sorted(String key);
}
