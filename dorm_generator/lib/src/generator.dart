// dORM
// Copyright (C) 2023  Beet Software
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

// ignore_for_file: invalid_use_of_visible_for_testing_member

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart' as cb;
import 'package:dart_style/dart_style.dart';
import 'package:dartx/dartx.dart';
import 'package:dorm_annotations/dorm_annotations.dart';
import 'package:source_gen/source_gen.dart';

import 'migration_schema.dart';

import 'utils/custom_types.dart';
import 'utils/orm_node.dart';
import 'visitors.dart';

final Uri _jsonAnnotationUrl = Uri(
  scheme: 'package',
  pathSegments: ['json_annotation', 'json_annotation.dart'],
);
final Uri _copyWithAnnotationUrl = Uri(
  scheme: 'package',
  pathSegments: ['copy_with_extension', 'copy_with_extension.dart'],
);
final Uri _dormUrl = Uri(
  scheme: 'package',
  pathSegments: ['dorm', 'dorm.dart'],
);
const String _identityGeneratorName = r'$dorm$generateId';

cb.Expression expressionOf(String code) => cb.CodeExpression(cb.Code(code));

class Naming<N extends ClassOrmNode> {
  final String name;
  final N node;

  const Naming({required this.name, required this.node});
}

/// Naming of code generation.
class DataNaming extends Naming<DataOrmNode> {
  const DataNaming({required super.name, required super.node});

  /// _User
  String get schemaName => name;

  /// User
  String get modelName => name.removePrefix('_');
}

class _PrimaryKeyNaming {
  final String fieldName;
  final String columnName;
  final cb.Reference type;
  final String dartType;
  final bool generated;
  final bool databaseGenerated;

  const _PrimaryKeyNaming({
    required this.fieldName,
    required this.columnName,
    required this.type,
    required this.dartType,
    required this.generated,
    this.databaseGenerated = false,
  });
}

class ModelNaming extends Naming<ModelOrmNode> {
  final Map<String, FieldOrmNode>? fields;

  const ModelNaming({required super.name, required super.node, this.fields});

  MethodElement? get identityGenerator {
    final ClassElement? element = node.element;
    if (element == null) return null;
    for (final MethodElement method in element.methods) {
      if (method.name == _identityGeneratorName) return method;
    }
    return null;
  }

  /// _User
  String get schemaName => name;

  /// _$User
  String get dummyName => '_\$$modelName';

  /// User
  String get modelName => schemaName.removePrefix('_');

  /// UserData
  String get dataName => '${modelName}Data';

  /// UserDependency
  String get dependencyName => '${modelName}Dependency';

  /// UserEntity
  String get entityName => '${modelName}Entity';

  /// user
  String get _defaultRepositoryName => modelName.decapitalize();

  String get repositoryName =>
      (node.annotation.as as $Symbol?)?.name ?? _defaultRepositoryName;

  String get tableName => node.annotation.name ?? modelName.decapitalize();

  /// UserProperties
  String get extensionName => '${modelName}Properties';

  /// UserFields
  String get fieldsName => '${modelName}Fields';

  List<_PrimaryKeyNaming> get _primaryKeys =>
      node.annotation.primaryKey.map(_resolvePrimaryKey).toList();

  _PrimaryKeyNaming get _primaryKey {
    final List<_PrimaryKeyNaming> keys = _primaryKeys;
    if (keys.length != 1) {
      throw StateError(
        '$schemaName has a composite primary key where a single key is '
        'required.',
      );
    }
    return keys.single;
  }

  _PrimaryKeyNaming _resolvePrimaryKey(IdSpec spec) {
    return switch (spec) {
      GeneratedIdSpec generated => _PrimaryKeyNaming(
        fieldName: _symbolName(generated.as) ?? 'id',
        columnName: generated.name,
        type: cb.Reference(switch (generated.type) {
          $Type type => type.name ?? 'String',
          _ => generated.type.toString(),
        }),
        dartType: switch (generated.type) {
          $Type type => type.name ?? 'String',
          _ => generated.type.toString(),
        },
        generated: true,
      ),
      DatabaseGeneratedIdSpec generated => _PrimaryKeyNaming(
        fieldName: _symbolName(generated.as) ?? 'id',
        columnName: generated.name,
        type: cb.Reference(switch (generated.type) {
          $Type type => type.name ?? 'String',
          _ => generated.type.toString(),
        }),
        dartType: switch (generated.type) {
          $Type type => type.name ?? 'String',
          _ => generated.type.toString(),
        },
        generated: true,
        databaseGenerated: true,
      ),
      ExistingIdSpec existing => _existingPrimaryKey(existing),
    };
  }

  _PrimaryKeyNaming _existingPrimaryKey(ExistingIdSpec existing) {
    final String? fieldName = _symbolName(existing.referTo);
    if (fieldName == null || fieldName.isEmpty) {
      throw StateError(
        '$schemaName has an ExistingIdSpec without a valid field symbol.',
      );
    }
    final FieldOrmNode? field = fields?[fieldName];
    if (field == null) {
      throw StateError(
        '$schemaName primary key refers to missing field $fieldName.',
      );
    }
    if (!field.annotation.isConcrete) {
      throw StateError(
        '$schemaName primary key $fieldName must refer to a persisted '
        'field, not a derived field.',
      );
    }
    if (!field.required) {
      throw StateError(
        '$schemaName primary key $fieldName must be non-nullable.',
      );
    }
    return _PrimaryKeyNaming(
      fieldName: fieldName,
      columnName: field.annotation.name ?? fieldName,
      type: cb.Reference(field.type),
      dartType: field.type,
      generated: false,
    );
  }

  String get idFieldName => _primaryKey.fieldName;

  String get idColumnName => _primaryKey.columnName;

  cb.Reference get idReference => _primaryKeys.length == 1
      ? _primaryKey.type
      : cb.Reference('CompositeKey', '$_dormUrl');

  cb.Reference get creationReference => cb.TypeReference((b) {
    b.symbol = isCompositePrimaryKey ? 'ExplicitCreation' : 'SimpleCreation';
    b.url = '$_dormUrl';
    b.types.add(cb.Reference(dataName));
    b.types.add(idReference);
  });

  bool get isCompositePrimaryKey => _primaryKeys.length > 1;

  bool get isGeneratedPrimaryKey =>
      _primaryKeys.length == 1 &&
      _primaryKeys.single.generated &&
      !_primaryKeys.single.databaseGenerated;

  bool get isDatabaseGeneratedPrimaryKey =>
      _primaryKeys.length == 1 && _primaryKeys.single.databaseGenerated;

  String get identityGenerationStrategy =>
      switch ((isDatabaseGeneratedPrimaryKey, isGeneratedPrimaryKey)) {
        (true, _) => 'database',
        (false, true) => 'engine',
        (false, false) => 'explicit',
      };

  List<String> get primaryKeyFieldNames =>
      _primaryKeys.map((key) => key.fieldName).toList();
}

class _GeneratedRelation {
  final ModelNaming current;
  final ModelNaming target;
  final String name;
  final String fieldName;
  final bool inverse;
  final bool unique;

  const _GeneratedRelation({
    required this.current,
    required this.target,
    required this.name,
    required this.fieldName,
    required this.inverse,
    required this.unique,
  });
}

String? _symbolName(Symbol? symbol) {
  return symbol is $Symbol ? symbol.name : null;
}

String _defaultRelationName(String fieldName) {
  if (fieldName.endsWith('Id') && fieldName.length > 2) {
    return fieldName.substring(0, fieldName.length - 2);
  }
  return fieldName;
}

class PolymorphicDataNaming extends Naming<PolymorphicDataOrmNode> {
  const PolymorphicDataNaming({required super.name, required super.node});

  /// _Circle
  String get schemaName => name;

  /// Circle
  String get modelName => schemaName.removePrefix('_');

  /// circle
  String get _defaultEnumFieldName => modelName.decapitalize();

  /// circular
  String get enumFieldName =>
      (node.annotation.as as $Symbol?)?.name ?? _defaultEnumFieldName;

  TagNaming get tag => TagNaming(node.tag.value);
}

class TagNaming {
  /// _Shape
  final String schemaName;

  const TagNaming(this.schemaName);

  /// Shape
  String get modelName => schemaName.removePrefix('_');

  /// ShapeType
  String get enumName => '${modelName}Type';
}

/// Arguments of code generation.
abstract class Args<A, F, N> {
  final Map<String, FieldedOrmNode<Object>> nodes;
  final A annotation;
  final Map<String, F> fields;
  final N naming;

  const Args({
    required this.nodes,
    required this.annotation,
    required this.fields,
    required this.naming,
  });

  void accept(cb.LibraryBuilder b);
}

abstract class FieldedArgs<A, N> extends Args<A, FieldOrmNode, N> {
  const FieldedArgs({
    required super.nodes,
    required super.annotation,
    required super.fields,
    required super.naming,
  });

