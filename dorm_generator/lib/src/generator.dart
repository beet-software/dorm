import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart' as cb;
import 'package:dart_style/dart_style.dart';
import 'package:dartx/dartx.dart';
import 'package:dorm_annotations/dorm_annotations.dart';
import 'package:source_gen/source_gen.dart';

import 'utils/custom_types.dart';

final Uri _jsonAnnotationUrl = Uri(
  scheme: 'package',
  pathSegments: ['json_annotation', 'json_annotation.dart'],
);

cb.Expression expressionOf(String code) => cb.CodeExpression(cb.Code(code));

/// Naming of code generation.
class SchemaNaming {
  /// _Schema
  final String schemaName;

  const SchemaNaming(this.schemaName);

  /// _$Schema
  String get dummyName => '_\$$modelName';

  /// Schema
  String get modelName => schemaName.substring(1);

  /// SchemaData
  String get dataName => '${modelName}Data';

  /// SchemaDependency
  String get dependencyName => '${modelName}Dependency';

  /// SchemaEntity
  String get entityName => '${modelName}Entity';
}

class PolymorphicNaming {
  // _Schema
  final String schemaName;

  const PolymorphicNaming(this.schemaName);

  // Schema
  String get modelName => schemaName.substring(1);

  // SchemaType
  String get enumName => '${modelName}Type';
}

/// Arguments of code generation.
abstract class Args<Annotation, Field, Naming> {
  final Annotation annotation;
  final Map<String, Field> fields;
  final Naming naming;

  const Args({
    required this.annotation,
    required this.fields,
    required this.naming,
  });

  void accept(cb.LibraryBuilder b);
}

