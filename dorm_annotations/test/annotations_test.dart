import 'package:dorm_annotations/dorm_annotations.dart';
import 'package:test/test.dart';

class _Profile {}

Object _generateId(Object model, String id) => id;

void main() {
  test('Data has no additional metadata', () {
    const Data annotation = Data();

    expect(annotation, isA<Data>());
  });

  test('Field preserves its optional storage name and default value', () {
    const Field annotation = Field(name: 'display_name', defaultValue: 'Ada');

    expect(annotation.name, 'display_name');
    expect(annotation.defaultValue, 'Ada');
    expect(const Field().name, isNull);
    expect(const Field().defaultValue, isNull);
  });

  test('ForeignField preserves relation metadata', () {
    const ForeignField annotation = ForeignField(
      name: 'profile_id',
      referTo: _Profile,
      unique: true,
      as: #profile,
      inverseAs: #user,
    );

    expect(annotation.name, 'profile_id');
    expect(annotation.referTo, _Profile);
    expect(annotation.unique, isTrue);
    expect(annotation.as, #profile);
    expect(annotation.inverseAs, #user);
  });

  test('ModelField preserves the referenced type and template', () {
    const ModelField annotation = ModelField(
      name: 'profile',
      referTo: _Profile,
    );

    expect(annotation.name, 'profile');
    expect(annotation.referTo, _Profile);
    expect(annotation.template, isA<ModelFieldTemplate<ModelFieldType>>());
  });

  test('Model preserves defaults and custom metadata', () {
    const Model defaults = Model();
    final Model custom = Model(
      name: 'users',
      as: #users,
      primaryKey: const [
        GeneratedIdSpec(as: #userId, name: 'user_id', type: int),
      ],
      primaryKeyGenerator: _generateId,
    );

    expect(defaults.name, isNull);
    expect(defaults.as, isNull);
    expect(defaults.primaryKey, hasLength(1));
    expect(defaults.primaryKey.single, isA<GeneratedIdSpec>());
    expect(custom.name, 'users');
    expect(custom.as, #users);
    expect(custom.primaryKeyGenerator, same(_generateId));
    final GeneratedIdSpec key = custom.primaryKey.single as GeneratedIdSpec;
    expect(key.as, #userId);
    expect(key.name, 'user_id');
    expect(key.type, int);
  });

  test('ExistingIdSpec preserves the referenced getter symbol', () {
    const ExistingIdSpec spec = ExistingIdSpec(referTo: #id);

    expect(spec.referTo, #id);
  });

  test('DerivedField preserves tokens and join configuration', () {
    const DerivedField annotation = DerivedField(
      name: 'search_name',
      referTo: [
        DerivedToken(#firstName, DerivedTransform.text),
        DerivedToken(#status, DerivedTransform.enumeration),
        DerivedToken(#createdAt, DerivedTransform.date),
        DerivedToken(#createdAt, DerivedTransform.datetime),
      ],
      joinBy: '|',
    );

    expect(annotation.name, 'search_name');
    expect(annotation.joinBy, '|');
    expect(annotation.referTo, hasLength(4));
    expect(annotation.referTo[0].field, #firstName);
    expect(annotation.referTo[0].transform, DerivedTransform.text);
    expect(annotation.referTo[1].field, #status);
    expect(annotation.referTo[1].transform, DerivedTransform.enumeration);
    expect(annotation.referTo[2].transform, DerivedTransform.date);
    expect(annotation.referTo[3].transform, DerivedTransform.datetime);
  });

  test('Polymorphic annotations preserve pivot and discriminator metadata', () {
    const PolymorphicData data = PolymorphicData(
      name: 'circle',
      as: #circle,
    );
    const PolymorphicField field = PolymorphicField(
      name: 'shape',
      pivotName: 'shape_type',
      pivotAs: #shapeType,
    );

    expect(data.name, 'circle');
    expect(data.as, #circle);
    expect(field.name, 'shape');
    expect(field.pivotName, 'shape_type');
    expect(field.pivotAs, #shapeType);
  });

  test('identity specifications expose their defaults', () {
    const GeneratedIdSpec generated = GeneratedIdSpec();
    const DatabaseGeneratedIdSpec database = DatabaseGeneratedIdSpec(
      as: #key,
      name: 'key',
      type: int,
    );

    expect(generated.as, #id);
    expect(generated.name, 'id');
    expect(generated.type, String);
    expect(database.as, #key);
    expect(database.name, 'key');
    expect(database.type, int);
  });
}
