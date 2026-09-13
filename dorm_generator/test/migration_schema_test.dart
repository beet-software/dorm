import 'package:dorm_generator/src/migration_schema.dart';
import 'package:test/test.dart';

void main() {
  test('snapshot JSON is deterministic', () {
    final SchemaSnapshot snapshot = SchemaSnapshot(
      entities: [
        SchemaEntity(
          name: 'User',
          tableName: 'users',
          primaryKeys: ['id'],
          fields: [
            const SchemaField(
              name: 'name',
              columnName: 'name',
              dartType: 'String',
              logicalType: 'text',
              nullable: false,
            ),
            const SchemaField(
              name: 'id',
              columnName: 'id',
              dartType: 'String',
              logicalType: 'text',
              nullable: false,
            ),
          ],
        ),
      ],
    );

    final String json = snapshot.encode();
    expect(
      SchemaSnapshot.fromJson(json).entities.single.fields.first.columnName,
      'id',
    );
    expect(SchemaSnapshot.fromJson(json).encode(), json);
  });

  test('round trips defaults, relations, and backend overrides', () {
    const SchemaField field = SchemaField(
      name: 'name',
      columnName: 'display_name',
      dartType: 'String',
      logicalType: 'text',
      nullable: true,
      modelDefault: 'Anonymous',
      foreignTable: 'profiles',
      foreignField: 'id',
      unique: true,
      typeOverrides: {'mysql': 'VARCHAR(255)'},
    );
    final SchemaSnapshot snapshot = SchemaSnapshot(
      entities: [
        const SchemaEntity(
          name: 'User',
          tableName: 'users',
          fields: [field],
          primaryKeys: ['id'],
        ),
      ],
    );

    final SchemaField restored = SchemaSnapshot.fromJson(
      snapshot.encode(),
    ).entities.single.fields.single;
    expect(restored.modelDefault, 'Anonymous');
    expect(restored.foreignTable, 'profiles');
    expect(restored.typeOverrides['mysql'], 'VARCHAR(255)');
  });

  test('rejects unsupported snapshot format', () {
    expect(
      () => SchemaSnapshot.fromJson('{"format": 99, "entities": []}'),
      throwsFormatException,
    );
  });
}
