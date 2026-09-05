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
  const FieldSchema({
    required this.fieldName,
    required this.columnName,
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

  /// The model's primary key field.
  final FieldSchema primaryKey;

  /// The model's persisted fields, excluding [primaryKey].
  final List<FieldSchema> fields;

  /// Creates an [EntitySchema].
  const EntitySchema({
    required this.tableName,
    required this.primaryKey,
    this.fields = const [],
  });

  /// Returns the foreign-key fields declared by [fields].
  Iterable<ForeignKeySchema> get foreignKeys =>
      fields.whereType<ForeignKeySchema>();
}
