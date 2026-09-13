// dORM
// Copyright (C) 2023  Beet Software
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

import 'filter.dart';

/// The portable value kinds understood by migration adapters.
enum MigrationValueType { text, integer, real, boolean, dateTime, json, binary }

/// Describes the strongest transaction boundary a migration adapter provides.
enum MigrationTransactionMode {
  /// All operations and the migration history record share one transaction.
  migration,

  /// Each operation runs in its own transaction boundary.
  operation,

  /// The adapter does not provide rollback for migration work.
  none,
}

/// Describes how an adapter prevents concurrent migration runs.
enum MigrationLockMode {
  /// The lock only coordinates callers within the current process.
  local,

  /// The lock is stored in the backend and has an owner and expiration.
  persistentLease,
}

/// A failure to acquire, renew, verify, or release a migration lease.
final class MigrationLeaseException implements Exception {
  const MigrationLeaseException(this.message);

  final String message;

  @override
  String toString() => 'MigrationLeaseException: $message';
}

/// A backend-owned lease used to coordinate migration runners.
abstract interface class MigrationLease {
  String get owner;

  int get fencingToken;

  DateTime get expiresAt;

  Future<void> renew();

  Future<void> release();
}

/// An optional persistent-lock capability for [MigrationAdapter].
abstract interface class MigrationLeaseAdapter {
  MigrationLockMode get lockMode;

  Future<T> withLease<T>(Future<T> Function(MigrationLease lease) action);
}

/// A normalized view of the schema currently known by a migration backend.
///
/// Implementations may inspect a live database and return this value. Backends
/// without a persistent or inspectable schema do not need to implement the
/// capability.
final class MigrationSchemaSnapshot {
  const MigrationSchemaSnapshot({required this.entities});

  final List<MigrationEntityDefinition> entities;
}

/// An optional capability for reading a backend's live schema.
///
/// This is intentionally separate from [MigrationAdapter]. A document store
/// may support migrations while having no schema that can be inspected in a
/// portable way.
abstract interface class MigrationSchemaInspector {
  Future<MigrationSchemaSnapshot> inspectSchema();
}

/// Describes a field as it is expected to be stored by a migration.
class MigrationFieldDefinition {
  const MigrationFieldDefinition({
    required this.fieldName,
    required this.columnName,
    required this.type,
    this.nullable = true,
    this.hasDefault = false,
    this.defaultValue,
  }) : assert(hasDefault || defaultValue == null);

  final String fieldName;
  final String columnName;
  final MigrationValueType type;
  final bool nullable;
  final bool hasDefault;
  final Object? defaultValue;
}

/// Describes an entity involved in a structural migration.
final class MigrationEntityDefinition {
  const MigrationEntityDefinition({
    required this.entityName,
    required this.tableName,
    required this.fields,
    required this.primaryKeys,
  });

  final String entityName;
  final String tableName;
  final List<MigrationFieldDefinition> fields;
  final List<String> primaryKeys;
}

/// Describes an index expected on an entity.
///
/// Set [unique] to true for a unique index. Backends may implement this as a
/// native unique constraint when their schema model distinguishes the two.
final class MigrationIndexDefinition {
  const MigrationIndexDefinition({
    required this.entityName,
    required this.name,
    required this.fields,
    this.unique = false,
  });

  final String entityName;
  final String name;
  final List<String> fields;
  final bool unique;
}

/// Signals that a backend cannot represent a requested migration operation.
final class MigrationUnsupportedException implements Exception {
  const MigrationUnsupportedException(this.message);

  final String message;

  @override
  String toString() => 'MigrationUnsupportedException: $message';
}

/// A logical database operation that a backend adapter can apply.
sealed class MigrationOperation {
  const MigrationOperation({required this.entityName});

  final String entityName;
}

/// Creates an entity or collection.
final class CreateEntityOperation extends MigrationOperation {
  CreateEntityOperation({required this.entity})
    : super(entityName: entity.entityName);

  final MigrationEntityDefinition entity;
}

