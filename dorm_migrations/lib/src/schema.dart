import 'package:dorm_framework/dorm_framework.dart';

/// The part of a live schema that differs from the expected schema.
enum MigrationSchemaDifferenceKind {
  missingEntity,
  unexpectedEntity,
  missingField,
  unexpectedField,
  fieldDefinition,
  primaryKey,
}

/// Describes one detected schema difference.
final class MigrationSchemaDifference {
  const MigrationSchemaDifference({
    required this.kind,
    required this.entityName,
    this.fieldName,
    required this.message,
  });

  final MigrationSchemaDifferenceKind kind;
  final String entityName;
  final String? fieldName;
  final String message;

  @override
  String toString() => message;
}

/// The result of comparing an expected schema with a live schema.
final class MigrationSchemaValidationResult {
  const MigrationSchemaValidationResult(this.differences);

  final List<MigrationSchemaDifference> differences;

  bool get isValid => differences.isEmpty;
}

/// Thrown when a live backend schema does not match the expected schema.
final class MigrationSchemaDriftException implements Exception {
  const MigrationSchemaDriftException(this.result);

  final MigrationSchemaValidationResult result;

  @override
  String toString() =>
      'MigrationSchemaDriftException: ${result.differences.join('; ')}';
}

/// Compares normalized schemas without depending on a provider SDK.
final class MigrationSchemaValidator {
  const MigrationSchemaValidator._();

  /// Reads [inspector] and compares its live schema with [expected].
  static Future<MigrationSchemaValidationResult> validate(
    MigrationSchemaInspector inspector,
    MigrationSchemaSnapshot expected, {
    Iterable<String> ignoredEntities = const <String>[],
  }) async {
    final MigrationSchemaSnapshot actual = await inspector.inspectSchema();
    return compare(expected, actual, ignoredEntities: ignoredEntities);
  }

  /// Compares two normalized schemas.
  static MigrationSchemaValidationResult compare(
    MigrationSchemaSnapshot expected,
    MigrationSchemaSnapshot actual, {
    Iterable<String> ignoredEntities = const <String>[],
  }) {
    final Set<String> ignored = ignoredEntities.toSet();
    final Map<String, MigrationEntityDefinition> expectedEntities = {
      for (final MigrationEntityDefinition entity in expected.entities)
        if (!ignored.contains(entity.tableName)) entity.tableName: entity,
    };
    final Map<String, MigrationEntityDefinition> actualEntities = {
      for (final MigrationEntityDefinition entity in actual.entities)
        if (!ignored.contains(entity.tableName)) entity.tableName: entity,
    };
    final List<MigrationSchemaDifference> differences = [];

    for (final MapEntry<String, MigrationEntityDefinition> entry
        in expectedEntities.entries) {
      final MigrationEntityDefinition? actualEntity = actualEntities[entry.key];
      if (actualEntity == null) {
        differences.add(
          MigrationSchemaDifference(
            kind: MigrationSchemaDifferenceKind.missingEntity,
            entityName: entry.key,
            message: 'Missing entity ${entry.key}.',
          ),
        );
        continue;
      }
      _compareEntity(entry.value, actualEntity, differences);
    }
    for (final String tableName in actualEntities.keys) {
      if (!expectedEntities.containsKey(tableName)) {
        differences.add(
          MigrationSchemaDifference(
            kind: MigrationSchemaDifferenceKind.unexpectedEntity,
            entityName: tableName,
            message: 'Unexpected entity $tableName.',
          ),
        );
      }
    }
    return MigrationSchemaValidationResult(List.unmodifiable(differences));
  }

  /// Throws [MigrationSchemaDriftException] when the schemas differ.
  static void requireMatch(MigrationSchemaValidationResult result) {
    if (!result.isValid) throw MigrationSchemaDriftException(result);
  }

