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
import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart' as cb;
import 'package:dart_style/dart_style.dart';
import 'package:dartx/dartx.dart';
import 'package:dorm_annotations/dorm_annotations.dart';
import 'package:source_gen/source_gen.dart';

import 'utils/custom_types.dart';
import 'utils/orm_node.dart';
import 'visitors.dart';

final Uri _jsonAnnotationUrl = Uri(
  scheme: 'package',
  pathSegments: ['json_annotation', 'json_annotation.dart'],
);
final Uri _dormUrl = Uri(
  scheme: 'package',
  pathSegments: ['dorm', 'dorm.dart'],
);

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

class ModelNaming extends Naming<ModelOrmNode> {
  const ModelNaming({required super.name, required super.node});

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

  /// users
  String get repositoryName =>
      (node.annotation.as as $Symbol?)?.name ?? _defaultRepositoryName;

  /// UserProperties
  String get extensionName => '${modelName}Properties';
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

  cb.Class newClass({
    required String name,
    required Spec spec,
  }) {
    final bool supportsSerialization = spec.supportsSerialization ||
        fields.where((field) => field.isNative).isNotEmpty;

    final List<PolymorphicField> polymorphicFields = fields.values
        .map((field) => field.annotation)
        .whereType<PolymorphicField>()
        .toList();

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
        if (spec.includesPrimaryKey)
          cb.Field((b) {
            if (spec.supportsSerialization) {
              b.annotations.add(cb.InvokeExpression.newOf(
                cb.Reference('JsonKey', '$_jsonAnnotationUrl'),
                [],
                {
                  'name': cb.literalString('_id'),
                  'required': cb.literalTrue,
                  'disallowNullValue': cb.literalTrue,
                },
              ));
            }
            b.modifier = cb.FieldModifier.final$;
            b.type = cb.Reference('String');
            b.name = 'id';
          }),
        ...fields.entries.expand((entry) sync* {
          final String declaredPropertyName = entry.key;
          final FieldOrmNode declaredPropertyInfo = entry.value;
          final String declaredPropertyTypeLabel = declaredPropertyInfo.type;
          final Field field = declaredPropertyInfo.annotation;
          if (!spec.shouldDeclareField(field)) return;

          final String? key = field.name;
          final Object? defaultValue = field.defaultValue;
          final bool required =
              defaultValue == null && declaredPropertyInfo.required;

          yield cb.Field((b) {
            b.name = declaredPropertyName;
            if (!spec.ignoreOverrideFor.contains(declaredPropertyName) &&
                (extendsReference != null || implementsReferences.isNotEmpty)) {
              b.annotations.add(expressionOf('override'));
            }
            if (spec.supportsSerialization) {
              b.annotations.add(cb.InvokeExpression.newOf(
                cb.Reference('JsonKey', '$_jsonAnnotationUrl'),
                [],
                {
                  if (key != null) 'name': cb.literalString(key),
                  if (required) 'required': cb.literalTrue,
                  if (required) 'disallowNullValue': cb.literalTrue,
                  if (defaultValue != null)
                    'defaultValue': cb.literal(defaultValue),
                },
              ));
            }
            b.modifier = cb.FieldModifier.final$;
            b.type = switch (
                spec.resolveTypeFromField(field, declaredPropertyTypeLabel)) {
              DirectSpecTypeResolution resolution => resolution.reference,
              IndirectSpecTypeResolution resolution => resolution.referenceBy(
                  (referredType) => nodes[referredType.name]?.annotation,
                ),
            };
          });
        }),
        if (spec.discriminatorSpec
            case (
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
        b.annotations.add(cb.InvokeExpression.newOf(
          cb.Reference('JsonSerializable', '$_jsonAnnotationUrl'),
          [],
          {
            'anyMap': cb.literalTrue,
            'explicitToJson': cb.literalTrue,
            if (polymorphicFields.isNotEmpty)
              'constructor': cb.literalString('_'),
          },
        ));
      }
      b.constructors.addAll([
        // `fromJson` factory method
        if (hasFields && supportsSerialization)
          cb.Constructor((b) {
            b.factory = true;
            b.name = 'fromJson';
            if (spec.includesPrimaryKey) {
              b.requiredParameters.add(cb.Parameter((b) {
                b.type = cb.Reference('String');
                b.name = 'id';
              }));
            }
            b.requiredParameters.add(cb.Parameter((b) {
              b.type = cb.Reference('Map');
              b.name = 'json';
            }));
            b.lambda = true;
            b.body =
                cb.ToCodeExpression(expressionOf('_\$${name}FromJson').call([
              spec.includesPrimaryKey
                  ? cb.literalMap({
                      cb.literalSpread(): expressionOf('json'),
                      cb.literalString('_id'): expressionOf('id'),
                    })
                  : expressionOf('json'),
            ]));
          }),
        // Polymorphic constructor
        if (polymorphicFields.isNotEmpty)
          cb.Constructor((b) {
            b.factory = true;
            b.name = '_';
            if (spec.includesPrimaryKey) {
              b.optionalParameters.add(cb.Parameter((b) {
                b.required = true;
                b.named = true;
                b.type = cb.Reference('String');
                b.name = 'id';
              }));
            }
            b.optionalParameters.addAll(fields
                .where((field) =>
                    spec.shouldDeclareField(field) || extendsReference != null)
                .entries
                .expand((entry) sync* {
              final String fieldName = entry.key;
              final String fieldType = entry.value.type;

              final Field field = entry.value.annotation;
              if (field is PolymorphicField) {
                yield cb.Parameter((b) {
                  b.required = true;
                  b.named = true;
                  b.type = cb.Reference('Map');
                  b.name = fieldName;
                });
              } else if (field is ModelField) {
                final $Type value = field.referTo as $Type;
                final cb.Reference type =
                    switch (spec.resolveTypeFromField(field, value.name!)) {
                  DirectSpecTypeResolution resolution => resolution.reference,
                  IndirectSpecTypeResolution resolution =>
                    resolution.referenceBy(
                      (referredType) => nodes[referredType.name]?.annotation,
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
            }));
            b.lambda = false;
            b.body = cb.Block((b) {
              if (extendsReference != null) {
                b.statements.add(cb
                    .declareFinal('data', type: extendsReference)
                    .assign(
                      cb.InvokeExpression.newOf(
                        extendsReference,
                        [],
                        Map.fromEntries(fields
                            .where((field) => field.isNative)
                            .entries
                            .expand((entry) sync* {
                          final String fieldName = entry.key;
                          yield MapEntry(fieldName, expressionOf(fieldName));
                        })),
                        [],
                        '_',
                      ),
                    )
                    .statement);
              }
              b.statements.add(
                cb.InvokeExpression.newOf(
                  cb.Reference(name),
                  [],
                  {
                    if (spec.includesPrimaryKey) 'id': expressionOf('id'),
                    ...Map.fromEntries(fields
                        .where((field) => field.isConcrete)
                        .entries
                        .expand((entry) sync* {
                      final String fieldName = entry.key;
                      final String fieldType = entry.value.type;

                      final Field field = entry.value.annotation;
                      if (!(spec.shouldDeclareField(field) ||
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
                    }))
                  },
                ).returned.statement,
              );
            });
          }),
        // Default constructor
        cb.Constructor((b) {
          b.constant = true;
          if (spec.includesPrimaryKey) {
            b.optionalParameters.add(cb.Parameter((b) {
              b.required = true;
              b.named = true;
              b.toThis = true;
              b.name = 'id';
            }));
          }
          b.optionalParameters.addAll(fields.entries.expand((entry) sync* {
            final String fieldName = entry.key;
            final Field field = entry.value.annotation;
            // Only concrete fields should be considered on the constructor
            // Virtual fields will be added as overridden getters
            if (!field.isConcrete) return;

            final bool declaresField = spec.shouldDeclareField(field);
            if (!declaresField && extendsReference == null) return;
            yield cb.Parameter((b) {
              b.required = true;
              b.named = true;
              final bool toThis = declaresField;
              b.toThis = toThis;
              b.toSuper = !toThis;
              b.name = fieldName;
            });
          }));
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

          final bool lambda = !(hasFields && supportsSerialization) ||
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
                  in fields.where((field) => field.isA<QueryField>()).entries) {
                final String? name =
                    (entry.value.annotation as QueryField).name;
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
              body = cb
                  .literalMap({
                    cb.literalSpread(): baseExpression
                        .cascade('remove')
                        .call([cb.literalString('_id')]),
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
    b.body.add(newClass(
      name: naming.modelName,
      spec: Spec(
        includesPrimaryKey: false,
        supportsSerialization: true,
        extendsReference: null,
        implementsReferences: [cb.Reference(naming.schemaName)],
        includesQueryGetters: false,
        ignoreOverrideFor: {'toJson'},
        discriminatorSpec: null,
        shouldDeclareField: (field) => field.isNative,
      ),
    ));
  }
}

class ModelArgs extends FieldedArgs<Model, ModelNaming> {
  const ModelArgs({
    required super.nodes,
    required super.annotation,
    required super.fields,
    required super.naming,
  });

  cb.Expression _uidTypeExpressionOf(UidType value) {
    return value.when(
      caseSimple: () => expressionOf('id'),
      caseComposite: () =>
          expressionOf('dependency').property('key').call([expressionOf('id')]),
      caseSameAs: (type) {
        type as $Type;
        for (MapEntry<String, FieldOrmNode> entry
            in fields.where((field) => field.isForeign).entries) {
          final $Type currentType =
              (entry.value.annotation as ForeignField).referTo as $Type;
          if (currentType.name != type.name) continue;
          return expressionOf('dependency').property(entry.key);
        }
        throw StateError('invalid reference on UidType.sameAs: ${type.name}');
      },
      caseCustom: (builder) {
        final $CustomUidValue value = builder(0) as $CustomUidValue;
        final String name = value.reader.functionName;
        return cb.InvokeExpression.newOf(cb.Reference(name), [
          cb.InvokeExpression.newOf(
            cb.Reference(naming.dummyName),
            [
              expressionOf('dependency'),
              expressionOf('data'),
            ],
            {},
            [],
            'fromData',
          ),
        ]).property('when').call([], {
          'caseSimple': expressionOf('() => id'),
          'caseComposite': expressionOf('() => dependency.key(id)'),
          'caseValue': expressionOf('(id) => id'),
        });
      },
    );
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
      }));
      b.constructors.add(cb.Constructor((b) {
        b.factory = true;
        b.name = 'fromData';
        b.requiredParameters.add(cb.Parameter((b) {
          b.type = cb.Reference(naming.dependencyName);
          b.name = 'dependency';
        }));
        b.requiredParameters.add(cb.Parameter((b) {
          b.type = cb.Reference(naming.dataName);
          b.name = 'data';
        }));
        b.body = cb.ToCodeExpression(
          cb.InvokeExpression.newOf(
            expressionOf(className),
            [],
            fields.where((field) => field.isConcrete).map((name, field) {
              final cb.Expression expression = expressionOf(
                  field.annotation is ForeignField ? 'dependency' : 'data');
              return MapEntry(name, expression.property(name));
            }),
          ),
        );
      }));
      b.constructors.add(cb.Constructor((b) {
        b.constant = true;
        b.optionalParameters
            .addAll(fields.where((field) => field.isConcrete).keys.map((name) {
          return cb.Parameter((b) {
            b.required = true;
            b.named = true;
            b.toThis = true;
            b.name = name;
          });
        }));
      }));
      final Iterable<cb.Method> queryGetters = fields.queryGetters;
      b.methods.addAll(queryGetters);
      final List<String> privateQueryGettersNames = queryGetters
          .mapNotNull((method) => method.name)
          .where((methodName) => methodName.startsWith('_'))
          .toList();
      if (privateQueryGettersNames.isNotEmpty) {
        b.methods.add(cb.Method.returnsVoid((b) {
          b.type = cb.MethodType.getter;
          b.name = '\$dorm\$privateFields';
          b.lambda = true;
          b.body =
              cb.literalList(privateQueryGettersNames.map(expressionOf)).code;
        }));
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
      b.fields
          .addAll(fields.where((field) => field.isForeign).entries.map((entry) {
        return cb.Field((b) {
          b.modifier = cb.FieldModifier.final$;
          b.type = cb.Reference(entry.value.type);
          b.name = entry.key;
        });
      }));
      if (fields.where((field) => field.isForeign).isEmpty) {
        b.constructors.add(cb.Constructor((b) {
          b.constant = true;
          b.initializers.add(cb.ToCodeExpression(
            expressionOf('super').property('strong').call([]),
          ));
        }));
      } else {
        b.constructors.add(cb.Constructor((b) {
          b.constant = false;
          b.optionalParameters
              .addAll(fields.where((field) => field.isForeign).keys.map((name) {
            return cb.Parameter((b) {
              b.required = true;
              b.named = true;
              b.toThis = true;
              b.name = name;
            });
          }));
          b.initializers.add(cb.ToCodeExpression(
            expressionOf('super').property('weak').call([
              cb.literalList(
                  fields.where((field) => field.isForeign).entries.map((entry) {
                cb.Expression expression = expressionOf(entry.key);
                if (!entry.value.required) {
                  expression = expression.ifNullThen(cb.literalString(''));
                }
                return expression;
              })),
            ]),
          ));
        }));
      }
    });
  }

  cb.Spec get _entityClass {
    return cb.Class((b) {
      b.name = naming.entityName;
      b.implements.add(cb.TypeReference((b) {
        b.symbol = 'Entity';
        b.url = '$_dormUrl';
        b.types.add(cb.Reference(naming.dataName));
        b.types.add(cb.Reference(naming.modelName));
      }));
      b.constructors.add(cb.Constructor((b) {
        b.constant = true;
      }));
      b.fields.add(cb.Field((b) {
        b.annotations.add(expressionOf('override'));
        b.modifier = cb.FieldModifier.final$;
        b.type = cb.Reference('String');
        b.name = 'tableName';
        b.assignment = cb.ToCodeExpression(cb.literalString(annotation.name));
      }));
      b.methods.add(cb.Method((b) {
        b.annotations.add(expressionOf('override'));
        b.returns = cb.Reference(naming.modelName);
        b.name = 'fromData';
        b.requiredParameters.add(cb.Parameter((b) {
          b.type = cb.Reference(naming.dependencyName);
          b.name = 'dependency';
        }));
        b.requiredParameters.add(cb.Parameter((b) {
          b.type = cb.Reference('String');
          b.name = 'id';
        }));
        b.requiredParameters.add(cb.Parameter((b) {
          b.type = cb.Reference(naming.dataName);
          b.name = 'data';
        }));
        b.lambda = false;
        b.body = cb.InvokeExpression.newOf(
          cb.Reference(naming.modelName),
          [],
          {
            'id': _uidTypeExpressionOf(annotation.uidType),
            ...Map.fromEntries(fields
                .where((field) => field.isConcrete)
                .entries
                .expand((entry) sync* {
              final String fieldName = entry.key;
              final Field baseField = entry.value.annotation;
              if (baseField is PolymorphicField) {
                final $ConcreteSymbol pivotSymbol =
                    baseField.pivotAs as $ConcreteSymbol;
                yield MapEntry(
                  pivotSymbol.name,
                  expressionOf('data').property(pivotSymbol.name),
                );
              }
              final cb.Expression prefixExpression;
              if (entry.value.annotation is ForeignField) {
                prefixExpression = expressionOf('dependency');
              } else {
                prefixExpression = expressionOf('data');
              }
              yield MapEntry(fieldName, prefixExpression.property(fieldName));
            })),
          },
        ).returned.statement;
      }));
      b.methods.add(cb.Method((b) {
        b.annotations.add(expressionOf('override'));
        b.returns = cb.Reference(naming.modelName);
        b.name = 'convert';
        b.requiredParameters.add(cb.Parameter((b) {
          b.type = cb.Reference(naming.modelName);
          b.name = 'model';
        }));
        b.requiredParameters.add(cb.Parameter((b) {
          b.type = cb.Reference(naming.dataName);
          b.name = 'data';
        }));
        b.lambda = true;

        cb.Expression baseExpression = expressionOf('model');
        if (fields.where((field) => field.isNative).isNotEmpty) {
          baseExpression =
              baseExpression.property('copyWith').call([expressionOf('data')]);
        }
        b.body = cb.ToCodeExpression(baseExpression);
      }));
      b.methods.add(cb.Method((b) {
        b.annotations.add(expressionOf('override'));
        b.returns = cb.Reference(naming.modelName);
        b.name = 'fromJson';
        b.requiredParameters.add(cb.Parameter((b) {
          b.type = cb.Reference('String');
          b.name = 'id';
        }));
        b.requiredParameters.add(cb.Parameter((b) {
          b.type = cb.Reference('Map');
          b.name = 'json';
        }));
        b.lambda = true;
        b.body = cb.ToCodeExpression(cb.InvokeExpression.newOf(
          cb.Reference(naming.modelName),
          ['id', 'json'].map(expressionOf).toList(),
          {},
          [],
          'fromJson',
        ));
      }));
      b.methods.add(cb.Method((b) {
        b.annotations.add(expressionOf('override'));
        b.returns = cb.Reference('String');
        b.name = 'identify';
        b.requiredParameters.add(cb.Parameter((b) {
          b.type = cb.Reference(naming.modelName);
          b.name = 'model';
        }));
        b.lambda = true;
        b.body = expressionOf('model').property('id').code;
      }));
      b.methods.add(cb.Method((b) {
        b.annotations.add(expressionOf('override'));
        b.returns = cb.TypeReference((b) {
          b.symbol = 'Map';
          b.types.add(cb.Reference('String'));
          b.types.add(cb.Reference('Object?'));
        });
        b.name = 'toJson';
        b.requiredParameters.add(cb.Parameter((b) {
          b.type = cb.Reference(naming.dataName);
          b.name = 'data';
        }));
        b.lambda = true;
        b.body = cb.ToCodeExpression(
          expressionOf('data').property('toJson').call([]),
        );
      }));
    });
  }

  cb.Spec get _extension {
    return cb.Extension((b) {
      b.name = naming.extensionName;
      b.on = cb.Reference(naming.modelName);
      b.methods.add(cb.Method((b) {
        b.returns = cb.Reference(naming.modelName);
        b.name = 'copyWith';
        b.requiredParameters.add(cb.Parameter((b) {
          b.type = cb.Reference(naming.dataName);
          b.name = 'data';
        }));
        b.body = cb.InvokeExpression.newOf(
          cb.Reference(naming.modelName),
          [],
          {
            'id': expressionOf('id'),
            ...Map.fromEntries(fields
                .where((field) => field.isConcrete)
                .entries
                .expand((entry) sync* {
              final String fieldName = entry.key;
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
            })),
          },
        ).returned.statement;
      }));
    });
  }

  @override
  void accept(cb.LibraryBuilder b) {
    annotation.uidType.when(
      caseSimple: () {},
      caseComposite: () {},
      caseSameAs: (_) {},
      caseCustom: (_) => b.body.add(_dummyClass),
    );
    b.body.add(newClass(
      name: naming.dataName,
      spec: Spec(
        includesPrimaryKey: false,
        supportsSerialization: true,
        extendsReference: null,
        implementsReferences: [],
        includesQueryGetters: false,
        ignoreOverrideFor: {},
        discriminatorSpec: null,
        shouldDeclareField: (field) => field.isNative,
      ),
    ));
    b.body.add(newClass(
      name: naming.modelName,
      spec: Spec(
        includesPrimaryKey: true,
        supportsSerialization: true,
        extendsReference: cb.Reference(naming.dataName),
        implementsReferences: [cb.Reference(naming.schemaName)],
        includesQueryGetters: true,
        ignoreOverrideFor: {},
        discriminatorSpec: null,
        shouldDeclareField: (field) => field.isForeign,
      ),
    ));
    b.body.add(_dependencyClass);
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
      b.values.addAll(fields.entries.map((entry) {
        final PolymorphicDataNaming naming = PolymorphicDataNaming(
          name: entry.key,
          node: entry.value,
        );
        return cb.EnumValue((b) {
          b.name = naming.enumFieldName;
        });
      }));
    });
  }

  cb.Spec get _baseClass {
    return cb.Class((b) {
      b.abstract = !annotation.isSealed;
      b.sealed = annotation.isSealed;
      b.name = naming.modelName;
      b.implements.add(cb.Reference(naming.schemaName));
      b.constructors.add(cb.Constructor((b) {
        b.factory = true;
        b.name = 'fromType';
        b.requiredParameters.add(cb.Parameter((b) {
          b.type = cb.Reference(naming.enumName);
          b.name = 'type';
        }));
        b.requiredParameters.add(cb.Parameter((b) {
          b.type = cb.Reference('Map');
          b.name = 'json';
        }));
        b.lambda = false;
        b.body = cb.Block((b) {
          b.statements.add(cb.Code('switch (type) {'));
          for (MapEntry<String, PolymorphicDataOrmNode> entry
              in fields.entries) {
            final PolymorphicDataNaming naming =
                PolymorphicDataNaming(name: entry.key, node: entry.value);
            b.statements.add(cb.Code(
                'case ${this.naming.enumName}.${naming.enumFieldName}:'));
            b.statements.add(cb.InvokeExpression.newOf(
              cb.Reference(naming.modelName),
              [expressionOf('json')],
              {},
              [],
              'fromJson',
            ).returned.statement);
          }
          b.statements.add(cb.Code('}'));
        });
      }));
      b.methods.add(cb.Method((b) {
        b.returns = cb.Reference(naming.enumName);
        b.type = cb.MethodType.getter;
        b.name = 'type';
      }));
      b.methods.add(cb.Method((b) {
        b.returns = cb.TypeReference((b) {
          b.symbol = 'Map';
          b.types.add(cb.Reference('String'));
          b.types.add(cb.Reference('Object?'));
        });
        b.name = 'toJson';
      }));
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
    b.body.add(newClass(
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
        shouldDeclareField: (field) => field.isConcrete,
      ),
    ));
  }
}

class Spec {
  final bool includesPrimaryKey;
  final bool supportsSerialization;
  final cb.Reference? extendsReference;
  final List<cb.Reference> implementsReferences;
  final bool includesQueryGetters;
  final Set<String> ignoreOverrideFor;
  final (cb.Reference, String)? discriminatorSpec;
  final bool Function(Field field) shouldDeclareField;

  const Spec({
    required this.includesPrimaryKey,
    required this.supportsSerialization,
    required this.extendsReference,
    required this.implementsReferences,
    required this.includesQueryGetters,
    required this.ignoreOverrideFor,
    required this.discriminatorSpec,
    required this.shouldDeclareField,
  });
}

sealed class SpecTypeResolution {
  final String declaredTypeLabel;
  const SpecTypeResolution({
    required this.declaredTypeLabel,
  });
}

class DirectSpecTypeResolution extends SpecTypeResolution {
  const DirectSpecTypeResolution({
    required super.declaredTypeLabel,
  });

  cb.Reference get reference => cb.Reference(declaredTypeLabel);
}

class IndirectSpecTypeResolution extends SpecTypeResolution {
  final $Type originalType;

  const IndirectSpecTypeResolution({
    required super.declaredTypeLabel,
    required this.originalType,
  });

  cb.Reference referenceBy(
    ClassOrmNode<Object>? Function($Type) accessor,
  ) {
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
        return DirectSpecTypeResolution(
          declaredTypeLabel: declaredTypeLabel,
        );
    }
  }
}

extension _BaseWriting on Map<String, FieldOrmNode> {
  Iterable<cb.Method> get queryGetters sync* {
    for (MapEntry<String, FieldOrmNode> entry
        in where((field) => field.isA<QueryField>()).entries) {
      final QueryField field = entry.value.annotation as QueryField;
      if (field.referTo.isEmpty) continue;

      yield cb.Method((b) {
        b.annotations.add(expressionOf('override'));
        b.returns = cb.Reference(entry.value.type);
        b.type = cb.MethodType.getter;
        b.name = entry.key;
        b.lambda = true;
        b.body = cb.ToCodeExpression(cb
            .literalList(field.referTo.map((token) {
              final QueryType? type = token.type;

              final String? symbolName = (token.field as $Symbol).name;
              if (symbolName == null) {
                throw StateError(
                  'field ${field.name} must have a symbol for all its tokens',
                );
              }

              final FieldOrmNode? referredField = this[symbolName] ??
                  where((field) => field.isA<PolymorphicField>())
                      .values
                      .firstOrNullWhere((node) {
                    final PolymorphicField field =
                        node.annotation as PolymorphicField;
                    final $ConcreteSymbol pivotSymbol =
                        field.pivotAs as $ConcreteSymbol;
                    return pivotSymbol.name == symbolName;
                  });

              if (referredField == null ||
                  referredField.annotation is QueryField) {
                throw StateError(
                  'field ${field.name}/$symbolName must have a '
                  'symbol referring to a valid field',
                );
              }

              cb.Expression expression = expressionOf(symbolName);
              final cb.Expression? callExpression;
              switch (type) {
                case QueryType.text:
                  callExpression = expressionOf('\$normalizeText');
                  break;
                case QueryType.enumeration:
                  callExpression = expressionOf('\$normalizeEnum');
                  break;
                case null:
                  callExpression = null;
                  break;
              }
              if (callExpression != null) {
                expression = callExpression.call([expression]);
              }
              if (!referredField.required) {
                expression = expression.ifNullThen(cb.literalString(''));
              }
              return expression;
            }))
            .property('join')
            .call([cb.literalString(field.joinBy)]));
      });
    }
  }
}

/// Code generator.
class OrmGenerator extends Generator {
  @override
  String? generate(LibraryReader library, BuildStep buildStep) {
    final Set<Uri> partUris = library.element.parts
        .map((element) => element.uri)
        .whereType<DirectiveUriWithSource>()
        .map((directive) => directive.relativeUri)
        .toSet();
    final bool hasDormDirective =
        partUris.any((uri) => uri.path.endsWith('.dorm.dart'));
    if (!hasDormDirective) return null;

    final Map<String, FieldedOrmNode<Object>> nodes = parseLibrary(library);
    final cb.Spec spec = cb.Library((b) {
      nodes.entries.mapNotNull<Args>((entry) {
        final String name = entry.key;
        final FieldedOrmNode<Object> node = entry.value;
        final ClassOrmNode<Object> classNode = node.annotation;
        if (classNode is ModelOrmNode) {
          return ModelArgs(
            nodes: nodes,
            naming: ModelNaming(name: name, node: classNode),
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
      }).forEach((arg) => arg.accept(b));

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
                  (entry) => entry.value.annotation as PolymorphicDataOrmNode)
              .entries
              .groupBy((entry) => entry.value.tag)
              .mapValues((entry) => Map.fromEntries(entry.value));

      for (MapEntry<PolymorphicDataTag,
          Map<String, PolymorphicDataOrmNode>> entry in groups.entries) {
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

      nodes.entries.mapNotNull((entry) {
        final String name = entry.key;
        final FieldedOrmNode<Object> node = entry.value;
        final ClassOrmNode<Object> classNode = node.annotation;
        if (classNode is! PolymorphicDataOrmNode) return null;
        return PolymorphicModelArgs(
          nodes: nodes,
          naming: PolymorphicDataNaming(name: name, node: classNode),
          fields: node.fields,
        );
      }).forEach((arg) => arg.accept(b));

      b.body.add(cb.Class((b) {
        b.name = 'Dorm';
        b.fields.add(cb.Field((b) {
          b.modifier = cb.FieldModifier.final$;
          b.type = cb.Reference('BaseEngine', '$_dormUrl');
          b.name = '_engine';
        }));
        b.constructors.add(cb.Constructor((b) {
          b.constant = true;
          b.requiredParameters.add(cb.Parameter((b) {
            b.toThis = true;
            b.name = '_engine';
          }));
        }));
        b.methods.addAll(nodes.entries.mapNotNull((entry) {
          final ClassOrmNode<Object> node = entry.value.annotation;
          if (node is! ModelOrmNode) return null;

          final ModelNaming naming = ModelNaming(name: entry.key, node: node);
          return cb.Method((b) {
            b.returns = cb.TypeReference((b) {
              b.symbol = 'DatabaseEntity';
              b.url = '$_dormUrl';
              b.types.add(cb.Reference(naming.dataName));
              b.types.add(cb.Reference(naming.modelName));
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
                {
                  'engine': expressionOf('_engine'),
                },
              ),
            );
          });
        }));
      }));
    });

    final cb.DartEmitter emitter = cb.DartEmitter(useNullSafetySyntax: true);
    return DartFormatter().format(spec.accept(emitter).toString());
  }
}
