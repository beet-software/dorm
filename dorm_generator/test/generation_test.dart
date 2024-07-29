import 'dart:isolate';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:dartx/dartx.dart';
import 'package:dorm_generator/src/generator.dart';
import 'package:dorm_generator/src/utils/custom_types.dart';
import 'package:package_config/package_config.dart';
import 'package:source_gen/source_gen.dart';
import 'package:test/test.dart';

import 'matchers.dart';
import 'proxy_matchers.dart';

const Generator _generator = OrmGenerator();

const bool kDebug = false;

// ignore: subtype_of_sealed_class
class _BuildStep implements BuildStep {
  const _BuildStep();

  @override
  Object? noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}

enum ClassFieldType { data, model, query }

sealed class ClassField {
  String get name;

  String get type;

  String get as;

  ClassFieldType get ownerType;

  const factory ClassField.data(
    String type,
    String name, {
    required String as,
  }) = _DataClassField;

  const factory ClassField.model(
    String type,
    String name, {
    required String as,
  }) = _ModelClassField;

  const factory ClassField.query(
    String type,
    String name, {
    required String as,
    required List<String> tokens,
  }) = QueryClassField;
}

class _DataClassField implements ClassField {
  @override
  final String type;

  @override
  final String name;

  @override
  final String as;

  const _DataClassField(this.type, this.name, {required this.as});

  @override
  ClassFieldType get ownerType => ClassFieldType.data;
}

class _ModelClassField implements ClassField {
  @override
  final String type;

  @override
  final String name;

  @override
  final String as;

  const _ModelClassField(this.type, this.name, {required this.as});

  @override
  ClassFieldType get ownerType => ClassFieldType.model;
}

class QueryClassField implements ClassField {
  @override
  final String type;

  @override
  final String name;

  @override
  final String as;

  final List<String> tokens;

  const QueryClassField(
    this.type,
    this.name, {
    required this.as,
    required this.tokens,
  });

  @override
  ClassFieldType get ownerType => ClassFieldType.query;
}

Matcher _hasDormDummyClass(
  String className,
  List<ClassField> fields,
) {
  final String actualClassName = '_\$$className';
  return HasElement([
    HasName(actualClassName),
    IsElement<ClassElement>([
      const HasAnnotations([]),
      const HasSuperclass([]),
      const HasInterfaces([
        HasElement([HasName('_Foo')]),
      ]),
      HasConstructors([
        HasElement([
          HasType(actualClassName),
          const HasName('fromData'),
          HasParameters([
            HasElement([
              HasType('${className}Dependency'),
              const HasName('dependency')
            ]),
            HasElement([HasType('${className}Data'), const HasName('data')]),
          ]),
          HasBody(() {
            final StringBuffer buffer = StringBuffer('=> $actualClassName(');
            buffer.writeAll([
              for (ClassField field in fields)
                if (field.ownerType != ClassFieldType.query)
                  switch (field.ownerType) {
                    ClassFieldType.data => '${field.name}: data.${field.name}',
                    ClassFieldType.model =>
                      '${field.name}: dependency.${field.name}',
                    ClassFieldType.query => null,
                  }
            ], ', ');
            buffer.write(');');
            return '$buffer';
          }()),
        ]),
        HasElement([
          const HasName(''),
          HasParameters([
            for (ClassField field in fields)
              HasElement([HasType(field.type), HasName(field.name)]),
          ]),
          const HasBody(";"),
        ]),
      ]),
      HasFields([
        for (ClassField field in fields)
          HasElement([HasType(field.type), HasName(field.name)]),
      ]),
      const HasAccessors([]),
      const HasMethods([]),
    ]),
  ]);
}

Matcher _hasDormDataClass(
  String className,
  List<ClassField> fields, {
  String? polymorphicClassName,
  bool rename = true,
}) {
  final String actualClassName = rename ? '${className}Data' : className;
  return HasElement([
    HasName(actualClassName),
    IsElement<ClassElement>([
      HasAnnotations([
        if (fields.any((field) => field.ownerType == ClassFieldType.data))
          const HasElement([HasName('JsonSerializable')]),
      ]),
      const HasSuperclass([]),
      const HasInterfaces([]),
      HasConstructors([
        if (fields.any((field) => field.ownerType == ClassFieldType.data))
          HasElement([
            HasType(actualClassName),
            const HasName('fromJson'),
            const HasParameters([
              HasElement([HasType('Map<dynamic, dynamic>'), HasName('json')]),
            ]),
            HasBody("=> _\$${actualClassName}FromJson(json);"),
          ]),
        HasElement([
          const HasName(''),
          HasParameters([
            if (polymorphicClassName != null)
              HasElement([
                HasType('${polymorphicClassName}Type'),
                const HasName('type'),
              ]),
            for (ClassField field in fields)
              if (field.ownerType == ClassFieldType.data)
                HasElement([HasType(field.type), HasName(field.name)]),
          ]),
          const HasBody(";"),
        ]),
        if (polymorphicClassName != null)
          HasElement([
            const HasName('_'),
            HasParameters([
              HasElement([
                HasType('${polymorphicClassName}Type'),
                const HasName('type'),
              ]),
              for (ClassField field in fields)
                if (field.ownerType == ClassFieldType.data)
                  HasElement([
                    field.type == polymorphicClassName
                        ? const HasType('Map<dynamic, dynamic>')
                        : HasType(field.type),
                    HasName(field.name)
                  ]),
            ]),
          ]),
      ]),
      HasFields([
        if (polymorphicClassName != null)
          HasElement([
            HasType('${polymorphicClassName}Type'),
            const HasName('type'),
          ]),
        for (ClassField field in fields)
          if (field.ownerType == ClassFieldType.data)
            HasElement([
              HasType(field.type),
              HasName(field.name),
              // const IsElement<FieldElement>([
              //   HasAnnotations([
              //     HasElement([HasName('JsonKey')]),
              //   ])
              // ]),
            ]),
      ]),
      const HasAccessors([]),
      HasMethods([
        HasElement([
          const HasType('Map<String, Object?>'),
          const HasName('toJson'),
          const HasParameters([]),
          !fields.any((field) => field.ownerType == ClassFieldType.data)
              ? const HasBody('=> const {};')
              : HasBody('=> _\$${actualClassName}ToJson(this);'),
        ]),
      ]),
    ]),
  ]);
}

Matcher _hasDormModelClass(
  String className,
  List<ClassField> fields, {
  String? polymorphicClassName,
}) {
  return HasElement([
    HasName(className),
    IsElement<ClassElement>([
      const HasAnnotations([
        HasElement([HasName('JsonSerializable')]),
      ]),
      HasSuperclass([HasName('${className}Data')]),
      HasInterfaces([
        HasElement([HasName('_$className')]),
      ]),
      HasConstructors([
        HasElement([
          const HasName(''),
          HasParameters([
            const HasElement([HasType('String'), HasName('id')]),
            if (polymorphicClassName != null)
              HasElement([
                HasType('${polymorphicClassName}Type'),
                const HasName('type'),
              ]),
            for (ClassField field in fields)
              if (field.ownerType != ClassFieldType.query)
                HasElement([HasType(field.type), HasName(field.name)]),
          ]),
          const HasBody(';'),
        ]),
        HasElement([
          const HasName('fromJson'),
          const HasParameters([
            HasElement([HasType('String'), HasName('id')]),
            HasElement([HasType('Map<dynamic, dynamic>'), HasName('json')]),
          ]),
          HasBody('=> _\$${className}FromJson({...json, \'_id\' : id});'),
        ]),
        if (polymorphicClassName != null)
          HasElement([
            const HasName('_'),
            HasParameters([
              const HasElement([HasType('String'), HasName('id')]),
              HasElement([
                HasType('${polymorphicClassName}Type'),
                const HasName('type')
              ]),
              for (ClassField field in fields)
                if (field.ownerType != ClassFieldType.query)
                  HasElement([
                    field.ownerType == ClassFieldType.data &&
                            field.type == polymorphicClassName
                        ? const HasType('Map<dynamic, dynamic>')
                        : HasType(field.type),
                    HasName(field.name),
                  ]),
            ]),
          ])
      ]),
      HasFields([
        const HasElement([HasType('String'), HasName('id')]),
        for (ClassField field in fields)
          if (field.ownerType == ClassFieldType.model)
            HasElement([HasType(field.type), HasName(field.name)]),
      ]),
      HasAccessors([
        for (ClassField field in fields)
          if (field case QueryClassField())
            HasElement([
              HasType(field.type),
              HasName(field.name),
              HasBody(() {
                final StringBuffer buffer = StringBuffer('=> [');
                buffer.writeAll(field.tokens, ', ');
                buffer.write('].join(\'_\');');
                return '$buffer';
              }()),
            ])
      ]),
      HasMethods([
        HasElement([
          const HasType('Map<String, Object?>'),
          const HasName('toJson'),
          const HasParameters([]),
          HasBody(() {
            final StringBuffer buffer = StringBuffer('{return {');
            buffer.writeAll([
              '..._\$${className}ToJson(this)..remove(\'_id\')',
              for (ClassField field in fields)
                if (field.ownerType == ClassFieldType.query)
                  switch (field.as.split('/')) {
                    [String key] => '\'$key\' : ${field.name}',
                    [...List<String> head, String key] =>
                      '\'${head.join('/')}\' : {\'$key\' : ${field.name}}',
                    _ => '',
                  },
            ], ', ');
            buffer.write('};}');
            return '$buffer';
          }()),
        ]),
      ]),
    ]),
  ]);
}

