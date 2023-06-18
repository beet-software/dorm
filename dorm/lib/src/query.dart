import 'filter.dart';

/// Represents how to consider rows within a read or delete operation.
abstract class BaseQuery<T> {
  /// Includes rows where the value of its attribute [key] is equal to [value].
  T whereValue(String key, Object? value);

  /// Includes rows where the value of its the attribute [key] is a String and
  /// starts with [prefix].
  ///
  /// Note that this comparison is not guaranteed to be case-sensitive, so you
  /// should implement strategies to overcome this in engines that do not
  /// support it.
  T whereText(String key, String prefix);

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
  T whereDate(String key, DateTime date, DateFilterUnit unit);

  /// Includes rows where the value of its attribute [key] is inside [range].
  ///
  /// [range] defines the [FilterRange.from] and [FilterRange.to] components,
  /// that can be used to delimit the comparison.
  T whereRange<R>(String key, FilterRange<R> range);

  /// Includes only a [count] number of the rows from the query.
  ///
  /// If [count] is positive, only the first [count] rows are included.
  /// If [count] is negative, only the last abs([count]) rows are included.
  /// If [count] is zero, no row is filtered (all rows are included).
  T limit(int count);
}
