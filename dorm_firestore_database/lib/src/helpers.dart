// dORM
// Copyright (C) 2023  Beet Software
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

import 'package:dorm_framework/dorm_framework.dart';

String firestoreCollectionPath(String tableName, String? parentPath) {
  if (tableName.isEmpty || tableName.contains('/')) {
    throw ArgumentError.value(
      tableName,
      'tableName',
      'Firestore collection names must be a single non-empty path segment.',
    );
  }
  if (parentPath == null || parentPath.isEmpty) return tableName;
  final List<String> segments = parentPath.split('/');
  if (segments.any((segment) => segment.isEmpty) || segments.length.isOdd) {
    throw ArgumentError.value(
      parentPath,
      'parentPath',
      'Firestore parentPath must identify a document.',
    );
  }
  return '$parentPath/$tableName';
}

String firestoreDocumentId(Object id) {
  if (id case String value when value.isNotEmpty && !value.contains('/')) {
    return value;
  }
  throw ArgumentError.value(
    id,
    'id',
    'Cloud Firestore dORM identities must be non-empty String values.',
  );
}

String firestoreDatePrefix(DateTime date, DateFilterUnit unit) {
  final String value = date.toIso8601String();
  return switch (unit) {
    DateFilterUnit.year => value.substring(0, 4),
    DateFilterUnit.month => value.substring(0, 7),
    DateFilterUnit.day => value.substring(0, 10),
    DateFilterUnit.hour => value.substring(0, 13),
    DateFilterUnit.minute => value.substring(0, 16),
    DateFilterUnit.second => value.substring(0, 19),
    DateFilterUnit.milliseconds => value.substring(0, 23),
  };
}

Object firestoreComparableValue(Object value) {
  return value is DateTime ? value.toIso8601String() : value;
}