  cb.Class newClass({required String name, required Spec spec}) {
    final bool supportsSerialization =
        spec.supportsSerialization ||
        fields.where((field) => field.isNative).isNotEmpty;

    final List<PolymorphicField> polymorphicFields = fields.values
        .map((field) => field.annotation)
        .whereType<PolymorphicField>()
        .toList();
    if (spec.isCompositePrimaryKey && polymorphicFields.isNotEmpty) {
      throw StateError(
        '$name cannot combine a composite primary key with polymorphic '
        'fields in this generator stage.',
      );
    }

    return cb.Class((b) {
      b.name = name;
      final cb.Reference? extendsReference = spec.extendsReference;
      if (extendsReference != null) {
        b.extend = extendsReference;
      }
      final List<cb.Reference> implementsReferences = spec.implementsReferences;
      if (implementsReferences.isNotEmpty) {
        b.implements.addAll(implementsReferences);
      }
      b.fields.addAll([
        if (spec.includesPrimaryKey &&
            spec.primaryKeyIsGenerated &&
            !spec.isCompositePrimaryKey)
          cb.Field((b) {
            if (spec.supportsSerialization) {
              b.annotations.add(
                cb.InvokeExpression.newOf(
                  cb.Reference('JsonKey', '$_jsonAnnotationUrl'),
                  [],
                  {
                    'name': cb.literalString('_id'),
                    'required': cb.literalTrue,
                    'disallowNullValue': cb.literalTrue,
                  },
                ),
              );
            }
            b.modifier = cb.FieldModifier.final$;
            b.type = spec.primaryKeyType ?? cb.Reference('String');
            b.name = spec.primaryKeyName;
          }),
        ...fields.entries.expand((entry) sync* {
          final String declaredPropertyName = entry.key;
          final FieldOrmNode declaredPropertyInfo = entry.value;
          final String declaredPropertyTypeLabel = declaredPropertyInfo.type;
          final Field field = declaredPropertyInfo.annotation;
          if (!spec.shouldDeclare(declaredPropertyName, field)) return;

          final String? key = field.name;
          final ConstantReader? defaultValueReader =
              field.defaultValue as ConstantReader?;
          final bool required =
              (defaultValueReader == null || defaultValueReader.isNull) &&
              declaredPropertyInfo.required;
          final cb.Expression? defaultValueExpression;
          if (defaultValueReader == null || defaultValueReader.isNull) {
            defaultValueExpression = null;
          } else if (defaultValueReader.isLiteral) {
            defaultValueExpression = cb.literal(
              defaultValueReader.literalValue,
            );
          } else {
            final revivable = defaultValueReader.revive();
            defaultValueExpression = revivable.accessor.isNotEmpty
                ? expressionOf(revivable.accessor)
                : expressionOf('$revivable');
          }

          yield cb.Field((b) {
            b.name = declaredPropertyName;
            if (!spec.ignoreOverrideFor.contains(declaredPropertyName) &&
                (extendsReference != null || implementsReferences.isNotEmpty)) {
              b.annotations.add(expressionOf('override'));
            }
            if (spec.supportsSerialization) {
              b.annotations.add(
                cb.InvokeExpression.newOf(
                  cb.Reference('JsonKey', '$_jsonAnnotationUrl'),
                  [],
                  {
                    if (key != null)
                      'name': cb.literalString(
                        spec.isExistingPrimaryKey(declaredPropertyName)
                            ? spec.primaryKeyJsonName(declaredPropertyName)
                            : key,
                      ),
                    if (required) 'required': cb.literalTrue,
                    if (required) 'disallowNullValue': cb.literalTrue,
                    if (defaultValueExpression != null)
                      'defaultValue': defaultValueExpression,
                  },
                ),
              );
            }
            b.modifier = cb.FieldModifier.final$;
            b.type = switch (spec.resolveTypeFromField(
              field,
              declaredPropertyTypeLabel,
            )) {
              DirectSpecTypeResolution resolution => resolution.reference,
              IndirectSpecTypeResolution resolution => resolution.referenceBy(
                (referredType) => nodes[referredType.name]?.annotation,
              ),
            };
          });
        }),
        if (spec.discriminatorSpec case (
          cb.Reference enumReference,
          String enumEntryName,
        ))
          cb.Field((b) {
            b.annotations.add(expressionOf('override'));
            b.modifier = cb.FieldModifier.final$;
            b.type = enumReference;
            b.name = 'type';
            b.assignment = enumReference.property(enumEntryName).code;
          }),
      ]);
      final bool hasFields = b.fields.isNotEmpty;
      if (hasFields && supportsSerialization) {
        b.annotations.add(
          cb.InvokeExpression.newOf(
            cb.Reference('JsonSerializable', '$_jsonAnnotationUrl'),
            [],
            {
              'anyMap': cb.literalTrue,
              'explicitToJson': cb.literalTrue,
              if (polymorphicFields.isNotEmpty)
                'constructor': cb.literalString('_'),
            },
          ),
        );
      }
      if (spec.generatesCopyWith) {
        b.annotations.add(
          cb.InvokeExpression.newOf(
            cb.Reference('CopyWith', '$_copyWithAnnotationUrl'),
            [],
            {'skipFields': cb.literalTrue},
          ),
        );
      }
      b.constructors.addAll([
        // `fromJson` factory method
        if (hasFields && supportsSerialization)
          cb.Constructor((b) {
            b.factory = true;
            b.name = 'fromJson';
            if (spec.includesPrimaryKey) {
              b.requiredParameters.add(
                cb.Parameter((b) {
                  b.type = spec.primaryKeyType ?? cb.Reference('String');
                  b.name = 'id';
                }),
              );
            }
            b.requiredParameters.add(
              cb.Parameter((b) {
                b.type = cb.Reference('Map');
                b.name = 'json';
              }),
            );
            b.lambda = true;
            b.body = cb.ToCodeExpression(
              expressionOf('_\$${name}FromJson').call([
                spec.includesPrimaryKey
                    ? cb.literalMap({
                        cb.literalSpread(): expressionOf('json'),
                        ..._primaryKeyJsonEntries(spec),
                      })
                    : expressionOf('json'),
              ]),
            );
          }),
        // Polymorphic constructor
        if (polymorphicFields.isNotEmpty)
          cb.Constructor((b) {
            b.factory = true;
            b.name = '_';
            if (spec.includesPrimaryKey) {
              b.optionalParameters.add(
                cb.Parameter((b) {
                  b.required = true;
                  b.named = true;
                  b.type = spec.primaryKeyType ?? cb.Reference('String');
                  b.name = spec.primaryKeyName;
                }),
              );
            }
            b.optionalParameters.addAll(
              fields
                  .where(
                    (field) =>
                        field.isConcrete &&
                        (spec.shouldDeclareField(field) ||
                            extendsReference != null),
                  )
                  .entries
                  .expand((entry) sync* {
                    final String fieldName = entry.key;
                    final String fieldType = entry.value.type;

                    final Field field = entry.value.annotation;
                    if (spec.isExistingPrimaryKey(fieldName)) return;
                    if (field is PolymorphicField) {
                      yield cb.Parameter((b) {
                        b.required = true;
                        b.named = true;
                        b.type = cb.Reference('Map');
                        b.name = fieldName;
                      });
                    } else if (field is ModelField) {
                      final $Type value = field.referTo as $Type;
                      final cb.Reference type = switch (spec
                          .resolveTypeFromField(field, value.name!)) {
                        DirectSpecTypeResolution resolution =>
                          resolution.reference,
                        IndirectSpecTypeResolution resolution =>
                          resolution.referenceBy(
                            (referredType) =>
                                nodes[referredType.name]?.annotation,
                          ),
                      };
                      yield cb.Parameter((b) {
                        b.required = true;
                        b.named = true;
                        b.type = type;
                        b.name = fieldName;
                      });
                    } else {
                      yield cb.Parameter((b) {
                        b.required = true;
                        b.named = true;
                        b.type = cb.Reference(fieldType);
                        b.name = fieldName;
                      });
                    }
                  }),
            );
            b.lambda = false;
            b.body = cb.Block((b) {
              if (extendsReference != null) {
                b.statements.add(
                  cb
                      .declareFinal('data', type: extendsReference)
                      .assign(
                        cb.InvokeExpression.newOf(
                          extendsReference,
                          [],
                          Map.fromEntries(
                            fields
                                .where((field) => field.isNative)
                                .entries
                                .expand((entry) sync* {
                                  final String fieldName = entry.key;
                                  if (spec.isExistingPrimaryKey(fieldName)) {
                                    return;
                                  }
                                  yield MapEntry(
                                    fieldName,
                                    expressionOf(fieldName),
                                  );
                                }),
                          ),
                          [],
                          '_',
                        ),
                      )
                      .statement,
                );
              }
              b.statements.add(
                cb.InvokeExpression.newOf(cb.Reference(name), [], {
                  if (spec.includesPrimaryKey)
                    spec.primaryKeyName: expressionOf('id'),
                  ...Map.fromEntries(
                    fields.where((field) => field.isConcrete).entries.expand((
                      entry,
                    ) sync* {
                      final String fieldName = entry.key;
                      final String fieldType = entry.value.type;

                      final Field field = entry.value.annotation;
                      if (spec.isExistingPrimaryKey(fieldName) ||
                          !(spec.shouldDeclare(fieldName, field) ||
                              extendsReference != null)) {
                        return;
                      }

                      final cb.Expression? rootExpression =
                          extendsReference == null
                          ? null
                          : expressionOf('data');

                      final cb.Expression fieldExpression;
                      if (rootExpression == null ||
                          entry.value.annotation is ForeignField) {
                        fieldExpression = expressionOf(fieldName);
                      } else {
                        fieldExpression = rootExpression.property(fieldName);
                      }

                      if (field is PolymorphicField) {
                        final $ConcreteSymbol pivotSymbol =
                            field.pivotAs as $ConcreteSymbol;
                        yield MapEntry(
                          pivotSymbol.name,
                          rootExpression == null
                              ? expressionOf(pivotSymbol.name)
                              : rootExpression.property(pivotSymbol.name),
                        );
                        if (extendsReference == null) {
                          yield MapEntry(
                            fieldName,
                            cb.InvokeExpression.newOf(
                              cb.Reference(fieldType.substring(1)),
                              [
                                expressionOf(pivotSymbol.name),
                                expressionOf(fieldName),
                              ],
                              {},
                              [],
                              'fromType',
                            ),
                          );
                        } else {
                          yield MapEntry(fieldName, fieldExpression);
                        }
                      } else {
                        yield MapEntry(fieldName, fieldExpression);
                      }
                    }),
                  ),
                }).returned.statement,
              );
            });
          }),
        // Default constructor
        cb.Constructor((b) {
          b.constant = true;
          if (spec.includesPrimaryKey) {
            b.optionalParameters.addAll(
              (spec.isCompositePrimaryKey
                      ? spec.primaryKeyNames
                      : [spec.primaryKeyName])
                  .map(
                    (name) => cb.Parameter((b) {
                      b.required = true;
                      b.named = true;
                      b.toThis = true;
                      b.name = name;
                    }),
                  ),
            );
          }
          b.optionalParameters.addAll(
            fields.entries.expand((entry) sync* {
              final String fieldName = entry.key;
              final Field field = entry.value.annotation;
              if (spec.isExistingPrimaryKey(fieldName)) return;
              // Only concrete fields should be considered on the constructor
              // Virtual fields will be added as overridden getters
              if (!field.isConcrete) return;

              final bool declaresField = spec.shouldDeclare(fieldName, field);
              if (!declaresField && extendsReference == null) return;
              yield cb.Parameter((b) {
                b.required = true;
                b.named = true;
                final bool toThis = declaresField;
                b.toThis = toThis;
                b.toSuper = !toThis;
                b.name = fieldName;
              });
            }),
          );
        }),
      ]);
      b.methods.addAll([
        if (spec.includesQueryGetters) ...fields.queryGetters,
        // toJson method
        cb.Method((b) {
          if (!spec.ignoreOverrideFor.contains('toJson') &&
              (extendsReference != null || implementsReferences.isNotEmpty)) {
            b.annotations.add(expressionOf('override'));
          }
          b.returns = cb.TypeReference((b) {
            b.symbol = 'Map';
            b.types.add(cb.Reference('String'));
            b.types.add(cb.Reference('Object?'));
          });
          b.name = 'toJson';

          final bool lambda =
              !(hasFields && supportsSerialization) ||
              !spec.includesQueryGetters;
          b.lambda = lambda;

          final cb.Code body;
          if (supportsSerialization && hasFields) {
            final Map<String, cb.Expression>? queryObject;
            if (lambda) {
              queryObject = null;
            } else {
              queryObject = {};
              final Map<String, Map<String, Object>> queries = {};
              for (MapEntry<String, FieldOrmNode> entry
                  in fields
                      .where((field) => field.isA<DerivedField>())
                      .entries) {
                final String? name =
                    (entry.value.annotation as DerivedField).name;
                if (name == null) continue;
                final List<String> segments = name.split('/');
                final cb.Expression child = expressionOf(entry.key);
                if (segments.length == 1) {
                  queryObject[name] = child;
                } else {
                  queries.putIfAbsent(segments[0], () => {})[segments[1]] =
                      child;
                }
              }
              if (queries.isNotEmpty) {
                for (MapEntry<String, Map<String, Object>> entry
                    in queries.entries) {
                  queryObject[entry.key] = cb.literalMap(entry.value);
                }
              }
            }

            final cb.Expression baseExpression = cb.InvokeExpression.newOf(
              cb.Reference('_\$${name}ToJson'),
              [expressionOf('this')],
            );
            if (queryObject == null) {
              body = cb.ToCodeExpression(baseExpression);
            } else {
              cb.Expression cleanedExpression = baseExpression;
              for (final String key in spec.primaryKeyNames.map(
                spec.primaryKeyJsonName,
              )) {
                cleanedExpression = cleanedExpression.cascade('remove').call([
                  cb.literalString(key),
                ]);
              }
              body = cb
                  .literalMap({
                    cb.literalSpread(): cleanedExpression,
                    ...queryObject,
                  })
                  .returned
                  .statement;
            }
          } else {
            body = cb.ToCodeExpression(cb.literalConstMap({}));
          }
          b.body = body;
        }),
      ]);
    });
  }
}

