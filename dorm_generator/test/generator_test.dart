import 'package:code_builder/code_builder.dart' as cb;
import 'package:dorm_annotations/dorm_annotations.dart';
import 'package:dorm_generator/src/generator.dart';
import 'package:dorm_generator/src/utils/orm_node.dart';
import 'package:test/test.dart';

void main() {
  group('DataNaming', () {
    test('derives schema and model names from the annotated class name', () {
      final DataNaming naming = DataNaming(
        name: '_User',
        node: const DataOrmNode(annotation: Data()),
      );

      expect(naming.schemaName, '_User');
      expect(naming.modelName, 'User');
    });
  });

  group('ModelNaming', () {
    test('derives simple model names and accessors', () {
      final ModelNaming naming = ModelNaming(
        name: '_User',
        node: const ModelOrmNode(annotation: Model(name: 'users')),
      );

      expect(naming.schemaName, '_User');
      expect(naming.modelName, 'User');
      expect(naming.dataName, 'UserData');
      expect(naming.dependencyName, 'UserDependency');
      expect(naming.entityName, 'UserEntity');
      expect(naming.repositoryName, 'user');
      expect(naming.tableName, 'users');
      expect(naming.extensionName, 'UserProperties');
      expect(naming.fieldsName, 'UserFields');
      expect(naming.primaryKeyFieldNames, ['id']);
      expect(naming.idFieldName, 'id');
      expect(naming.idColumnName, 'id');
      expect(naming.isCompositePrimaryKey, isFalse);
      expect(naming.isGeneratedPrimaryKey, isTrue);
      expect(naming.creationReference.symbol, 'SimpleCreation');
    });

    test('rejects an existing primary key without parsed field metadata', () {
      final ModelNaming naming = ModelNaming(
        name: '_User',
        node: const ModelOrmNode(
          annotation: Model(primaryKey: [ExistingIdSpec(referTo: #missing)]),
        ),
        fields: const {},
      );

      expect(() => naming.primaryKeyFieldNames, throwsStateError);
    });
  });

  group('Spec', () {
    Spec spec({
      List<String> primaryKeyNames = const ['id'],
      bool primaryKeyIsGenerated = true,
      bool includeExistingPrimaryKey = false,
    }) {
      return Spec(
        includesPrimaryKey: true,
        primaryKeyType: cb.Reference('String'),
        primaryKeyNames: primaryKeyNames,
        primaryKeyIsGenerated: primaryKeyIsGenerated,
        includeExistingPrimaryKey: includeExistingPrimaryKey,
        supportsSerialization: true,
        extendsReference: null,
        implementsReferences: const [],
        includesQueryGetters: false,
        ignoreOverrideFor: const {},
        discriminatorSpec: null,
        generatesCopyWith: false,
        shouldDeclareField: (_) => true,
      );
    }

    test('identifies simple and composite primary-key specs', () {
      expect(spec().isCompositePrimaryKey, isFalse);
      expect(
        spec(primaryKeyNames: ['tenant', 'user']).isCompositePrimaryKey,
        isTrue,
      );
      expect(spec().primaryKeyName, 'id');
      expect(
        () => spec(primaryKeyNames: ['tenant', 'user']).primaryKeyName,
        throwsStateError,
      );
    });

    test('maps JSON names for simple and composite keys', () {
      expect(spec().primaryKeyJsonName('id'), '_id');
      final Spec composite = spec(primaryKeyNames: ['tenant', 'user']);
      expect(composite.primaryKeyJsonName('tenant'), '_id_tenant');
      expect(composite.primaryKeyJsonName('user'), '_id_user');
    });

    test('recognizes existing primary-key fields', () {
      final Spec generated = spec();
      expect(generated.isExistingPrimaryKey('id'), isFalse);

      final Spec existing = spec(
        primaryKeyIsGenerated: false,
        includeExistingPrimaryKey: true,
      );
      expect(existing.isExistingPrimaryKey('id'), isTrue);
      expect(existing.isExistingPrimaryKey('name'), isFalse);
      expect(existing.shouldDeclare('id', const Field()), isTrue);
    });
  });
}
