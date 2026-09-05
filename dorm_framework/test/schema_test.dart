import 'package:dorm_framework/dorm_framework.dart';
import 'package:test/test.dart';

void main() {
  test('exposes foreign-key metadata without engine details', () {
    const EntitySchema schema = EntitySchema(
      tableName: 'students',
      primaryKey: FieldSchema(fieldName: 'id', columnName: 'id'),
      fields: [
        ForeignKeySchema(
          fieldName: 'schoolId',
          columnName: 'school_id',
          targetTableName: 'schools',
          targetColumnName: 'id',
        ),
        FieldSchema(fieldName: 'name', columnName: 'name'),
      ],
    );

    expect(schema.foreignKeys, hasLength(1));
    expect(schema.foreignKeys.single.unique, isFalse);
  });

  test('preserves unique foreign-key metadata', () {
    const ForeignKeySchema foreignKey = ForeignKeySchema(
      fieldName: 'profileId',
      columnName: 'profile_id',
      targetTableName: 'profiles',
      targetColumnName: 'id',
      unique: true,
    );

    expect(foreignKey.unique, isTrue);
  });
}