class DataArgs extends FieldedArgs<Data, DataNaming> {
  const DataArgs({
    required super.nodes,
    required super.annotation,
    required super.fields,
    required super.naming,
  });

  @override
  void accept(cb.LibraryBuilder b) {
    b.body.add(
      newClass(
        name: naming.modelName,
        spec: Spec(
          includesPrimaryKey: false,
          supportsSerialization: true,
          extendsReference: null,
          implementsReferences: [cb.Reference(naming.schemaName)],
          includesQueryGetters: false,
          ignoreOverrideFor: {'toJson'},
          discriminatorSpec: null,
          generatesCopyWith: false,
          shouldDeclareField: (field) => field.isNative,
        ),
      ),
    );
  }
}

class ModelArgs extends FieldedArgs<Model, ModelNaming> {
  const ModelArgs({
    required super.nodes,
    required super.annotation,
    required super.fields,
    required super.naming,
  });

  cb.Expression get _primaryKeyExpression {
    final MethodElement? generator = naming.identityGenerator;
    if (generator == null) return expressionOf('creation.id');
    final cb.Expression generated = cb.InvokeExpression.newOf(
      cb.Reference('${naming.schemaName}.$_identityGeneratorName'),
      [
        cb.InvokeExpression.newOf(
          cb.Reference(naming.dummyName),
          [
            expressionOf('creation.dependency as ${naming.dependencyName}'),
            expressionOf('creation.data'),
          ],
          {},
          [],
          'fromData',
        ),
        expressionOf('creation.id'),
      ],
    );
    return expressionOf(
      'creation.identitySource == CreationIdentitySource.generated',
    ).conditional(generated, expressionOf('creation.id'));
  }

  cb.Spec get _dummyClass {
    final String className = naming.dummyName;
    return cb.Class((b) {
      b.name = className;
      b.implements.add(cb.Reference(naming.schemaName));
      b.fields.addAll(
        fields.where((field) => field.isConcrete).entries.map((entry) {
          return cb.Field((b) {
            b.annotations.add(expressionOf('override'));
            b.modifier = cb.FieldModifier.final$;
            b.type = cb.Reference(entry.value.type);
            b.name = entry.key;
          });
        }),
      );
      b.constructors.add(
        cb.Constructor((b) {
          b.factory = true;
          b.name = 'fromData';
          b.requiredParameters.add(
            cb.Parameter((b) {
              b.type = cb.Reference(naming.dependencyName);
              b.name = 'dependency';
            }),
          );
          b.requiredParameters.add(
            cb.Parameter((b) {
              b.type = cb.Reference(naming.dataName);
              b.name = 'data';
            }),
          );
          b.body = cb.ToCodeExpression(
            cb.InvokeExpression.newOf(
              expressionOf(className),
              [],
              fields.where((field) => field.isConcrete).map((name, field) {
                final cb.Expression expression = expressionOf(
                  field.annotation is ForeignField ? 'dependency' : 'data',
                );
                return MapEntry(name, expression.property(name));
              }),
            ),
          );
        }),
      );
      b.constructors.add(
        cb.Constructor((b) {
          b.constant = true;
          b.optionalParameters.addAll(
            fields.where((field) => field.isConcrete).keys.map((name) {
              return cb.Parameter((b) {
                b.required = true;
                b.named = true;
                b.toThis = true;
                b.name = name;
              });
            }),
          );
        }),
      );
      final Iterable<cb.Method> queryGetters = fields.queryGetters;
      b.methods.addAll(queryGetters);
      final List<String> privateQueryGettersNames = queryGetters
          .mapNotNull((method) => method.name)
          .where((methodName) => methodName.startsWith('_'))
          .toList();
      if (privateQueryGettersNames.isNotEmpty) {
        b.methods.add(
          cb.Method.returnsVoid((b) {
            b.type = cb.MethodType.getter;
            b.name = '\$dorm\$privateFields';
            b.lambda = true;
            b.body = cb
                .literalList(privateQueryGettersNames.map(expressionOf))
                .code;
          }),
        );
      }
    });
  }

  cb.Spec get _dependencyClass {
    return cb.Class((b) {
      b.name = naming.dependencyName;
      b.extend = cb.TypeReference((b) {
        b.symbol = 'Dependency';
        b.url = '$_dormUrl';
        b.types.add(cb.Reference(naming.dataName));
      });
      b.fields.addAll(
        fields.where((field) => field.isForeign).entries.map((entry) {
          return cb.Field((b) {
            b.modifier = cb.FieldModifier.final$;
            b.type = cb.Reference(entry.value.type);
            b.name = entry.key;
          });
        }),
      );
      if (fields.where((field) => field.isForeign).isEmpty) {
        b.constructors.add(
          cb.Constructor((b) {
            b.constant = true;
            b.initializers.add(
              cb.ToCodeExpression(
                expressionOf('super').property('strong').call([]),
              ),
            );
          }),
        );
      } else {
        b.constructors.add(
          cb.Constructor((b) {
            b.constant = false;
            b.optionalParameters.addAll(
              fields.where((field) => field.isForeign).keys.map((name) {
                return cb.Parameter((b) {
                  b.required = true;
                  b.named = true;
                  b.toThis = true;
                  b.name = name;
                });
              }),
            );
            b.initializers.add(
              cb.ToCodeExpression(
                expressionOf('super').property('weak').call([
                  cb.literalList(
                    fields.where((field) => field.isForeign).entries.map((
                      entry,
                    ) {
                      cb.Expression expression = expressionOf(entry.key);
                      return expression;
                    }),
                  ),
                ]),
              ),
            );
          }),
        );
      }
    });
  }

  ModelNaming _foreignTargetNaming(ForeignField field) {
    final $Type targetType = field.referTo as $Type;
    final String? targetName = targetType.name;
    final FieldedOrmNode<Object>? targetNode = targetName == null
        ? null
        : nodes[targetName];
    final ClassOrmNode<Object>? targetClass = targetNode?.annotation;
    if (targetName == null || targetClass is! ModelOrmNode) {
      throw StateError(
        'Foreign field in ${naming.schemaName} must refer to a model '
        'annotated with @Model(), found ${targetType.name ?? 'unknown'}.',
      );
    }
    return ModelNaming(
      name: targetName,
      node: targetClass,
      fields: targetNode!.fields,
    );
  }

  String _foreignTargetTableName(ForeignField field) {
    return _foreignTargetNaming(field).tableName;
  }

  cb.Expression _fieldSchema(String fieldName, FieldOrmNode node) {
    final Field field = node.annotation;
    final String columnName = field.name ?? fieldName;
    if (field is ForeignField) {
      return cb.InvokeExpression.constOf(
        cb.Reference('ForeignKeySchema', '$_dormUrl'),
        [],
        {
          'fieldName': cb.literalString(fieldName),
          'columnName': cb.literalString(columnName),
          'targetTableName': cb.literalString(_foreignTargetTableName(field)),
          'targetColumnName': cb.literalString(
            _foreignTargetNaming(field).idColumnName,
          ),
          'unique': cb.literalBool(field.unique),
        },
      );
    }
    return cb.InvokeExpression.constOf(
      cb.Reference('FieldSchema', '$_dormUrl'),
      [],
      {
        'fieldName': cb.literalString(fieldName),
        'columnName': cb.literalString(columnName),
      },
    );
  }

  cb.Expression _derivedFieldSchema(String fieldName, FieldOrmNode node) {
    final DerivedField field = node.annotation as DerivedField;
    final String name = field.name ?? fieldName;
    final List<String> path = name.split('/');
    if (path.length > 2 || path.any((segment) => segment.isEmpty)) {
      throw StateError(
        'Derived field $fieldName must use a simple name or a root/child path.',
      );
    }
    return cb.InvokeExpression.constOf(
      cb.Reference('DerivedFieldSchema', '$_dormUrl'),
      [],
      {
        'fieldName': cb.literalString(fieldName),
        'columnName': cb.literalString(name),
        'path': cb.literalList(path.map(cb.literalString)),
        'storageName': cb.literalString(path.first),
      },
    );
  }

  String _derivedSchemaFieldName(String fieldName) {
    final String publicName = fieldName.removePrefix('_');
    if (publicName.isEmpty) {
      throw StateError(
        'Derived field $fieldName must have a public schema name.',
      );
    }
    return publicName;
  }

