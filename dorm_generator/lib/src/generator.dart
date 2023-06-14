import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart' as cb;
import 'package:dart_style/dart_style.dart';
import 'package:dorm_annotations/dorm_annotations.dart';
import 'package:source_gen/source_gen.dart';

import 'utils/custom_types.dart';
import 'visitors.dart';

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

class _PolymorphicNaming {
  // _Schema
  final String schemaName;

  const _PolymorphicNaming(this.schemaName);

  String get modelName => schemaName.substring(1);

  String get enumName => '${modelName}Type';
}

class _SchemaWriter {
  final $Model model;
  final SchemaNaming naming;
  final Map<String, Map<String, $PolymorphicData>> polymorphicTree;

  const _SchemaWriter({
    required this.model,
    required this.naming,
    required this.polymorphicTree,
  });

  cb.Expression _uidTypeExpressionOf(UidType value) {
    return value.when(
      caseSimple: () => cb.CodeExpression(cb.Code('id')),
      caseComposite: () => cb.CodeExpression(cb.Code('dependency'))
          .property('key')
          .call([cb.CodeExpression(cb.Code('id'))]),
      caseSameAs: (type) {
        type as $Type;
        for (MapEntry<String, $ModelField> entry
            in model.foreignFields.entries) {
          final $Type currentType =
              (entry.value.field as ForeignField).referTo as $Type;
          if (currentType.name != type.name) continue;
          return cb.CodeExpression(cb.Code('dependency')).property(entry.key);
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
              cb.CodeExpression(cb.Code('dependency')),
              cb.CodeExpression(cb.Code('data')),
            ],
            {},
            [],
            'fromData',
          ),
        ]).property('when').call([], {
          'caseSimple': cb.CodeExpression(cb.Code('() => id')),
          'caseComposite':
              cb.CodeExpression(cb.Code('() => dependency.key(id)')),
          'caseValue': cb.CodeExpression(cb.Code('(id) => id')),
        });
      },
    );
  }

  cb.Spec get _dummyClass {
    final String className = naming.dummyName;
    return cb.Class((b) {
      b.name = className;
      b.implements.add(cb.Reference(naming.schemaName));
      b.fields.addAll(model.ownFields.entries.map((entry) {
        return cb.Field((b) {
          b.annotations.add(cb.CodeExpression(cb.Code('override')));
          b.modifier = cb.FieldModifier.final$;
          b.type = cb.Reference(entry.value.data.type);
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
        b.body = cb.ToCodeExpression(cb.InvokeExpression.newOf(
          cb.CodeExpression(cb.Code(className)),
          [],
          model.ownFields.map((name, field) {
            final cb.Expression expression = cb.CodeExpression(
              cb.Code(field.field is ForeignField ? 'dependency' : 'data'),
            );
            return MapEntry(name, expression.property(name));
          }),
        ));
      }));
      b.constructors.add(cb.Constructor((b) {
        b.constant = true;
        b.optionalParameters.addAll(model.ownFields.keys.map((name) {
          return cb.Parameter((b) {
            b.required = true;
            b.named = true;
            b.toThis = true;
            b.name = name;
          });
        }));
      }));
      b.methods.addAll(_queryGetters);
    });
  }

  cb.Spec get _dataClass {
    final Set<String> polymorphicKeys = polymorphicTree.keys.toSet();
    final Set<String> modelFieldTypes =
        model.fields.values.map((field) => field.data.type).toSet();
    final bool hasPolymorphism =
        polymorphicKeys.intersection(modelFieldTypes).isNotEmpty;

    return cb.Class((b) {
      b.annotations.add(cb.InvokeExpression.newOf(
        cb.Reference('JsonSerializable'),
        [],
        {
          'anyMap': cb.literalTrue,
          'explicitToJson': cb.literalTrue,
          if (hasPolymorphism) 'constructor': cb.literalString('_'),
        },
      ));
      b.name = naming.dataName;
      b.fields.addAll(model.dataFields.entries.expand((entry) sync* {
        final String fieldName = entry.key;
        final String fieldType = entry.value.data.type;
        if (polymorphicKeys.contains(fieldType)) {
          final String typeKey =
              (entry.value.field as PolymorphicField).pivotName;
          yield cb.Field((b) {
            b.annotations.add(cb.InvokeExpression.newOf(
              cb.Reference('JsonKey'),
              [],
              {
                'name': cb.literalString(typeKey),
                'required': cb.literalTrue,
                'disallowNullValue': cb.literalTrue,
              },
            ));
            b.modifier = cb.FieldModifier.final$;
            b.type = cb.Reference('${fieldType.substring(1)}Type');
            b.name = 'type';
          });
        }
        final bool isModelField = entry.value.field is ModelField;
        final String? key = entry.value.field.name;
        final Object? defaultValue = entry.value.field.defaultValue;
        final bool required =
            defaultValue == null && !entry.value.data.type.endsWith('?');

        yield cb.Field((b) {
          b.annotations.add(cb.InvokeExpression.newOf(
            cb.Reference('JsonKey'),
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
          if (polymorphicKeys.contains(fieldType)) {
            type = cb.Reference(fieldType.substring(1));
          } else if (isModelField) {
            final $Type value =
                ((entry.value.field as ModelField).referTo as $Type);
            type = cb.Reference('${value.name!.substring(1)}Data');
          } else {
            type = cb.Reference(fieldType);
          }
          b.type = type;

          b.name = fieldName;
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
        b.body = cb.ToCodeExpression(cb.InvokeExpression.newOf(
          cb.Reference('_\$${naming.dataName}FromJson'),
          [cb.CodeExpression(cb.Code('json'))],
        ));
      }));
      if (hasPolymorphism) {
        b.constructors.add(cb.Constructor((b) {
          b.factory = true;
          b.name = '_';
          b.optionalParameters
              .addAll(model.dataFields.entries.expand((entry) sync* {
            final String fieldName = entry.key;
            final String fieldType = entry.value.data.type;
            final bool isPolymorphicField = polymorphicKeys.contains(fieldType);

            if (isPolymorphicField) {
              yield cb.Parameter((b) {
                b.required = true;
                b.named = true;
                b.type = cb.Reference('${fieldType.substring(1)}Type');
                b.name = 'type';
              });
            }
            yield cb.Parameter((b) {
              b.required = true;
              b.named = true;
              b.type = cb.Reference(isPolymorphicField ? 'Map' : fieldType);
              b.name = fieldName;
            });
          }));
          b.lambda = false;
          b.body = cb.InvokeExpression.newOf(
            cb.Reference(naming.dataName),
            [],
            Map.fromEntries(model.dataFields.entries.expand((entry) sync* {
              final String fieldName = entry.key;
              final String fieldType = entry.value.data.type;

              if (polymorphicKeys.contains(fieldType)) {
                yield MapEntry(
                  'type',
                  cb.CodeExpression(cb.Code('type')),
                );
                yield MapEntry(
                  fieldName,
                  cb.InvokeExpression.newOf(
                    cb.Reference(fieldType.substring(1)),
                    ['type', fieldName]
                        .map((code) => cb.CodeExpression(cb.Code(code)))
                        .toList(),
                    {},
                    [],
                    'fromType',
                  ),
                );
              } else {
                yield MapEntry(
                  fieldName,
                  cb.CodeExpression(cb.Code(fieldName)),
                );
              }
            })),
          ).returned.statement;
        }));
      }
      b.constructors.add(cb.Constructor((b) {
        b.constant = true;
        b.optionalParameters.addAll(model.dataFields.keys.map((name) {
          return cb.Parameter((b) {
            b.required = true;
            b.named = true;
            b.toThis = true;
            b.name = name;
          });
        }));
        if (hasPolymorphism) {
          b.optionalParameters.add(cb.Parameter((b) {
            b.required = true;
            b.named = true;
            b.toThis = true;
            b.name = 'type';
          }));
        }
      }));
      b.methods.add(cb.Method((b) {
        b.returns = cb.TypeReference((b) {
          b.symbol = 'Map';
          b.types.add(cb.Reference('String'));
          b.types.add(cb.Reference('Object?'));
        });
        b.name = 'toJson';
        b.lambda = true;
        b.body = cb.ToCodeExpression(cb.InvokeExpression.newOf(
          cb.Reference('_\$${naming.dataName}ToJson'),
          [cb.CodeExpression(cb.Code('this'))],
        ));
      }));
    });
  }

  cb.Spec get _modelClass {
    final Set<String> polymorphicKeys = polymorphicTree.keys.toSet();
    final Set<String> modelFieldTypes =
        model.fields.values.map((field) => field.data.type).toSet();
    final bool hasPolymorphism =
        polymorphicKeys.intersection(modelFieldTypes).isNotEmpty;

    return cb.Class((b) {
      b.annotations.add(cb.InvokeExpression.newOf(
        cb.Reference('JsonSerializable'),
        [],
        {
          'anyMap': cb.literalTrue,
          'explicitToJson': cb.literalTrue,
          if (hasPolymorphism) 'constructor': cb.literalString('_'),
        },
      ));
      b.name = naming.modelName;
      b.extend = cb.Reference(naming.dataName);
      b.implements.add(cb.Reference(naming.schemaName));
      b.fields.add(cb.Field((b) {
        b.annotations.add(cb.InvokeExpression.newOf(
          cb.Reference('JsonKey'),
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
      b.fields.addAll(model.foreignFields.entries.map((entry) {
        final String? key = entry.value.field.name;
        final String fieldName = entry.key;
        final String fieldType = entry.value.data.type;
        final bool required = !fieldType.endsWith('?');

        return cb.Field((b) {
          b.annotations.add(cb.CodeExpression(cb.Code('override')));
          b.annotations.add(cb.InvokeExpression.newOf(
            cb.Reference('JsonKey'),
            [],
            {
              if (key != null) 'name': cb.literalString(key),
              if (required) 'required': cb.literalTrue,
              if (required) 'disallowNullValue': cb.literalTrue,
            },
          ));
          b.modifier = cb.FieldModifier.final$;
          b.type = cb.Reference(fieldType);
          b.name = fieldName;
        });
      }));
      b.constructors.add(cb.Constructor((b) {
        b.factory = true;
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
          cb.Reference('_\$${naming.modelName}FromJson'),
          [
            cb.literalMap({
              cb.literalSpread(): cb.CodeExpression(cb.Code('json')),
              cb.literalString('_id'): cb.CodeExpression(cb.Code('id')),
            }),
          ],
        ));
      }));
      if (hasPolymorphism) {
        b.constructors.add(cb.Constructor((b) {
          b.factory = true;
          b.name = '_';
          b.optionalParameters.add(cb.Parameter((b) {
            b.required = true;
            b.named = true;
            b.type = cb.Reference('String');
            b.name = 'id';
          }));
          b.optionalParameters
              .addAll(model.fields.entries.expand((entry) sync* {
            final String fieldName = entry.key;
            final String fieldType = entry.value.data.type;
            if (polymorphicKeys.contains(fieldType)) {
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
          b.body = cb.Block((b) {
            b.statements.add(
              cb
                  .declareFinal('data', type: cb.Reference(naming.dataName))
                  .assign(
                    cb.InvokeExpression.newOf(
                      cb.Reference(naming.dataName),
                      [],
                      Map.fromEntries(
                          model.dataFields.entries.expand((entry) sync* {
                        final String fieldName = entry.key;
                        final String fieldType = entry.value.data.type;
                        if (polymorphicKeys.contains(fieldType)) {
                          yield MapEntry(
                              'type', cb.CodeExpression(cb.Code('type')));
                        }
                        yield MapEntry(
                            fieldName, cb.CodeExpression(cb.Code(fieldName)));
                      })),
                      [],
                      '_',
                    ),
                  )
                  .statement,
            );
            b.statements.add(cb.InvokeExpression.newOf(
              cb.Reference(naming.modelName),
              [],
              {
                'id': cb.CodeExpression(cb.Code('id')),
                ...Map.fromEntries(model.fields.entries.expand((entry) sync* {
                  final String fieldName = entry.key;
                  final String fieldType = entry.value.data.type;

                  final cb.Expression rootExpression =
                      cb.CodeExpression(cb.Code('data'));
                  final cb.Expression expression;
                  if (entry.value.field is ForeignField) {
                    expression = cb.CodeExpression(cb.Code(fieldName));
                  } else {
                    expression = rootExpression.property(fieldName);
                  }
                  if (polymorphicKeys.contains(fieldType)) {
                    yield MapEntry('type', rootExpression.property('type'));
                  }
                  yield MapEntry(fieldName, expression);
                }))
              },
            ).returned.statement);
          });
        }));
      }
      b.constructors.add(cb.Constructor((b) {
        b.constant = true;
        b.optionalParameters.add(cb.Parameter((b) {
          b.required = true;
          b.named = true;
          b.toThis = true;
          b.name = 'id';
        }));
        b.optionalParameters
            .addAll(model.ownFields.entries.expand((entry) sync* {
          final String fieldName = entry.key;
          final String fieldType = entry.value.data.type;
          final bool isForeignField = entry.value.field is ForeignField;
          if (polymorphicKeys.contains(fieldType)) {
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
            b.toThis = isForeignField;
            b.toSuper = !isForeignField;
            b.name = fieldName;
          });
        }));
      }));
      b.methods.addAll(_queryGetters);
      b.methods.add(cb.Method((b) {
        b.annotations.add(cb.CodeExpression(cb.Code('override')));
        b.returns = cb.Reference('Map<String, Object?>');
        b.name = 'toJson';
        b.lambda = false;

        final Map<String, cb.Expression> queryObject = {};
        final Map<String, Map<String, Object>> queries = {};
        for (MapEntry<String, $ModelField> entry in model.queryFields.entries) {
          final String? name = (entry.value.field as QueryField).name;
          if (name == null) continue;

          final List<String> segments = name.split('/');
          if (segments.length == 1) {
            queryObject[name] = cb.literalString(entry.key);
          } else {
            queries.putIfAbsent(segments[0], () => {})[segments[1]] = entry.key;
          }
        }
        if (queries.isNotEmpty) {
          for (MapEntry<String, Map<String, Object>> entry in queries.entries) {
            queryObject[entry.key] = cb.literalMap(entry.value);
          }
        }

        b.body = cb
            .literalMap({
              cb.literalSpread(): cb.InvokeExpression.newOf(
                cb.Reference('_\$${naming.modelName}ToJson'),
                [cb.CodeExpression(cb.Code('this'))],
              ).cascade('remove').call([cb.literalString('_id')]),
              ...queryObject,
            })
            .returned
            .statement;
      }));
    });
  }

  Iterable<cb.Method> get _queryGetters sync* {
    for (MapEntry<String, $ModelField> entry in model.queryFields.entries) {
      final QueryField field = entry.value.field as QueryField;
      if (field.referTo.isEmpty) continue;

      yield cb.Method((b) {
        b.returns = cb.Reference(entry.value.data.type);
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

              final $ModelField? referredField = model.ownFields[symbolName];
              if (referredField == null) {
                throw StateError(
                  'field ${field.name}/$symbolName must have a '
                  'symbol referring to a valid field',
                );
              }

              cb.Expression expression = cb.CodeExpression(cb.Code(symbolName));
              final cb.Expression? callExpression;
              switch (type) {
                case QueryType.text:
                  callExpression =
                      cb.CodeExpression(cb.Code('\$normalizeText'));
                  break;
                case QueryType.enumeration:
                  callExpression =
                      cb.CodeExpression(cb.Code('\$normalizeEnum'));
                  break;
                case null:
                  callExpression = null;
                  break;
              }
              if (callExpression != null) {
                expression = callExpression.call([expression]);
              }
              if (referredField.data.type.endsWith('?')) {
                expression = expression.ifNullThen(cb.literalString(''));
              }
              return expression;
            }))
            .property('join')
            .call([cb.literalString(field.joinBy)]));
      });
    }
  }

  cb.Spec get _dependencyClass {
    return cb.Class((b) {
      b.name = naming.dependencyName;
      b.extend = cb.TypeReference((b) {
        b.symbol = 'Dependency';
        b.types.add(cb.Reference(naming.dataName));
      });
      b.fields.addAll(model.foreignFields.entries.map((entry) {
        return cb.Field((b) {
          b.modifier = cb.FieldModifier.final$;
          b.type = cb.Reference(entry.value.data.type);
          b.name = entry.key;
        });
      }));
      if (model.foreignFields.isEmpty) {
        b.constructors.add(cb.Constructor((b) {
          b.constant = true;
          b.initializers.add(cb.ToCodeExpression(
            cb.CodeExpression(cb.Code('super')).property('strong').call([]),
          ));
        }));
      } else {
        b.constructors.add(cb.Constructor((b) {
          b.constant = false;
          b.optionalParameters.addAll(model.foreignFields.keys.map((name) {
            return cb.Parameter((b) {
              b.required = true;
              b.named = true;
              b.toThis = true;
              b.name = name;
            });
          }));
          b.initializers.add(cb.ToCodeExpression(
            cb.CodeExpression(cb.Code('super')).property('weak').call([
              cb.literalList(model.foreignFields.entries.map((entry) {
                cb.Expression expression =
                    cb.CodeExpression(cb.Code(entry.key));
                if (entry.value.data.type.endsWith('?')) {
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
    final Set<String> polymorphicKeys = polymorphicTree.keys.toSet();
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
        b.annotations.add(cb.CodeExpression(cb.Code('override')));
        b.modifier = cb.FieldModifier.final$;
        b.type = cb.Reference('String');
        b.name = 'tableName';
        b.assignment = cb.ToCodeExpression(cb.literalString(model.name));
      }));
      b.methods.add(cb.Method((b) {
        b.annotations.add(cb.CodeExpression(cb.Code('override')));
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
            'id': _uidTypeExpressionOf(model.uidType),
            ...Map.fromEntries(model.ownFields.entries.expand((entry) sync* {
              final String fieldName = entry.key;
              final String fieldType = entry.value.data.type;
              if (polymorphicKeys.contains(fieldType)) {
                yield MapEntry(
                  'type',
                  cb.CodeExpression(cb.Code('data')).property('type'),
                );
              }
              final cb.Expression prefixExpression;
              if (entry.value.field is ForeignField) {
                prefixExpression = cb.CodeExpression(cb.Code('dependency'));
              } else {
                prefixExpression = cb.CodeExpression(cb.Code('data'));
              }
              yield MapEntry(fieldName, prefixExpression.property(fieldName));
            })),
          },
        ).returned.statement;
      }));
      b.methods.add(cb.Method((b) {
        b.annotations.add(cb.CodeExpression(cb.Code('override')));
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
            'id': cb.CodeExpression(cb.Code('model')).property('id'),
            ...Map.fromEntries(model.ownFields.entries.expand((entry) sync* {
              final String fieldName = entry.key;
              final String fieldType = entry.value.data.type;

              if (polymorphicKeys.contains(fieldType)) {
                yield MapEntry(
                  'type',
                  cb.CodeExpression(cb.Code('data')).property('type'),
                );
              }
              final cb.Expression prefixExpression;
              if (entry.value.field is ForeignField) {
                prefixExpression = cb.CodeExpression(cb.Code('model'));
              } else {
                prefixExpression = cb.CodeExpression(cb.Code('data'));
              }
              yield MapEntry(fieldName, prefixExpression.property(fieldName));
            })),
          },
        ).returned.statement;
      }));
      b.methods.add(cb.Method((b) {
        b.annotations.add(cb.CodeExpression(cb.Code('override')));
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
        b.annotations.add(cb.CodeExpression(cb.Code('override')));
        b.returns = cb.Reference('String');
        b.name = 'identify';
        b.requiredParameters.add(cb.Parameter((b) {
          b.type = cb.Reference(naming.modelName);
          b.name = 'model';
        }));
        b.lambda = true;
        b.body = cb.CodeExpression(cb.Code('model')).property('id').code;
      }));
      b.methods.add(cb.Method((b) {
        b.annotations.add(cb.CodeExpression(cb.Code('override')));
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
          cb.CodeExpression(cb.Code('data')).property('toJson').call([]),
        );
      }));
    });
  }

  cb.Spec get code {
    return cb.Library((b) {
      // b.body.add(cb.Code('// ***********************************************'));
      // b.body.add(cb.Code('//            DORM: ${naming.modelName}           '));
      // b.body.add(cb.Code('// ***********************************************'));
      model.uidType.when(
        caseSimple: () {},
        caseComposite: () {},
        caseSameAs: (_) {},
        caseCustom: (_) => b.body.add(_dummyClass),
      );
      b.body.add(_dataClass);
      b.body.add(_modelClass);
      b.body.add(_dependencyClass);
      b.body.add(_entityClass);
    });
  }
}

class _PolymorphicWriter {
  final Map<String, $PolymorphicData> datum;
  final _PolymorphicNaming naming;

  const _PolymorphicWriter({
    required this.datum,
    required this.naming,
  });

  void _writeEnum(StringSink sink) {
    final String enumName = naming.enumName;
    sink.writeln('enum $enumName {');
    for (String name in datum.keys) {
      final String enumTypeName = name[1].toLowerCase() + name.substring(2);
      sink
        ..write(enumTypeName)
        ..writeln(',');
    }
    sink.writeln('}');
  }

  void _writeClass(StringSink sink) {
    final String className = naming.modelName;
    sink.writeln('abstract class $className implements ${naming.schemaName} {');

    // Factories
    sink.writeln('factory $className.fromType('
        '${naming.enumName} type, '
        'Map json) {');
    sink.writeln('switch (type) {');
    for (MapEntry<String, $PolymorphicData> entry in datum.entries) {
      final String branchName =
          entry.key[1].toLowerCase() + entry.key.substring(2);
      sink.writeln('case ${naming.enumName}.$branchName:');
      sink.writeln('return ${entry.key.substring(1)}.fromJson(json);');
    }
    sink.writeln('}');
    sink.writeln('}');
    sink.writeln();

    // Constructor
    sink.writeln('const $className._();');
    sink.writeln();

    // Getters
    sink.writeln('${naming.enumName} get type;');
    sink.writeln();

    // Methods
    sink.writeln('Map<String, Object?> toJson();');

    sink.writeln();

    sink.writeln('}');
  }

  void _writeModelClass(StringSink sink, String name, $PolymorphicData data) {
    sink.writeln('@JsonSerializable(anyMap: true, explicitToJson: true)');
    sink.writeln('class ${name.substring(1)} '
        'extends ${naming.modelName} '
        'implements $name {');

    // Fields
    for (MapEntry<String, $PolymorphicDataField> entry in data.fields.entries) {
      final String? key = entry.value.name;
      final String name = entry.key;
      final String type = entry.value.variable.type;
      final bool required = !type.endsWith('?');
      sink
        ..writeln('@override')
        ..write('@JsonKey(')
        ..writeAll(
          [
            if (key != null) 'name: \'$key\'',
            if (required) 'required: true',
            if (required) 'disallowNullValue: true',
          ],
          ', ',
        )
        ..writeln(')');

      sink
        ..write('final ')
        ..write(entry.value.variable.type)
        ..write(' ')
        ..write(name)
        ..writeln(';')
        ..writeln();
    }
    sink.writeln();

    // Factories
    sink.writeln('factory ${name.substring(1)}.fromJson(Map json) => '
        '_\$${name.substring(1)}FromJson(json);');
    sink.writeln();

    // Constructors
    sink.writeln('const ${name.substring(1)}({');
    for (MapEntry<String, $PolymorphicDataField> entry in data.fields.entries) {
      sink
        ..write('required this.')
        ..write(entry.key)
        ..writeln(',');
    }
    sink.writeln('}) : super._();');
    sink.writeln();

    // Getters
    final String enumTypeName = name[1].toLowerCase() + name.substring(2);
    sink
      ..writeln('@override')
      ..writeln('${naming.enumName} get type => '
          '${naming.enumName}.$enumTypeName;')
      ..writeln();

    // Methods
    sink
      ..writeln('@override')
      ..writeln('Map<String, Object?> toJson() =>'
          '_\$${name.substring(1)}ToJson(this);')
      ..writeln();

    sink.writeln('}');
  }

  String write() {
    final StringSink sink = StringBuffer();
    _writeEnum(sink);
    _writeClass(sink);
    for (MapEntry<String, $PolymorphicData> entry in datum.entries) {
      _writeModelClass(sink, entry.key, entry.value);
    }
    return '$sink';
  }
}

class OrmContext {
  final Map<String, Map<String, $PolymorphicData>> polymorphicDatum;
  final Map<String, $Model> modelDatum;

  const OrmContext({
    required this.polymorphicDatum,
    required this.modelDatum,
  });
}

class OrmGenerator extends Generator {
  @override
  FutureOr<String> generate(LibraryReader library, BuildStep buildStep) {
    final OrmContext context = OrmContext(modelDatum: {}, polymorphicDatum: {});
    for (ClassElement element in library.classes) {
      final List<Visitor> visitors = [PolymorphicDataVisitor(), ModelVisitor()];
      for (Visitor visitor in visitors) {
        if (!visitor.canVisit(element)) continue;
        visitor.onVisit(context, element);
      }
    }

    final cb.Spec spec = cb.Library((b) {
      // b.body.add(cb.CodeExpression(cb.Code('/*****************************')));
      // b.body.add(cb.CodeExpression(cb.Code('//             DORM            ')));
      // b.body.add(cb.CodeExpression(cb.Code('// **************************** */')));

      for (MapEntry<String, $Model> entry in context.modelDatum.entries) {
        b.body.add(_SchemaWriter(
          model: entry.value,
          naming: SchemaNaming(entry.key),
          polymorphicTree: context.polymorphicDatum,
        ).code);
      }
      // TODO
      // for (MapEntry<String, Map<String, $PolymorphicData>> entry
      //     in context.polymorphicDatum.entries) {
      //   b.body.add(_PolymorphicWriter(
      //     datum: entry.value,
      //     naming: _PolymorphicNaming(entry.key),
      //   ).code);
      // }

      b.body.add(cb.Class((b) {
        b.name = 'Dorm';
        b.fields.add(cb.Field((b) {
          b.modifier = cb.FieldModifier.final$;
          b.type = cb.Reference('Reference');
          b.name = '_root';
        }));
        b.constructors.add(cb.Constructor((b) {
          b.constant = true;
          b.requiredParameters.add(cb.Parameter((b) {
            b.toThis = true;
            b.name = '_root';
          }));
        }));
        b.methods.addAll(context.modelDatum.entries.map((entry) {
          final SchemaNaming naming = SchemaNaming(entry.key);
          final $Model model = entry.value;
          return cb.Method((b) {
            b.returns = cb.TypeReference((b) {
              b.symbol = 'DatabaseEntity';
              b.types.add(cb.Reference(naming.dataName));
              b.types.add(cb.Reference(naming.modelName));
            });
            b.type = cb.MethodType.getter;
            b.lambda = true;
            b.name = (model.as as $Symbol?)?.name ??
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
                  'reference': cb.CodeExpression(cb.Code('_root')),
                },
              ),
            );
          });
        }));
      }));
    });

    final cb.DartEmitter emitter = cb.DartEmitter(allocator: cb.Allocator());
    // print(spec.accept(emitter).toString());
    return DartFormatter().format(spec.accept(emitter).toString());
  }
}
