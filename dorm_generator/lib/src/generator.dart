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
import 'package:meta/meta.dart';
import 'package:source_gen/source_gen.dart';

import 'utils/custom_types.dart';
import 'utils/orm_node.dart';
import 'visitors.dart';

class DormError {
  final String summary;
  final String description;
  final String hint;
  final List<String> exampleCode;

  const DormError({
    required this.summary,
    required this.description,
    required this.hint,
    this.exampleCode = const [],
  });

  @override
  String toString() {
    final StringBuffer buffer = StringBuffer();
    buffer.writeln('============= ERROR =============');
    buffer.writeln(summary);
    buffer.writeln('---------------------------------');
    buffer.writeln(description);
    buffer.writeln('---------------------------------');
    buffer.writeln(hint);
    if (exampleCode.isNotEmpty) {
      buffer.writeln('=========== [EXAMPLE] ===========');
      for (String exampleCodeLine in exampleCode) {
        buffer.write('   ');
        buffer.writeln(exampleCodeLine);
      }
    }
    buffer.writeln('=================================');
    return '$buffer';
  }
}

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

  String get repositoryName =>
      (node.annotation.as as $Symbol?)?.name ?? _defaultRepositoryName;

  String get tableName => node.annotation.name ?? modelName.decapitalize();

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

abstract class Args<Naming> {
  final ParsingContext context;
  final Naming naming;

  const Args({
    required this.context,
    required this.naming,
  });

  void accept(cb.LibraryBuilder b);
}

/// Arguments of code generation.
abstract class AnnotatedArgs<DormAnnotation, Naming> extends Args<Naming> {
  final ClassOrmNode<DormAnnotation> node;

  const AnnotatedArgs({
    required super.context,
    required super.naming,
    required this.node,
  });
}

class DataArgs extends AnnotatedArgs<Data, DataNaming> {
  const DataArgs({
    required super.context,
    required super.node,
    required super.naming,
  });

  cb.Spec get _class {
    return node.baseClassOf(
      context,
      name: naming.modelName,
      shouldImplementAnnotatedClass: true,
    );
  }

  @override
  void accept(cb.LibraryBuilder b) {
    b.body.add(_class);
  }
}

class ModelArgs extends AnnotatedArgs<Model, ModelNaming> {
  const ModelArgs({
    required super.context,
    required super.node,
    required super.naming,
  });