/// Removes an entity or collection.
final class DropEntityOperation extends MigrationOperation {
  const DropEntityOperation({required super.entityName});
}

/// Adds a field to an entity.
final class AddFieldOperation extends MigrationOperation {
  const AddFieldOperation({required super.entityName, required this.field});

  final MigrationFieldDefinition field;
}

/// Removes a field from an entity.
final class RemoveFieldOperation extends MigrationOperation {
  const RemoveFieldOperation({required super.entityName, required this.field});

  final String field;
}

/// Renames a stored field without changing its value.
final class RenameFieldOperation extends MigrationOperation {
  const RenameFieldOperation({
    required super.entityName,
    required this.from,
    required this.to,
  });

  final String from;
  final String to;
}

/// Changes the declared definition of an existing field.
final class AlterFieldOperation extends MigrationOperation {
  const AlterFieldOperation({required super.entityName, required this.field});

  final MigrationFieldDefinition field;
}

/// Describes a unique constraint expected on an entity.
final class MigrationUniqueConstraintDefinition {
  const MigrationUniqueConstraintDefinition({
    required this.entityName,
    required this.name,
    required this.fields,
  });

  final String entityName;
  final String name;
  final List<String> fields;
}

/// The referential action applied when a referenced row changes.
enum MigrationReferentialAction { noAction, restrict, cascade, setNull }

/// Describes a foreign key expected on an entity.
final class MigrationForeignKeyDefinition {
  const MigrationForeignKeyDefinition({
    required this.entityName,
    required this.name,
    required this.fields,
    required this.referencedEntity,
    required this.referencedFields,
    this.onDelete = MigrationReferentialAction.noAction,
    this.onUpdate = MigrationReferentialAction.noAction,
  });

  final String entityName;
  final String name;
  final List<String> fields;
  final String referencedEntity;
  final List<String> referencedFields;
  final MigrationReferentialAction onDelete;
  final MigrationReferentialAction onUpdate;
}

/// Describes a SQL trigger managed by a migration.
///
/// [createStatement] must be valid for the target SQL provider. Trigger bodies
/// and trigger functions are intentionally not translated by the framework.
final class MigrationTriggerDefinition {
  const MigrationTriggerDefinition({
    required this.entityName,
    required this.name,
    required this.createStatement,
  });

  final String entityName;
  final String name;
  final String createStatement;
}

/// Creates a SQL trigger.
final class CreateTriggerOperation extends MigrationOperation {
  CreateTriggerOperation({required this.trigger})
    : super(entityName: trigger.entityName);

  final MigrationTriggerDefinition trigger;
}

/// Removes a SQL trigger.
final class DropTriggerOperation extends MigrationOperation {
  const DropTriggerOperation({
    required super.entityName,
    required this.triggerName,
  });

  final String triggerName;
}

/// Describes a database sequence managed by a migration.
final class MigrationSequenceDefinition {
  const MigrationSequenceDefinition({
    required this.name,
    this.startWith = 1,
    this.incrementBy = 1,
  });

  final String name;
  final int startWith;
  final int incrementBy;
}

/// Creates a database sequence.
final class CreateSequenceOperation extends MigrationOperation {
  CreateSequenceOperation({required this.sequence})
    : super(entityName: sequence.name);

  final MigrationSequenceDefinition sequence;
}

/// Removes a database sequence.
final class DropSequenceOperation extends MigrationOperation {
  const DropSequenceOperation({required super.entityName});
}

/// Describes an operation understood only by a named provider.
///
/// This is an explicit escape hatch for schema features that do not belong in
/// the portable contract. The statement is not translated or validated by the
/// framework, and the migration author is responsible for making it safe to
/// retry.
final class ProviderMigrationOperation extends MigrationOperation {
  ProviderMigrationOperation({
    required this.provider,
    required this.name,
    required this.statement,
    this.safety = MigrationOperationSafety.safe,
  }) : super(entityName: name);

  final String provider;
  final String name;
  final String statement;
  final MigrationOperationSafety safety;
}

