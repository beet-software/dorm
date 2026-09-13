import 'package:dorm_migrations/dorm_migrations.dart';
import 'package:test/test.dart';

void main() {
  test('validates a live schema against the expected schema', () {
    const MigrationEntityDefinition expectedUsers = MigrationEntityDefinition(
      entityName: 'User',
      tableName: 'users',
      fields: [
        MigrationFieldDefinition(
          fieldName: 'id',
          columnName: 'id',
          type: MigrationValueType.integer,
          nullable: false,
        ),
        MigrationFieldDefinition(
          fieldName: 'name',
          columnName: 'name',
          type: MigrationValueType.text,
        ),
      ],
      primaryKeys: ['id'],
    );
    const MigrationEntityDefinition actualUsers = MigrationEntityDefinition(
      entityName: 'users',
      tableName: 'users',
      fields: [
        MigrationFieldDefinition(
          fieldName: 'id',
          columnName: 'id',
          type: MigrationValueType.integer,
          nullable: false,
        ),
        MigrationFieldDefinition(
          fieldName: 'name',
          columnName: 'name',
          type: MigrationValueType.text,
        ),
      ],
      primaryKeys: ['id'],
    );

    final MigrationSchemaValidationResult result =
        MigrationSchemaValidator.compare(
          const MigrationSchemaSnapshot(entities: [expectedUsers]),
          const MigrationSchemaSnapshot(entities: [actualUsers]),
        );

    expect(result.isValid, isTrue);
  });

  test('reports missing and unexpected schema elements', () {
    final MigrationSchemaValidationResult result =
        MigrationSchemaValidator.compare(
          const MigrationSchemaSnapshot(
            entities: [
              MigrationEntityDefinition(
                entityName: 'User',
                tableName: 'users',
                fields: [
                  MigrationFieldDefinition(
                    fieldName: 'id',
                    columnName: 'id',
                    type: MigrationValueType.integer,
                  ),
                  MigrationFieldDefinition(
                    fieldName: 'name',
                    columnName: 'name',
                    type: MigrationValueType.text,
                  ),
                ],
                primaryKeys: ['id'],
              ),
            ],
          ),
          const MigrationSchemaSnapshot(
            entities: [
              MigrationEntityDefinition(
                entityName: 'users',
                tableName: 'users',
                fields: [
                  MigrationFieldDefinition(
                    fieldName: 'id',
                    columnName: 'id',
                    type: MigrationValueType.text,
                  ),
                  MigrationFieldDefinition(
                    fieldName: 'createdAt',
                    columnName: 'created_at',
                    type: MigrationValueType.dateTime,
                  ),
                ],
                primaryKeys: [],
              ),
              MigrationEntityDefinition(
                entityName: 'audit',
                tableName: 'audit',
                fields: const [],
                primaryKeys: const [],
              ),
            ],
          ),
        );

    expect(
      result.differences.map((difference) => difference.kind),
      containsAllInOrder([
        MigrationSchemaDifferenceKind.fieldDefinition,
        MigrationSchemaDifferenceKind.missingField,
        MigrationSchemaDifferenceKind.unexpectedField,
        MigrationSchemaDifferenceKind.primaryKey,
        MigrationSchemaDifferenceKind.unexpectedEntity,
      ]),
    );
    expect(
      () => MigrationSchemaValidator.requireMatch(result),
      throwsA(isA<MigrationSchemaDriftException>()),
    );
  });

  test('detects a changed default value', () {
    const MigrationEntityDefinition expected = MigrationEntityDefinition(
      entityName: 'User',
      tableName: 'users',
      fields: [
        MigrationFieldDefinition(
          fieldName: 'active',
          columnName: 'active',
          type: MigrationValueType.boolean,
          hasDefault: true,
          defaultValue: true,
        ),
      ],
      primaryKeys: [],
    );
    const MigrationEntityDefinition actual = MigrationEntityDefinition(
      entityName: 'User',
      tableName: 'users',
      fields: [
        MigrationFieldDefinition(
          fieldName: 'active',
          columnName: 'active',
          type: MigrationValueType.boolean,
          hasDefault: true,
          defaultValue: false,
        ),
      ],
      primaryKeys: [],
    );

    final MigrationSchemaValidationResult result =
        MigrationSchemaValidator.compare(
          const MigrationSchemaSnapshot(entities: [expected]),
          const MigrationSchemaSnapshot(entities: [actual]),
        );

    expect(result.differences, hasLength(1));
    expect(
      result.differences.single.kind,
      MigrationSchemaDifferenceKind.fieldDefinition,
    );
  });
  test('normalizes equivalent SQL boolean defaults', () {
    const MigrationEntityDefinition expected = MigrationEntityDefinition(
      entityName: 'User',
      tableName: 'users',
      fields: [
        MigrationFieldDefinition(
          fieldName: 'active',
          columnName: 'active',
          type: MigrationValueType.boolean,
          hasDefault: true,
          defaultValue: false,
        ),
      ],
      primaryKeys: [],
    );
    const MigrationEntityDefinition actual = MigrationEntityDefinition(
      entityName: 'User',
      tableName: 'users',
      fields: [
        MigrationFieldDefinition(
          fieldName: 'active',
          columnName: 'active',
          type: MigrationValueType.boolean,
          hasDefault: true,
          defaultValue: '0',
        ),
      ],
      primaryKeys: [],
    );

    expect(
      MigrationSchemaValidator.compare(
        const MigrationSchemaSnapshot(entities: [expected]),
        const MigrationSchemaSnapshot(entities: [actual]),
      ).isValid,
      isTrue,
    );
  });
  test('SQL adapter reads SQLite schema metadata', () async {
    final SqlMigrationAdapter adapter = SqlMigrationAdapter(
      _SqlSchemaBackend(),
      dialect: SqlMigrationDialect.sqlite,
    );

    final MigrationSchemaSnapshot snapshot = await adapter.inspectSchema();

    expect(snapshot.entities, hasLength(1));
    final MigrationEntityDefinition users = snapshot.entities.single;
    expect(users.tableName, 'users');
    expect(users.primaryKeys, ['id']);
    expect(users.fields.map((field) => field.columnName), ['id', 'name']);
    expect(users.fields.first.type, MigrationValueType.integer);
    expect(users.fields.first.nullable, isFalse);
    expect(users.fields.last.type, MigrationValueType.text);
  });
}

final class _SqlSchemaBackend implements SqlMigrationBackend {
  @override
  Future<List<Map<String, Object?>>> query(
    String sql, [
    Object? parameters = const [],
  ]) async {
    if (sql.contains('sqlite_master')) {
      return const [
        {'name': 'users'},
        {'name': '__dorm_migrations'},
      ];
    }
    if (sql.contains('PRAGMA table_info')) {
      return const [
        {
          'name': 'id',
          'type': 'INTEGER',
          'notnull': 1,
          'dflt_value': null,
          'pk': 1,
        },
        {
          'name': 'name',
          'type': 'TEXT',
          'notnull': 0,
          'dflt_value': null,
          'pk': 0,
        },
      ];
    }
    return const [];
  }

  @override
  Future<void> execute(String sql, [Object? parameters = const []]) async {}

  @override
  Future<T> lock<T>(Future<T> Function() action) => action();
}