  cb.Spec get _dummyClass {
    final String className = naming.dummyName;
    return cb.Class((b) {
      b.name = className;
      b.implements.add(cb.Reference(naming.schemaName));
      b.fields.addAll(
          node.fields.where(FieldFilter.belongsToSchema).entries.map((entry) {
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
            node.fields.where(FieldFilter.belongsToSchema).map((name, field) {
              final cb.Expression expression = expressionOf(
                  field.annotation is ForeignField ? 'dependency' : 'data');
              return MapEntry(name, expression.property(name));
            }),
          ),
        );
      }));
      b.constructors.add(cb.Constructor((b) {
        b.constant = true;
        b.optionalParameters.addAll(
            node.fields.where(FieldFilter.belongsToSchema).keys.map((name) {
          return cb.Parameter((b) {
            b.required = true;
            b.named = true;
            b.toThis = true;
            b.name = name;
          });
        }));
      }));
      b.methods.addAll(node.queryGetters);
    });
  }

  cb.Spec get _dataClass {
    return node.baseClassOf(
      context,
      name: naming.dataName,
    );
  }

  cb.Spec get _modelClass {
    return node.baseClassOf(
      context,
      name: naming.modelName,
      baseName: naming.dataName,
      shouldImplementAnnotatedClass: true,
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
      b.fields.addAll(
          node.fields.where(FieldFilter.belongsToModel).entries.map((entry) {
        return cb.Field((b) {
          b.modifier = cb.FieldModifier.final$;
          b.type = cb.Reference(entry.value.type);
          b.name = entry.key;
        });
      }));
      if (node.fields.where(FieldFilter.belongsToModel).isEmpty) {
        b.constructors.add(cb.Constructor((b) {
          b.constant = true;
          b.initializers.add(cb.ToCodeExpression(
            expressionOf('super').property('strong').call([]),
          ));
        }));
      } else {
        b.constructors.add(cb.Constructor((b) {
          b.constant = false;
          b.optionalParameters.addAll(
              node.fields.where(FieldFilter.belongsToModel).keys.map((name) {
            return cb.Parameter((b) {
              b.required = true;
              b.named = true;
              b.toThis = true;
              b.name = name;
            });
          }));
          b.initializers.add(cb.ToCodeExpression(
            expressionOf('super').property('weak').call([
              cb.literalList(node.fields
                  .where(FieldFilter.belongsToModel)
                  .entries
                  .map((entry) {
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
        b.assignment = cb.ToCodeExpression(cb.literalString(naming.tableName));
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
            'id': switch (node.annotation.primaryKeyGenerator) {
              null => expressionOf('id'),
              String Function(Object?, String) generator =>
                cb.InvokeExpression.newOf(cb.Reference(generator(null, '')), [
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
                  expressionOf('id'),
                ]),
              Function f => throw DormError(
                  summary: 'Invalid primary key generator function signature.',
                  description: 'The class ${naming.schemaName} annotated with '
                      '@Model() references a function with an incorrect signature: $f. '
                      'The primary key generator function must accept exactly '
                      'two parameters: the abstract class being annotated '
                      '(${naming.schemaName}) and a String with a fresh ID, and it '
                      'should return a String representing the generated primary '
                      'key.',
                  hint: 'Update the function signature to match the required '
                      'format.',
                  exampleCode: [
                    'static String _yourFunction(${naming.schemaName} model, String id) {',
                    '  // TODO Implementation here',
                    '}',
                  ],
                ),
            },
            ...Map.fromEntries(node.fields
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
        b.lambda = true;

        cb.Expression baseExpression = expressionOf('model');
        if (node.fields.where(FieldFilter.belongsToData).isNotEmpty) {
          baseExpression = baseExpression
              .property('updateWith')
              .call([expressionOf('data')]);
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
        b.name = 'updateWith';
        b.requiredParameters.add(cb.Parameter((b) {
          b.type = cb.Reference(naming.dataName);
          b.name = 'data';
        }));
        b.body = cb.InvokeExpression.newOf(
          cb.Reference(naming.modelName),
          [],
          {
            'id': expressionOf('id'),
            ...Map.fromEntries(node.fields
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
    if (node.annotation.primaryKeyGenerator != null) {
      b.body.add(_dummyClass);
    }
    b.body.add(_dataClass);
    b.body.add(_modelClass);
    b.body.add(_dependencyClass);
    b.body.add(_entityClass);
    if (node.fields.where(FieldFilter.belongsToData).isNotEmpty) {
      b.body.add(_extension);
    }
  }
}

class PolymorphicArgs extends Args<TagNaming> {
  final PolymorphicGroupOrmNode node;

  const PolymorphicArgs({
    required super.context,
    required super.naming,
    required this.node,
  });

  cb.Spec get _enumClass {
    return cb.Enum((b) {
      b.name = naming.enumName;
      b.values.addAll(node.children.entries.map((entry) {
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
      b.abstract = !node.isSealed;
      b.sealed = node.isSealed;
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
              in node.children.entries) {
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
    extends AnnotatedArgs<PolymorphicData, PolymorphicDataNaming> {
  final String parentName;

  const PolymorphicModelArgs({
    required super.context,
    required super.naming,
    required super.node,
    required this.parentName,
  });

  cb.Spec get _class {
    return node.baseClassOf(
      context,
      name: naming.modelName,
      baseName: TagNaming(parentName).modelName,
      shouldImplementAnnotatedClass: true,
      polymorphicName: naming.enumFieldName,
    );
  }

  @override
  void accept(cb.LibraryBuilder b) {
    b.body.add(_class);
  }
}

/// Base of code generation.
extension _BaseWriting on ClassOrmNode<Object> {
  cb.Spec baseClassOf(
    ParsingContext context, {
    required String name,
    String? baseName,
    String? polymorphicName,
    bool shouldImplementAnnotatedClass = false,
  }) {
    final bool base = polymorphicName != null || baseName == null;
    final bool serializable =
        !base || fields.where(FieldFilter.belongsToData).isNotEmpty;

    final bool hasPolymorphism =
        fields.values.any((field) => field.annotation is PolymorphicField);

    return cb.Class((b) {
      if (serializable) {
        b.annotations.add(cb.InvokeExpression.newOf(
          cb.Reference('JsonSerializable', '$_jsonAnnotationUrl'),
          [],
          {
            'anyMap': cb.literalTrue,
            'explicitToJson': cb.literalTrue,
            if (hasPolymorphism) 'constructor': cb.literalString('_'),
          },
        ));
      }
      if (!base ||
          polymorphicName != null ||
          fields.where(FieldFilter.belongsToData).isNotEmpty) {
        b.annotations.add(cb.InvokeExpression.newOf(
          cb.Reference('CopyWith', '$_copyWithAnnotationUrl'),
          [],
          {
            'skipFields': cb.literalTrue,
          },
        ));
      }
      b.name = name;
      if (baseName != null) {
        if (polymorphicName == null) {
          b.extend = cb.Reference(baseName);
        } else {
          b.implements.add(cb.Reference(baseName));
        }
      }
      if (shouldImplementAnnotatedClass) {
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
      b.fields.addAll(fields.entries.expand((entry) sync* {
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
        final ConstantReader? defaultValueReader =
            baseField.defaultValue as ConstantReader?;
        final bool required =
            (defaultValueReader == null || defaultValueReader.isNull) &&
                data.required;

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
          if (polymorphicName != null || shouldImplementAnnotatedClass) {
            b.annotations.add(expressionOf('override'));
          }
          final cb.Expression? defaultValueExpression;
          if (defaultValueReader == null || defaultValueReader.isNull) {
            defaultValueExpression = null;
          } else if (defaultValueReader.isLiteral) {
            defaultValueExpression =
                cb.literal(defaultValueReader.literalValue);
          } else {
            final Revivable revivable = defaultValueReader.revive();
            if (revivable.accessor.isNotEmpty) {
              defaultValueExpression = expressionOf(revivable.accessor);
            } else {
              defaultValueExpression = expressionOf('$revivable');
            }
          }
          b.annotations.add(cb.InvokeExpression.newOf(
            cb.Reference('JsonKey', '$_jsonAnnotationUrl'),
            [],
            {
              if (key != null) 'name': cb.literalString(key),
              if (required) 'required': cb.literalTrue,
              if (required) 'disallowNullValue': cb.literalTrue,
              if (defaultValueExpression != null)
                'defaultValue': defaultValueExpression,
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
            final ClassOrmNode<Object>? node =
                context.monomorphicNodes[value.name];
            final String name;
            if (node is DataOrmNode) {
              name = value.name!.substring(1);
            } else {
              name = '${value.name!.substring(1)}Data';
            }
            if (fieldType.startsWith('List<')) {
              type = cb.TypeReference((b) {
                b.symbol = 'List';
                b.types.add(cb.Reference(name));
              });
            } else if (fieldType.endsWith('?')) {
              type = cb.Reference('$name?');
            } else {
              type = cb.Reference(name);
            }
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
      if (serializable) {
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
      }
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
          b.optionalParameters.addAll(fields
              .where(baseName == null
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
            } else if (baseField is ModelField) {
              final $Type value = baseField.referTo as $Type;
              final ClassOrmNode<Object>? node =
                  context.monomorphicNodes[value.name];
              final String name;
              if (node is DataOrmNode) {
                name = value.name!.substring(1);
              } else {
                name = '${value.name!.substring(1)}Data';
              }
              final cb.Reference type;
              if (fieldType.startsWith('List<')) {
                type = cb.TypeReference((b) {
                  b.symbol = 'List';
                  b.types.add(cb.Reference(name));
                });
              } else if (fieldType.endsWith('?')) {
                type = cb.Reference('$name?');
              } else {
                type = cb.Reference(name);
              }
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
            if (baseName != null) {
              b.statements.add(
                cb
                    .declareFinal('data', type: cb.Reference(baseName))
                    .assign(
                      cb.InvokeExpression.newOf(
                        cb.Reference(baseName),
                        [],
                        Map.fromEntries(fields
                            .where(FieldFilter.belongsToData)
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
                  ...Map.fromEntries(fields
                      .where(FieldFilter.belongsToSchema)
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
        b.optionalParameters.addAll(fields.entries.expand((entry) sync* {
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
        b.lambda = lambda;

        final cb.Code body;
        if (serializable) {
          final Map<String, cb.Expression>? queryObject;
          if (lambda) {
            queryObject = null;
          } else {
            queryObject = {};
            final Map<String, Map<String, Object>> queries = {};
            for (MapEntry<String, FieldOrmNode> entry
                in fields.where(FieldFilter.isA<QueryField>).entries) {
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
      }));
    });
  }

  Iterable<cb.Method> get queryGetters sync* {
    for (MapEntry<String, FieldOrmNode> entry
        in fields.where(FieldFilter.isA<QueryField>).entries) {
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

              final FieldOrmNode? referredField = fields[symbolName] ??
                  fields
                      .where(FieldFilter.isA<PolymorphicField>)
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
            .call([cb.literalString(field.joinBy, raw: true)]));
      });
    }
  }
}

/// Code generator.
class OrmGenerator extends Generator {
  const OrmGenerator();

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

    final ParsingContext context = parseLibrary(library);
    return const OrmCodeProvider().provide(context);
  }
}

@visibleForTesting
class OrmCodeProvider {
  const OrmCodeProvider();

  String provide(ParsingContext context) {
    final cb.Spec spec = cb.Library((b) {
      context.monomorphicNodes.entries.mapNotNull<Args<Object>>((entry) {
        final String name = entry.key;
        final MonomorphicOrmNode<Object> node = entry.value;
        switch (node) {
          case DataOrmNode():
            return DataArgs(
              context: context,
              node: node,
              naming: DataNaming(name: name, node: node),
            );
          case ModelOrmNode():
            return ModelArgs(
              context: context,
              node: node,
              naming: ModelNaming(name: name, node: node),
            );
        }
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
      for (MapEntry<String, PolymorphicGroupOrmNode> entry
          in context.polymorphicGroups.entries) {
        final PolymorphicArgs args = PolymorphicArgs(
          context: context,
          node: entry.value,
          naming: TagNaming(entry.key),
        );
        args.accept(b);
      }

      context.polymorphicGroups.entries
          .expand((contextEntry) => contextEntry.value.children.entries
              .map((entry) => (contextEntry.key, entry.key, entry.value)))
          .mapNotNull((t) {
        final (String parentName, String name, PolymorphicDataOrmNode node) = t;
        return PolymorphicModelArgs(
          context: context,
          parentName: parentName,
          node: node,
          naming: PolymorphicDataNaming(name: name, node: node),
        );
      }).forEach((arg) => arg.accept(b));

      b.body.add(cb.Class((b) {
        b.name = 'Dorm';
        b.fields.add(cb.Field((b) {
          b.modifier = cb.FieldModifier.final$;
          b.type = cb.TypeReference((b) {
            b.symbol = 'BaseEngine';
            b.url = '$_dormUrl';
            b.types.add(cb.Reference('Query'));
          });
          b.name = '_engine';
        }));
        b.constructors.add(cb.Constructor((b) {
          b.constant = true;
          b.requiredParameters.add(cb.Parameter((b) {
            b.toThis = true;
            b.name = '_engine';
          }));
        }));
        b.methods.addAll(context.monomorphicNodes.entries.mapNotNull((entry) {
          final ClassOrmNode<Object> node = entry.value;
          if (node is! ModelOrmNode) return null;

          final ModelNaming naming = ModelNaming(name: entry.key, node: node);
          return cb.Method((b) {
            b.returns = cb.TypeReference((b) {
              b.symbol = 'DatabaseEntity';
              b.url = '$_dormUrl';
              b.types.add(cb.Reference(naming.dataName));
              b.types.add(cb.Reference(naming.modelName));
              b.types.add(cb.Reference('Query'));
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
