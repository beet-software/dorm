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

  TagNaming get tag => TagNaming(node.tag);
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
abstract class Args<Annotation, Field, Naming> {
  final Map<String, FieldedOrmNode<Object>> nodes;
  final Annotation annotation;
  final Map<String, Field> fields;
  final Naming naming;

  const Args({
    required this.nodes,
    required this.annotation,
    required this.fields,
    required this.naming,
  });

  void accept(cb.LibraryBuilder b);
}

class DataArgs extends Args<Data, FieldOrmNode, DataNaming> {
  const DataArgs({
    required super.nodes,
    required super.annotation,
    required super.fields,
    required super.naming,
  });

  cb.Spec get _class {
    return fields.baseClassOf(nodes, name: naming.modelName);
  }

  @override
  void accept(cb.LibraryBuilder b) {
    b.body.add(_class);
  }
}

class ModelArgs extends Args<Model, FieldOrmNode, ModelNaming> {
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
            expressionOf(className),
            [],
            fields.where(FieldFilter.belongsToSchema).map((name, field) {
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
    return fields.baseClassOf(
      nodes,
      name: naming.dataName,
    );
  }

  cb.Spec get _modelClass {
    return fields.baseClassOf(
      nodes,
      name: naming.modelName,
      baseName: naming.dataName,
    );
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

class PolymorphicArgs extends Args<void, PolymorphicDataOrmNode, TagNaming> {
  const PolymorphicArgs({
    required super.nodes,
    required super.fields,
    required super.naming,
  }) : super(annotation: null);

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

class PolymorphicModelArgs
    extends Args<void, FieldOrmNode, PolymorphicDataNaming> {
  const PolymorphicModelArgs({
    required super.nodes,
    required super.fields,
    required super.naming,
  }) : super(annotation: null);

  cb.Spec get _class {
    return fields.baseClassOf(
      nodes,
      name: naming.modelName,
      baseName: naming.tag.modelName,
      polymorphicName: naming.enumFieldName,
    );
  }

  @override
  void accept(cb.LibraryBuilder b) {
    b.body.add(_class);
  }
}

/// Base of code generation.
extension _BaseWriting on Map<String, FieldOrmNode> {
  cb.Spec baseClassOf(
    Map<String, FieldedOrmNode<Object>> nodes, {
    required String name,
    String? baseName,
    String? polymorphicName,
  }) {
    final bool base = polymorphicName != null || baseName == null;

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
        if (polymorphicName == null) {
          b.extend = cb.Reference(baseName);
        } else {
          b.implements.add(cb.Reference(baseName));
        }
        b.implements.add(cb.Reference('_$name'));
      }
      if (!base) {
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
        final FieldOrmNode data = entry.value;
        final String fieldType = data.type;

        final Field baseField = data.annotation;
        if (base) {
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
          if (polymorphicName != null || baseName != null) {
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
          if (!base) {
            type = cb.Reference(fieldType);
          } else if (baseField is PolymorphicField) {
            type = cb.Reference(fieldType.substring(1));
          } else if (baseField is ModelField) {
            final $Type value = baseField.referTo as $Type;
            final ClassOrmNode<Object>? node = nodes[value.name]?.annotation;
            final String name;
            if (node is DataOrmNode) {
              name = value.name!.substring(1);
            } else {
              name = '${value.name!.substring(1)}Data';
            }
            type = cb.Reference(name);
          } else {
            type = cb.Reference(fieldType);
          }
          b.type = type;
          b.name = fieldName;
        });
      }));
      if (polymorphicName != null) {
        b.fields.add(cb.Field((b) {
          b.annotations.add(expressionOf('override'));
          b.modifier = cb.FieldModifier.final$;
          b.type = cb.Reference('${baseName}Type');
          b.name = 'type';
          b.assignment =
              expressionOf('${baseName}Type').property(polymorphicName).code;
        }));
      }
      // `fromJson` factory method
      b.constructors.add(cb.Constructor((b) {
        b.factory = true;
        b.name = 'fromJson';
        if (!base) {
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
        b.body = cb.ToCodeExpression(expressionOf('_\$${name}FromJson').call([
          base
              ? expressionOf('json')
              : cb.literalMap({
                  cb.literalSpread(): expressionOf('json'),
                  cb.literalString('_id'): expressionOf('id'),
                }),
        ]));
      }));
      // Polymorphic constructor
      if (hasPolymorphism) {
        b.constructors.add(cb.Constructor((b) {
          b.factory = true;
          b.name = '_';
          if (!base) {
            b.optionalParameters.add(cb.Parameter((b) {
              b.required = true;
              b.named = true;
              b.type = cb.Reference('String');
              b.name = 'id';
            }));
          }
          b.optionalParameters.addAll(where(baseName == null
                  ? FieldFilter.belongsToData
                  : FieldFilter.belongsToSchema)
              .entries
              .expand((entry) sync* {
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
                          yield MapEntry(fieldName, expressionOf(fieldName));
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
                  if (!base) 'id': expressionOf('id'),
                  ...Map.fromEntries(where(FieldFilter.belongsToSchema)
                      .entries
                      .expand((entry) sync* {
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
                      fieldExpression = expressionOf(fieldName);
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
                            [expressionOf('type'), expressionOf(fieldName)],
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
        if (!base) {
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
            final bool toThis = base || baseField is ForeignField;
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

        final bool lambda = base;

        final Map<String, cb.Expression>? queryObject;
        if (lambda) {
          queryObject = null;
        } else {
          queryObject = {};
          final Map<String, Map<String, Object>> queries = {};
          for (MapEntry<String, FieldOrmNode> entry
              in where(FieldFilter.isA<QueryField>).entries) {
            final String? name = (entry.value.annotation as QueryField).name;
            if (name == null) continue;
            final List<String> segments = name.split('/');
            final cb.Expression child = expressionOf(entry.key);
            if (segments.length == 1) {
              queryObject[name] = child;
            } else {
              queries.putIfAbsent(segments[0], () => {})[segments[1]] = child;
            }
          }
          if (queries.isNotEmpty) {
            for (MapEntry<String, Map<String, Object>> entry
                in queries.entries) {
              queryObject[entry.key] = cb.literalMap(entry.value);
            }
          }
        }

        b.lambda = lambda;
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
    for (MapEntry<String, FieldOrmNode> entry
        in where(FieldFilter.isA<QueryField>).entries) {
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
                  where(FieldFilter.isA<PolymorphicField>)
                      .values
                      .firstOrNullWhere((node) {
                    final PolymorphicField field =
                        node.annotation as PolymorphicField;
                    final $Symbol? pivotSymbol = field.pivotAs as $Symbol?;
                    if (pivotSymbol == null) return false;
                    return (pivotSymbol.name ?? 'type') == symbolName;
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

      final Map<String, Map<String, PolymorphicDataOrmNode>> groups = nodes
          .filterValues((data) => data.annotation is PolymorphicDataOrmNode)
          .mapValues(
              (entry) => entry.value.annotation as PolymorphicDataOrmNode)
          .entries
          .groupBy((entry) => entry.value.tag)
          .mapValues((entry) => Map.fromEntries(entry.value));

      for (MapEntry<String, Map<String, PolymorphicDataOrmNode>> entry
          in groups.entries) {
        final PolymorphicArgs args = PolymorphicArgs(
          nodes: nodes,
          naming: TagNaming(entry.key),
          fields: entry.value,
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
          b.type = cb.Reference('BaseReference', '$_dormUrl');
          b.name = '_root';
        }));
        b.constructors.add(cb.Constructor((b) {
          b.constant = true;
          b.requiredParameters.add(cb.Parameter((b) {
            b.toThis = true;
            b.name = '_root';
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
