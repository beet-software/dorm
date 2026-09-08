import 'package:dorm_annotations/dorm_annotations.dart';
import 'package:test/test.dart';

class _Profile {}

enum _State { ready }

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
    );

    expect(defaults.name, isNull);
    expect(defaults.as, isNull);
    expect(defaults.primaryKey, hasLength(1));
    expect(defaults.primaryKey.single, isA<GeneratedIdSpec>());
    expect(custom.name, 'users');
    expect(custom.as, #users);
    final GeneratedIdSpec key = custom.primaryKey.single as GeneratedIdSpec;
    expect(key.as, #userId);
    expect(key.name, 'user_id');
    expect(key.type, int);
  });

  test('ExistingIdSpec preserves the referenced getter symbol', () {
    const ExistingIdSpec spec = ExistingIdSpec(referTo: #id);

    expect(spec.referTo, #id);
  });

  test('DerivedField preserves its optional storage name', () {
    const DerivedField annotation = DerivedField(name: 'search_name');

    expect(annotation.name, 'search_name');
    expect(const DerivedField().name, isNull);
  });

  test('DerivedTransformations delegate to the normalization helpers', () {
    const DerivedTransformations transformations = DerivedTransformations();

    expect(transformations.text('Olá mundo'), 'OLAMUNDO');
    expect(transformations.enumeration(_State.ready), 'ready');
    expect(transformations.date(DateTime(2024, 2, 3)), '20240203');
    expect(
      transformations.datetime(DateTime(2024, 2, 3, 4, 5, 6, 7)),
      '20240203040506007',
    );
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
