import 'dart:convert';

import 'package:dorm_framework/dorm_framework.dart';
import 'package:sqlite3/sqlite3.dart';

String quoteIdentifier(String value) => '"${value.replaceAll('"', '""')}"';

Object? sqliteValue(Object? value) {
  return switch (value) {
    DateTime date => date.toIso8601String(),
    Map<dynamic, dynamic> map => jsonEncode({
      for (final MapEntry<dynamic, dynamic> entry in map.entries)
        entry.key.toString(): sqliteValue(entry.value),
    }),
    List<dynamic> list => jsonEncode([
      for (final Object? item in list) sqliteValue(item),
    ]),
    _ => value,
  };
}

Map<String, Object?> decodeRow(
  EntitySchema schema,
  Map<String, Object?> row,
  Set<String> booleanColumns,
) {
  final Map<String, Object?> result = {...row};
  for (final String column in booleanColumns) {
    final Object? value = result[column];
    if (value is int && (value == 0 || value == 1)) {
      result[column] = value == 1;
    }
  }
  for (final DerivedFieldSchema field in schema.derivedFields) {
    if (field.path.length == 1) continue;
    final Object? value = result[field.storageName];
    if (value is String) {
      try {
        result[field.storageName] = jsonDecode(value);
      } on FormatException {
        // Preserve malformed or non-JSON values for the entity decoder.
      }
    }
  }
  return result;
}

Map<String, Object?> rowMap(Row row) => {
  for (final String key in row.keys) key: row[key],
};