Matcher _hasDormDependencyClass(
  String className,
  List<ClassField> fields,
) {
  return HasElement([
    HasName('${className}Dependency'),
    IsElement<ClassElement>([
      const HasAnnotations([]),
      HasSuperclass([HasName('Dependency<${className}Data>')]),
      const HasInterfaces([]),
      HasConstructors([
        HasElement([
          const HasName(''),
          HasParameters([
            for (ClassField field in fields)
              if (field.ownerType == ClassFieldType.model)
                HasElement([HasType(field.type), HasName(field.name)]),
          ]),
          const HasBody(";"),
        ]),
      ]),
      HasFields([
        for (ClassField field in fields)
          if (field.ownerType == ClassFieldType.model)
            HasElement([HasType(field.type), HasName(field.name)]),
      ]),
      const HasAccessors([]),
      const HasMethods([]),
    ]),
  ]);
}

sealed class UidModel {}

class CompositeUidModel implements UidModel {
  const CompositeUidModel();
}

class SameAsUidModel implements UidModel {
  final String fieldName;

  const SameAsUidModel(this.fieldName);
}

class CustomUidModel implements UidModel {
  final String generatorName;

  const CustomUidModel(this.generatorName);
}

Matcher _hasDormEntityClass(
  String className,
  List<ClassField> fields, {
  String? polymorphicClassName,
  UidModel? uidModel,
}) {
  return HasElement([
    HasName('${className}Entity'),
    IsElement<ClassElement>([
      const HasAnnotations([]),
      const HasSuperclass([]),
      HasInterfaces([
        HasElement([HasName('Entity<${className}Data, $className>')]),
      ]),
      const HasConstructors([
        HasElement([
          HasName(''),
          HasBody(';'),
        ]),
      ]),
      const HasFields([
        HasElement([HasType('String'), HasName('tableName')]),
      ]),
      const HasAccessors([]),
      HasMethods([
        HasElement([
          HasType(className),
          const HasName('fromData'),
          HasParameters([
            HasElement([
              HasType('${className}Dependency'),
              const HasName('dependency')
            ]),
            const HasElement([HasType('String'), HasName('id')]),
            HasElement([HasType('${className}Data'), const HasName('data')]),
          ]),
          HasBody(() {
            final StringBuffer buffer = StringBuffer('{return $className(');
            buffer.writeAll(
              [
                'id: ${switch (uidModel) {
                  null => 'id',
                  CompositeUidModel() => 'dependency.key(id)',
                  SameAsUidModel(:String fieldName) => 'dependency.$fieldName',
                  CustomUidModel(:String generatorName) => '$generatorName('
                      '_\$$className.fromData(dependency, data)).when('
                      'caseSimple: () => id, '
                      'caseComposite: () => dependency.key(id), '
                      'caseValue: (id) => id'
                      ')',
                }}',
                for (ClassField field in fields)
                  if (field.ownerType != ClassFieldType.query)
                    field.ownerType == ClassFieldType.model
                        ? '${field.name}: dependency.${field.name}'
                        : field.type == polymorphicClassName
                            ? 'type: data.type, ${field.name}: data.${field.name}'
                            : '${field.name}: data.${field.name}',
              ],
              ', ',
            );
            return '$buffer);}';
          }()),
        ]),
        HasElement([
          HasType(className),
          const HasName('convert'),
          HasParameters([
            HasElement([HasType(className), const HasName('model')]),
            HasElement([HasType('${className}Data'), const HasName('data')]),
          ]),
          !fields.any((field) => field.ownerType == ClassFieldType.data)
              ? const HasBody('=> model;')
              : const HasBody('=> model.copyWith(data);'),
        ]),
        HasElement([
          HasType(className),
          const HasName('fromJson'),
          const HasParameters([
            HasElement([HasType('String'), HasName('id')]),
            HasElement([HasType('Map<dynamic, dynamic>'), HasName('json')]),
          ]),
          HasBody('=> $className.fromJson(id, json);'),
        ]),
        HasElement([
          const HasType('String'),
          const HasName('identify'),
          HasParameters([
            HasElement([HasType(className), const HasName('model')]),
          ]),
          const HasBody('=> model.id;'),
        ]),
        HasElement([
          const HasType('Map<String, Object?>'),
          const HasName('toJson'),
          HasParameters([
            HasElement([HasType('${className}Data'), const HasName('data')]),
          ]),
          const HasBody('=> data.toJson();'),
        ]),
      ]),
    ]),
  ]);
}

Matcher _hasDormBasePolymorphicClass(
  String className,
  Map<String, String> fields,
) {
  return HasElement([
    HasName(className),
    IsElement<ClassElement>([
      const HasAnnotations([]),
      const HasSuperclass([]),
      HasInterfaces([
        HasElement([HasName('_$className')]),
      ]),
      HasConstructors([
        HasElement([
          const HasName('fromType'),
          HasParameters([
            HasElement([HasType('${className}Type'), const HasName('type')]),
            const HasElement(
                [HasType('Map<dynamic, dynamic>'), HasName('json')]),
          ]),
          HasBody(() {
            final StringBuffer buffer = StringBuffer('{switch (type) {');
            buffer.writeAll(fields.mapEntries((entry) {
              return 'case ${className}Type.${entry.value}: return ${entry.key}.fromJson(json);';
            }), ' ');
            buffer.write('}}');
            return '$buffer';
          }()),
        ]),
      ]),
      const HasFields([]),
      HasAccessors([
        HasElement([
          HasType('${className}Type'),
          const HasName('type'),
          const HasBody(';'),
        ]),
      ]),
      const HasMethods([
        HasElement([
          HasType('Map<String, Object?>'),
          HasName('toJson'),
          HasParameters([]),
          HasBody(';'),
        ]),
      ]),
    ]),
  ]);
}

Matcher _hasDormPolymorphicClass(
  String className,
  String baseClassName,
  List<ClassField> fields,
) {
  return HasElement([
    HasName(className),
    IsElement<ClassElement>([
      const HasAnnotations([
        HasElement([HasName('JsonSerializable')]),
      ]),
      const HasSuperclass([]),
      HasInterfaces([
        HasElement([HasName(baseClassName)]),
        HasElement([HasName('_$className')]),
      ]),
      HasConstructors([
        HasElement([
          const HasName('fromJson'),
          const HasParameters([
            HasElement([HasType('Map<dynamic, dynamic>'), HasName('json')]),
          ]),
          HasBody('=> _\$${className}FromJson(json);'),
        ]),
        HasElement([
          const HasName(''),
          HasParameters([
            for (ClassField field in fields)
              HasElement([HasType(field.type), HasName(field.name)]),
          ]),
          const HasBody(';'),
        ]),
      ]),
      HasFields([
        for (ClassField field in fields)
          HasElement([HasType(field.type), HasName(field.name)]),
        HasElement([HasType('${baseClassName}Type'), const HasName('type')]),
      ]),
      const HasAccessors([]),
      HasMethods([
        HasElement([
          const HasType('Map<String, Object?>'),
          const HasName('toJson'),
          const HasParameters([]),
          HasBody('=> _\$${className}ToJson(this);'),
        ]),
      ]),
    ]),
  ]);
}

Matcher _hasDormMainClass(
  Map<String, String> repositories,
) {
  return HasElement([
    const HasName('Dorm'),
    IsElement<ClassElement>([
      const HasAnnotations([]),
      const HasSuperclass([]),
      const HasInterfaces([]),
      const HasConstructors([
        HasElement([
          HasName(''),
          HasParameters([
            HasElement([HasType('BaseEngine'), HasName('_engine')]),
          ]),
          HasBody(';'),
        ]),
      ]),
      const HasFields([
        HasElement([HasType('BaseEngine'), HasName('_engine')]),
      ]),
      HasAccessors([
        for (final MapEntry(key: String fieldName, value: String fieldType)
            in repositories.entries)
          HasElement([
            HasType('DatabaseEntity<${fieldType}Data, $fieldType>'),
            HasName(fieldName),
            HasBody(
                '=> DatabaseEntity(const ${fieldType}Entity(), engine: _engine);'),
          ]),
      ]),
      const HasMethods([]),
    ]),
  ]);
}

Matcher _hasDormModelExtension(
  String className,
  List<ClassField> fields,
) {
  return HasElement([
    HasName('${className}Properties'),
    IsElement<ExtensionElement>([
      HasMethods([
        HasElement([
          HasType(className),
          const HasName('copyWith'),
          HasParameters([
            HasElement([HasType('${className}Data'), const HasName('data')]),
          ]),
          HasBody(() {
            final StringBuffer buffer = StringBuffer('{return $className(');
            buffer.writeAll([
              'id: id',
              for (ClassField field in fields)
                if (field.ownerType != ClassFieldType.query)
                  switch (field.ownerType) {
                    ClassFieldType.data => '${field.name}: data.${field.name}',
                    ClassFieldType.model => '${field.name}: ${field.name}',
                    ClassFieldType.query => null,
                  }
            ], ', ');
            buffer.write(');}');
            return '$buffer';
          }()),
        ]),
      ]),
    ]),
  ]);
}

