import 'dart:convert';

const int migrationSchemaFormat = 1;

final class SchemaSnapshot {
  const SchemaSnapshot({
    this.format = migrationSchemaFormat,
    required this.entities,
  });

  final int format;
  final List<SchemaEntity> entities;

  Map<String, Object?> toJson() => <String, Object?>{
    'format': format,
    'entities': [
      for (final entity in [...entities]..sort(_compareEntity)) entity.toJson(),
    ],
  };

  String encode() => const JsonEncoder.withIndent('  ').convert(toJson());

  static SchemaSnapshot fromJson(String source) {
    final Object? value = jsonDecode(source);
    if (value is! Map) {
      throw const FormatException('Schema snapshot must be a JSON object.');
    }
    final Object? format = value['format'];
    if (format != migrationSchemaFormat) {
      throw FormatException(
        'Unsupported schema snapshot format: $format. Expected '
        '$migrationSchemaFormat.',
      );
    }
    final Object? entities = value['entities'];
    if (entities is! List) {
      throw const FormatException('Schema snapshot entities must be a list.');
    }
    return SchemaSnapshot(
      format: format as int,
      entities: [
        for (final Object? entity in entities) SchemaEntity.fromJson(entity),
      ]..sort(_compareEntity),
    );
  }
}

final class SchemaEntity {
  const SchemaEntity({
    required this.name,
    required this.tableName,
    required this.fields,
    required this.primaryKeys,
  });

  final String name;
  final String tableName;
  final List<SchemaField> fields;
  final List<String> primaryKeys;

  Map<String, Object?> toJson() => <String, Object?>{
    'name': name,
    'tableName': tableName,
    'primaryKeys': [...primaryKeys]..sort(),
    'fields': [
      for (final field in [...fields]..sort(_compareField)) field.toJson(),
    ],
  };

  static SchemaEntity fromJson(Object? value) {
    if (value is! Map) {
      throw const FormatException('Schema entity must be an object.');
    }
    final Object? fields = value['fields'];
    final Object? primaryKeys = value['primaryKeys'];
    if (fields is! List || primaryKeys is! List) {
      throw const FormatException(
        'Schema entity fields and keys must be lists.',
      );
    }
    return SchemaEntity(
      name: _string(value, 'name'),
      tableName: _string(value, 'tableName'),
      primaryKeys: [for (final Object? key in primaryKeys) key as String]
        ..sort(),
      fields: [for (final Object? field in fields) SchemaField.fromJson(field)]
        ..sort(_compareField),
    );
  }
}

final class SchemaField {
  const SchemaField({
    required this.name,
    required this.columnName,
    required this.dartType,
    required this.logicalType,
    required this.nullable,
    this.modelDefault,
    this.foreignTable,
    this.foreignField,
    this.unique = false,
    this.typeOverrides = const <String, String>{},
  });

  final String name;
  final String columnName;
  final String dartType;
  final String logicalType;
  final bool nullable;
  final String? modelDefault;
  final String? foreignTable;
  final String? foreignField;
  final bool unique;
  final Map<String, String> typeOverrides;
  SchemaField copyWith({
    String? name,
    String? columnName,
    String? dartType,
    String? logicalType,
    bool? nullable,
    String? modelDefault,
    String? foreignTable,
    String? foreignField,
    bool? unique,
    Map<String, String>? typeOverrides,
  }) => SchemaField(
    name: name ?? this.name,
    columnName: columnName ?? this.columnName,
    dartType: dartType ?? this.dartType,
    logicalType: logicalType ?? this.logicalType,
    nullable: nullable ?? this.nullable,
    modelDefault: modelDefault ?? this.modelDefault,
    foreignTable: foreignTable ?? this.foreignTable,
    foreignField: foreignField ?? this.foreignField,
    unique: unique ?? this.unique,
    typeOverrides: typeOverrides ?? this.typeOverrides,
  );

  Map<String, Object?> toJson() => <String, Object?>{
    'name': name,
    'columnName': columnName,
    'dartType': dartType,
    'logicalType': logicalType,
    'nullable': nullable,
    if (modelDefault != null) 'modelDefault': modelDefault,
    if (foreignTable != null) 'foreignTable': foreignTable,
    if (foreignField != null) 'foreignField': foreignField,
    if (unique) 'unique': true,
    if (typeOverrides.isNotEmpty)
      'typeOverrides': {
        for (final key in typeOverrides.keys.toList()..sort())
          key: typeOverrides[key],
      },
  };

  static SchemaField fromJson(Object? value) {
    if (value is! Map) {
      throw const FormatException('Schema field must be an object.');
    }
    final Object? overrides = value['typeOverrides'];
    return SchemaField(
      name: _string(value, 'name'),
      columnName: _string(value, 'columnName'),
      dartType: _string(value, 'dartType'),
      logicalType: _string(value, 'logicalType'),
      nullable: value['nullable'] as bool,
      modelDefault: value['modelDefault'] as String?,
      foreignTable: value['foreignTable'] as String?,
      foreignField: value['foreignField'] as String?,
      unique: value['unique'] as bool? ?? false,
      typeOverrides: overrides is Map
          ? {
              for (final MapEntry<Object?, Object?> entry in overrides.entries)
                entry.key as String: entry.value as String,
            }
          : const <String, String>{},
    );
  }
}

String _string(Map value, String key) {
  final Object? result = value[key];
  if (result is! String || result.isEmpty) {
    throw FormatException('Schema property "$key" must be a non-empty string.');
  }
  return result;
}

int _compareEntity(SchemaEntity a, SchemaEntity b) =>
    a.tableName.compareTo(b.tableName);

int _compareField(SchemaField a, SchemaField b) =>
    a.columnName.compareTo(b.columnName);

final class MigrationSchemaException implements Exception {
  const MigrationSchemaException(this.message);

  final String message;

  @override
  String toString() => 'MigrationSchemaException: $message';
}

final class MigrationConfig {
  const MigrationConfig({
    this.typeOverrides = const <String, Map<String, Map<String, String>>>{},
  });

  final Map<String, Map<String, Map<String, String>>> typeOverrides;
}
