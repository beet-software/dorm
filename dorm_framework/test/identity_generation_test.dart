import 'package:dorm_framework/dorm_framework.dart';
import 'package:test/test.dart';

class _Data {
  final String value;

  const _Data(this.value);
}

class _Model extends _Data {
  final String id;

  const _Model({required this.id, required String value}) : super(value);
}

class _ManualEntity
    extends Entity<_Data, _Model, String, Creation<_Data, String>> {
  _ManualEntity();

  @override
  final EntitySchema schema = const EntitySchema(
    tableName: 'items',
    primaryKeys: [FieldSchema(fieldName: 'id', columnName: 'id')],
  );

  @override
  _Model fromData(ResolvedCreation<_Data, String> creation) =>
      _Model(id: creation.id, value: creation.data.value);

  @override
  _Model fromJson(String id, Map data) =>
      _Model(id: id, value: data['value'] as String);

  @override
  String identify(_Model model) => model.id;

  @override
  Map<String, Object?> toJson(_Data data) => {'value': data.value};

  @override
  _Model convert(_Model model, _Data data) =>
      _Model(id: model.id, value: data.value);
}

void main() {
  test('exposes the three identity generation strategies', () {
    expect(
      IdentityGenerationStrategy.values,
      containsAll(<IdentityGenerationStrategy>[
        IdentityGenerationStrategy.engine,
        IdentityGenerationStrategy.database,
        IdentityGenerationStrategy.explicit,
      ]),
    );
  });

  test('manual entities default to engine-generated identities', () {
    expect(
      _ManualEntity().identityGeneration,
      IdentityGenerationStrategy.engine,
    );
  });
}
