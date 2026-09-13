import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dorm_framework/dorm_framework.dart';

import 'sql.dart';

/// Creates a stable digest for a migration's logical operations.
final class MigrationChecksum {
  const MigrationChecksum._();

  /// Returns the SHA-256 digest of the canonical migration representation.
  static String of(Migration migration) {
    final String source = jsonEncode(_migration(migration));
    return sha256.convert(utf8.encode(source)).toString();
  }

  static Map<String, Object?> _migration(Migration migration) => {
    'version': migration.version,
    'name': migration.name,
    if (migration.id != null) 'id': migration.id,
    if (migration.dependsOn.isNotEmpty) 'dependsOn': migration.dependsOn,
    'operations': [
      for (final MigrationOperation operation in migration.operations)
        _operation(operation),
    ],
  };

  static Map<String, Object?> _operation(MigrationOperation operation) {
    return switch (operation) {
      ProviderMigrationOperation() => {
        'type': 'provider',
        'provider': operation.provider,
        'name': operation.name,
        'statement': operation.statement,
        'safety': operation.safety.name,
      },
      CreateSequenceOperation() => {
        'type': 'createSequence',
        'sequence': _sequence(operation.sequence),
      },
      CreateTriggerOperation() => {
        'type': 'createTrigger',
        'trigger': _trigger(operation.trigger),
      },
      CreateViewOperation() => {
        'type': 'createView',
        'view': _view(operation.view),
      },
      CreateCheckConstraintOperation() => {
        'type': 'createCheckConstraint',
        'constraint': _checkConstraint(operation.constraint),
      },
      CreateEntityOperation() => {
        'type': 'createEntity',
        'entity': _entity(operation.entity),
      },
      DropSequenceOperation() => {
        'type': 'dropSequence',
        'sequenceName': operation.entityName,
      },
      DropTriggerOperation() => {
        'type': 'dropTrigger',
        'entityName': operation.entityName,
        'triggerName': operation.triggerName,
      },
      DropViewOperation() => {
        'type': 'dropView',
        'viewName': operation.entityName,
      },
      DropCheckConstraintOperation() => {
        'type': 'dropCheckConstraint',
        'entityName': operation.entityName,
        'constraintName': operation.constraintName,
      },
      DropEntityOperation() => {
        'type': 'dropEntity',
        'entityName': operation.entityName,
      },
      AddFieldOperation() => {
        'type': 'addField',
        'entityName': operation.entityName,
        'field': _field(operation.field),
      },
      RemoveFieldOperation() => {
        'type': 'removeField',
        'entityName': operation.entityName,
        'field': operation.field,
      },
      RenameFieldOperation() => {
        'type': 'renameField',
        'entityName': operation.entityName,
        'from': operation.from,
        'to': operation.to,
      },
      AlterFieldOperation() => {
        'type': 'alterField',
        'entityName': operation.entityName,
        'field': _field(operation.field),
      },
      CreateIndexOperation() => {
        'type': 'createIndex',
        'index': _index(operation.index),
      },
      CreateUniqueConstraintOperation() => {
        'type': 'createUniqueConstraint',
        'constraint': _constraint(operation.constraint),
      },
      DropIndexOperation() => {
        'type': 'dropIndex',
        'entityName': operation.entityName,
        'indexName': operation.indexName,
      },
      DropUniqueConstraintOperation() => {
        'type': 'dropUniqueConstraint',
        'entityName': operation.entityName,
        'constraintName': operation.constraintName,
      },
      CreateForeignKeyOperation() => {
        'type': 'createForeignKey',
        'foreignKey': _foreignKey(operation.foreignKey),
      },
      DropForeignKeyOperation() => {
        'type': 'dropForeignKey',
        'entityName': operation.entityName,
        'foreignKeyName': operation.foreignKeyName,
      },
      BackfillFieldOperation() => {
        'type': 'backfillField',
        'entityName': operation.entityName,
        'field': operation.field,
        'value': _value(operation.value),
        'onlyMissing': operation.onlyMissing,
        'batchSize': operation.batchSize,
      },
      CopyFieldOperation() => {
        'type': 'copyField',
        'entityName': operation.entityName,
        'from': operation.from,
        'to': operation.to,
        'onlyMissing': operation.onlyMissing,
        'batchSize': operation.batchSize,
      },
      RemoveFieldValueOperation() => {
        'type': 'removeFieldValue',
        'entityName': operation.entityName,
        'field': operation.field,
        'batchSize': operation.batchSize,
      },
      TransformFieldOperation() => {
        'type': 'transformField',
        'entityName': operation.entityName,
        'field': operation.field,
        'transform': _transform(operation.transform),
        'filter': _filter(operation.filter),
        'batchSize': operation.batchSize,
        'onlyMissing': operation.onlyMissing,
      },
    };
  }

  static Map<String, Object?> _transform(MigrationValueTransform transform) {
    return switch (transform) {
      CopyMigrationValue(:final sourceField, :final outputType) => {
        'type': 'copy',
        'sourceField': sourceField,
        'outputType': outputType.name,
      },
      TextMigrationValue(:final sourceField, :final operation) => {
        'type': 'text',
        'sourceField': sourceField,
        'operation': operation.name,
      },
      ConvertMigrationValue(:final sourceField, :final outputType) => {
        'type': 'convert',
        'sourceField': sourceField,
        'outputType': outputType.name,
      },
    };
  }

