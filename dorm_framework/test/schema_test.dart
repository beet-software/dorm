import 'package:dorm_framework/dorm_framework.dart';
import 'package:test/test.dart';

class _Query extends BaseQuery<_Query> {
  String? key;
  Object? value;

  @override
  _Query whereValue(String key, Object? value) {
    this.key = key;
    this.value = value;
    return this;
  }

  @override
  _Query whereText(String key, String prefix) => this;

  @override
  _Query whereDate(String key, DateTime date, DateFilterUnit unit) => this;

  @override
  _Query whereRange<R>(String key, FilterRange<R> range) => this;

  @override
  _Query limit(int count) => this;

  @override
  _Query sorted(String key) => this;
}

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

  test('exposes derived-field path and storage metadata', () {
    const DerivedFieldSchema field = DerivedFieldSchema(
      fieldName: 'searchName',
      columnName: '_query/name',
      path: ['_query', 'name'],
      storageName: '_query',
    );

    expect(field.path, ['_query', 'name']);
    expect(field.storageName, '_query');
  });

  test('resolves a value filter field from its schema metadata', () {
    const FieldSchema field = FieldSchema(
      fieldName: 'schoolId',
      columnName: 'school_id',
    );

    final _Query query = const BaseFilter<_Query>.value(
      7,
      field: field,
    ).accept(_Query());

    expect(query.key, 'school_id');
    expect(query.value, 7);
  });
}
