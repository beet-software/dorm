import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
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

  String _encodeUidType(UidType uidType) {
    return uidType.when(
      caseSimple: () => 'id',
      caseComposite: () => 'dependency.key(id)',
      caseSameAs: (type) {
        type as $Type;
        for (MapEntry<String, $ModelField> entry
            in model.foreignFields.entries) {
          final $Type currentType =
              (entry.value.field as ForeignField).referTo as $Type;
          if (currentType.name != type.name) continue;
          return 'dependency.${entry.key}';
        }
        throw StateError('invalid reference on UidType.sameAs: ${type.name}');
      },
      caseCustom: (builder) {
        final $CustomUidValue value = builder(0) as $CustomUidValue;
        final String name = value.reader.functionName;
        return '$name(${naming.dummyName}.fromData(dependency, data))'
            '.when('
            'caseSimple: () => id,'
            'caseComposite: () => dependency.key(id),'
            'caseValue: (id) => id,'
            ')';
      },
    );
  }

  void _writeDummyClass(StringSink sink) {
    final String className = naming.dummyName;
    sink.writeln('class $className implements ${naming.schemaName} {');

    // Fields
    for (MapEntry<String, $ModelField> entry in model.ownFields.entries) {
      sink
        ..writeln('@override')
        ..writeln('final ${entry.value.data.type} ${entry.key};')
        ..writeln();
    }

    // Factories
    sink.writeln('factory $className.fromData('
        '${naming.dependencyName} dependency, '
        '${naming.dataName} data) {');
    sink.writeln('return $className(');
    for (MapEntry<String, $ModelField> entry in model.ownFields.entries) {
      final String variableName =
          entry.value.field is ForeignField ? 'dependency' : 'data';
      sink.writeln('${entry.key}: $variableName.${entry.key},');
    }
    sink.writeln(');');
    sink.writeln('}');

    // Constructors
    sink.writeln('const $className({');
    for (MapEntry<String, $ModelField> entry in model.ownFields.entries) {
      sink.writeln('required this.${entry.key},');
    }
    sink.writeln('});');

    // Getters
    _writeQueryGetters(sink);

    sink.writeln('}');
  }

  void _writeDataClass(StringSink sink) {
    final String className = naming.dataName;

    final Set<String> polymorphicKeys = polymorphicTree.keys.toSet();
    final Set<String> modelFieldTypes =
        model.fields.values.map((field) => field.data.type).toSet();
    final bool hasPolymorphism =
        polymorphicKeys.intersection(modelFieldTypes).isNotEmpty;

    sink
      ..write('@JsonSerializable(')
      ..writeAll([
        'anyMap: true',
        'explicitToJson: true',
        if (hasPolymorphism) 'constructor: \'_\'',
      ], ', ')
      ..writeln(')');

    sink.writeln('class $className {');

    // Fields
    sink.writeln();
    for (MapEntry<String, $ModelField> entry in model.dataFields.entries) {
      final String fieldName = entry.key;
      final String fieldType = entry.value.data.type;
      final bool isModelField = entry.value.field is ModelField;
      final bool isPolymorphicField = polymorphicKeys.contains(fieldType);

      if (isPolymorphicField) {
        final String typeKey =
            (entry.value.field as PolymorphicField).pivotName;
        sink
          ..write('@JsonKey(')
          ..writeAll([
            'name: \'$typeKey\'',
            'required: true',
            'disallowNullValue: true',
          ], ', ')
          ..writeln(')');

        sink
          ..write('final ')
          ..write('${fieldType.substring(1)}Type')
          ..write(' ')
          ..write('type')
          ..writeln(';')
          ..writeln();
      }

      final String? key = entry.value.field.name;
      final Object? defaultValue = entry.value.field.defaultValue;
      final bool required =
          defaultValue == null && !entry.value.data.type.endsWith('?');
      sink
        ..write('@JsonKey(')
        ..writeAll([
          if (key != null) 'name: \'$key\'',
          if (required) 'required: true',
          if (required) 'disallowNullValue: true',
          if (defaultValue != null) 'defaultValue: $defaultValue',
        ], ', ')
        ..writeln(')');

      sink
        ..write('final ')
        ..write(isPolymorphicField
            ? fieldType.substring(1)
            : isModelField
                ? '${fieldType.substring(1)}Data'
                : fieldType)
        ..write(' ')
        ..write(fieldName)
        ..writeln(';');

      sink.writeln();
    }
    sink.writeln();

    // Factories
    sink.writeln();
    sink.writeln('factory $className.fromJson(Map json) =>');
    sink.writeln('_\$${className}FromJson(json);');
    sink.writeln();

    if (hasPolymorphism) {
      sink.writeln('factory $className._({');
      for (MapEntry<String, $ModelField> entry in model.dataFields.entries) {
        final String fieldName = entry.key;
        final String fieldType = entry.value.data.type;
        final bool isPolymorphicField = polymorphicKeys.contains(fieldType);

        if (isPolymorphicField) {
          sink
            ..write('required ')
            ..write('${fieldType.substring(1)}Type')
            ..writeln(' type,');
        }
        sink
          ..write('required ')
          ..write(isPolymorphicField ? 'Map' : fieldType)
          ..write(' ')
          ..write(fieldName)
          ..writeln(',');
      }
      sink.writeln('}) {');
      sink.writeln('return $className(');
      for (MapEntry<String, $ModelField> entry in model.dataFields.entries) {
        final String fieldName = entry.key;
        final String fieldType = entry.value.data.type;
        final bool isPolymorphicField = polymorphicKeys.contains(fieldType);

        if (isPolymorphicField) {
          sink.writeln('type: type,');
          sink
            ..write(fieldName)
            ..write(': ')
            ..write(fieldType.substring(1))
            ..write('.fromType(type, ')
            ..write(fieldName)
            ..writeln('),');
        } else {
          sink
            ..write(fieldName)
            ..write(': ')
            ..write(fieldName)
            ..writeln(',');
        }
      }
      sink.writeln(');');
      sink.writeln('}');
    }

    // Constructors
    sink.writeln();
    sink.write('const ${naming.dataName}(');
    sink.writeln(model.dataFields.isEmpty ? '' : '{');
    for (MapEntry<String, $ModelField> entry in model.dataFields.entries) {
      sink
        ..write('required this.')
        ..write(entry.key)
        ..writeln(',');
    }
    if (hasPolymorphism) {
      sink.writeln('required this.type,');
    }

    sink.write(model.dataFields.isEmpty ? '' : '}');
    sink.writeln(');');
    sink.writeln();

    // Methods
    sink.writeln();
    sink.writeln('Map<String, Object?> toJson() =>');
    sink.writeln('_\$${className}ToJson(this);');
    sink.writeln();

    sink.writeln('}');
  }

  void _writeModelClass(StringSink sink) {
    final String className = naming.modelName;

    final Set<String> polymorphicKeys = polymorphicTree.keys.toSet();
    final Set<String> modelFieldTypes =
        model.fields.values.map((field) => field.data.type).toSet();
    final bool hasPolymorphism =
        polymorphicKeys.intersection(modelFieldTypes).isNotEmpty;

    sink
      ..write('@JsonSerializable(')
      ..writeAll([
        'anyMap: true',
        'explicitToJson: true',
        if (hasPolymorphism) 'constructor: \'_\'',
      ], ', ')
      ..writeln(')');

    sink.writeln('class $className '
        'extends ${naming.dataName} '
        'implements ${naming.schemaName} {');

    // Fields
    sink
      ..write('@JsonKey(')
      ..writeAll([
        'name: \'_id\'',
        'required: true',
        'disallowNullValue: true',
      ], ', ')
      ..writeln(')');
    sink.writeln('final String id;');

    for (MapEntry<String, $ModelField> entry in model.foreignFields.entries) {
      sink.writeln();
      final String? key = entry.value.field.name;
      final bool required = !entry.value.data.type.endsWith('?');

      sink.writeln('@override');
      sink
        ..write('@JsonKey(')
        ..writeAll([
          if (key != null) 'name: \'$key\'',
          if (required) 'required: true',
          if (required) 'disallowNullValue: true',
        ], ', ')
        ..writeln(')');

      final String fieldName = entry.key;
      final String fieldType = entry.value.data.type;
      sink
        ..write('final ')
        ..write(fieldType)
        ..write(' ')
        ..write(fieldName)
        ..writeln(';');
    }
    sink.writeln();

    // Factories
    sink.writeln('factory $className.fromJson(String id, Map json) =>');
    sink.writeln("_\$${className}FromJson({...json, '_id': id});");
    sink.writeln();

    if (hasPolymorphism) {
      sink.writeln('factory $className._({');
      sink.writeln('required String id,');
      for (MapEntry<String, $ModelField> entry in model.fields.entries) {
        final String fieldName = entry.key;
        final String fieldType = entry.value.data.type;
        final bool isPolymorphicField = polymorphicKeys.contains(fieldType);

        if (isPolymorphicField) {
          sink
            ..write('required ')
            ..write('${fieldType.substring(1)}Type')
            ..writeln(' type,');

          sink
            ..write('required Map ')
            ..write(fieldName)
            ..writeln(',');
        } else {
          sink
            ..write('required ')
            ..write(fieldType)
            ..write(' ')
            ..write(fieldName)
            ..writeln(',');
        }
      }
      sink.writeln('}) {');
      sink.writeln('final ${naming.dataName} data = ${naming.dataName}._(');
      for (MapEntry<String, $ModelField> entry in model.dataFields.entries) {
        final String fieldName = entry.key;
        final String fieldType = entry.value.data.type;
        final bool isPolymorphicField = polymorphicKeys.contains(fieldType);

        if (isPolymorphicField) {
          sink.writeln('type: type,');
        }
        sink
          ..write(fieldName)
          ..write(': ')
          ..write(fieldName)
          ..writeln(',');
      }
      sink.writeln(');');

      sink.writeln('return $className(');
      sink.writeln('id: id,');
      for (MapEntry<String, $ModelField> entry in model.fields.entries) {
        final String prefix = entry.value.field is ForeignField ? '' : 'data.';
        final String fieldName = entry.key;
        final String fieldType = entry.value.data.type;
        final bool isPolymorphicField = polymorphicKeys.contains(fieldType);

        if (isPolymorphicField) {
          sink.write('type: data.type,');
        }

        sink
          ..write(fieldName)
          ..write(': ')
          ..write(prefix)
          ..write(fieldName)
          ..writeln(',');
      }
      sink.writeln(');');

      sink.writeln('}');
      sink.writeln();
    }

    // Constructor
    sink.writeln('const $className({');
    sink.writeln('required this.id,');
    for (MapEntry<String, $ModelField> entry in model.ownFields.entries) {
      final String fieldName = entry.key;
      final String fieldType = entry.value.data.type;
      final bool isPolymorphicField = polymorphicKeys.contains(fieldType);
      final String prefix =
          entry.value.field is ForeignField ? 'this' : 'super';

      if (isPolymorphicField) {
        sink.writeln('required super.type,');
      }
      sink
        ..write('required $prefix.')
        ..write(fieldName)
        ..writeln(',');
    }
    sink.writeln('});');
    sink.writeln();

    // Getters
    _writeQueryGetters(sink);

    // Methods
    sink.writeln();
    sink.writeln('@override');
    sink.writeln('Map<String, Object?> toJson() {');
    sink.writeln('return {');
    sink.writeln('..._\$${className}ToJson(this)..remove(\'_id\'),');
    for (MapEntry<String, $ModelField> entry in model.queryFields.entries) {
      final QueryField field = entry.value.field as QueryField;
      sink
        ..write('\'')
        ..write(field.name)
        ..write('\': ')
        ..write(entry.key)
        ..writeln(',');
    }
    sink.writeln('};');
    sink.writeln('}');
    sink.writeln();

    sink.writeln('}');
  }

  void _writeQueryGetters(StringSink sink) {
    sink.writeln();
    for (MapEntry<String, $ModelField> entry in model.queryFields.entries) {
      final QueryField field = entry.value.field as QueryField;
      if (field.referTo.isEmpty) continue;

      sink.writeln('@override');
      sink
        ..write(entry.value.data.type)
        ..write(' get ')
        ..write(entry.key)
        ..write(' => ');

      final String args = field.referTo.map((token) {
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

        String name = symbolName;
        if (type != null) {
          switch (type) {
            case QueryType.text:
              {
                name = '\$normalizeText($name)';
                break;
              }
            case QueryType.enumeration:
              {
                name = '\$normalizeEnum($name)';
                break;
              }
          }
        }

        if (referredField.data.type.endsWith('?')) name = '$name ?? \'\'';
        return name;
      }).join(', ');

      sink
        ..write('[')
        ..write(args)
        ..write('].join(\'')
        ..write(field.joinBy)
        ..writeln('\');');

      sink.writeln();
    }
  }

  void _writeDependencyClass(StringSink sink) {
    final String className = naming.dependencyName;

    sink.writeln('class $className '
        'extends Dependency<${naming.dataName}> {');
    for (MapEntry<String, $ModelField> entry in model.foreignFields.entries) {
      sink.writeln('final ${entry.value.data.type} ${entry.key};');
    }
    sink.writeln();
    if (model.foreignFields.isEmpty) {
      sink.writeln('const $className() : super.strong();');
    } else {
      sink.writeln('$className({');
      for (String name in model.foreignFields.keys) {
        sink.writeln('required this.$name,');
      }
      sink.write('}) : super.weak([');
      sink.write(model.foreignFields.entries.map((entry) {
        final String suffix =
            entry.value.data.type.endsWith('?') ? ' ?? \'\'' : '';
        return '${entry.key}$suffix';
      }).join(', '));
      sink.writeln(']);');
    }
    sink.writeln('}');
  }

  void _writeEntityClass(StringSink sink) {
    final String className = naming.entityName;

    sink.writeln('class $className '
        'implements Entity<${naming.dataName}, '
        '${naming.modelName}> {');

    // Constructors
    sink.writeln('const $className();');
    sink.writeln();

    // tableName
    sink.writeln('@override');
    sink.writeln('String get tableName => \'${model.name}\';');
    sink.writeln();

    // fromData
    sink.writeln('@override');
    sink.writeln('${naming.modelName} fromData(');
    sink.writeln('${naming.dependencyName} dependency,');
    sink.writeln('String id,');
    sink.writeln('${naming.dataName} data,');
    sink.writeln(') {');
    sink.writeln('return ${naming.modelName}(');

    final UidType uidType = model.uidType;
    sink
      ..write('id: ')
      ..write(_encodeUidType(uidType))
      ..writeln(',');

    final Set<String> polymorphicKeys = polymorphicTree.keys.toSet();
    for (MapEntry<String, $ModelField> entry in model.ownFields.entries) {
      final String fieldName = entry.key;
      final String fieldType = entry.value.data.type;
      final bool isPolymorphicField = polymorphicKeys.contains(fieldType);
      final String prefix =
          entry.value.field is ForeignField ? 'dependency' : 'data';

      if (isPolymorphicField) {
        sink.writeln('type: data.type,');
      }

      sink
        ..write(fieldName)
        ..write(': ')
        ..write(prefix)
        ..write('.')
        ..write(fieldName)
        ..writeln(',');
    }

    sink.writeln(');');
    sink.writeln('}');
    sink.writeln();

    // convert
    sink.writeln('@override');
    sink.writeln('${naming.modelName} convert('
        '${naming.modelName} model, ${naming.dataName} data) {');
    sink.writeln('return ${naming.modelName}(');
    sink.writeln('id: model.id,');

    for (MapEntry<String, $ModelField> entry in model.ownFields.entries) {
      final String fieldName = entry.key;
      final String fieldType = entry.value.data.type;
      final bool isPolymorphicField = polymorphicKeys.contains(fieldType);
      final String prefix =
          entry.value.field is ForeignField ? 'model' : 'data';

      if (isPolymorphicField) {
        sink.writeln('type: data.type,');
      }

      sink
        ..write(fieldName)
        ..write(': ')
        ..write(prefix)
        ..write('.')
        ..write(fieldName)
        ..writeln(',');
    }

    sink.writeln(');');
    sink.writeln('}');

    // fromJson
    sink.writeln('@override');
    sink.writeln('${naming.modelName} fromJson(String id, Map json) =>');
    sink.writeln('${naming.modelName}.fromJson(id, json);');
    sink.writeln();

    // identify
    sink.writeln('@override');
    sink.writeln('String identify(${naming.modelName} '
        'model) => model.id;');
    sink.writeln();

    // toJson
    sink.writeln('@override');
    sink.writeln(
        'Map<String, Object?> toJson(${naming.dataName} data) => data.toJson();');

    sink.writeln('}');
  }

  String write() {
    final StringBuffer buffer = StringBuffer();
    buffer.writeln('// **************************************************');
    buffer.writeln('//     DORM: ${naming.modelName}');
    buffer.writeln('// **************************************************');
    buffer.writeln();
    model.uidType.when(
      caseSimple: () {},
      caseComposite: () {},
      caseSameAs: (_) {},
      caseCustom: (_) => _writeDummyClass(buffer),
    );
    _writeDataClass(buffer);
    _writeModelClass(buffer);
    _writeDependencyClass(buffer);
    _writeEntityClass(buffer);
    return buffer.toString();
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

    final StringSink sink = StringBuffer();
    for (MapEntry<String, Map<String, $PolymorphicData>> entry
        in context.polymorphicDatum.entries) {
      sink.writeln(_PolymorphicWriter(
        datum: entry.value,
        naming: _PolymorphicNaming(entry.key),
      ).write());
    }
    for (MapEntry<String, $Model> entry in context.modelDatum.entries) {
      sink.writeln(_SchemaWriter(
        model: entry.value,
        naming: SchemaNaming(entry.key),
        polymorphicTree: context.polymorphicDatum,
      ).write());
    }
    sink.writeln();
    sink.writeln();
    sink.writeln('// **************************************************');
    sink.writeln('//     DORM');
    sink.writeln('// **************************************************');
    sink.writeln();

    sink.writeln('class Dorm {');
    sink.writeln('final Reference _root;');
    sink.writeln();
    sink.writeln('const Dorm(this._root);');
    sink.writeln();
    for (MapEntry<String, $Model> entry in context.modelDatum.entries) {
      final SchemaNaming naming = SchemaNaming(entry.key);
      final $Model model = entry.value;

      final String fieldName =
          (model.as as $Symbol?)?.name ?? naming.modelName.toLowerCase();
      sink.writeln('DatabaseEntity<${naming.dataName}, ');
      sink.writeln('${naming.modelName}> get $fieldName =>');
      sink.writeln('DatabaseEntity(const ${naming.entityName}(), '
          'reference: _root);');
      sink.writeln();
    }
    sink.writeln('}');

    return '$sink';
  }
}