Future<LibraryReader?> _generate(
  String sourceCode, {
  String packageName = 'test_lib',
  String libraryName = 'example',
  String fileName = 'models',
}) async {
  final LibraryElement? element = await resolveSource(
    '''
    library $libraryName;
    
    $sourceCode
    ''',
    (resolver) => resolver.findLibraryByName(libraryName),
  );
  if (element == null) {
    return null;
  }
  final LibraryReader reader = LibraryReader(element);
  final String? generatedSourceCode =
      await _generator.generate(reader, const _BuildStep());
  if (generatedSourceCode == null) {
    return null;
  }
  if (kDebug) {
    print(generatedSourceCode);
  }
  final LibraryElement? generatedElement = await resolveSources(
    {
      '$packageName|lib/$fileName.dart': '''
      library $libraryName;
      
      $sourceCode
      ''',
      '$packageName|lib/$fileName.dorm.dart': '''
      part of '$fileName.dart';

      $generatedSourceCode
      ''',
    },
    (resolver) => resolver.findLibraryByName(libraryName),
    packageConfig: await Isolate.packageConfig
        .then((uri) => uri!)
        .then(loadPackageConfigUri),
  );
  if (generatedElement == null) {
    return null;
  }
  return LibraryReader(generatedElement);
}

void main() async {
  test('when given class with no annotations', () async {
    final LibraryReader? reader = await _generate(r'''
    class Foo {}
    ''');
    expect(reader, isNull);
  });
  group('Model', () {
    test('no *Fields', () async {
      final LibraryReader? reader = await _generate(r'''
      import 'package:dorm_annotations/dorm_annotations.dart';
      import 'package:dorm_framework/dorm_framework.dart';
    
      part 'models.dorm.dart';
    
      @Model(name: 'Model\$name', as: #Model$as)
      class _Foo {}
      ''');
      expect(
        reader,
        IsInstance<LibraryReader>([
          HasClasses([
            const HasElement([HasName('_Foo')]),
            _hasDormDataClass('Foo', []),
            _hasDormModelClass('Foo', []),
            _hasDormDependencyClass('Foo', []),
            _hasDormEntityClass('Foo', []),
            _hasDormMainClass({'Model\$as': 'Foo'}),
          ]),
          const HasExtensions([]),
        ]),
      );
    });
    test('as (default)', () async {
      final LibraryReader? reader = await _generate(r'''
      import 'package:dorm_annotations/dorm_annotations.dart';
      import 'package:dorm_framework/dorm_framework.dart';
    
      part 'models.dorm.dart';
    
      @Model(name: 'Model\$name')
      class _Foo {}
      ''');
      expect(
        reader,
        IsInstance<LibraryReader>([
          HasClasses([
            const HasElement([HasName('_Foo')]),
            _hasDormDataClass('Foo', []),
            _hasDormModelClass('Foo', []),
            _hasDormDependencyClass('Foo', []),
            _hasDormEntityClass('Foo', []),
            _hasDormMainClass({'foo': 'Foo'}),
          ]),
          const HasExtensions([]),
        ]),
      );
    });
  });
  group('Field', () {
    void testSingleField(
      LibraryReader? reader,
      String fieldType,
      String fieldName,
      String fieldAs, {
      List<String> additionalClassesNames = const [],
      List<String> additionalEnumsNames = const [],
    }) {
      final List<ClassField> fields = [
        ClassField.data(fieldType, fieldName, as: fieldAs),
      ];
      expect(
        reader,
        IsInstance<LibraryReader>([
          HasClasses([
            for (String additionalClassName in additionalClassesNames)
              HasElement([HasName(additionalClassName)]),
            const HasElement([HasName('_Foo')]),
            _hasDormDataClass('Foo', fields),
            _hasDormModelClass('Foo', fields),
            _hasDormDependencyClass('Foo', fields),
            _hasDormEntityClass('Foo', fields),
            _hasDormMainClass({'Model\$as': 'Foo'}),
          ]),
          HasEnums([
            for (String additionalEnumName in additionalEnumsNames)
              HasElement([HasName(additionalEnumName)]),
          ]),
          HasExtensions([
            _hasDormModelExtension('Foo', fields),
          ]),
        ]),
      );
    }

    test('int', () async {
      final LibraryReader? reader = await _generate(r'''
      import 'package:dorm_annotations/dorm_annotations.dart';
      import 'package:dorm_framework/dorm_framework.dart';
      
      part 'models.dorm.dart';
      
      @Model(name: 'Model\$name', as: #Model$as)
      class _Foo {
        @Field(name: '_Foo@Field#age')
        int get age;
      }
      ''');
      testSingleField(reader, 'int', 'age', '_Foo@Field#age');
    });
    test('int?', () async {
      final LibraryReader? reader = await _generate(r'''
      import 'package:dorm_annotations/dorm_annotations.dart';
      import 'package:dorm_framework/dorm_framework.dart';
      
      part 'models.dorm.dart';
      
      @Model(name: 'Model\$name', as: #Model$as)
      class _Foo {
        @Field(name: '_Foo@Field#age')
        int? get age;
      }
      ''');
      testSingleField(reader, 'int?', 'age', '_Foo@Field#age');
    });
    test('String', () async {
      final LibraryReader? reader = await _generate(r'''
      import 'package:dorm_annotations/dorm_annotations.dart';
      import 'package:dorm_framework/dorm_framework.dart';
      
      part 'models.dorm.dart';
      
      @Model(name: 'Model\$name', as: #Model$as)
      class _Foo {
        @Field(name: '_Foo@Field#name')
        String get name;
      }
      ''');
      testSingleField(reader, 'String', 'name', '_Foo@Field#name');
    });
    test('DateTime', () async {
      final LibraryReader? reader = await _generate(r'''
      import 'package:dorm_annotations/dorm_annotations.dart';
      import 'package:dorm_framework/dorm_framework.dart';
      
      part 'models.dorm.dart';
      
      @Model(name: 'Model\$name', as: #Model$as)
      class _Foo {
        @Field(name: '_Foo@Field#birthDate')
        DateTime get birthDate;
      }
      ''');
      testSingleField(reader, 'DateTime', 'birthDate', '_Foo@Field#birthDate');
    });
    test('Enum', () async {
      final LibraryReader? reader = await _generate(r'''
      import 'package:dorm_annotations/dorm_annotations.dart';
      import 'package:dorm_framework/dorm_framework.dart';
      
      part 'models.dorm.dart';
      
      enum Status { waiting, active, done }
      
      @Model(name: 'Model\$name', as: #Model$as)
      class _Foo {
        @Field(name: '_Foo@Field#status')
        Status get status;
      }
      ''');
      testSingleField(
        reader,
        'Status',
        'status',
        '_Foo@Field#status',
        additionalEnumsNames: ['Status'],
      );
    });
    test('List<double>', () async {
      final LibraryReader? reader = await _generate(r'''
      import 'package:dorm_annotations/dorm_annotations.dart';
      import 'package:dorm_framework/dorm_framework.dart';
      
      part 'models.dorm.dart';
            
      @Model(name: 'Model\$name', as: #Model$as)
      class _Foo {
        @Field(name: '_Foo@Field#weights')
        List<double> get weights;
      }
      ''');
      testSingleField(reader, 'List<double>', 'weights', '_Foo@Field#weights');
    });
    test('List<double>: defaulted', () async {
      final LibraryReader? reader = await _generate(r'''
      import 'package:dorm_annotations/dorm_annotations.dart';
      import 'package:dorm_framework/dorm_framework.dart';
      
      part 'models.dorm.dart';
            
      @Model(name: 'Model\$name', as: #Model$as)
      class _Foo {
        @Field(name: '_Foo@Field#weights', defaultValue: [])
        List<double> get weights;
      }
      ''');
      testSingleField(reader, 'List<double>', 'weights', '_Foo@Field#weights');
    });
    test('custom', () async {
      final LibraryReader? reader = await _generate(r'''
      import 'package:dorm_annotations/dorm_annotations.dart';
      import 'package:dorm_framework/dorm_framework.dart';
      
      part 'models.dorm.dart';
      
      class LatLng {
        final double lat;
        final double lng;

        factory LatLng.fromJson(Map json) => LatLng(json['lat'], json['lng']);
        
        const LatLng(this.lat, this.lng);
        
        Map<String, Object?> toJson() => {'lat': lat, 'lng': lng};
      }
            
      @Model(name: 'Model\$name', as: #Model$as)
      class _Foo {
        @Field(name: '_Foo@Field#coordinates')
        LatLng get coordinates;
      }
      ''');
      testSingleField(
        reader,
        'LatLng',
        'coordinates',
        '_Foo@Field#coordinates',
        additionalClassesNames: ['LatLng'],
      );
    });
  });
  group('UidType', () {
    test('unique', () async {
      final LibraryReader? reader = await _generate(r'''
      import 'package:dorm_annotations/dorm_annotations.dart';
      import 'package:dorm_framework/dorm_framework.dart';
      
      part 'models.dorm.dart';
      
      @Model(name: 'Model\$name', as: #Model$as, uidType: UidType.unique())
      class _Foo {
        @Field(name: '_Foo@Field#days')
        Set<int> days;
      }
      ''');

      const List<ClassField> fields = [
        ClassField.data('Set<int>', 'days', as: '_Foo@Field#days'),
      ];
      expect(
        reader,
        IsInstance<LibraryReader>([
          HasClasses([
            const HasElement([HasName('_Foo')]),
            _hasDormDataClass('Foo', fields),
            _hasDormModelClass('Foo', fields),
            _hasDormDependencyClass('Foo', fields),
            _hasDormEntityClass('Foo', fields),
            _hasDormMainClass({'Model\$as': 'Foo'}),
          ]),
          HasExtensions([
            _hasDormModelExtension('Foo', fields),
          ]),
        ]),
      );
    });
    test('composite', () async {
      final LibraryReader? reader = await _generate(r'''
      import 'package:dorm_annotations/dorm_annotations.dart';
      import 'package:dorm_framework/dorm_framework.dart';
      
      part 'models.dorm.dart';
      
      @Model(name: 'Model\$name', as: #Model$as, uidType: UidType.composite())
      class _Foo {
        @Field(name: '_Foo@Field#name')
        String get name;
      }
      ''');

      const List<ClassField> fields = [
        ClassField.data('String', 'name', as: '_Foo@Field#name'),
      ];
      expect(
        reader,
        IsInstance<LibraryReader>([
          HasClasses([
            const HasElement([HasName('_Foo')]),
            _hasDormDataClass('Foo', fields),
            _hasDormModelClass('Foo', fields),
            _hasDormDependencyClass('Foo', fields),
            _hasDormEntityClass(
              'Foo',
              fields,
              uidModel: const CompositeUidModel(),
            ),
            _hasDormMainClass({'Model\$as': 'Foo'}),
          ]),
          HasExtensions([
            _hasDormModelExtension('Foo', fields),
          ]),
        ]),
      );
    });
    test('sameAs: without reference', () async {
      await expectLater(
        _generate(r'''
        import 'package:dorm_annotations/dorm_annotations.dart';
        import 'package:dorm_framework/dorm_framework.dart';
      
        part 'models.dorm.dart';
      
        @Model(name: '_Foo@Model', as: #_Foo$as)
        class _Foo {
          @Field(name: '_Foo@Field#counts')
          List<int> get counts;
        }
      
        @Model(name: '_Bar@Model', as: #_Bar$as, uidType: UidType.sameAs(_Foo))
        class _Bar {
          @Field(name: '_Bar@Field#level')
          double get level;
        }
        '''),
        throwsA(
          isStateError.having((e) => e.message, 'message',
              'invalid reference on UidType.sameAs: _Foo'),
        ),
      );
    });
    test('sameAs: invalid reference', () async {
      await expectLater(
        _generate(r'''
        import 'package:dorm_annotations/dorm_annotations.dart';
        import 'package:dorm_framework/dorm_framework.dart';
      
        part 'models.dorm.dart';
      
        @Model(name: '_Foo@Model', as: #_Foo$as)
        class _Foo {
          @Field(name: '_Foo@Field#counts')
          List<int> get counts;
        }
      
        @Model(name: '_Bar@Model', as: #_Bar$as)
        class _Bar {
          @Field(name: '_Bar@Field#counts')
          List<int> get counts;
        }
      
        @Model(name: '_Baz@Model', as: #_Baz$as, uidType: UidType.sameAs(_Foo))
        class _Baz {
          @ForeignField(name: '_Baz@Field#barId', referTo: _Bar)
          String get barId;
        }
        '''),
        throwsA(
          isStateError.having((e) => e.message, 'message',
              'invalid reference on UidType.sameAs: _Foo'),
        ),
      );
    });
    test('sameAs: valid reference', () async {
      final LibraryReader? reader = await _generate(r'''
      import 'package:dorm_annotations/dorm_annotations.dart';
      import 'package:dorm_framework/dorm_framework.dart';
      
      part 'models.dorm.dart';
      
      @Model(name: '_Foo@Model', as: #_Foo$as)
      class _Foo {
        @Field(name: '_Foo@Field#insertionDate')
        DateTime get insertionDate;
      }
      
      @Model(name: '_Bar@Model', as: #_Bar$as, uidType: UidType.sameAs(_Foo))
      class _Bar {
        @ForeignField(name: '_Bar@ForeignField#fooId', referTo: _Foo)
        String get fooId;
      }
      ''');

      const List<ClassField> fooFields = [
        ClassField.data('DateTime', 'insertionDate',
            as: '_Foo@Field#insertionDate'),
      ];
      const List<ClassField> barFields = [
        ClassField.model('String', 'fooId', as: '_Bar@ForeignField#fooId'),
      ];
      expect(
        reader,
        IsInstance<LibraryReader>([
          HasClasses([
            const HasElement([HasName('_Foo')]),
            const HasElement([HasName('_Bar')]),
            _hasDormDataClass('Foo', fooFields),
            _hasDormModelClass('Foo', fooFields),
            _hasDormDependencyClass('Foo', fooFields),
            _hasDormEntityClass('Foo', fooFields),
            _hasDormDataClass('Bar', barFields),
            _hasDormModelClass('Bar', barFields),
            _hasDormDependencyClass('Bar', barFields),
            _hasDormEntityClass('Bar', barFields,
                uidModel: const SameAsUidModel('fooId')),
            _hasDormMainClass({'_Foo\$as': 'Foo', '_Bar\$as': 'Bar'}),
          ]),
          HasExtensions([
            _hasDormModelExtension('Foo', fooFields),
          ]),
        ]),
      );
    });
    test('custom', () async {
      final LibraryReader? reader = await _generate(r'''
      import 'package:dorm_annotations/dorm_annotations.dart';
      import 'package:dorm_framework/dorm_framework.dart';
      
      part 'models.dorm.dart';
      
      @Model(name: 'Model\$name', as: #Model$as, uidType: UidType.custom(_Foo._generate))
      class _Foo {
        static UidValue _generate(Object data) {
          throw UnimplementedError();
        }
      
        @Field(name: '_Foo@Field#name')
        String get name;
      }
      ''');

      const List<ClassField> fields = [
        ClassField.data('String', 'name', as: '_Foo@Field#name'),
      ];
      expect(
        reader,
        IsInstance<LibraryReader>([
          HasClasses([
            const HasElement([HasName('_Foo')]),
            _hasDormDummyClass('Foo', fields),
            _hasDormDataClass('Foo', fields),
            _hasDormModelClass('Foo', fields),
            _hasDormDependencyClass('Foo', fields),
            _hasDormEntityClass(
              'Foo',
              fields,
              uidModel: const CustomUidModel('_Foo._generate'),
            ),
            _hasDormMainClass({'Model\$as': 'Foo'}),
          ]),
          HasExtensions([
            _hasDormModelExtension('Foo', fields),
          ]),
        ]),
      );
    });
  });
  group('Data', () {
    test('no *Fields', () async {
      final LibraryReader? reader = await _generate(r'''
      import 'package:dorm_annotations/dorm_annotations.dart';
      import 'package:dorm_framework/dorm_framework.dart';
      
      part 'models.dorm.dart';
      
      @Data()
      class _Foo {}
      ''');
      expect(
        reader,
        IsInstance<LibraryReader>([
          HasClasses([
            const HasElement([HasName('_Foo')]),
            _hasDormDataClass('Foo', [], rename: false),
            _hasDormMainClass({}),
          ]),
          const HasExtensions([]),
        ]),
      );
    });
  });
  group('ModelField', () {
    test('from Data', () async {
      final LibraryReader? reader = await _generate(r'''
      import 'package:dorm_annotations/dorm_annotations.dart';
      import 'package:dorm_framework/dorm_framework.dart';

      part 'models.dorm.dart';
      
      @Data()
      abstract class _Bar {
        @Field(name: '_Bar@Field#weight')
        double get weight;
      }

      @Model(name: 'Model\$name', as: #Model$as)
      class _Foo {
        @ModelField(name: '_Foo@ModelField#bar', referTo: _Bar)
        get bar;
      }
      ''');
      const List<ClassField> fields = [
        ClassField.data('Bar', 'bar', as: '_Foo@ModelField#bar'),
      ];
      expect(
        reader,
        IsInstance<LibraryReader>([
          HasClasses([
            const HasElement([HasName('_Foo')]),
            const HasElement([HasName('_Bar')]),
            _hasDormDataClass(
              'Bar',
              [
                const ClassField.data('double', 'weight',
                    as: '_Bar@Field#weight'),
              ],
              rename: false,
            ),
            _hasDormDataClass('Foo', fields),
            _hasDormModelClass('Foo', fields),
            _hasDormDependencyClass('Foo', fields),
            _hasDormEntityClass('Foo', fields),
            _hasDormMainClass({'Model\$as': 'Foo'}),
          ]),
          HasExtensions([
            _hasDormModelExtension('Foo', fields),
          ]),
        ]),
      );
    });
    test('from Model', () async {
      final LibraryReader? reader = await _generate(r'''
      import 'package:dorm_annotations/dorm_annotations.dart';
      import 'package:dorm_framework/dorm_framework.dart';
    
      part 'models.dorm.dart';
      
      @Model(name: 'Model\$name', as: #Model$asBar)
      abstract class _Bar {
        @Field(name: '_Bar@Field#weight')
        double get weight;
      }
    
      @Model(name: 'Model\$name', as: #Model$asFoo)
      class _Foo {
        @ModelField(name: '_Foo@ModelField#bar', referTo: _Bar)
        get bar;
      }
      ''');
      const List<ClassField> barFields = [
        ClassField.data('double', 'weight', as: '_Bar@Field#weight'),
      ];
      const List<ClassField> fooFields = [
        ClassField.data('BarData', 'bar', as: '_Foo@ModelField#bar'),
      ];
      expect(
        reader,
        IsInstance<LibraryReader>([
          HasClasses([
            const HasElement([HasName('_Foo')]),
            const HasElement([HasName('_Bar')]),
            _hasDormDataClass('Bar', barFields),
            _hasDormModelClass('Bar', barFields),
            _hasDormDependencyClass('Bar', barFields),
            _hasDormEntityClass('Bar', barFields),
            _hasDormDataClass('Foo', fooFields),
            _hasDormModelClass('Foo', fooFields),
            _hasDormDependencyClass('Foo', fooFields),
            _hasDormEntityClass('Foo', fooFields),
            _hasDormMainClass({'Model\$asBar': 'Bar', 'Model\$asFoo': 'Foo'}),
          ]),
          HasExtensions([
            _hasDormModelExtension('Foo', fooFields),
            _hasDormModelExtension('Bar', barFields),
          ]),
        ]),
      );
    });
    test('from List<Data>', () async {
      final LibraryReader? reader = await _generate(r'''
      import 'package:dorm_annotations/dorm_annotations.dart';
      import 'package:dorm_framework/dorm_framework.dart';

      part 'models.dorm.dart';
      
      @Data()
      abstract class _Bar {
        @Field(name: '_Bar@Field#weight')
        double get weight;
      }

      @Model(name: 'Model\$name', as: #Model$as)
      class _Foo {
        @ModelField(name: '_Foo@ModelField#bars', referTo: _Bar)
        List get bars;
      }
      ''');
      const List<ClassField> fields = [
        ClassField.data('List<Bar>', 'bars', as: '_Foo@ModelField#bars'),
      ];
      expect(
        reader,
        IsInstance<LibraryReader>([
          HasClasses([
            const HasElement([HasName('_Foo')]),
            const HasElement([HasName('_Bar')]),
            _hasDormDataClass(
              'Bar',
              [
                const ClassField.data('double', 'weight',
                    as: '_Bar@Field#weight'),
              ],
              rename: false,
            ),
            _hasDormDataClass('Foo', fields),
            _hasDormModelClass('Foo', fields),
            _hasDormDependencyClass('Foo', fields),
            _hasDormEntityClass('Foo', fields),
            _hasDormMainClass({'Model\$as': 'Foo'}),
          ]),
          HasExtensions([
            _hasDormModelExtension('Foo', fields),
          ]),
        ]),
      );
    });
    test('from List<Model>', () async {
      final LibraryReader? reader = await _generate(r'''
      import 'package:dorm_annotations/dorm_annotations.dart';
      import 'package:dorm_framework/dorm_framework.dart';
    
      part 'models.dorm.dart';
      
      @Model(name: 'Model\$name', as: #Model$asBar)
      abstract class _Bar {
        @Field(name: '_Bar@Field#weight')
        double get weight;
      }
    
      @Model(name: 'Model\$name', as: #Model$asFoo)
      class _Foo {
        @ModelField(name: '_Foo@ModelField#bars', referTo: _Bar)
        List get bars;
      }
      ''');
      const List<ClassField> barFields = [
        ClassField.data('double', 'weight', as: '_Bar@Field#weight'),
      ];
      const List<ClassField> fooFields = [
        ClassField.data('List<BarData>', 'bars', as: '_Foo@ModelField#bars'),
      ];
      expect(
        reader,
        IsInstance<LibraryReader>([
          HasClasses([
            const HasElement([HasName('_Foo')]),
            const HasElement([HasName('_Bar')]),
            _hasDormDataClass('Bar', barFields),
            _hasDormModelClass('Bar', barFields),
            _hasDormDependencyClass('Bar', barFields),
            _hasDormEntityClass('Bar', barFields),
            _hasDormDataClass('Foo', fooFields),
            _hasDormModelClass('Foo', fooFields),
            _hasDormDependencyClass('Foo', fooFields),
            _hasDormEntityClass('Foo', fooFields),
            _hasDormMainClass({'Model\$asBar': 'Bar', 'Model\$asFoo': 'Foo'}),
          ]),
          HasExtensions([
            _hasDormModelExtension('Foo', fooFields),
            _hasDormModelExtension('Bar', barFields),
          ]),
        ]),
      );
    });
  });
  group('ForeignField', () {
    test('Model', () async {
      final LibraryReader? reader = await _generate(r'''
      import 'package:dorm_annotations/dorm_annotations.dart';
      import 'package:dorm_framework/dorm_framework.dart';
    
      part 'models.dorm.dart';
    
      typedef _Bar = int 
    
      @Model(name: 'Model\$name', as: #Model$as)
      class _Foo {
        @ForeignField(name: '_Foo@ForeignField#barId', referTo: _Bar)
        String get barId;
      }
      ''');
      const List<ClassField> fields = [
        ClassField.model('String', 'barId', as: '_Foo@ForeignField#barId'),
      ];
      expect(
        reader,
        IsInstance<LibraryReader>([
          HasClasses([
            const HasElement([HasName('_Foo')]),
            _hasDormDataClass('Foo', fields),
            _hasDormModelClass('Foo', fields),
            _hasDormDependencyClass('Foo', fields),
            _hasDormEntityClass('Foo', fields),
            _hasDormMainClass({'Model\$as': 'Foo'}),
          ]),
          const HasExtensions([]),
        ]),
      );
    });
    test('Model: nullable', () async {
      final LibraryReader? reader = await _generate(r'''
      import 'package:dorm_annotations/dorm_annotations.dart';
      import 'package:dorm_framework/dorm_framework.dart';
    
      part 'models.dorm.dart';
    
      typedef _Bar = int 
    
      @Model(name: 'Model\$name', as: #Model$as)
      class _Foo {
        @ForeignField(name: '_Foo@ForeignField#barId', referTo: _Bar)
        String? get barId;
      }
      ''');
      const List<ClassField> fields = [
        ClassField.model('String?', 'barId', as: '_Foo@ForeignField#barId'),
      ];
      expect(
        reader,
        IsInstance<LibraryReader>([
          HasClasses([
            const HasElement([HasName('_Foo')]),
            _hasDormDataClass('Foo', fields),
            _hasDormModelClass('Foo', fields),
            _hasDormDependencyClass('Foo', fields),
            _hasDormEntityClass('Foo', fields),
            _hasDormMainClass({'Model\$as': 'Foo'}),
          ]),
          const HasExtensions([]),
        ]),
      );
    });
    test('Model: with Field', () async {
      final LibraryReader? reader = await _generate(r'''
      import 'package:dorm_annotations/dorm_annotations.dart';
      import 'package:dorm_framework/dorm_framework.dart';
    
      part 'models.dorm.dart';
    
      typedef _Bar = int 
    
      @Model(name: 'Model\$name', as: #Model$as)
      class _Foo {
        @Field(name: '_Foo@Field#active')
        bool get active;
    
        @ForeignField(name: '_Foo@ForeignField#barId', referTo: _Bar)
        String get barId;
      }
      ''');
      const List<ClassField> fields = [
        ClassField.data('bool', 'active', as: '_Foo@Field#active'),
        ClassField.model('String', 'barId', as: '_Foo@ForeignField#barId'),
      ];
      expect(
        reader,
        IsInstance<LibraryReader>([
          HasClasses([
            const HasElement([HasName('_Foo')]),
            _hasDormDataClass('Foo', fields),
            _hasDormModelClass('Foo', fields),
            _hasDormDependencyClass('Foo', fields),
            _hasDormEntityClass('Foo', fields),
            _hasDormMainClass({'Model\$as': 'Foo'})
          ]),
          const HasEnums([]),
          HasExtensions([
            _hasDormModelExtension('Foo', fields),
          ]),
        ]),
      );
    });
  });
  group('QueryField', () {
    test('by value', () async {
      final LibraryReader? reader = await _generate(r'''
      import 'package:dorm_annotations/dorm_annotations.dart';
      import 'package:dorm_framework/dorm_framework.dart';
      
      part 'models.dorm.dart';
      
      @Model(name: 'Model\$name', as: #Model$as)
      class _Foo {
        @Field(name: '_Foo@Field#quantity')
        int get quantity;
    
        @QueryField(name: '_Foo@QueryField#_q0', referTo: [QueryToken(#quantity)])
        String get _q0;
      }
      ''');
      const List<ClassField> fields = [
        ClassField.data('int', 'quantity', as: '_Foo@Field#quantity'),
        ClassField.query(
          'String',
          '_q0',
          as: '_Foo@QueryField#_q0',
          tokens: ['quantity'],
        ),
      ];
      expect(
        reader,
        IsInstance<LibraryReader>([
          HasClasses([
            const HasElement([HasName('_Foo')]),
            _hasDormDataClass('Foo', fields),
            _hasDormModelClass('Foo', fields),
            _hasDormDependencyClass('Foo', fields),
            _hasDormEntityClass('Foo', fields),
            _hasDormMainClass({'Model\$as': 'Foo'})
          ]),
          const HasEnums([]),
          HasExtensions([
            _hasDormModelExtension('Foo', fields),
          ]),
        ]),
      );
    });
    test('by text', () async {
      final LibraryReader? reader = await _generate(r'''
      import 'package:dorm_annotations/dorm_annotations.dart';
      import 'package:dorm_framework/dorm_framework.dart';
      
      part 'models.dorm.dart';
      
      @Model(name: 'Model\$name', as: #Model$as)
      class _Foo {
        @Field(name: '_Foo@Field#name')
        String get name;
    
        @QueryField(name: '_Foo@QueryField#_q1', referTo: [QueryToken(#name, QueryType.text)])
        String get _q1;
      }
      ''');
      const List<ClassField> fields = [
        ClassField.data('String', 'name', as: '_Foo@Field#name'),
        ClassField.query(
          'String',
          '_q1',
          as: '_Foo@QueryField#_q1',
          tokens: ['\$normalizeText(name)'],
        ),
      ];
      expect(
        reader,
        IsInstance<LibraryReader>([
          HasClasses([
            const HasElement([HasName('_Foo')]),
            _hasDormDataClass('Foo', fields),
            _hasDormModelClass('Foo', fields),
            _hasDormDependencyClass('Foo', fields),
            _hasDormEntityClass('Foo', fields),
            _hasDormMainClass({'Model\$as': 'Foo'})
          ]),
          const HasEnums([]),
          HasExtensions([
            _hasDormModelExtension('Foo', fields),
          ]),
        ]),
      );
    });
    test('by enum', () async {
      final LibraryReader? reader = await _generate(r'''
      import 'package:dorm_annotations/dorm_annotations.dart';
      import 'package:dorm_framework/dorm_framework.dart';
      
      part 'models.dorm.dart';
      
      enum State { on, off }
      
      @Model(name: 'Model\$name', as: #Model$as)
      class _Foo {
        @Field(name: '_Foo@Field#state')
        State get state;
    
        @QueryField(name: '_Foo@QueryField#_q2', referTo: [QueryToken(#state, QueryType.enumeration)])
        String get _q2;
      }
      ''');
      const List<ClassField> fields = [
        ClassField.data('State', 'state', as: '_Foo@Field#state'),
        ClassField.query(
          'String',
          '_q2',
          as: '_Foo@QueryField#_q2',
          tokens: ['\$normalizeEnum(state)'],
        ),
      ];
      expect(
        reader,
        IsInstance<LibraryReader>([
          HasClasses([
            const HasElement([HasName('_Foo')]),
            _hasDormDataClass('Foo', fields),
            _hasDormModelClass('Foo', fields),
            _hasDormDependencyClass('Foo', fields),
            _hasDormEntityClass('Foo', fields),
            _hasDormMainClass({'Model\$as': 'Foo'})
          ]),
          const HasEnums([
            HasElement([HasName('State')]),
          ]),
          HasExtensions([
            _hasDormModelExtension('Foo', fields),
          ]),
        ]),
      );
    });
    test('by value, nullable', () async {
      final LibraryReader? reader = await _generate(r'''
      import 'package:dorm_annotations/dorm_annotations.dart';
      import 'package:dorm_framework/dorm_framework.dart';
      
      part 'models.dorm.dart';
      
      @Model(name: 'Model\$name', as: #Model$as)
      class _Foo {
        @Field(name: '_Foo@Field#quantity')
        int? get quantity;
    
        @QueryField(name: '_Foo@QueryField#_q0', referTo: [QueryToken(#quantity)])
        String get _q0;
      }
      ''');
      const List<ClassField> fields = [
        ClassField.data('int?', 'quantity', as: '_Foo@Field#quantity'),
        ClassField.query(
          'String',
          '_q0',
          as: '_Foo@QueryField#_q0',
          tokens: ['quantity ?? \'\''],
        ),
      ];
      expect(
        reader,
        IsInstance<LibraryReader>([
          HasClasses([
            const HasElement([HasName('_Foo')]),
            _hasDormDataClass('Foo', fields),
            _hasDormModelClass('Foo', fields),
            _hasDormDependencyClass('Foo', fields),
            _hasDormEntityClass('Foo', fields),
            _hasDormMainClass({'Model\$as': 'Foo'})
          ]),
          const HasEnums([]),
          HasExtensions([
            _hasDormModelExtension('Foo', fields),
          ]),
        ]),
      );
    });
    test('by text, nullable', () async {
      final LibraryReader? reader = await _generate(r'''
      import 'package:dorm_annotations/dorm_annotations.dart';
      import 'package:dorm_framework/dorm_framework.dart';
      
      part 'models.dorm.dart';
      
      @Model(name: 'Model\$name', as: #Model$as)
      class _Foo {
        @Field(name: '_Foo@Field#name')
        String? get name;
    
        @QueryField(name: '_Foo@QueryField#_q1', referTo: [QueryToken(#name, QueryType.text)])
        String get _q1;
      }
      ''');
      const List<ClassField> fields = [
        ClassField.data('String?', 'name', as: '_Foo@Field#name'),
        ClassField.query(
          'String',
          '_q1',
          as: '_Foo@QueryField#_q1',
          tokens: ['\$normalizeText(name) ?? \'\''],
        ),
      ];
      expect(
        reader,
        IsInstance<LibraryReader>([
          HasClasses([
            const HasElement([HasName('_Foo')]),
            _hasDormDataClass('Foo', fields),
            _hasDormModelClass('Foo', fields),
            _hasDormDependencyClass('Foo', fields),
            _hasDormEntityClass('Foo', fields),
            _hasDormMainClass({'Model\$as': 'Foo'})
          ]),
          const HasEnums([]),
          HasExtensions([
            _hasDormModelExtension('Foo', fields),
          ]),
        ]),
      );
    });
    test('by enum, nullable', () async {
      final LibraryReader? reader = await _generate(r'''
      import 'package:dorm_annotations/dorm_annotations.dart';
      import 'package:dorm_framework/dorm_framework.dart';
      
      part 'models.dorm.dart';
      
      enum State { on, off }
      
      @Model(name: 'Model\$name', as: #Model$as)
      class _Foo {
        @Field(name: '_Foo@Field#state')
        State? get state;
    
        @QueryField(name: '_Foo@QueryField#_q2', referTo: [QueryToken(#state, QueryType.enumeration)])
        String get _q2;
      }
      ''');
      const List<ClassField> fields = [
        ClassField.data('State?', 'state', as: '_Foo@Field#state'),
        ClassField.query(
          'String',
          '_q2',
          as: '_Foo@QueryField#_q2',
          tokens: ['\$normalizeEnum(state) ?? \'\''],
        ),
      ];
      expect(
        reader,
        IsInstance<LibraryReader>([
          HasClasses([
            const HasElement([HasName('_Foo')]),
            _hasDormDataClass('Foo', fields),
            _hasDormModelClass('Foo', fields),
            _hasDormDependencyClass('Foo', fields),
            _hasDormEntityClass('Foo', fields),
            _hasDormMainClass({'Model\$as': 'Foo'})
          ]),
          const HasEnums([
            HasElement([HasName('State')]),
          ]),
          HasExtensions([
            _hasDormModelExtension('Foo', fields),
          ]),
        ]),
      );
    });
    test('multiple references', () async {
      final LibraryReader? reader = await _generate(r'''
      import 'package:dorm_annotations/dorm_annotations.dart';
      import 'package:dorm_framework/dorm_framework.dart';
      
      part 'models.dorm.dart';
      
      @Model(name: 'Model\$name', as: #Model$as)
      class _Foo {
        @Field(name: '_Foo@Field#valid')
        bool get valid;
        
        @Field(name: '_Foo@Field#text')
        String get text;
    
        @QueryField(name: '_Foo@QueryField#_q3', referTo: [QueryToken(#valid), QueryToken(#text, QueryType.text)])
        String get _q3;
      }
      ''');
      const List<ClassField> fields = [
        ClassField.data('bool', 'valid', as: '_Foo@Field#valid'),
        ClassField.data('String', 'text', as: '_Foo@Field#text'),
        ClassField.query(
          'String',
          '_q3',
          as: '_Foo@QueryField#_q3',
          tokens: ['valid', '\$normalizeText(text)'],
        ),
      ];
      expect(
        reader,
        IsInstance<LibraryReader>([
          HasClasses([
            const HasElement([HasName('_Foo')]),
            _hasDormDataClass('Foo', fields),
            _hasDormModelClass('Foo', fields),
            _hasDormDependencyClass('Foo', fields),
            _hasDormEntityClass('Foo', fields),
            _hasDormMainClass({'Model\$as': 'Foo'})
          ]),
          const HasEnums([]),
          HasExtensions([
            _hasDormModelExtension('Foo', fields),
          ]),
        ]),
      );
    });
    test('invalid reference', () async {
      await expectLater(
        _generate(r'''
        import 'package:dorm_annotations/dorm_annotations.dart';
        import 'package:dorm_framework/dorm_framework.dart';
      
        part 'models.dorm.dart';
        
        @Model(name: 'Model\$name', as: #Model$as)
        class _Foo {
          @Field(name: '_Foo@Field#width')
          double get width;
    
          @QueryField(name: '_Foo@QueryField#_q4', referTo: [QueryToken(#height)])
          String get _q4;
        }
        '''),
        throwsA(isStateError.having(
          (e) => e.message,
          'message',
          'field _Foo@QueryField#_q4/height must have a symbol referring to a valid field',
        )),
      );
    });
    test('multiple fields', () async {
      final LibraryReader? reader = await _generate(r'''
      import 'package:dorm_annotations/dorm_annotations.dart';
      import 'package:dorm_framework/dorm_framework.dart';
      
      part 'models.dorm.dart';
      
      @Model(name: 'Model\$name', as: #Model$as)
      class _Foo {
        @Field(name: '_Foo@Field#month')
        int get month;
        
        @Field(name: '_Foo@Field#description')
        String get description;
    
        @QueryField(name: '_Foo@QueryField#_q5', referTo: [QueryToken(#month)])
        String get _q5;
        
        @QueryField(name: '_Foo@QueryField#_q6', referTo: [QueryToken(#description, QueryType.text)])
        String get _q6;
      }
      ''');
      const List<ClassField> fields = [
        ClassField.data('int', 'month', as: '_Foo@Field#month'),
        ClassField.data('String', 'description', as: '_Foo@Field#description'),
        ClassField.query(
          'String',
          '_q5',
          as: '_Foo@QueryField#_q5',
          tokens: ['month'],
        ),
        ClassField.query(
          'String',
          '_q6',
          as: '_Foo@QueryField#_q6',
          tokens: ['\$normalizeText(description)'],
        ),
      ];
      expect(
        reader,
        IsInstance<LibraryReader>([
          HasClasses([
            const HasElement([HasName('_Foo')]),
            _hasDormDataClass('Foo', fields),
            _hasDormModelClass('Foo', fields),
            _hasDormDependencyClass('Foo', fields),
            _hasDormEntityClass('Foo', fields),
            _hasDormMainClass({'Model\$as': 'Foo'})
          ]),
          const HasEnums([]),
          HasExtensions([
            _hasDormModelExtension('Foo', fields),
          ]),
        ]),
      );
    });
    test('nested field name', () async {
      final LibraryReader? reader = await _generate(r'''
      import 'package:dorm_annotations/dorm_annotations.dart';
      import 'package:dorm_framework/dorm_framework.dart';
      
      part 'models.dorm.dart';
      
      @Model(name: 'Model\$name', as: #Model$as)
      class _Foo {
        @Field(name: '_Foo@Field#quantity')
        int get quantity;
    
        @QueryField(name: '_Foo@QueryField#query/_q0', referTo: [QueryToken(#quantity)])
        String get _q0;
      }
      ''');
      const List<ClassField> fields = [
        ClassField.data('int', 'quantity', as: '_Foo@Field#quantity'),
        ClassField.query(
          'String',
          '_q0',
          as: '_Foo@QueryField#query/_q0',
          tokens: ['quantity'],
        ),
      ];
      expect(
        reader,
        IsInstance<LibraryReader>([
          HasClasses([
            const HasElement([HasName('_Foo')]),
            _hasDormDataClass('Foo', fields),
            _hasDormModelClass('Foo', fields),
            _hasDormDependencyClass('Foo', fields),
            _hasDormEntityClass('Foo', fields),
            _hasDormMainClass({'Model\$as': 'Foo'})
          ]),
          const HasEnums([]),
          HasExtensions([
            _hasDormModelExtension('Foo', fields),
          ]),
        ]),
      );
    });
  });
  group('PolymorphicField', () {
    test('no Models', () async {
      final LibraryReader? reader = await _generate(r'''
      import 'package:dorm_annotations/dorm_annotations.dart';
      import 'package:dorm_framework/dorm_framework.dart';
    
      part 'models.dorm.dart';
    
      abstract class _Foo {}
    
      @PolymorphicData(name: 'bar', as: #FooBar$as)
      abstract class _FooBar implements _Foo {
        @Field(name: '_FooBar@Field#description')
        String get description;
      }
    
      @PolymorphicData(name: 'baz', as: #FooBaz$as)
      abstract class _FooBaz implements _Foo {
        @Field(name: '_FooBaz@Field#timestamp')
        DateTime get timestamp;
      }
      ''');
      expect(
        reader,
        IsInstance<LibraryReader>([
          const HasEnums([
            HasElement([
              HasName('FooType'),
              IsElement<EnumElement>([
                HasFields([
                  HasElement([HasType('FooType'), HasName('FooBar\$as')]),
                  HasElement([HasType('FooType'), HasName('FooBaz\$as')]),
                ]),
              ]),
            ]),
          ]),
          HasClasses([
            const HasElement([HasName('_Foo')]),
            const HasElement([HasName('_FooBar')]),
            const HasElement([HasName('_FooBaz')]),
            _hasDormBasePolymorphicClass(
                'Foo', {'FooBar': 'FooBar\$as', 'FooBaz': 'FooBaz\$as'}),
            _hasDormPolymorphicClass('FooBar', 'Foo', [
              const ClassField.data(
                'String',
                'description',
                as: '_FooBar@Field#description',
              ),
            ]),
            _hasDormPolymorphicClass('FooBaz', 'Foo', [
              const ClassField.data(
                'DateTime',
                'timestamp',
                as: '_FooBaz@Field#timestamp',
              ),
            ]),
            _hasDormMainClass({})
          ]),
        ]),
      );
    });
    test('no Models: as (default)', () async {
      final LibraryReader? reader = await _generate(r'''
      import 'package:dorm_annotations/dorm_annotations.dart';
      import 'package:dorm_framework/dorm_framework.dart';
    
      part 'models.dorm.dart';
    
      abstract class _Foo {}
    
      @PolymorphicData(name: 'bar')
      abstract class _FooBar implements _Foo {
        @Field(name: '_FooBar@Field#description')
        String get description;
      }
    
      @PolymorphicData(name: 'baz')
      abstract class _FooBaz implements _Foo {
        @Field(name: '_FooBaz@Field#timestamp')
        DateTime get timestamp;
      }
      ''');
      expect(
        reader,
        IsInstance<LibraryReader>([
          const HasEnums([
            HasElement([
              HasName('FooType'),
              IsElement<EnumElement>([
                HasFields([
                  HasElement([HasType('FooType'), HasName('fooBar')]),
                  HasElement([HasType('FooType'), HasName('fooBaz')]),
                ]),
              ]),
            ]),
          ]),
          HasClasses([
            const HasElement([HasName('_Foo')]),
            const HasElement([HasName('_FooBar')]),
            const HasElement([HasName('_FooBaz')]),
            _hasDormBasePolymorphicClass('Foo', {
              'FooBar': 'fooBar',
              'FooBaz': 'fooBaz',
            }),
            _hasDormPolymorphicClass('FooBar', 'Foo', [
              const ClassField.data(
                'String',
                'description',
                as: '_FooBar@Field#description',
              ),
            ]),
            _hasDormPolymorphicClass('FooBaz', 'Foo', [
              const ClassField.data(
                'DateTime',
                'timestamp',
                as: '_FooBaz@Field#timestamp',
              ),
            ]),
            _hasDormMainClass({})
          ]),
        ]),
      );
    });
    test('Model', () async {
      final LibraryReader? reader = await _generate(r'''
      import 'package:dorm_annotations/dorm_annotations.dart';
      import 'package:dorm_framework/dorm_framework.dart';
    
      part 'models.dorm.dart';
    
      abstract class _Bar {}
    
      @PolymorphicData(name: 'bar-1', as: #Bar1$as)
      abstract class _Bar1 implements _Bar {
        @Field(name: '_Bar1@Field#count')
        int get count;
      }
    
      @PolymorphicData(name: 'bar-2', as: #Bar2$as)
      abstract class _Bar2 implements _Bar {
        @Field(name: '_Bar2@Field#enabled')
        bool get enabled;
      }
        
      @Model(name: 'Model\$name', as: #Model$as)
      abstract class _Foo {
        @PolymorphicField(name: '_Foo@PolymorphicField#contents', pivotName: 'pivottype')
        _Bar get contents;
      }
      ''');
      final List<ClassField> fields = [
        const ClassField.data('Bar', 'contents', as: '_Foo@Field#contents'),
      ];
      expect(
        reader,
        IsInstance<LibraryReader>([
          const HasEnums([
            HasElement([
              HasName('BarType'),
              IsElement<EnumElement>([
                HasFields([
                  HasElement([HasType('BarType'), HasName('Bar1\$as')]),
                  HasElement([HasType('BarType'), HasName('Bar2\$as')]),
                ]),
              ]),
            ]),
          ]),
          HasClasses([
            const HasElement([HasName('_Bar')]),
            const HasElement([HasName('_Bar1')]),
            const HasElement([HasName('_Bar2')]),
            const HasElement([HasName('_Foo')]),
            _hasDormBasePolymorphicClass('Bar', {
              'Bar1': 'Bar1\$as',
              'Bar2': 'Bar2\$as',
            }),
            _hasDormPolymorphicClass('Bar1', 'Bar', [
              const ClassField.data('int', 'count', as: '_Bar1@Field#count'),
            ]),
            _hasDormPolymorphicClass('Bar2', 'Bar', [
              const ClassField.data('bool', 'enabled',
                  as: '_Bar2@Field#enabled'),
            ]),
            _hasDormDataClass('Foo', fields, polymorphicClassName: 'Bar'),
            _hasDormModelClass('Foo', fields, polymorphicClassName: 'Bar'),
            _hasDormDependencyClass('Foo', fields),
            _hasDormEntityClass('Foo', fields, polymorphicClassName: 'Bar'),
            _hasDormMainClass({'Model\$as': 'Foo'})
          ]),
        ]),
      );
    });
    test('Model: multiple interfaces', () async {
      await expectLater(
        _generate(r'''
      import 'package:dorm_annotations/dorm_annotations.dart';
      import 'package:dorm_framework/dorm_framework.dart';
    
      part 'models.dorm.dart';
    
      abstract class _Bar {}

      abstract class _Baz {}
    
      @PolymorphicData(name: 'bar-1', as: #Bar1$as)
      abstract class _Bar1 implements _Bar, _Baz {
        @Field(name: '_Bar1@Field#count')
        int get count;
      }
    
      @PolymorphicData(name: 'bar-2', as: #Bar2$as)
      abstract class _Bar2 implements _Bar {
        @Field(name: '_Bar2@Field#enabled')
        bool get enabled;
      }
        
      @Model(name: 'Model\$name', as: #Model$as)
      abstract class _Foo {
        @PolymorphicField(name: '_Foo@PolymorphicField#contents', pivotName: 'pivottype')
        _Bar get contents;
      }
      '''),
        throwsA(isStateError.having(
          (e) => e.message,
          'message',
          'the _Bar1 class annotated with PolymorphicData should contain a '
              'single supertype, found _Bar, _Baz',
        )),
      );
    });
    test('Model: with Field', () async {
      final LibraryReader? reader = await _generate(r'''
      import 'package:dorm_annotations/dorm_annotations.dart';
      import 'package:dorm_framework/dorm_framework.dart';
    
      part 'models.dorm.dart';
    
      abstract class _Bar {}
    
      @PolymorphicData(name: 'bar-1', as: #Bar1$as)
      abstract class _Bar1 implements _Bar {
        @Field(name: '_Bar1@Field#count')
        int get count;
      }
    
      @PolymorphicData(name: 'bar-2', as: #Bar2$as)
      abstract class _Bar2 implements _Bar {
        @Field(name: '_Bar2@Field#enabled')
        bool get enabled;
      }
        
      @Model(name: 'Model\$name', as: #Model$as)
      abstract class _Foo {
        @Field(name: '_Foo@PolymorphicField#year')
        int get year;
        
        @PolymorphicField(name: '_Foo@PolymorphicField#contents', pivotName: 'pivottype')
        _Bar get contents;
      }
      ''');
      final List<ClassField> fields = [
        const ClassField.data('int', 'year', as: '_Foo@Field#year'),
        const ClassField.data('Bar', 'contents', as: '_Foo@Field#contents'),
      ];
      expect(
        reader,
        IsInstance<LibraryReader>([
          const HasEnums([
            HasElement([
              HasName('BarType'),
              IsElement<EnumElement>([
                HasFields([
                  HasElement([HasType('BarType'), HasName('Bar1\$as')]),
                  HasElement([HasType('BarType'), HasName('Bar2\$as')]),
                ]),
              ]),
            ]),
          ]),
          HasClasses([
            const HasElement([HasName('_Bar')]),
            const HasElement([HasName('_Bar1')]),
            const HasElement([HasName('_Bar2')]),
            const HasElement([HasName('_Foo')]),
            _hasDormBasePolymorphicClass('Bar', {
              'Bar1': 'Bar1\$as',
              'Bar2': 'Bar2\$as',
            }),
            _hasDormPolymorphicClass('Bar1', 'Bar', [
              const ClassField.data('int', 'count', as: '_Bar1@Field#count'),
            ]),
            _hasDormPolymorphicClass('Bar2', 'Bar', [
              const ClassField.data('bool', 'enabled',
                  as: '_Bar2@Field#enabled'),
            ]),
            _hasDormDataClass('Foo', fields, polymorphicClassName: 'Bar'),
            _hasDormModelClass('Foo', fields, polymorphicClassName: 'Bar'),
            _hasDormDependencyClass('Foo', fields),
            _hasDormEntityClass('Foo', fields, polymorphicClassName: 'Bar'),
            _hasDormMainClass({'Model\$as': 'Foo'})
          ]),
        ]),
      );
    });
    test('Model: with QueryField', () async {
      final LibraryReader? reader = await _generate(r'''
      import 'package:dorm_annotations/dorm_annotations.dart';
      import 'package:dorm_framework/dorm_framework.dart';
    
      part 'models.dorm.dart';
    
      abstract class _Bar {}
    
      @PolymorphicData(name: 'bar-1', as: #Bar1$as)
      abstract class _Bar1 implements _Bar {
        @Field(name: '_Bar1@Field#count')
        int get count;
      }
    
      @PolymorphicData(name: 'bar-2', as: #Bar2$as)
      abstract class _Bar2 implements _Bar {
        @Field(name: '_Bar2@Field#enabled')
        bool get enabled;
      }
        
      @Model(name: 'Model\$name', as: #Model$as)
      abstract class _Foo { 
        @PolymorphicField(name: '_Foo@PolymorphicField#contents', pivotName: 'pivottype')
        _Bar get contents;
        
        @QueryField(name: '_Foo@PolymorphicField#_q', referTo: [QueryToken(#type, QueryType.enumeration)])
        String get _q;
      }
      ''');
      final List<ClassField> fields = [
        const ClassField.data('Bar', 'contents', as: '_Foo@Field#contents'),
        const ClassField.query(
          'String',
          '_q',
          as: '_Foo@PolymorphicField#_q',
          tokens: ['\$normalizeEnum(type)'],
        ),
      ];
      expect(
        reader,
        IsInstance<LibraryReader>([
          const HasEnums([
            HasElement([
              HasName('BarType'),
              IsElement<EnumElement>([
                HasFields([
                  HasElement([HasType('BarType'), HasName('Bar1\$as')]),
                  HasElement([HasType('BarType'), HasName('Bar2\$as')]),
                ]),
              ]),
            ]),
          ]),
          HasClasses([
            const HasElement([HasName('_Bar')]),
            const HasElement([HasName('_Bar1')]),
            const HasElement([HasName('_Bar2')]),
            const HasElement([HasName('_Foo')]),
            _hasDormBasePolymorphicClass('Bar', {
              'Bar1': 'Bar1\$as',
              'Bar2': 'Bar2\$as',
            }),
            _hasDormPolymorphicClass('Bar1', 'Bar', [
              const ClassField.data('int', 'count', as: '_Bar1@Field#count'),
            ]),
            _hasDormPolymorphicClass('Bar2', 'Bar', [
              const ClassField.data('bool', 'enabled',
                  as: '_Bar2@Field#enabled'),
            ]),
            _hasDormDataClass('Foo', fields, polymorphicClassName: 'Bar'),
            _hasDormModelClass('Foo', fields, polymorphicClassName: 'Bar'),
            _hasDormDependencyClass('Foo', fields),
            _hasDormEntityClass('Foo', fields, polymorphicClassName: 'Bar'),
            _hasDormMainClass({'Model\$as': 'Foo'})
          ]),
        ]),
      );
    });
  });
  group('_internal', () {
    test('\$CustomUidValue', () {
      const $CustomUidValue value = $CustomUidValue(_$ConstantReader());
      expect(
        () => value.when<void>(
          caseSimple: () {},
          caseComposite: () {},
          caseValue: (_) {},
        ),
        throwsA(isUnimplementedError),
      );
    });
  });
}

class _$ConstantReader implements ConstantReader {
  const _$ConstantReader();

  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw UnimplementedError();
  }
}