  void _validateDerivedFields() {
    final Map<String, String> ordinaryStorageNames = {};
    final Map<String, bool> derivedRootShapes = {};
    final Map<String, String> generatedSchemaNames = {};
    for (MapEntry<String, FieldOrmNode> entry in fields.entries) {
      final Field field = entry.value.annotation;
      final String schemaName = field.isDerived
          ? _derivedSchemaFieldName(entry.key)
          : entry.key;
      final String? previousSchemaName = generatedSchemaNames[schemaName];
      if (previousSchemaName != null && previousSchemaName != entry.key) {
        throw StateError(
          'Generated field metadata name $schemaName conflicts with '
          '$previousSchemaName.',
        );
      }
      generatedSchemaNames[schemaName] = entry.key;
      if (!field.isDerived) {
        ordinaryStorageNames[field.name ?? entry.key] = entry.key;
      }
    }
    for (MapEntry<String, FieldOrmNode> entry in fields.entries) {
      final Field field = entry.value.annotation;
      if (!field.isDerived) continue;
      final MethodElement? method = entry.value.method;
      if (method == null) {
        throw StateError(
          'Derived field ${entry.key} must be declared on a method named '
          '$dormDerivedMethodPrefix<name>.',
        );
      }
      if (method.enclosingElement != naming.node.element) {
        throw StateError(
          'Derived field ${entry.key} must be declared directly on '
          '${naming.schemaName}.',
        );
      }
      if (!method.name!.startsWith(dormDerivedMethodPrefix)) {
        throw StateError(
          'Derived field ${entry.key} must use the reserved method prefix '
          '$dormDerivedMethodPrefix.',
        );
      }
      final String methodFieldName = method.name!.substring(
        dormDerivedMethodPrefix.length,
      );
      if (methodFieldName != entry.key || methodFieldName.isEmpty) {
        throw StateError(
          'Derived field ${entry.key} must use a non-empty valid name after '
          '$dormDerivedMethodPrefix.',
        );
      }
      if (!method.isStatic) {
        throw StateError('${naming.schemaName}.${method.name} must be static.');
      }
      final List<FormalParameterElement> parameters = method.formalParameters;
      if (parameters.length != 2 ||
          parameters.any((parameter) => !parameter.isRequiredPositional)) {
        throw StateError(
          '${naming.schemaName}.${method.name} must declare exactly two '
          'required positional parameters.',
        );
      }
      final ClassElement? modelElement = naming.node.element;
      if (modelElement == null || parameters[0].type != modelElement.thisType) {
        throw StateError(
          '${naming.schemaName}.${method.name} first parameter must have '
          'type ${modelElement?.thisType.getDisplayString() ?? naming.schemaName}.',
        );
      }
      if (parameters[1].type.getDisplayString() != 'DerivedTransformations') {
        throw StateError(
          '${naming.schemaName}.${method.name} second parameter must have '
          'type DerivedTransformations.',
        );
      }
      final String returnType = method.returnType.getDisplayString();
      final bool isAsyncOrFunction = switch (method.returnType) {
        FunctionType() => true,
        InterfaceType type
            when type.element.name == 'Future' ||
                type.element.name == 'FutureOr' ||
                type.element.name == 'Stream' =>
          true,
        _ => false,
      };
      if (returnType == 'void' || isAsyncOrFunction) {
        throw StateError(
          '${naming.schemaName}.${method.name} must return a synchronous '
          'serializable value.',
        );
      }
      final String declaredName = field.name ?? entry.key;
      final List<String> path = declaredName.split('/');
      if (path.length > 2 || path.any((segment) => segment.isEmpty)) {
        throw StateError(
          'Derived field ${entry.key} must use a simple name or a root/child path.',
        );
      }
      final String root = path.first;
      final String? previous = ordinaryStorageNames[root];
      if (previous != null) {
        throw StateError(
          'Derived field ${entry.key} conflicts with storage field $previous.',
        );
      }
      final bool hierarchical = path.length == 2;
      final bool? previousShape = derivedRootShapes[root];
      if (previousShape != null && previousShape != hierarchical) {
        throw StateError(
          'Derived field ${entry.key} conflicts with the storage shape of '
          'derived fields rooted at $root.',
        );
      }
      derivedRootShapes[root] = hierarchical;
      final String? duplicate = fields.entries
          .where(
            (other) =>
                other.key != entry.key && other.value.annotation.isDerived,
          )
          .firstOrNullWhere(
            (other) =>
                (other.value.annotation.name ?? other.key) == declaredName,
          )
          ?.key;
      if (duplicate != null) {
        throw StateError(
          'Derived field ${entry.key} duplicates derived field $duplicate.',
        );
      }
    }
  }

  cb.Spec get _fieldsClass {
    _validateDerivedFields();
    return cb.Class((b) {
      b.name = naming.fieldsName;
      b.constructors.add(
        cb.Constructor((b) {
          b.constant = true;
        }),
      );
      b.fields.addAll(
        naming.primaryKeyFieldNames.map((fieldName) {
          final FieldOrmNode? field = fields[fieldName];
          return cb.Field((b) {
            b.modifier = cb.FieldModifier.final$;
            b.type = cb.Reference(
              field?.annotation is ForeignField
                  ? 'ForeignKeySchema'
                  : 'FieldSchema',
              '$_dormUrl',
            );
            b.name = fieldName;
            b.assignment = cb.ToCodeExpression(
              field == null
                  ? cb.InvokeExpression.constOf(
                      cb.Reference('FieldSchema', '$_dormUrl'),
                      [],
                      {
                        'fieldName': cb.literalString(fieldName),
                        'columnName': cb.literalString(
                          naming._primaryKeys
                              .firstWhere((key) => key.fieldName == fieldName)
                              .columnName,
                        ),
                      },
                    )
                  : _fieldSchema(fieldName, field),
            );
          });
        }),
      );
      b.fields.addAll(
        fields.entries
            .where(
              (entry) =>
                  entry.value.annotation.isConcrete &&
                  !naming.primaryKeyFieldNames.contains(entry.key),
            )
            .map((entry) {
              return cb.Field((b) {
                b.modifier = cb.FieldModifier.final$;
                b.type = cb.Reference(
                  entry.value.annotation is ForeignField
                      ? 'ForeignKeySchema'
                      : 'FieldSchema',
                  '$_dormUrl',
                );
                b.name = entry.key;
                b.assignment = cb.ToCodeExpression(
                  _fieldSchema(entry.key, entry.value),
                );
              });
            }),
      );
      b.fields.addAll(
        fields.entries.where((entry) => entry.value.annotation.isDerived).map((
          entry,
        ) {
          return cb.Field((b) {
            b.modifier = cb.FieldModifier.final$;
            b.type = cb.Reference('DerivedFieldSchema', '$_dormUrl');
            b.name = _derivedSchemaFieldName(entry.key);
            b.assignment = cb.ToCodeExpression(
              _derivedFieldSchema(entry.key, entry.value),
            );
          });
        }),
      );
    });
  }

  cb.Expression get _schemaExpression {
    return cb.InvokeExpression.newOf(
      cb.Reference('EntitySchema', '$_dormUrl'),
      [],
      {
        'tableName': cb.literalString(naming.tableName),
        'primaryKeys': cb.literalList(
          naming.primaryKeyFieldNames.map(
            (fieldName) => expressionOf('fields.$fieldName'),
          ),
        ),
        'fields': cb.literalList([
          for (MapEntry<String, FieldOrmNode> entry in fields.entries.where(
            (entry) =>
                entry.value.annotation.isConcrete &&
                !naming.primaryKeyFieldNames.contains(entry.key),
          ))
            expressionOf('fields.${entry.key}'),
        ]),
        'derivedFields': cb.literalList([
          for (MapEntry<String, FieldOrmNode> entry in fields.entries.where(
            (entry) => entry.value.annotation.isDerived,
          ))
            expressionOf('fields.${_derivedSchemaFieldName(entry.key)}'),
        ]),
      },
    );
  }

  cb.Spec get _entityClass {
    return cb.Class((b) {
      b.name = naming.entityName;
      b.implements.add(
        cb.TypeReference((b) {
          b.symbol = 'Entity';
          b.url = '$_dormUrl';
          b.types.add(cb.Reference(naming.dataName));
          b.types.add(cb.Reference(naming.modelName));
          b.types.add(naming.idReference);
          b.types.add(naming.creationReference);
        }),
      );
      b.constructors.add(
        cb.Constructor((b) {
          b.constant = true;
        }),
      );
      b.fields.add(
        cb.Field((b) {
          b.static = true;
          b.modifier = cb.FieldModifier.final$;
          b.type = cb.Reference('EntitySchema', '$_dormUrl');
          b.name = '_schema';
          b.assignment = cb.ToCodeExpression(_schemaExpression);
        }),
      );
      b.methods.add(
        cb.Method((b) {
          b.annotations.add(expressionOf('override'));
          b.returns = cb.Reference('EntitySchema', '$_dormUrl');
          b.name = 'schema';
          b.type = cb.MethodType.getter;
          b.lambda = true;
          b.body = expressionOf('_schema').code;
        }),
      );
      b.methods.add(
        cb.Method((b) {
          b.annotations.add(expressionOf('override'));
          b.returns = cb.TypeReference((b) {
            b.symbol = 'PrimaryKeyCodec';
            b.url = '$_dormUrl';
            b.types.add(naming.idReference);
          });
          b.name = 'primaryKeyCodec';
          b.type = cb.MethodType.getter;
          b.lambda = true;
          b.body = cb.InvokeExpression.constOf(
            cb.Reference(
              naming.isCompositePrimaryKey
                  ? 'CompositePrimaryKeyCodec'
                  : 'SinglePrimaryKeyCodec',
              '$_dormUrl',
            ),
            [],
          ).code;
        }),
      );
      b.methods.add(
        cb.Method((b) {
          b.annotations.add(expressionOf('override'));
          b.returns = cb.Reference('IdentityGenerationStrategy', '$_dormUrl');
          b.name = 'identityGeneration';
          b.type = cb.MethodType.getter;
          b.lambda = true;
          b.body = expressionOf(
            'IdentityGenerationStrategy.${naming.identityGenerationStrategy}',
          ).code;
        }),
      );
      b.fields.insertAll(0, [
        cb.Field((b) {
          b.static = true;
          b.modifier = cb.FieldModifier.constant;
          b.type = cb.Reference(naming.fieldsName);
          b.name = 'fields';
          b.assignment = cb.ToCodeExpression(
            cb.InvokeExpression.constOf(cb.Reference(naming.fieldsName), []),
          );
        }),
      ]);
      b.methods.add(
        cb.Method((b) {
          b.annotations.add(expressionOf('override'));
          b.returns = cb.Reference(naming.modelName);
          b.name = 'fromData';
          b.requiredParameters.add(
            cb.Parameter((b) {
              b.type = cb.TypeReference((b) {
                b.symbol = 'ResolvedCreation';
                b.url = '$_dormUrl';
                b.types.add(cb.Reference(naming.dataName));
                b.types.add(naming.idReference);
              });
              b.name = 'creation';
            }),
          );
          b.lambda = false;
          final Map<String, cb.Expression> primaryKeyEntries =
              naming.isCompositePrimaryKey
              ? {
                  for (
                    int index = 0;
                    index < naming.primaryKeyFieldNames.length;
                    index++
                  )
                    naming.primaryKeyFieldNames[index]: expressionOf(
                      'creation.id.values[$index]',
                    ),
                }
              : {naming.idFieldName: _primaryKeyExpression};
          b.body = cb.InvokeExpression.newOf(
            cb.Reference(naming.modelName),
            [],
            {
              ...primaryKeyEntries,
              ...Map.fromEntries(
                fields.where((field) => field.isConcrete).entries.expand((
                  entry,
                ) sync* {
                  final String fieldName = entry.key;
                  if (naming.primaryKeyFieldNames.contains(fieldName)) {
                    return;
                  }
                  final Field baseField = entry.value.annotation;
                  if (baseField is PolymorphicField) {
                    final $ConcreteSymbol pivotSymbol =
                        baseField.pivotAs as $ConcreteSymbol;
                    yield MapEntry(
                      pivotSymbol.name,
                      expressionOf('creation.data').property(pivotSymbol.name),
                    );
                  }
                  final cb.Expression fieldExpression =
                      entry.value.annotation is ForeignField
                      ? expressionOf(
                          '(creation.dependency as '
                          '${naming.dependencyName}).$fieldName',
                        )
                      : expressionOf('creation.data').property(fieldName);
                  yield MapEntry(fieldName, fieldExpression);
                }),
              ),
            },
          ).returned.statement;
        }),
      );
      b.methods.add(
        cb.Method((b) {
          b.annotations.add(expressionOf('override'));
          b.returns = cb.Reference(naming.modelName);
          b.name = 'convert';
          b.requiredParameters.add(
            cb.Parameter((b) {
              b.type = cb.Reference(naming.modelName);
              b.name = 'model';
            }),
          );
          b.requiredParameters.add(
            cb.Parameter((b) {
              b.type = cb.Reference(naming.dataName);
              b.name = 'data';
            }),
          );
          b.lambda = true;

          cb.Expression baseExpression = expressionOf('model');
          if (fields.where((field) => field.isNative).isNotEmpty) {
            baseExpression = baseExpression.property('updateWith').call([
              expressionOf('data'),
            ]);
          }
          b.body = cb.ToCodeExpression(baseExpression);
        }),
      );
      b.methods.add(
        cb.Method((b) {
          b.annotations.add(expressionOf('override'));
          b.returns = cb.Reference(naming.modelName);
          b.name = 'fromJson';
          b.requiredParameters.add(
            cb.Parameter((b) {
              b.type = naming.idReference;
              b.name = 'id';
            }),
          );
          b.requiredParameters.add(
            cb.Parameter((b) {
              b.type = cb.Reference('Map');
              b.name = 'json';
            }),
          );
          b.lambda = true;
          b.body = cb.ToCodeExpression(
            cb.InvokeExpression.newOf(
              cb.Reference(naming.modelName),
              ['id', 'json'].map(expressionOf).toList(),
              {},
              [],
              'fromJson',
            ),
          );
        }),
      );
      b.methods.add(
        cb.Method((b) {
          b.annotations.add(expressionOf('override'));
          b.returns = naming.idReference;
          b.name = 'identify';
          b.requiredParameters.add(
            cb.Parameter((b) {
              b.type = cb.Reference(naming.modelName);
              b.name = 'model';
            }),
          );
          b.lambda = true;
          b.body = naming.isCompositePrimaryKey
              ? cb.InvokeExpression.newOf(
                  cb.Reference('CompositeKey', '$_dormUrl'),
                  [
                    cb.literalList(
                      naming.primaryKeyFieldNames.map(
                        (fieldName) =>
                            expressionOf('model').property(fieldName),
                      ),
                    ),
                  ],
                ).code
              : expressionOf('model').property(naming.idFieldName).code;
        }),
      );
      b.methods.add(
        cb.Method((b) {
          b.annotations.add(expressionOf('override'));
          b.returns = cb.TypeReference((b) {
            b.symbol = 'Map';
            b.types.add(cb.Reference('String'));
            b.types.add(cb.Reference('Object?'));
          });
          b.name = 'toJson';
          b.requiredParameters.add(
            cb.Parameter((b) {
              b.type = cb.Reference(naming.dataName);
              b.name = 'data';
            }),
          );
          b.lambda = true;
          b.body = cb.ToCodeExpression(
            expressionOf('data').property('toJson').call([]),
          );
        }),
      );
    });
  }