/// Describes a SQL view managed by a migration.
///
/// [query] is written in the target SQL dialect. The framework does not
/// translate arbitrary view queries between providers.
final class MigrationViewDefinition {
  const MigrationViewDefinition({required this.name, required this.query});

  final String name;
  final String query;
}

/// Creates a SQL view.
final class CreateViewOperation extends MigrationOperation {
  CreateViewOperation({required this.view}) : super(entityName: view.name);

  final MigrationViewDefinition view;
}

/// Removes a SQL view.
final class DropViewOperation extends MigrationOperation {
  const DropViewOperation({required super.entityName});
}

/// Describes a check constraint expected on an entity.
///
/// [expression] uses the syntax of the target provider. It is intentionally
/// explicit because the framework does not translate arbitrary expressions
/// between providers.
final class MigrationCheckConstraintDefinition {
  const MigrationCheckConstraintDefinition({
    required this.entityName,
    required this.name,
    required this.expression,
  });

  final String entityName;
  final String name;
  final String expression;
}

/// Creates a check constraint on an entity.
final class CreateCheckConstraintOperation extends MigrationOperation {
  CreateCheckConstraintOperation({required this.constraint})
    : super(entityName: constraint.entityName);

  final MigrationCheckConstraintDefinition constraint;
}

/// Removes a check constraint from an entity.
final class DropCheckConstraintOperation extends MigrationOperation {
  const DropCheckConstraintOperation({
    required super.entityName,
    required this.constraintName,
  });

  final String constraintName;
}

/// Creates an index or unique index on an entity.
final class CreateIndexOperation extends MigrationOperation {
  CreateIndexOperation({required this.index})
    : super(entityName: index.entityName);

  final MigrationIndexDefinition index;
}

/// Removes an index or unique index from an entity.
final class DropIndexOperation extends MigrationOperation {
  const DropIndexOperation({
    required super.entityName,
    required this.indexName,
  });

  final String indexName;
}

/// Creates a database-level uniqueness constraint.
final class CreateUniqueConstraintOperation extends MigrationOperation {
  CreateUniqueConstraintOperation({required this.constraint})
    : super(entityName: constraint.entityName);

  final MigrationUniqueConstraintDefinition constraint;
}

/// Removes a database-level uniqueness constraint.
final class DropUniqueConstraintOperation extends MigrationOperation {
  const DropUniqueConstraintOperation({
    required super.entityName,
    required this.constraintName,
  });

  final String constraintName;
}

/// Creates a foreign key constraint on an entity.
final class CreateForeignKeyOperation extends MigrationOperation {
  CreateForeignKeyOperation({required this.foreignKey})
    : super(entityName: foreignKey.entityName);

  final MigrationForeignKeyDefinition foreignKey;
}

/// Removes a foreign key constraint from an entity.
final class DropForeignKeyOperation extends MigrationOperation {
  const DropForeignKeyOperation({
    required super.entityName,
    required this.foreignKeyName,
  });

  final String foreignKeyName;
}

/// The supported operations for a declarative field transformation.
enum MigrationTextTransform { trim, lowerCase, upperCase }

/// Describes a typed, provider-neutral value transformation.
sealed class MigrationValueTransform {
  const MigrationValueTransform({required this.outputType});

  final MigrationValueType outputType;
}

/// Copies a value from another stored field.
final class CopyMigrationValue extends MigrationValueTransform {
  const CopyMigrationValue({
    required this.sourceField,
    required super.outputType,
  });

  final String sourceField;
}

/// Applies a text operation to a stored string field.
final class TextMigrationValue extends MigrationValueTransform {
  const TextMigrationValue({required this.sourceField, required this.operation})
    : super(outputType: MigrationValueType.text);

  final String sourceField;
  final MigrationTextTransform operation;
}

/// Converts a stored value to one of the framework's logical types.
final class ConvertMigrationValue extends MigrationValueTransform {
  const ConvertMigrationValue({
    required this.sourceField,
    required super.outputType,
  });

  final String sourceField;
}