  static Object? _filter(FilterExpression expression) {
    return switch (expression) {
      EmptyFilterExpression() => {'type': 'empty'},
      ValueFilterExpression(:final field, :final value) => {
        'type': 'value',
        'field': field,
        'value': _value(value),
      },
      TextFilterExpression(:final field, :final prefix) => {
        'type': 'text',
        'field': field,
        'prefix': prefix,
      },
      DateFilterExpression(:final field, :final value, :final unit) => {
        'type': 'date',
        'field': field,
        'value': _value(value),
        'unit': unit.name,
      },
      RangeFilterExpression(:final field, :final range) => {
        'type': 'range',
        'field': field,
        'from': _value(range.from),
        'to': _value(range.to),
      },
      ComparisonFilterExpression(:final field, :final operator, :final value) =>
        {
          'type': 'comparison',
          'field': field,
          'operator': operator.name,
          'value': _value(value),
        },
      SetFilterExpression(:final field, :final values, :final negated) => {
        'type': 'set',
        'field': field,
        'values': [for (final value in values) _value(value)],
        'negated': negated,
      },
      NullFilterExpression(:final field, :final isNull) => {
        'type': 'null',
        'field': field,
        'isNull': isNull,
      },
      ContainsFilterExpression(:final field, :final value) => {
        'type': 'contains',
        'field': field,
        'value': _value(value),
      },
      ContainsAnyFilterExpression(:final field, :final values) => {
        'type': 'containsAny',
        'field': field,
        'values': [for (final value in values) _value(value)],
      },
      AllFilterExpression(:final filters) => {
        'type': 'all',
        'filters': [for (final item in filters) _filter(item)],
      },
      AnyFilterExpression(:final filters) => {
        'type': 'any',
        'filters': [for (final item in filters) _filter(item)],
      },
      NotFilterExpression(:final filter) => {
        'type': 'not',
        'filter': _filter(filter),
      },
    };
  }

  static Map<String, Object?> _sequence(MigrationSequenceDefinition sequence) =>
      {
        'name': sequence.name,
        'startWith': sequence.startWith,
        'incrementBy': sequence.incrementBy,
      };

  static Map<String, Object?> _trigger(MigrationTriggerDefinition trigger) => {
    'entityName': trigger.entityName,
    'name': trigger.name,
    'createStatement': trigger.createStatement,
  };

  static Map<String, Object?> _view(MigrationViewDefinition view) => {
    'name': view.name,
    'query': view.query,
  };

  static Map<String, Object?> _checkConstraint(
    MigrationCheckConstraintDefinition constraint,
  ) => {
    'entityName': constraint.entityName,
    'name': constraint.name,
    'expression': constraint.expression,
  };

  static Map<String, Object?> _index(MigrationIndexDefinition index) => {
    'entityName': index.entityName,
    'name': index.name,
    'fields': index.fields,
    'unique': index.unique,
  };

  static Map<String, Object?> _constraint(
    MigrationUniqueConstraintDefinition constraint,
  ) => {
    'entityName': constraint.entityName,
    'name': constraint.name,
    'fields': constraint.fields,
  };
  static Map<String, Object?> _foreignKey(
    MigrationForeignKeyDefinition foreignKey,
  ) => {
    'entityName': foreignKey.entityName,
    'name': foreignKey.name,
    'fields': foreignKey.fields,
    'referencedEntity': foreignKey.referencedEntity,
    'referencedFields': foreignKey.referencedFields,
    'onDelete': foreignKey.onDelete.name,
    'onUpdate': foreignKey.onUpdate.name,
  };

  static Map<String, Object?> _entity(MigrationEntityDefinition entity) => {
    'entityName': entity.entityName,
    'tableName': entity.tableName,
    'fields': [for (final field in entity.fields) _field(field)],
    'primaryKeys': entity.primaryKeys,
  };

  static Map<String, Object?> _field(MigrationFieldDefinition field) => {
    'fieldName': field.fieldName,
    'columnName': field.columnName,
    'type': field.type.name,
    'nullable': field.nullable,
    'hasDefault': field.hasDefault,
    'defaultValue': _value(field.defaultValue),
    if (field case final SqlMigrationFieldDefinition sqlField)
      'typeOverrides': {
        for (final entry in sqlField.typeOverrides.entries)
          entry.key.name: entry.value,
      },
  };

  static Object? _value(Object? value) {
    if (value == null || value is String || value is num || value is bool) {
      return value;
    }
    if (value is DateTime) {
      return {'dateTime': value.toIso8601String()};
    }
    if (value is Map) {
      if (value.keys.any((key) => key is! String)) {
        throw StateError('Migration checksum maps must use String keys.');
      }
      final List<String> keys = [for (final key in value.keys) key as String]
        ..sort();
      return {for (final String key in keys) key: _value(value[key])};
    }
    if (value is Iterable) {
      return [for (final item in value) _value(item)];
    }
    throw StateError(
      'Cannot calculate a migration checksum for ${value.runtimeType}.',
    );
  }
}