  cb.Spec get _extension {
    return cb.Extension((b) {
      b.name = naming.extensionName;
      b.on = cb.Reference(naming.modelName);
      b.methods.add(
        cb.Method((b) {
          b.returns = cb.Reference(naming.modelName);
          b.name = 'updateWith';
          b.requiredParameters.add(
            cb.Parameter((b) {
              b.type = cb.Reference(naming.dataName);
              b.name = 'data';
            }),
          );
          final Map<String, cb.Expression> primaryKeyEntries =
              naming.isCompositePrimaryKey
              ? {
                  for (final String fieldName in naming.primaryKeyFieldNames)
                    fieldName: expressionOf(fieldName),
                }
              : {naming.idFieldName: expressionOf(naming.idFieldName)};
          b.body =
              cb.InvokeExpression.newOf(cb.Reference(naming.modelName), [], {
                ...primaryKeyEntries,
                ...Map.fromEntries(
                  fields.where((field) => field.isConcrete).entries.expand((
                    entry,
                  ) sync* {
                    final String fieldName = entry.key;
                    if (naming.primaryKeyFieldNames.contains(fieldName)) {
                      return;
                    }
                    final Field baseField = entry.value.annotation;
                    if (baseField is PolymorphicField) {
                      final $ConcreteSymbol pivotSymbol =
                          baseField.pivotAs as $ConcreteSymbol;
                      yield MapEntry(
                        pivotSymbol.name,
                        expressionOf('data').property(pivotSymbol.name),
                      );
                    }
                    yield MapEntry(
                      fieldName,
                      entry.value.annotation is ForeignField
                          ? expressionOf(fieldName)
                          : expressionOf('data').property(fieldName),
                    );
                  }),
                ),
              }).returned.statement;
        }),
      );
    });
  }

  @override
  void accept(cb.LibraryBuilder b) {
    if (naming.identityGenerator != null) b.body.add(_dummyClass);
    b.body.add(
      newClass(
        name: naming.dataName,
        spec: Spec(
          includesPrimaryKey: false,
          primaryKeyType: naming.idReference,
          primaryKeyNames: naming.primaryKeyFieldNames,
          primaryKeyIsGenerated:
              naming.isGeneratedPrimaryKey ||
              naming.isDatabaseGeneratedPrimaryKey,
          supportsSerialization: true,
          extendsReference: null,
          implementsReferences: [],
          includesQueryGetters: false,
          ignoreOverrideFor: {},
          discriminatorSpec: null,
          generatesCopyWith: false,
          shouldDeclareField: (field) => field.isNative,
        ),
      ),
    );
    b.body.add(
      newClass(
        name: naming.modelName,
        spec: Spec(
          includesPrimaryKey: true,
          primaryKeyType: naming.idReference,
          primaryKeyNames: naming.primaryKeyFieldNames,
          primaryKeyIsGenerated:
              naming.isGeneratedPrimaryKey ||
              naming.isDatabaseGeneratedPrimaryKey,
          includeExistingPrimaryKey:
              !naming.isGeneratedPrimaryKey &&
              !naming.isDatabaseGeneratedPrimaryKey,
          supportsSerialization: true,
          extendsReference: cb.Reference(naming.dataName),
          implementsReferences: [cb.Reference(naming.schemaName)],
          includesQueryGetters: true,
          ignoreOverrideFor: {},
          discriminatorSpec: null,
          generatesCopyWith: true,
          shouldDeclareField: (field) => field.isForeign,
        ),
      ),
    );
    b.body.add(_dependencyClass);
    b.body.add(_fieldsClass);
    b.body.add(_entityClass);
    if (fields.where((field) => field.isNative).isNotEmpty) {
      b.body.add(_extension);
    }
  }
}

class PolymorphicArgs
    extends Args<PolymorphicDataTag, PolymorphicDataOrmNode, TagNaming> {
  const PolymorphicArgs({
    required super.nodes,
    required super.annotation,
    required super.fields,
    required super.naming,
  });

  cb.Spec get _enumClass {
    return cb.Enum((b) {
      b.name = naming.enumName;
      b.values.addAll(
        fields.entries.map((entry) {
          final PolymorphicDataNaming naming = PolymorphicDataNaming(
            name: entry.key,
            node: entry.value,
          );
          return cb.EnumValue((b) {
            b.name = naming.enumFieldName;
          });
        }),
      );
    });
  }

  cb.Spec get _baseClass {
    return cb.Class((b) {
      b.abstract = !annotation.isSealed;
      b.sealed = annotation.isSealed;
      b.name = naming.modelName;
      b.implements.add(cb.Reference(naming.schemaName));
      b.constructors.add(
        cb.Constructor((b) {
          b.factory = true;
          b.name = 'fromType';
          b.requiredParameters.add(
            cb.Parameter((b) {
              b.type = cb.Reference(naming.enumName);
              b.name = 'type';
            }),
          );
          b.requiredParameters.add(
            cb.Parameter((b) {
              b.type = cb.Reference('Map');
              b.name = 'json';
            }),
          );
          b.lambda = false;
          b.body = cb.Block((b) {
            b.statements.add(cb.Code('switch (type) {'));
            for (MapEntry<String, PolymorphicDataOrmNode> entry
                in fields.entries) {
              final PolymorphicDataNaming naming = PolymorphicDataNaming(
                name: entry.key,
                node: entry.value,
              );
              b.statements.add(
                cb.Code(
                  'case ${this.naming.enumName}.${naming.enumFieldName}:',
                ),
              );
              b.statements.add(
                cb.InvokeExpression.newOf(
                  cb.Reference(naming.modelName),
                  [expressionOf('json')],
                  {},
                  [],
                  'fromJson',
                ).returned.statement,
              );
            }
            b.statements.add(cb.Code('}'));
          });
        }),
      );
      b.methods.add(
        cb.Method((b) {
          b.returns = cb.Reference(naming.enumName);
          b.type = cb.MethodType.getter;
          b.name = 'type';
        }),
      );
      b.methods.add(
        cb.Method((b) {
          b.returns = cb.TypeReference((b) {
            b.symbol = 'Map';
            b.types.add(cb.Reference('String'));
            b.types.add(cb.Reference('Object?'));
          });
          b.name = 'toJson';
        }),
      );
    });
  }

  @override
  void accept(cb.LibraryBuilder b) {
    b.body.add(_enumClass);
    b.body.add(_baseClass);
  }
}

class PolymorphicModelArgs extends FieldedArgs<void, PolymorphicDataNaming> {
  const PolymorphicModelArgs({
    required super.nodes,
    required super.fields,
    required super.naming,
  }) : super(annotation: null);

  @override
  void accept(cb.LibraryBuilder b) {
    b.body.add(
      newClass(
        name: naming.modelName,
        spec: Spec(
          includesPrimaryKey: false,
          supportsSerialization: true,
          extendsReference: null,
          implementsReferences: [
            cb.Reference(naming.tag.modelName),
            cb.Reference(naming.schemaName),
          ],
          ignoreOverrideFor: {},
          includesQueryGetters: false,
          discriminatorSpec: (
            cb.Reference(naming.tag.enumName),
            naming.enumFieldName,
          ),
          generatesCopyWith: true,
          shouldDeclareField: (field) => field.isConcrete,
        ),
      ),
    );
  }
}

class Spec {
  final bool includesPrimaryKey;
  final cb.Reference? primaryKeyType;
  final List<String> primaryKeyNames;
  final bool primaryKeyIsGenerated;
  final bool includeExistingPrimaryKey;
  final bool supportsSerialization;
  final cb.Reference? extendsReference;
  final List<cb.Reference> implementsReferences;
  final bool includesQueryGetters;
  final Set<String> ignoreOverrideFor;
  final (cb.Reference, String)? discriminatorSpec;
  final bool generatesCopyWith;
  final bool Function(Field field) shouldDeclareField;