class ModelArgs extends Args<Model, FieldAnnotationData, SchemaNaming> {
  const ModelArgs({
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
        for (MapEntry<String, FieldAnnotationData> entry
            in fields.where(FieldFilter.belongsToModel).entries) {
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
          fields.where(FieldFilter.belongsToSchema).entries.map((entry) {
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
            cb.CodeExpression(cb.Code(className)),
            [],
            fields.where(FieldFilter.belongsToSchema).map((name, field) {
              final cb.Expression expression = cb.CodeExpression(
                cb.Code(
                    field.annotation is ForeignField ? 'dependency' : 'data'),
              );
              return MapEntry(name, expression.property(name));
            }),
          ),
        );
      }));
      b.constructors.add(cb.Constructor((b) {
        b.constant = true;
        b.optionalParameters
            .addAll(fields.where(FieldFilter.belongsToSchema).keys.map((name) {
          return cb.Parameter((b) {
            b.required = true;
            b.named = true;
            b.toThis = true;
            b.name = name;
          });
        }));
      }));
      b.methods.addAll(fields.queryGetters);
    });
  }

  cb.Spec get _dataClass {
    return fields.baseClassOf(naming.dataName);
  }

  cb.Spec get _modelClass {
    return fields.baseClassOf(naming.modelName, baseName: naming.dataName);
  }

  cb.Spec get _dependencyClass {
    return cb.Class((b) {
      b.name = naming.dependencyName;
      b.extend = cb.TypeReference((b) {
        b.symbol = 'Dependency';
        b.types.add(cb.Reference(naming.dataName));
      });
      b.fields
          .addAll(fields.where(FieldFilter.belongsToModel).entries.map((entry) {
        return cb.Field((b) {
          b.modifier = cb.FieldModifier.final$;
          b.type = cb.Reference(entry.value.type);
          b.name = entry.key;
        });
      }));
      if (fields.where(FieldFilter.belongsToModel).isEmpty) {
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
              .addAll(fields.where(FieldFilter.belongsToModel).keys.map((name) {
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
                  fields.where(FieldFilter.belongsToModel).entries.map((entry) {
                cb.Expression expression =
                    cb.CodeExpression(cb.Code(entry.key));
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
                .where(FieldFilter.belongsToSchema)
                .entries
                .expand((entry) sync* {
              final String fieldName = entry.key;
              final Field baseField = entry.value.annotation;
              if (baseField is PolymorphicField) {
                yield MapEntry(
                  'type',
                  expressionOf('data').property('type'),
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
        b.lambda = false;
        b.body = cb.InvokeExpression.newOf(
          cb.Reference(naming.modelName),
          [],
          {
            'id': expressionOf('model').property('id'),
            ...Map.fromEntries(fields
                .where(FieldFilter.belongsToSchema)
                .entries
                .expand((entry) sync* {
              final String fieldName = entry.key;
              final Field baseField = entry.value.annotation;
              if (baseField is PolymorphicField) {
                yield MapEntry(
                  'type',
                  expressionOf('data').property('type'),
                );
              }
              final cb.Expression prefixExpression;
              if (entry.value.annotation is ForeignField) {
                prefixExpression = expressionOf('model');
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
          ['id', 'json']
              .map((code) => cb.CodeExpression(cb.Code(code)))
              .toList(),
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

  @override
  void accept(cb.LibraryBuilder b) {
    annotation.uidType.when(
      caseSimple: () {},
      caseComposite: () {},
      caseSameAs: (_) {},
      caseCustom: (_) => b.body.add(_dummyClass),
    );
    b.body.add(_dataClass);
    b.body.add(_modelClass);
    b.body.add(_dependencyClass);
    b.body.add(_entityClass);
  }
}

class PolymorphicArgs
    extends Args<void, PolymorphicClassAnnotationData, PolymorphicNaming> {
  const PolymorphicArgs({
    required super.fields,
    required super.naming,
  }) : super(annotation: null);

  cb.Spec get _enumClass {
    return cb.Enum((b) {
      b.name = naming.enumName;
      b.values.addAll(fields.entries.map((entry) {
        final String name = entry.key;
        final String fieldName =
            (entry.value.annotation.as as $Symbol?)?.name ??
                (name[1].toLowerCase() + name.substring(2));
        return cb.EnumValue((b) {
          b.name = fieldName;
        });
      }));
    });
  }

  cb.Spec get _baseClass {
    return cb.Class((b) {
      b.abstract = true;
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
          for (String name in fields.keys) {
            final String branchName = name[1].toLowerCase() + name.substring(2);
            b.statements.add(cb.Code('case ${naming.enumName}.$branchName:'));
            b.statements.add(cb.InvokeExpression.newOf(
              cb.Reference(name.substring(1)),
              [expressionOf('json')],
              {},
              [],
              'fromJson',
            ).returned.statement);
          }
          b.statements.add(cb.Code('}'));
        });
      }));
      b.constructors.add(cb.Constructor((b) {
        b.constant = true;
        b.name = '_';
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

class PolymorphicModelArgs
    extends Args<PolymorphicData, FieldAnnotationData, PolymorphicNaming> {
  const PolymorphicModelArgs({
    required super.annotation,
    required super.fields,
    required super.naming,
  });

  cb.Spec get _class {
    final String name = naming.modelName;
    return cb.Class((b) {
      b.annotations.add(cb.InvokeExpression.newOf(
        cb.Reference('JsonSerializable', '$_jsonAnnotationUrl'),
        [],
        {'anyMap': cb.literalTrue, 'explicitToJson': cb.literalTrue},
      ));
      b.name = name.substring(1);
      b.extend = cb.Reference(naming.modelName);
      b.implements.add(cb.Reference(name));
      b.fields.addAll(fields.entries.map((entry) {
        final String? key = entry.value.annotation.name;
        final String name = entry.key;
        final String type = entry.value.type;
        final bool required = entry.value.required;
        return cb.Field((b) {
          b.annotations.add(expressionOf('override'));
          b.annotations.add(cb.InvokeExpression.newOf(
            cb.Reference('JsonKey', '$_jsonAnnotationUrl'),
            [],
            {
              if (key != null) 'name': cb.literalString(key),
              if (required) 'required': cb.literalTrue,
              if (required) 'disallowNullValue': cb.literalTrue,
            },
          ));
          b.modifier = cb.FieldModifier.final$;
          b.type = cb.Reference(type);
          b.name = name;
        });
      }));
      b.constructors.add(cb.Constructor((b) {
        b.factory = true;
        b.name = 'fromJson';
        b.requiredParameters.add(cb.Parameter((b) {
          b.type = cb.Reference('Map');
          b.name = 'json';
        }));
        b.lambda = true;
        b.body = cb.InvokeExpression.newOf(
          cb.Reference('_\$${name.substring(1)}FromJson'),
          [expressionOf('json')],
        ).code;
      }));
      b.constructors.add(cb.Constructor((b) {
        b.constant = true;
        b.optionalParameters.addAll(fields.keys.map((name) {
          return cb.Parameter((b) {
            b.required = true;
            b.named = true;
            b.toThis = true;
            b.name = name;
          });
        }));
        b.initializers.add(cb.ToCodeExpression(
          expressionOf('super').property('_').call([]),
        ));
      }));
      b.fields.add(cb.Field((b) {
        b.annotations.add(expressionOf('override'));
        b.modifier = cb.FieldModifier.final$;
        b.type = cb.Reference(naming.enumName);
        b.name = 'type';
        b.assignment = cb.CodeExpression(cb.Code(naming.enumName))
            .property(name[1].toLowerCase() + name.substring(2))
            .code;
      }));
      b.methods.add(cb.Method((b) {
        b.annotations.add(expressionOf('override'));
        b.returns = cb.TypeReference((b) {
          b.symbol = 'Map';
          b.types.add(cb.Reference('String'));
          b.types.add(cb.Reference('Object?'));
        });
        b.name = 'toJson';
        b.lambda = true;
        b.body = expressionOf('_\$${name.substring(1)}ToJson')
            .call([expressionOf('this')]).code;
      }));
    });
  }

  @override
  void accept(cb.LibraryBuilder b) {
    b.body.add(_class);
  }
}

/// Base of code generation.
extension _BaseWriting on Map<String, FieldAnnotationData> {
  cb.Spec baseClassOf(String name, {String? baseName}) {
    final bool hasPolymorphism = values
        .map((field) => field.annotation)
        .whereType<PolymorphicField>()
        .isNotEmpty;

    return cb.Class((b) {
      b.annotations.add(cb.InvokeExpression.newOf(
        cb.Reference('JsonSerializable', '$_jsonAnnotationUrl'),
        [],
        {
          'anyMap': cb.literalTrue,
          'explicitToJson': cb.literalTrue,
          if (hasPolymorphism) 'constructor': cb.literalString('_'),
        },
      ));
      b.name = name;
      if (baseName != null) {
        b.extend = cb.Reference(baseName);
        b.implements.add(cb.Reference('_$name'));
        b.fields.add(cb.Field((b) {
          b.annotations.add(cb.InvokeExpression.newOf(
            cb.Reference('JsonKey', '$_jsonAnnotationUrl'),
            [],
            {
              'name': cb.literalString('_id'),
              'required': cb.literalTrue,
              'disallowNullValue': cb.literalTrue,
            },
          ));
          b.modifier = cb.FieldModifier.final$;
          b.type = cb.Reference('String');
          b.name = 'id';
        }));
      }
      b.fields.addAll(entries.expand((entry) sync* {
        final String fieldName = entry.key;
        final FieldAnnotationData data = entry.value;
        final String fieldType = data.type;

        final Field baseField = data.annotation;
        if (baseName == null) {
          if (!FieldFilter.belongsToData(baseField)) return;
        } else {
          if (!FieldFilter.belongsToModel(baseField)) return;
        }

        final String? key = baseField.name;
        final Object? defaultValue = baseField.defaultValue;
        final bool required = defaultValue == null && data.required;

        if (baseName == null && baseField is PolymorphicField) {
          final String pivotKey = baseField.pivotName;
          final String? pivotName = (baseField.pivotAs as $Symbol?)?.name;
          yield cb.Field((b) {
            b.annotations.add(cb.InvokeExpression.newOf(
              cb.Reference('JsonKey', '$_jsonAnnotationUrl'),
              [],
              {
                'name': cb.literalString(pivotKey),
                'required': cb.literalTrue,
                'disallowNullValue': cb.literalTrue,
              },
            ));
            b.modifier = cb.FieldModifier.final$;
            b.type = cb.Reference('${fieldType.substring(1)}Type');
            b.name = pivotName ?? 'type';
          });
        }

        yield cb.Field((b) {
          if (baseName != null) {
            b.annotations.add(expressionOf('override'));
          }
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
          b.modifier = cb.FieldModifier.final$;

          final cb.Reference type;
          if (baseName != null) {
            type = cb.Reference(fieldType);
          } else if (baseField is PolymorphicField) {
            type = cb.Reference(fieldType.substring(1));
          } else if (baseField is ModelField) {
            final $Type value = baseField.referTo as $Type;
            type = cb.Reference('${value.name!.substring(1)}Data');
          } else {
            type = cb.Reference(fieldType);
          }
          b.type = type;
          b.name = fieldName;
        });
      }));
      // `fromJson` factory method
      b.constructors.add(cb.Constructor((b) {
        b.factory = true;
        b.name = 'fromJson';
        if (baseName != null) {
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
        b.body = cb.ToCodeExpression(cb.InvokeExpression.newOf(
          cb.Reference('_\$${name}FromJson'),
          [
            baseName == null
                ? expressionOf('json')
                : cb.literalMap({
                    cb.literalSpread(): expressionOf('json'),
                    cb.literalString('_id'): expressionOf('id'),
                  }),
          ],
        ));
      }));
      // Polymorphic constructor
      if (hasPolymorphism) {
        b.constructors.add(cb.Constructor((b) {
          b.factory = true;
          b.name = '_';
          if (baseName != null) {
            b.optionalParameters.add(cb.Parameter((b) {
              b.required = true;
              b.named = true;
              b.type = cb.Reference('String');
              b.name = 'id';
            }));
          }
          b.optionalParameters.addAll(entries.expand((entry) sync* {
            final String fieldName = entry.key;
            final String fieldType = entry.value.type;

            final Field baseField = entry.value.annotation;
            if (baseField is PolymorphicField) {
              yield cb.Parameter((b) {
                b.required = true;
                b.named = true;
                b.type = cb.Reference('${fieldType.substring(1)}Type');
                b.name = 'type';
              });
              yield cb.Parameter((b) {
                b.required = true;
                b.named = true;
                b.type = cb.Reference('Map');
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
            if (baseName != null) {
              b.statements.add(
                cb
                    .declareFinal('data', type: cb.Reference(baseName))
                    .assign(
                      cb.InvokeExpression.newOf(
                        cb.Reference(baseName),
                        [],
                        Map.fromEntries(where(FieldFilter.belongsToData)
                            .entries
                            .expand((entry) sync* {
                          final String fieldName = entry.key;
                          final Field baseField = entry.value.annotation;
                          if (baseField is PolymorphicField) {
                            yield MapEntry('type', expressionOf('type'));
                          }
                          yield MapEntry(
                            fieldName,
                            cb.CodeExpression(cb.Code(fieldName)),
                          );
                        })),
                        [],
                        '_',
                      ),
                    )
                    .statement,
              );
            }
            b.statements.add(
              cb.InvokeExpression.newOf(
                cb.Reference(name),
                [],
                {
                  if (baseName != null) 'id': expressionOf('id'),
                  ...Map.fromEntries(entries.expand((entry) sync* {
                    final String fieldName = entry.key;
                    final String fieldType = entry.value.type;

                    final Field baseField = entry.value.annotation;
                    if (baseName == null &&
                        !FieldFilter.belongsToData(baseField)) {
                      return;
                    }

                    final cb.Expression? rootExpression =
                        baseName == null ? null : expressionOf('data');

                    final cb.Expression fieldExpression;
                    if (rootExpression == null ||
                        entry.value.annotation is ForeignField) {
                      fieldExpression = cb.CodeExpression(cb.Code(fieldName));
                    } else {
                      fieldExpression = rootExpression.property(fieldName);
                    }

                    if (baseField is PolymorphicField) {
                      yield MapEntry(
                        'type',
                        rootExpression == null
                            ? expressionOf('type')
                            : rootExpression.property('type'),
                      );
                      if (baseName == null) {
                        yield MapEntry(
                          fieldName,
                          cb.InvokeExpression.newOf(
                            cb.Reference(fieldType.substring(1)),
                            [
                              expressionOf('type'),
                              cb.CodeExpression(cb.Code(fieldName)),
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
        }));
      }
      // Default constructor
      b.constructors.add(cb.Constructor((b) {
        b.constant = true;
        if (baseName != null) {
          b.optionalParameters.add(cb.Parameter((b) {
            b.required = true;
            b.named = true;
            b.toThis = true;
            b.name = 'id';
          }));
        }
        b.optionalParameters.addAll(entries.expand((entry) sync* {
          final String fieldName = entry.key;
          final Field baseField = entry.value.annotation;
          if (!FieldFilter.belongsToSchema(baseField)) return;
          if (baseName == null && !FieldFilter.belongsToData(baseField)) return;

          if (baseName != null && baseField is PolymorphicField) {
            yield cb.Parameter((b) {
              b.required = true;
              b.named = true;
              b.toSuper = true;
              b.name = 'type';
            });
          }
          yield cb.Parameter((b) {
            b.required = true;
            b.named = true;
            final bool toThis = baseName == null || baseField is ForeignField;
            b.toThis = toThis;
            b.toSuper = !toThis;
            b.name = fieldName;
          });
        }));
        if (baseName == null && hasPolymorphism) {
          b.optionalParameters.add(cb.Parameter((b) {
            b.required = true;
            b.named = true;
            b.toThis = true;
            b.name = 'type';
          }));
        }
      }));
      if (baseName != null) b.methods.addAll(queryGetters);
      b.methods.add(cb.Method((b) {
        if (baseName != null) {
          b.annotations.add(expressionOf('override'));
        }
        b.returns = cb.TypeReference((b) {
          b.symbol = 'Map';
          b.types.add(cb.Reference('String'));
          b.types.add(cb.Reference('Object?'));
        });
        b.name = 'toJson';

        final Map<String, cb.Expression>? queryObject;
        if (baseName == null) {
          queryObject = null;
        } else {
          queryObject = {};
          final Map<String, Map<String, Object>> queries = {};
          for (MapEntry<String, FieldAnnotationData> entry
              in where(FieldFilter.isA<QueryField>).entries) {
            final String? name = (entry.value.annotation as QueryField).name;
            if (name == null) continue;
            final List<String> segments = name.split('/');
            if (segments.length == 1) {
              queryObject[name] = cb.literalString(entry.key);
            } else {
              queries.putIfAbsent(segments[0], () => {})[segments[1]] =
                  entry.key;
            }
          }
          if (queries.isNotEmpty) {
            for (MapEntry<String, Map<String, Object>> entry
                in queries.entries) {
              queryObject[entry.key] = cb.literalMap(entry.value);
            }
          }
        }

        b.lambda = baseName == null;
        final cb.Expression baseExpression = cb.InvokeExpression.newOf(
          cb.Reference('_\$${name}ToJson'),
          [expressionOf('this')],
        );
        if (queryObject == null) {
          b.body = cb.ToCodeExpression(baseExpression);
        } else {
          b.body = cb
              .literalMap({
                cb.literalSpread(): baseExpression
                    .cascade('remove')
                    .call([cb.literalString('_id')]),
                ...queryObject,
              })
              .returned
              .statement;
        }
      }));
    });
  }

  Iterable<cb.Method> get queryGetters sync* {
    for (MapEntry<String, FieldAnnotationData> entry
        in where(FieldFilter.isA<QueryField>).entries) {
      final QueryField field = entry.value.annotation as QueryField;
      if (field.referTo.isEmpty) continue;

      yield cb.Method((b) {
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

              final FieldAnnotationData? referredField = this[symbolName];
              if (referredField == null ||
                  referredField.annotation is QueryField) {
                throw StateError(
                  'field ${field.name}/$symbolName must have a '
                  'symbol referring to a valid field',
                );
              }

              cb.Expression expression = cb.CodeExpression(cb.Code(symbolName));
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

    final Map<String, ClassAnnotationData<Object>> annotations = {
      '_Rectangle': PolymorphicClassAnnotationData(
        annotation: PolymorphicData(name: 'retangulo'),
        tag: '_Shape',
        fields: {
          'width': FieldAnnotationData(
            annotation: Field(name: 'largura'),
            type: 'double',
            required: true,
          ),
          'height': FieldAnnotationData(
            annotation: Field(name: 'altura'),
            type: 'double',
            required: true,
          ),
        },
      ),
      '_Circle': PolymorphicClassAnnotationData(
        annotation: PolymorphicData(name: 'circulo', as: #circular),
        tag: '_Shape',
        fields: {
          'radius': FieldAnnotationData(
            annotation: Field(name: 'raio'),
            type: 'double',
            required: true,
          ),
        },
      ),
      '_Drawing': ModelClassAnnotationData(
        annotation: Model(name: 'desenho', as: #drawings),
        fields: {
          'color': FieldAnnotationData(
            annotation: Field(name: 'cor'),
            type: 'String',
            required: true,
          ),
          'shape': FieldAnnotationData(
            annotation: PolymorphicField(name: 'formato', pivotName: 'tipo'),
            type: '_Shape',
            required: true,
          ),
        },
      ),
    };

    final cb.Spec spec = cb.Library((b) {
      for (MapEntry<String, ClassAnnotationData<Object>> entry
          in annotations.entries) {
        final Object annotation = entry.value.annotation;
        final Args args;
        if (annotation is Model) {
          args = ModelArgs(
            naming: SchemaNaming(entry.key),
            annotation: annotation,
            fields: entry.value.fields,
          );
        } else if (annotation is PolymorphicData) {
          args = PolymorphicModelArgs(
            naming: PolymorphicNaming(entry.key),
            annotation: annotation,
            fields: entry.value.fields,
          );
        } else {
          continue;
        }
        args.accept(b);
      }

      final Map<String, Map<String, PolymorphicClassAnnotationData>> groups =
          annotations
              .filterValues((data) => data is PolymorphicClassAnnotationData)
              .mapValues((entry) => entry.value as PolymorphicClassAnnotationData)
              .entries
              .groupBy((entry) => entry.value.tag)
              .mapValues((entry) => Map.fromEntries(entry.value));

      for (MapEntry<String, Map<String, PolymorphicClassAnnotationData>> entry in groups.entries) {
        final PolymorphicArgs args = PolymorphicArgs(
          naming: PolymorphicNaming(entry.key),
          fields: entry.value,
        );
        args.accept(b);
      }

      b.body.add(cb.Class((b) {
        b.name = 'Dorm';
        b.fields.add(cb.Field((b) {
          b.modifier = cb.FieldModifier.final$;
          b.type = cb.Reference('BaseReference');
          b.name = '_root';
        }));
        b.constructors.add(cb.Constructor((b) {
          b.constant = true;
          b.requiredParameters.add(cb.Parameter((b) {
            b.toThis = true;
            b.name = '_root';
          }));
        }));
        b.methods.addAll(annotations.entries.mapNotNull((entry) {
          final Object annotation = entry.value.annotation;
          if (annotation is! Model) return null;

          final SchemaNaming naming = SchemaNaming(entry.key);
          return cb.Method((b) {
            b.returns = cb.TypeReference((b) {
              b.symbol = 'DatabaseEntity';
              b.types.add(cb.Reference(naming.dataName));
              b.types.add(cb.Reference(naming.modelName));
            });
            b.type = cb.MethodType.getter;
            b.lambda = true;
            b.name = (annotation.as as $Symbol?)?.name ??
                (naming.modelName[0].toLowerCase() +
                    naming.modelName.substring(1));
            b.body = cb.ToCodeExpression(
              cb.InvokeExpression.newOf(
                cb.Reference('DatabaseEntity'),
                [
                  cb.InvokeExpression.constOf(
                    cb.Reference(naming.entityName),
                    [],
                  ),
                ],
                {
                  'reference': expressionOf('_root'),
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