  static void _compareEntity(
    MigrationEntityDefinition expected,
    MigrationEntityDefinition actual,
    List<MigrationSchemaDifference> differences,
  ) {
    final Map<String, MigrationFieldDefinition> expectedFields = {
      for (final MigrationFieldDefinition field in expected.fields)
        field.columnName: field,
    };
    final Map<String, MigrationFieldDefinition> actualFields = {
      for (final MigrationFieldDefinition field in actual.fields)
        field.columnName: field,
    };
    for (final MapEntry<String, MigrationFieldDefinition> entry
        in expectedFields.entries) {
      final MigrationFieldDefinition? actualField = actualFields[entry.key];
      if (actualField == null) {
        differences.add(
          MigrationSchemaDifference(
            kind: MigrationSchemaDifferenceKind.missingField,
            entityName: expected.tableName,
            fieldName: entry.key,
            message: 'Missing field ${expected.tableName}.${entry.key}.',
          ),
        );
        continue;
      }
      final MigrationFieldDefinition expectedField = entry.value;
      if (!_sameField(expectedField, actualField)) {
        differences.add(
          MigrationSchemaDifference(
            kind: MigrationSchemaDifferenceKind.fieldDefinition,
            entityName: expected.tableName,
            fieldName: entry.key,
            message:
                'Field ${expected.tableName}.${entry.key} differs: '
                'expected ${_describeField(expectedField)}, '
                'found ${_describeField(actualField)}.',
          ),
        );
      }
    }
    for (final String fieldName in actualFields.keys) {
      if (!expectedFields.containsKey(fieldName)) {
        differences.add(
          MigrationSchemaDifference(
            kind: MigrationSchemaDifferenceKind.unexpectedField,
            entityName: expected.tableName,
            fieldName: fieldName,
            message: 'Unexpected field ${expected.tableName}.$fieldName.',
          ),
        );
      }
    }
    if (!_sameKeys(expected.primaryKeys, actual.primaryKeys)) {
      differences.add(
        MigrationSchemaDifference(
          kind: MigrationSchemaDifferenceKind.primaryKey,
          entityName: expected.tableName,
          message:
              'Primary key for ${expected.tableName} differs: '
              'expected ${expected.primaryKeys}, found ${actual.primaryKeys}.',
        ),
      );
    }
  }

  static bool _sameField(
    MigrationFieldDefinition expected,
    MigrationFieldDefinition actual,
  ) {
    return expected.columnName == actual.columnName &&
        expected.type == actual.type &&
        expected.nullable == actual.nullable &&
        expected.hasDefault == actual.hasDefault &&
        (!expected.hasDefault || _sameDefault(expected, actual));
  }

  static bool _sameDefault(
    MigrationFieldDefinition expected,
    MigrationFieldDefinition actual,
  ) {
    final Object? expectedValue = _normalizeDefault(
      expected.type,
      expected.defaultValue,
    );
    final Object? actualValue = _normalizeDefault(
      actual.type,
      actual.defaultValue,
    );
    if (expectedValue == actualValue) return true;
    if (expectedValue == null || actualValue == null) return false;
    return expectedValue.toString().trim().toLowerCase() ==
        actualValue.toString().trim().toLowerCase();
  }

  static Object? _normalizeDefault(MigrationValueType type, Object? value) {
    if (value == null) return null;
    final String text = value.toString().trim().replaceAll("'", '');
    return switch (type) {
      MigrationValueType.boolean => switch (text.toLowerCase()) {
        '1' || 'true' => true,
        '0' || 'false' => false,
        _ => value,
      },
      MigrationValueType.integer => int.tryParse(text) ?? value,
      MigrationValueType.real => double.tryParse(text) ?? value,
      _ => value,
    };
  }

  static bool _sameKeys(List<String> expected, List<String> actual) {
    if (expected.length != actual.length) return false;
    for (int index = 0; index < expected.length; index++) {
      if (expected[index] != actual[index]) return false;
    }
    return true;
  }

  static String _describeField(MigrationFieldDefinition field) =>
      '${field.type}, nullable=${field.nullable}, '
      'hasDefault=${field.hasDefault}, default=${field.defaultValue}';
}
