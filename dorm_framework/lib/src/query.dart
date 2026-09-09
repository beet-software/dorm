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

  /// From previous queries, includes only the first [count] rows.
  Q limit(int count);

  /// From previous queries, skips the first [count] rows.
  Q offset(int count);

  /// From previous queries, sorts the query by the field [key].
  Q sorted(String key, {bool ascending = true});
}

/// Operators for scalar comparisons supported by an extended query.
enum FilterComparisonOperator {
  notEqual,
  lessThan,
  lessThanOrEqual,
  greaterThan,
  greaterThanOrEqual,
}

/// A query that can execute scalar comparisons and set membership filters.
///
/// This is an optional capability. Engines that do not implement this
/// interface intentionally do not expose the corresponding [BaseFilter]
/// factories through their concrete query type.
abstract interface class ComparisonQuery<Q extends ComparisonQuery<Q>>
    implements BaseQuery<Q> {
  Q whereComparison(
    String key,
    FilterComparisonOperator operator,
    Object? value,
  );

  Q whereSet(String key, Iterable<Object?> values, {required bool negated});

  Q whereNull(String key, {required bool isNull});
}

/// A query that can combine filters with boolean conjunction or disjunction.
abstract interface class LogicalQuery<Q extends LogicalQuery<Q>>
    implements BaseQuery<Q> {
  Q whereAll(Iterable<BaseFilter> filters);

  Q whereAny(Iterable<BaseFilter> filters);
}

/// A query that can negate a filter expression.
abstract interface class NegationQuery<Q extends NegationQuery<Q>>
    implements BaseQuery<Q> {
  Q whereNot(BaseFilter filter);
}

/// A query that can test values inside persisted collections.
abstract interface class CollectionQuery<Q extends CollectionQuery<Q>>
    implements BaseQuery<Q> {
  Q whereContains(String key, Object? value);

  Q whereContainsAny(String key, Iterable<Object?> values);
}