/// Transforms values in existing records using a portable expression.
///
/// [filter] is evaluated before the transformation. Adapters that support
/// paging use [batchSize] as their page limit; set-based SQL adapters may
/// execute the same operation as one statement. With [onlyMissing], existing
/// non-null target values are preserved so retries remain safe.
final class TransformFieldOperation extends MigrationOperation {
  const TransformFieldOperation({
    required super.entityName,
    required this.field,
    required this.transform,
    this.filter = const EmptyFilterExpression(),
    this.batchSize = 100,
    this.onlyMissing = true,
  }) : assert(batchSize > 0);

  final String field;
  final MigrationValueTransform transform;
  final FilterExpression filter;
  final int batchSize;
  final bool onlyMissing;
}

/// Writes a constant value to existing records.
///
/// When [onlyMissing] is true, both an absent field and a field whose value
/// is `null` are treated as missing.
final class BackfillFieldOperation extends MigrationOperation {
  const BackfillFieldOperation({
    required super.entityName,
    required this.field,
    required this.value,
    this.onlyMissing = true,
    this.batchSize,
  }) : assert(batchSize == null || batchSize > 0);

  final String field;
  final Object? value;
  final bool onlyMissing;
  final int? batchSize;
}

/// Copies values from one stored field to another.
///
/// When [onlyMissing] is true, both an absent target field and a target whose
/// value is `null` are treated as missing.
final class CopyFieldOperation extends MigrationOperation {
  const CopyFieldOperation({
    required super.entityName,
    required this.from,
    required this.to,
    this.onlyMissing = true,
    this.batchSize,
  }) : assert(batchSize == null || batchSize > 0);

  final String from;
  final String to;
  final bool onlyMissing;
  final int? batchSize;
}

/// Clears a field value on existing records by storing `null`.
///
/// This differs from [RemoveFieldOperation], which removes the field from the
/// stored structure where the backend supports that operation.
final class RemoveFieldValueOperation extends MigrationOperation {
  const RemoveFieldValueOperation({
    required super.entityName,
    required this.field,
    this.batchSize,
  }) : assert(batchSize == null || batchSize > 0);

  final String field;
  final int? batchSize;
}

/// Describes whether an operation can remove or overwrite stored data.
enum MigrationOperationSafety {
  /// The operation does not intentionally remove or overwrite existing data.
  safe,

  /// The operation can remove or overwrite existing data.
  destructive,
}

/// Classifies the data-loss risk of a migration operation.
extension MigrationOperationClassification on MigrationOperation {
  MigrationOperationSafety get safety => switch (this) {
    DropEntityOperation() ||
    RemoveFieldOperation() ||
    RenameFieldOperation() ||
    DropUniqueConstraintOperation() ||
    DropForeignKeyOperation() ||
    DropCheckConstraintOperation() ||
    DropViewOperation() ||
    DropTriggerOperation() ||
    DropSequenceOperation() ||
    RemoveFieldValueOperation() => MigrationOperationSafety.destructive,
    ProviderMigrationOperation(:final safety) => safety,
    BackfillFieldOperation(:final onlyMissing) when !onlyMissing =>
      MigrationOperationSafety.destructive,
    CopyFieldOperation(:final onlyMissing) when !onlyMissing =>
      MigrationOperationSafety.destructive,
    _ => MigrationOperationSafety.safe,
  };

  bool get isDestructive => safety == MigrationOperationSafety.destructive;
}

/// A named, ordered set of operations.
///
/// [id] and [dependsOn] optionally describe a migration graph. Versions remain
/// unique, while dependencies allow independent branches to be merged without
/// relying only on their numeric order.
final class Migration {
  const Migration({
    required this.version,
    required this.name,
    required this.operations,
    this.id,
    this.dependsOn = const <String>[],
  }) : assert(version > 0);

  final int version;
  final String name;
  final List<MigrationOperation> operations;
  final String? id;
  final List<String> dependsOn;

  /// Returns the stable graph identity, falling back to the version.
  String get graphId => id ?? '$version';
}

/// Errors found while validating migration dependencies.
final class MigrationGraphException implements Exception {
  const MigrationGraphException(this.message);