  const Spec({
    required this.includesPrimaryKey,
    this.primaryKeyType,
    this.primaryKeyNames = const ['id'],
    this.primaryKeyIsGenerated = true,
    this.includeExistingPrimaryKey = false,
    required this.supportsSerialization,
    required this.extendsReference,
    required this.implementsReferences,
    required this.includesQueryGetters,
    required this.ignoreOverrideFor,
    required this.discriminatorSpec,
    required this.generatesCopyWith,
    required this.shouldDeclareField,
  });

  bool get isCompositePrimaryKey => primaryKeyNames.length > 1;

  String get primaryKeyName {
    if (isCompositePrimaryKey) {
      throw StateError(
        'A composite primary key does not have a single field name.',
      );
    }
    return primaryKeyNames.single;
  }

  String primaryKeyJsonName(String fieldName) =>
      isCompositePrimaryKey ? '_id_$fieldName' : '_id';

  bool isExistingPrimaryKey(String fieldName) =>
      !primaryKeyIsGenerated && primaryKeyNames.contains(fieldName);

  bool shouldDeclare(String fieldName, Field field) {
    if (isExistingPrimaryKey(fieldName)) return includeExistingPrimaryKey;
    return shouldDeclareField(field);
  }
}

Map<cb.Expression, cb.Expression> _primaryKeyJsonEntries(Spec spec) {
  return {
    for (int index = 0; index < spec.primaryKeyNames.length; index++)
      cb.literalString(
        spec.primaryKeyJsonName(spec.primaryKeyNames[index]),
      ): spec.isCompositePrimaryKey
          ? expressionOf('id.values[$index]')
          : expressionOf('id'),
  };
}

sealed class SpecTypeResolution {
  final String declaredTypeLabel;
  const SpecTypeResolution({required this.declaredTypeLabel});
}

class DirectSpecTypeResolution extends SpecTypeResolution {
  const DirectSpecTypeResolution({required super.declaredTypeLabel});

  cb.Reference get reference => cb.Reference(declaredTypeLabel);
}

class IndirectSpecTypeResolution extends SpecTypeResolution {
  final $Type originalType;

  const IndirectSpecTypeResolution({
    required super.declaredTypeLabel,
    required this.originalType,
  });

  cb.Reference referenceBy(ClassOrmNode<Object>? Function($Type) accessor) {
    final derivedClassNode = accessor(originalType);
    final String derivedTypeName = switch (derivedClassNode) {
      DataOrmNode() => originalType.name!.substring(1),
      _ => '${originalType.name!.substring(1)}Data',
    };
    return cb.Reference(
      declaredTypeLabel.replaceAll('$ModelFieldType', derivedTypeName),
    );
  }
}

extension on Spec {
  /// Converts a template type into its respective result type as a
  /// [cb.Reference], according to the rules below.
  ///
  /// ## Definitions
  ///
  /// The **argument type** should correspond to a class annotated with a
  /// [Model], [Data] or [PolymorphicData].
  ///
  /// The **derived type** is calculated from the _argument_ type. For example,
  /// if the argument type is `_User` and it's annotated with
  /// - [Model], the derived type is `UserData` ([ModelNaming.dataName])
  /// - [Data], the derived type is `User` ([DataNaming.modelName])
  /// - [PolymorphicData], the derived type is `User`
  ///   (PolymorphicDataNaming.modelName])
  ///
  /// The **template type** tells the generator to apply a transformation to the
  /// _derived_ type. It can be
  /// - an `Object`, which tells the generator to keep the derived type
  ///   untouched
  /// - an `Object?`, which tells the generator to make the derived type
  ///   nullable
  /// - a `List<dynamic>`, which tells the generator to wrap the derived type
  ///   into a list
  ///
  /// Finally, the **result type** is the transformation declared by the
  /// _template_ type applied to the _derived_ type.
  ///
  /// In practice, if a user writes:
  ///
  /// ```dart
  /// @Model(name: 'tbl_students', as: #students)
  /// abstract class _Student {}
  ///
  /// @Data(name: 'schools')
  /// abstract class _School {
  ///   @ModelField(name: 'col_students', referTo: _Student)
  ///   List get students;
  /// }
  /// ```
  ///
  /// in the context of the `students` getter on the `_School` schema:
  ///
  /// - the argument type is `_Student`
  /// - the derived type is `Student`
  /// - the template type is `List<dynamic>`
  /// - the result type is `List<Student>`
  ///
  /// The [field] argument here would contain the [ModelField] object, while the
  /// [declaredTypeLabel] would contain the.
  SpecTypeResolution resolveTypeFromField(
    Field field,
    String declaredTypeLabel,
  ) {
    switch (field) {
      case PolymorphicField():
        return DirectSpecTypeResolution(
          declaredTypeLabel: declaredTypeLabel.substring(1),
        );
      case ModelField():
        return IndirectSpecTypeResolution(
          declaredTypeLabel: (field.template as $ModelFieldTemplate).name!,
          originalType: field.referTo as $Type,
        );
      default:
        return DirectSpecTypeResolution(declaredTypeLabel: declaredTypeLabel);
    }
  }
}

extension _BaseWriting on Map<String, FieldOrmNode> {
  Iterable<cb.Method> get queryGetters sync* {
    for (MapEntry<String, FieldOrmNode> entry in where(
      (field) => field.isA<DerivedField>(),
    ).entries) {
      final MethodElement? method = entry.value.method;
      if (method == null) continue;

      yield cb.Method((b) {
        b.returns = cb.Reference(entry.value.type);
        b.type = cb.MethodType.getter;
        b.name = entry.key;
        b.lambda = true;
        b.body = cb.ToCodeExpression(
          cb.Reference(
            method.enclosingElement?.name ?? '',
          ).property(method.name!).call([
            expressionOf('this'),
            cb.InvokeExpression.constOf(
              cb.Reference('DerivedTransformations'),
              const [],
            ),
          ]),
        );
      });
    }
  }
}

/// Code generator.
class OrmGenerator extends Generator {
  const OrmGenerator();

  void _validatePrimaryKeyStage(
    ModelNaming naming,
    Map<String, FieldOrmNode> fields,
  ) {
    final List<IdSpec> specs = naming.node.annotation.primaryKey;
    if (specs.isEmpty) {
      throw StateError(
        '${naming.schemaName} must declare at least one primary-key '
        'specification.',
      );
    }

    final MethodElement? identityGenerator = naming.identityGenerator;
    if (identityGenerator != null) {
      _validateIdentityGenerator(naming, identityGenerator, specs);
    }

    if (specs.length > 1) {
      for (final IdSpec spec in specs) {
        switch (spec) {
          case ExistingIdSpec():
            break;
          case GeneratedIdSpec():
            throw StateError(
              '${naming.schemaName} supports only ExistingIdSpec parts for '
              'composite primary keys.',
            );
          case DatabaseGeneratedIdSpec():
            throw StateError(
              '${naming.schemaName} supports only ExistingIdSpec parts for '
              'composite primary keys.',
            );
        }
      }
      final List<String> names = naming.primaryKeyFieldNames;
      if (names.toSet().length != names.length) {
        throw StateError(
          '${naming.schemaName} cannot repeat a field in its primary key.',
        );
      }
      naming._primaryKeys;
      return;
    }

    switch (specs.single) {
      case ExistingIdSpec():
        return;
      case GeneratedIdSpec spec:
        _validateGeneratedPrimaryKeySpec(
          naming,
          fields,
          as: spec.as,
          name: spec.name,
          type: spec.type,
        );
        return;
      case DatabaseGeneratedIdSpec spec:
        _validateGeneratedPrimaryKeySpec(
          naming,
          fields,
          as: spec.as,
          name: spec.name,
          type: spec.type,
        );
    }
  }

  void _validateIdentityGenerator(
    ModelNaming naming,
    MethodElement method,
    List<IdSpec> specs,
  ) {
    if (specs.length != 1 || specs.single is! GeneratedIdSpec) {
      throw StateError(
        '${naming.schemaName} cannot use $_identityGeneratorName with '
        'an ExistingIdSpec, DatabaseGeneratedIdSpec, or composite primary '
        'key.',
      );
    }

    if (!method.isStatic) {
      throw StateError(
        '${naming.schemaName}.$_identityGeneratorName must be static.',
      );
    }

    final List<FormalParameterElement> parameters = method.formalParameters;
    if (parameters.length != 2 ||
        parameters.any((parameter) => !parameter.isRequiredPositional)) {
      throw StateError(
        '${naming.schemaName}.$_identityGeneratorName must declare exactly '
        'two required positional parameters.',
      );
    }

    final ClassElement? modelElement = naming.node.element;
    if (modelElement == null) {
      throw StateError(
        '${naming.schemaName}.$_identityGeneratorName cannot be validated '
        'without its annotated class.',
      );
    }

    final FormalParameterElement modelParameter = parameters[0];
    if (modelParameter.type != modelElement.thisType) {
      throw StateError(
        '${naming.schemaName}.$_identityGeneratorName first parameter must '
        'have type ${modelElement.thisType.getDisplayString()}.',
      );
    }

    final GeneratedIdSpec spec = specs.single as GeneratedIdSpec;
    final String expectedTypeName = switch (spec.type) {
      $Type type => type.name ?? type.toString(),
      _ => spec.type.toString(),
    };
    final DartType? expectedType = switch (spec.type) {
      $Type type => type.dartType,
      _ => null,
    };
    bool matchesIdentityType(DartType actual) {
      if (expectedType != null) return actual == expectedType;
      return actual.getDisplayString() == expectedTypeName;
    }

    if (!matchesIdentityType(parameters[1].type)) {
      throw StateError(
        '${naming.schemaName}.$_identityGeneratorName second parameter must '
        'have identity type $expectedTypeName.',
      );
    }
    if (!matchesIdentityType(method.returnType)) {
      throw StateError(
        '${naming.schemaName}.$_identityGeneratorName must return identity '
        'type $expectedTypeName.',
      );
    }
  }

  void _validateGeneratedPrimaryKeySpec(
    ModelNaming naming,
    Map<String, FieldOrmNode> fields, {
    required Symbol as,
    required String name,
    required Type type,
  }) {
    final String? propertyName = _symbolName(as);
    final String? typeName = switch (type) {
      $Type value => value.name,
      _ => type.toString(),
    };
    if (propertyName == null || propertyName.isEmpty) {
      throw StateError(
        '${naming.schemaName} has a generated identity specification without '
        'a valid Dart property name.',
      );
    }
    if (name.isEmpty) {
      throw StateError(
        '${naming.schemaName} has a generated identity specification without '
        'a storage name.',
      );
    }
    if (typeName == null || typeName.endsWith('?')) {
      throw StateError(
        '${naming.schemaName} has a nullable or unresolved generated '
        'primary-key type.',
      );
    }
    if (fields.containsKey(propertyName)) {
      throw StateError(
        '${naming.schemaName} declares a field named $propertyName, which '
        'conflicts with its generated primary key.',
      );
    }
  }

