import 'package:dorm_framework/dorm_framework.dart';
import 'package:test/test.dart';

void main() {
  test('composite keys compare by ordered values', () {
    expect(CompositeKey(['tenant', 7]), equals(CompositeKey(['tenant', 7])));
    expect(
      CompositeKey(['tenant', 7]),
      isNot(equals(CompositeKey([7, 'tenant']))),
    );
  });

  test('composite codec round-trips values', () {
    const CompositePrimaryKeyCodec codec = CompositePrimaryKeyCodec();
    final CompositeKey key = CompositeKey(['tenant', 7]);

    expect(codec.decode(codec.encode(key)), equals(key));
  });

  test('composite keys preserve their values from later input changes', () {
    final List<Object?> values = ['tenant', 7];
    final CompositeKey key = CompositeKey(values);
    values[1] = 8;

    expect(key.values, ['tenant', 7]);
  });

  test('single codec rejects a value count different from one', () {
    const SinglePrimaryKeyCodec<String> codec = SinglePrimaryKeyCodec();

    expect(() => codec.decode(const []), throwsStateError);
    expect(() => codec.decode(['a', 'b']), throwsStateError);
  });

  test('schema exposes ordered composite key fields', () {
    const FieldSchema tenant = FieldSchema(
      fieldName: 'tenantId',
      columnName: 'tenant-id',
    );
    const FieldSchema user = FieldSchema(
      fieldName: 'userId',
      columnName: 'user-id',
    );
    const EntitySchema schema = EntitySchema(
      tableName: 'memberships',
      primaryKeys: [tenant, user],
    );

    expect(schema.isCompositePrimaryKey, isTrue);
    expect(schema.primaryKeys, [tenant, user]);
  });
}