  final String message;

  @override
  String toString() => 'MigrationGraphException: $message';
}

/// Orders migrations while checking optional branch and merge dependencies.
final class MigrationGraph {
  const MigrationGraph._();

  /// Returns a deterministic topological order of [source].
  ///
  /// A migration without dependencies keeps the historical version ordering.
  /// A dependency must identify another migration by [Migration.id], or by its
  /// version converted to text when the dependency has no explicit id.
  static List<Migration> order(Iterable<Migration> source) {
    final List<Migration> migrations = source.toList();
    final Map<int, Migration> byVersion = {};
    final Map<String, Migration> byId = {};
    for (final Migration migration in migrations) {
      if (byVersion.containsKey(migration.version)) {
        throw MigrationGraphException(
          'Migration version ${migration.version} is declared more than once.',
        );
      }
      if (byId.containsKey(migration.graphId)) {
        throw MigrationGraphException(
          'Migration id "${migration.graphId}" is declared more than once.',
        );
      }
      byVersion[migration.version] = migration;
      byId[migration.graphId] = migration;
    }

    final Map<Migration, int> state = {};
    final List<Migration> ordered = [];
    void visit(Migration migration) {
      switch (state[migration] ?? 0) {
        case 1:
          throw MigrationGraphException(
            'Migration dependency cycle includes ${migration.graphId}.',
          );
        case 2:
          return;
        case 0:
          state[migration] = 1;
          for (final String dependency in migration.dependsOn) {
            final Migration? parent =
                byId[dependency] ??
                switch (int.tryParse(dependency)) {
                  int version => byVersion[version],
                  _ => null,
                };
            if (parent == null) {
              throw MigrationGraphException(
                'Migration ${migration.graphId} depends on unknown migration '
                '"$dependency".',
              );
            }
            if (parent.version >= migration.version) {
              throw MigrationGraphException(
                'Migration ${migration.graphId} must depend on an older '
                'migration version.',
              );
            }
            visit(parent);
          }
          state[migration] = 2;
          ordered.add(migration);
      }
    }

    migrations.sort((a, b) => a.version.compareTo(b.version));
    for (final Migration migration in migrations) {
      visit(migration);
    }
    return List.unmodifiable(ordered);
  }
}

/// A migration recorded by a backend.
///
/// A null [checksum] identifies a legacy record created before migration
/// integrity checking was available. Runners must not silently trust such a
/// record as equivalent to a current migration.
final class MigrationHistoryEntry {
  const MigrationHistoryEntry({
    required this.version,
    required this.name,
    this.checksum,
  });

  final int version;
  final String name;
  final String? checksum;
}

/// Applies migrations and stores their completed versions.
///
/// This is an optional engine capability. It is deliberately not part of
/// [BaseEngine], because many engines have no persistent schema to evolve.
abstract interface class MigrationAdapter {
  Future<List<MigrationHistoryEntry>> appliedMigrations();

  Future<T> lock<T>(Future<T> Function() action);

  Future<void> apply(MigrationOperation operation);
  Future<void> record(Migration migration, {required String checksum});
}

/// An optional capability for compacting completed migration history.
///
/// Compaction records [migration] as an externally completed replacement and
/// removes history entries through [through]. It must not execute operations.
/// Adapters should make the replacement idempotent and use their strongest
/// available transaction or lease guarantee.
abstract interface class MigrationHistoryCompactionAdapter {
  Future<void> compactHistory(
    Migration migration, {
    required int through,
    required String checksum,
  });
}

/// An optional transaction capability for [MigrationAdapter].
///
/// The runner uses [transactionMode] to decide whether it should group a
/// complete migration, each operation, or no migration work in a transaction.
/// Adapters must not report a stronger mode than their backend can guarantee.
abstract interface class TransactionalMigrationAdapter {
  MigrationTransactionMode get transactionMode;

  Future<T> transaction<T>(Future<T> Function() action);
}

/// An optional capability implemented by engines with migration support.
abstract interface class MigrationCapableEngine {
  MigrationAdapter get migrationAdapter;
}