  List<_GeneratedRelation> _relations(
    Map<String, FieldedOrmNode<Object>> nodes,
    List<ModelNaming> models,
  ) {
    final List<_GeneratedRelation> relations = [];
    for (final ModelNaming current in models) {
      final FieldedOrmNode<Object> node = nodes[current.schemaName]!;
      for (final MapEntry<String, FieldOrmNode> entry in node.fields.entries) {
        final Field field = entry.value.annotation;
        if (field is! ForeignField) continue;

        final $Type targetType = field.referTo as $Type;
        final String? targetName = targetType.name;
        final FieldedOrmNode<Object>? targetNode = targetName == null
            ? null
            : nodes[targetName];
        final ClassOrmNode<Object>? targetClass = targetNode?.annotation;
        if (targetName == null || targetClass is! ModelOrmNode) {
          throw StateError(
            'Foreign field in ${current.schemaName} must refer to a model '
            'annotated with @Model(), found ${targetType.name ?? 'unknown'}.',
          );
        }

        final ModelNaming target = ModelNaming(
          name: targetName,
          node: targetClass,
          fields: targetNode!.fields,
        );
        if (current.isCompositePrimaryKey || target.isCompositePrimaryKey) {
          throw StateError(
            'ForeignField relationships involving composite primary keys are '
            'not supported yet: ${current.schemaName}.${entry.key}.',
          );
        }
        relations.add(
          _GeneratedRelation(
            current: current,
            target: target,
            name: _symbolName(field.as) ?? _defaultRelationName(entry.key),
            fieldName: entry.key,
            inverse: false,
            unique: field.unique,
          ),
        );

        final String? inverseName = _symbolName(field.inverseAs);
        if (inverseName != null) {
          relations.add(
            _GeneratedRelation(
              current: target,
              target: current,
              name: inverseName,
              fieldName: entry.key,
              inverse: true,
              unique: field.unique,
            ),
          );
        }
      }
    }
    return relations;
  }

  List<cb.Spec> _relationPathSpecs(
    List<ModelNaming> models,
    List<_GeneratedRelation> relations,
  ) {
    final List<cb.Spec> specs = [
      cb.Class((b) {
        b.name = 'DormRelations';
        b.types.add(_queryTypeParameter());
        b.types.add(_pageTypeParameter());
        b.fields.add(
          cb.Field((b) {
            b.modifier = cb.FieldModifier.final$;
            b.type = _dormType();
            b.name = '_dorm';
          }),
        );
        b.constructors.add(
          cb.Constructor((b) {
            b.constant = true;
            b.requiredParameters.add(
              cb.Parameter((b) {
                b.toThis = true;
                b.name = '_dorm';
              }),
            );
          }),
        );
        b.methods.addAll(
          models.map(
            (model) => cb.Method((b) {
              b.type = cb.MethodType.getter;
              b.lambda = true;
              b.name = model.repositoryName;
              b.returns = _relationPathType(
                model.modelName,
                cb.Reference(model.modelName),
              );
              b.body = cb.Reference('RelationPath')
                  .property('root')
                  .call(
                    [
                      expressionOf(
                        '_dorm',
                      ).property(model.repositoryName).property('repository'),
                    ],
                    {'context': expressionOf('_dorm')},
                  )
                  .code;
            }),
          ),
        );
      }),
    ];

    final Map<String, List<_GeneratedRelation>> grouped = {};
    for (final _GeneratedRelation relation in relations) {
      grouped.putIfAbsent(relation.current.modelName, () => []).add(relation);
    }

    for (final ModelNaming model in models) {
      final List<_GeneratedRelation> currentRelations =
          grouped[model.modelName] ?? const [];
      if (currentRelations.isEmpty) continue;

      final Set<String> generatedNames = {};

      specs.add(
        cb.Extension((b) {
          b.name = '${model.modelName}RelationPaths';
          b.types.add(cb.Reference('Root'));
          b.types.add(_queryTypeParameter());
          b.types.add(_pageTypeParameter());
          b.on = _relationPathType('Root', cb.Reference(model.modelName));

          for (final _GeneratedRelation relation in currentRelations) {
            final bool many = relation.inverse && !relation.unique;

            void emit({
              required String name,
              required String method,
              required cb.Reference resultType,
            }) {
              if (!generatedNames.add(name)) {
                throw StateError(
                  'Duplicate generated relationship path "$name" on '
                  '${model.modelName}. Use distinct ForeignField.as or '
                  'ForeignField.inverseAs values.',
                );
              }
              b.methods.add(
                cb.Method((b) {
                  b.type = cb.MethodType.getter;
                  b.name = name;
                  b.returns = _relationPathType('Root', resultType);
                  b.body = _relationPathCall(
                    relation,
                    method: method,
                    many: many,
                  ).returned.statement;
                }),
              );
            }

            if (many) {
              emit(
                name: relation.name,
                method: 'toMany',
                resultType: cb.Reference(relation.target.modelName),
              );
              emit(
                name: '${relation.name}OrEmpty',
                method: 'toManyOrEmpty',
                resultType: _listType(relation.target.modelName),
              );
            } else {
              emit(
                name: relation.name,
                method: 'toOne',
                resultType: cb.Reference(relation.target.modelName),
              );
              emit(
                name: '${relation.name}OrNull',
                method: 'toOneOrNull',
                resultType: cb.TypeReference((b) {
                  b.symbol = relation.target.modelName;
                  b.isNullable = true;
                }),
              );
            }
          }
        }),
      );
    }
    return specs;
  }

  cb.Reference _relationPathType(String rootType, cb.Reference resultType) {
    return cb.TypeReference((b) {
      b.symbol = 'RelationPath';
      b.types.addAll([
        _dormType(),
        cb.Reference(rootType),
        resultType,
        cb.Reference('Q'),
      ]);
    });
  }

  cb.TypeReference _dormType() {
    return cb.TypeReference((b) {
      b.symbol = 'Dorm';
      b.types.add(cb.Reference('Q'));
      b.types.add(cb.Reference('P'));
    });
  }

  cb.TypeReference _queryTypeParameter() {
    return cb.TypeReference((b) {
      b.symbol = 'Q';
      b.bound = cb.TypeReference((b) {
        b.symbol = 'BaseQuery';
        b.url = '$_dormUrl';
        b.types.add(cb.Reference('Q'));
      });
    });
  }

  cb.TypeReference _pageTypeParameter() {
    return cb.TypeReference((b) {
      b.symbol = 'P';
      b.bound = cb.Reference('PageRequest', '$_dormUrl');
    });
  }

  cb.Reference _listType(String type) {
    return cb.TypeReference((b) {
      b.symbol = 'List';
      b.types.add(cb.Reference(type));
    });
  }

  cb.Expression _relationPathCall(
    _GeneratedRelation relation, {
    required String method,
    required bool many,
  }) {
    final String currentEntity = '${relation.current.modelName}Entity';
    final cb.Expression sourceField = cb.Reference(currentEntity)
        .property('fields')
        .property(
          relation.inverse ? relation.current.idFieldName : relation.fieldName,
        );
    final cb.Expression targetField =
        cb.Reference('${relation.target.modelName}Entity')
            .property('fields')
            .property(
              relation.inverse
                  ? relation.fieldName
                  : relation.target.idFieldName,
            );
    final cb.Expression targetRepository = expressionOf(
      'context',
    ).property(relation.target.repositoryName).property('repository');
    final cb.Expression callbackExpression = relation.inverse
        ? cb.Reference('BaseFilter')
              .property('value')
              .call(
                [expressionOf('model').property(relation.current.idFieldName)],
                {'field': targetField},
              )
        : expressionOf('model').property(relation.fieldName);
    final cb.Expression callback = cb.Method((b) {
      b.lambda = true;
      b.requiredParameters.add(
        cb.Parameter((b) {
          b.name = 'model';
        }),
      );
      b.body = callbackExpression.code;
    }).closure;

    final cb.Expression spec = cb.Reference('RelationSpec').newInstance([], {
      'cardinality': cb.Reference(
        'RelationCardinality',
      ).property(many ? 'many' : 'one'),
      'source': sourceField,
      'target': targetField,
    });
    return cb.Reference(
      method,
    ).call([targetRepository], {'spec': spec, 'on': callback});
  }

