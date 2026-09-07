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

/// Describes a persisted model field without depending on a database engine.
class FieldSchema {
  /// The Dart field represented by this schema field.
  final String fieldName;

  /// The field name used by the underlying storage.
  final String columnName;

  /// Creates a [FieldSchema].
  const FieldSchema({required this.fieldName, required this.columnName});
}

/// Describes a persisted value derived from other model fields.
class DerivedFieldSchema extends FieldSchema {
  /// The path used by the storage adapter.
  final List<String> path;

  /// The physical storage column containing the value.
  final String storageName;

  /// Creates a [DerivedFieldSchema].
  const DerivedFieldSchema({
    required super.fieldName,
    required super.columnName,
    required this.path,
    required this.storageName,
  });
}

/// Describes a foreign key field without depending on a database engine.
class ForeignKeySchema extends FieldSchema {
  /// The target model's storage name.
  final String targetTableName;

  /// The target model's primary-key storage name.
  final String targetColumnName;

  /// Whether this foreign key is unique in the source model.
  final bool unique;

  /// Creates a [ForeignKeySchema].
  const ForeignKeySchema({
    required super.fieldName,
    required super.columnName,
    required this.targetTableName,
    required this.targetColumnName,
    this.unique = false,
  });
}

/// Describes the persisted shape of an entity.
class EntitySchema {
  /// The model's storage name.
  final String tableName;

  /// The ordered fields that make up the primary key.
  ///
  /// A single-field key contains one item; a composite key contains multiple
  /// items.
  final List<FieldSchema> primaryKeys;

  /// The model's persisted fields, excluding [primaryKeys].
  final List<FieldSchema> fields;

  /// The model's generated persisted fields.
  final List<DerivedFieldSchema> derivedFields;

  /// Creates an [EntitySchema].
  const EntitySchema({
    required this.tableName,
    required this.primaryKeys,
    this.fields = const [],
    this.derivedFields = const [],
  });

  /// Whether this schema contains more than one primary-key field.
  bool get isCompositePrimaryKey => primaryKeys.length > 1;

  /// Returns the foreign-key fields declared by [fields].
  Iterable<ForeignKeySchema> get foreignKeys =>
      fields.whereType<ForeignKeySchema>();
}
