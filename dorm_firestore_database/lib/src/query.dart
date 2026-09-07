// dORM
// Copyright (C) 2023  Beet Software
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

import 'package:cloud_firestore/cloud_firestore.dart' as fs;
import 'package:dorm_framework/dorm_framework.dart';

import 'helpers.dart';

/// A [BaseQuery] backed by a Cloud Firestore query.
class Query implements BaseQuery<Query> {
  final fs.Query<Map<String, dynamic>> query;

  const Query(this.query);

  @override
  Query whereValue(String key, Object? value) =>
      Query(query.where(key, isEqualTo: value));

  @override
  Query whereText(String key, String prefix) {
    return Query(
      query
          .where(key, isGreaterThanOrEqualTo: prefix)
          .where(key, isLessThan: '$prefix\uf8ff'),
    );
  }

  @override
  Query whereDate(String key, DateTime date, DateFilterUnit unit) {
    final String prefix = firestoreDatePrefix(date, unit);
    return whereText(key, prefix);
  }

  @override
  Query whereRange<T>(String key, FilterRange<T> range) {
    final Object? from = range.from;
    final Object? to = range.to;
    if (from == null && to == null) return this;

    final DateFilterUnit? unit = range is DateFilterRange
        ? (range as DateFilterRange).unit
        : null;
    final Object? lower = from is DateTime && unit != null
        ? firestoreDatePrefix(from, unit)
        : from == null
        ? null
        : firestoreComparableValue(from);
    final Object? upper = to is DateTime && unit != null
        ? '${firestoreDatePrefix(to, unit)}\uf8ff'
        : to == null
        ? null
        : firestoreComparableValue(to);

    fs.Query<Map<String, dynamic>> result = query;
    if (lower != null) {
      result = result.where(key, isGreaterThanOrEqualTo: lower);
    }
    if (upper != null) {
      result = result.where(key, isLessThanOrEqualTo: upper);
    }
    return Query(result);
  }

  @override
  Query limit(int count) {
    if (count == 0) return this;
    return Query(count > 0 ? query.limit(count) : query.limitToLast(-count));
  }

  @override
  Query offset(int count) {
    if (count < 0) {
      throw ArgumentError.value(count, 'count', 'Offset must be non-negative.');
    }
    if (count == 0) return this;
    throw UnsupportedError(
      'Cloud Firestore offset is applied by the dORM reference.',
    );
  }

  @override
  Query sorted(String key, {bool ascending = true}) =>
      Query(query.orderBy(key, descending: !ascending));
}