  @override
  String? generate(LibraryReader library, BuildStep buildStep) {
    final Set<Uri> partUris = library.element.fragments
        .expand((fragment) => fragment.partIncludes)
        .map((element) => element.uri)
        .whereType<DirectiveUriWithSource>()
        .map((directive) => directive.relativeUri)
        .toSet();
    final bool hasDormDirective = partUris.any(
      (uri) => uri.path.endsWith('.dorm.dart'),
    );
    if (!hasDormDirective) return null;

    final Map<String, FieldedOrmNode<Object>> nodes = parseLibrary(library);
    final cb.Spec spec = cb.Library((b) {
      nodes.entries
          .mapNotNull<Args>((entry) {
            final String name = entry.key;
            final FieldedOrmNode<Object> node = entry.value;
            final ClassOrmNode<Object> classNode = node.annotation;
            if (classNode is ModelOrmNode) {
              return ModelArgs(
                nodes: nodes,
                naming: ModelNaming(
                  name: name,
                  node: classNode,
                  fields: node.fields,
                ),
                annotation: classNode.annotation,
                fields: node.fields,
              );
            }
            if (classNode is DataOrmNode) {
              return DataArgs(
                nodes: nodes,
                naming: DataNaming(name: name, node: classNode),
                annotation: classNode.annotation,
                fields: node.fields,
              );
            }
            return null;
          })
          .forEach((arg) => arg.accept(b));

      // Evaluates all classes annotated with `PolymorphicData` on *models.dart*,
      // then groups by their supertype, then groups by their type.
      //
      // Assuming the *models.dart* file has the following contents,
      //
      // ```none
      // abstract class _Shape {}
      //
      // @PolymorphicData(name: 'rectangle')
      // abstract class _Rectangle implements _Shape {/* ... */}
      //
      // @PolymorphicData(name: 'circle', as: #circular)
      // abstract class _Circle implements _Shape {/* ... */}
      //
      // sealed class _Brush {}
      //
      // @PolymorphicData(name: 'crayon', as: #crayon)
      // abstract class _Crayon implements _Brush {/* ... */}
      //
      // @PolymorphicData(name: 'marker')
      // abstract class _Marker implements _Brush {/* ... */}
      // ```
      //
      // the following statement will evaluate a map equivalent to
      //
      // ```none
      // {
      //   '_Shape': {
      //     '_Rectangle': PolymorphicDataOrmNode(
      //       annotation: PolymorphicData(name: 'rectangle'),
      //       tag: PolymorphicDataTag(value: '_Shape', isSealed: false),
      //     ),
      //     '_Circle': PolymorphicDataOrmNode(
      //       annotation: PolymorphicData(name: 'circle', as: #circular),
      //       tag: PolymorphicDataTag(value: '_Shape', isSealed: false),
      //     ),
      //   },
      //   '_Brush': {
      //     '_Crayon': PolymorphicDataOrmNode(
      //       annotation: PolymorphicData(name: 'crayon', as: #crayon),
      //       tag: PolymorphicDataTag(value: '_Brush', isSealed: true),
      //     ),
      //     '_Marker': PolymorphicDataOrmNode(
      //       annotation: PolymorphicData(name: 'marker'),
      //       tag: PolymorphicDataTag(value: '_Brush', isSealed: true),
      //     ),
      //   },
      // }
      // ```
      final Map<PolymorphicDataTag, Map<String, PolymorphicDataOrmNode>>
      groups = nodes
          .filterValues((data) => data.annotation is PolymorphicDataOrmNode)
          .mapValues(
            (entry) => entry.value.annotation as PolymorphicDataOrmNode,
          )
          .entries
          .groupBy((entry) => entry.value.tag)
          .mapValues((entry) => Map.fromEntries(entry.value));

      for (MapEntry<PolymorphicDataTag, Map<String, PolymorphicDataOrmNode>>
          entry
          in groups.entries) {
        final PolymorphicDataTag tag = entry.key;
        final Map<String, PolymorphicDataOrmNode> polymorphicNodes =
            entry.value;
        final PolymorphicArgs args = PolymorphicArgs(
          nodes: nodes,
          annotation: tag,
          naming: TagNaming(tag.value),
          fields: polymorphicNodes,
        );
        args.accept(b);
      }

      nodes.entries
          .mapNotNull((entry) {
            final String name = entry.key;
            final FieldedOrmNode<Object> node = entry.value;
            final ClassOrmNode<Object> classNode = node.annotation;
            if (classNode is! PolymorphicDataOrmNode) return null;
            return PolymorphicModelArgs(
              nodes: nodes,
              naming: PolymorphicDataNaming(name: name, node: classNode),
              fields: node.fields,
            );
          })
          .forEach((arg) => arg.accept(b));

      final List<ModelNaming> modelsNamings = [
        for (MapEntry<String, FieldedOrmNode<Object>> entry in nodes.entries)
          if (entry.value.annotation case ModelOrmNode node)
            ModelNaming(
              name: entry.key,
              node: node,
              fields: entry.value.fields,
            ),
      ];
      if (modelsNamings.isNotEmpty) {
        for (final ModelNaming model in modelsNamings) {
          _validatePrimaryKeyStage(model, nodes[model.schemaName]!.fields);
        }
        final List<_GeneratedRelation> relations = _relations(
          nodes,
          modelsNamings,
        );
        b.body.add(
          cb.Class((b) {
            b.name = 'Dorm';
            b.types.add(_queryTypeParameter());
            b.types.add(_pageTypeParameter());
            b.fields.add(
              cb.Field((b) {
                b.modifier = cb.FieldModifier.final$;
                b.type = cb.TypeReference((b) {
                  b.symbol = 'BaseEngine';
                  b.url = '$_dormUrl';
                  b.types.add(cb.Reference('Q'));
                  b.types.add(cb.Reference('P'));
                });
                b.name = '_engine';
              }),
            );
            b.constructors.add(
              cb.Constructor((b) {
                b.constant = true;
                b.requiredParameters.add(
                  cb.Parameter((b) {
                    b.toThis = true;
                    b.name = '_engine';
                  }),
                );
              }),
            );
            b.methods.addAll(
              modelsNamings.map((naming) {
                return cb.Method((b) {
                  b.returns = cb.TypeReference((b) {
                    b.symbol = 'DatabaseEntity';
                    b.url = '$_dormUrl';
                    b.types.add(cb.Reference(naming.dataName));
                    b.types.add(cb.Reference(naming.modelName));
                    b.types.add(naming.idReference);
                    b.types.add(cb.Reference('Q'));
                    b.types.add(naming.creationReference);
                    b.types.add(cb.Reference('P'));
                  });
                  b.type = cb.MethodType.getter;
                  b.lambda = true;
                  b.name = naming.repositoryName;
                  b.body = cb.ToCodeExpression(
                    cb.InvokeExpression.newOf(
                      cb.Reference('DatabaseEntity', '$_dormUrl'),
                      [
                        cb.InvokeExpression.constOf(
                          cb.Reference(naming.entityName),
                          [],
                        ),
                      ],
                      {'engine': expressionOf('_engine')},
                    ),
                  );
                });
              }),
            );
            if (relations.isNotEmpty) {
              b.methods.add(
                cb.Method((b) {
                  b.returns = cb.TypeReference((b) {
                    b.symbol = 'DormRelations';
                    b.types.add(cb.Reference('Q'));
                    b.types.add(cb.Reference('P'));
                  });
                  b.type = cb.MethodType.getter;
                  b.lambda = true;
                  b.name = 'relations';
                  b.body = expressionOf('DormRelations<Q, P>(this)').code;
                }),
              );
            }
          }),
        );
        b.body.add(
          cb.Class((b) {
            b.name = 'TransactionalDorm';
            b.extend = cb.TypeReference((b) {
              b.symbol = 'Dorm';
              b.types.add(cb.Reference('Q'));
              b.types.add(cb.Reference('P'));
            });
            b.types.add(_queryTypeParameter());
            b.types.add(_pageTypeParameter());
            b.fields.add(
              cb.Field((b) {
                b.modifier = cb.FieldModifier.final$;
                b.type = cb.TypeReference((b) {
                  b.symbol = 'TransactionalEngine';
                  b.url = '$_dormUrl';
                  b.types.add(cb.Reference('Q'));
                  b.types.add(cb.Reference('P'));
                });
                b.name = '_transactionalEngine';
              }),
            );
            b.constructors.add(
              cb.Constructor((b) {
                b.constant = true;
                b.requiredParameters.add(
                  cb.Parameter((b) {
                    b.toThis = true;
                    b.name = '_transactionalEngine';
                  }),
                );
                b.initializers.add(cb.Code('super(_transactionalEngine)'));
              }),
            );
            b.methods.add(
              cb.Method((b) {
                b.name = 'transaction';
                b.lambda = true;
                b.types.add(
                  cb.TypeReference((b) {
                    b.symbol = 'T';
                  }),
                );
                b.returns = cb.Reference('Future<T>');
                b.requiredParameters.add(
                  cb.Parameter((b) {
                    b.name = 'action';
                    b.type = cb.FunctionType((b) {
                      b.returnType = cb.Reference('Future<T>');
                      b.requiredParameters.add(
                        cb.TypeReference((b) {
                          b.symbol = 'Dorm';
                          b.url = '$_dormUrl';
                          b.types.add(cb.Reference('Q'));
                          b.types.add(cb.Reference('P'));
                        }),
                      );
                    });
                  }),
                );
                b.body = expressionOf(
                  '_transactionalEngine.transaction((engine) => action('
                  'Dorm<Q, P>(engine)))',
                ).code;
              }),
            );
          }),
        );
        if (relations.isNotEmpty) {
          b.body.addAll(_relationPathSpecs(modelsNamings, relations));
        }
      }
    });

    final cb.DartEmitter emitter = cb.DartEmitter(useNullSafetySyntax: true);
    return DartFormatter(
      languageVersion: library.element.languageVersion.effective,
    ).format(spec.accept(emitter).toString());
  }
}

/// Builds the normalized schema used by the migration CLI.
SchemaSnapshot buildMigrationSchema(
  LibraryReader library, {
  MigrationConfig config = const MigrationConfig(),
}) {
  final Map<String, FieldedOrmNode<Object>> nodes = parseLibrary(library);
  final Map<String, String> tablesByModel = {};
  for (final MapEntry<String, FieldedOrmNode<Object>> entry in nodes.entries) {
    final ClassOrmNode<Object> annotation = entry.value.annotation;
    if (annotation is ModelOrmNode) {
      final ModelNaming naming = ModelNaming(
        name: entry.key,
        node: annotation,
        fields: entry.value.fields,
      );
      tablesByModel[naming.modelName] = naming.tableName;
      tablesByModel[entry.key] = naming.tableName;
    }
  }

  final List<SchemaEntity> entities = [];
  for (final MapEntry<String, FieldedOrmNode<Object>> entry in nodes.entries) {
    final ClassOrmNode<Object> annotation = entry.value.annotation;
    if (annotation is! ModelOrmNode) continue;
    final ModelNaming naming = ModelNaming(
      name: entry.key,
      node: annotation,
      fields: entry.value.fields,
    );
    final List<SchemaField> fields = [];
    for (final MapEntry<String, FieldOrmNode> fieldEntry
        in entry.value.fields.entries) {
      final FieldOrmNode field = fieldEntry.value;
      if (!field.annotation.isConcrete) continue;
      final String dartType = field.type;
      final ForeignField? foreign = field.annotation is ForeignField
          ? field.annotation as ForeignField
          : null;
      final String fieldName = field.annotation.name ?? fieldEntry.key;
      fields.add(
        SchemaField(
          name: fieldEntry.key,
          columnName: fieldName,
          dartType: dartType,
          logicalType: _migrationLogicalType(dartType),
          nullable: !field.required,
          modelDefault: field.annotation.defaultValue?.toString(),
          foreignTable: foreign == null
              ? null
              : tablesByModel[_typeName(foreign.referTo)],
          foreignField: foreign == null ? null : 'id',
          unique: foreign?.unique ?? false,
          typeOverrides:
              config.typeOverrides[naming.tableName]?[fieldName] ??
              const <String, String>{},
        ),
      );
    }
    for (final _PrimaryKeyNaming key in naming._primaryKeys) {
      if (fields.any((field) => field.columnName == key.columnName)) continue;
      fields.add(
        SchemaField(
          name: key.fieldName,
          columnName: key.columnName,
          dartType: key.dartType,
          logicalType: _migrationLogicalType(key.dartType),
          nullable: false,
        ),
      );
    }
    entities.add(
      SchemaEntity(
        name: naming.modelName,
        tableName: naming.tableName,
        fields: fields,
        primaryKeys: naming._primaryKeys.map((key) => key.columnName).toList(),
      ),
    );
  }
  entities.sort((a, b) => a.tableName.compareTo(b.tableName));
  return SchemaSnapshot(entities: entities);
}

String _typeName(Type type) {
  final String value = type.toString();
  return value.split('<').first.split('.').last;
}

String _migrationLogicalType(String original) {
  final String type = original.replaceAll('?', '').trim();
  if (type == 'String') return 'text';
  if (type == 'int') return 'integer';
  if (type == 'double' || type == 'num') return 'real';
  if (type == 'bool') return 'boolean';
  if (type == 'DateTime') return 'dateTime';
  if (type == 'Uint8List' || type.endsWith('.Uint8List')) return 'binary';
  if (type == 'Map' || type.startsWith('Map<')) return 'json';
  if (type == 'List' || type.startsWith('List<')) return 'json';
  throw MigrationSchemaException(
    'Cannot infer a portable migration type for Dart type "$original". '
    'Use a supported scalar, Map, List, or Uint8List.',
  );
}
