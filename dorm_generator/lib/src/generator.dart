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

class _OrmWriter {
  final $Model model;
  final SchemaNaming naming;

  const _OrmWriter({
    required this.model,
    required this.naming,
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
        return '\$parseCustomUidValue(dependency, id, '
            '$name(${naming.dummyName}.fromData(dependency, data)),)';
      },
    );
  }

  void _writeDummyClass(StringSink sink) {
    final String className = naming.dummyName;
    sink.writeln('class $className implements ${naming.schemaName} {');

    // Fields
    for (MapEntry<String, $ModelField> entry in model.fields.entries) {
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
    for (MapEntry<String, $ModelField> entry in model.fields.entries) {
      final String variableName =
          entry.value.field is ForeignField ? 'dependency' : 'data';
      sink.writeln('${entry.key}: $variableName.${entry.key},');
    }
    sink.writeln(');');
    sink.writeln('}');

    // Constructors
    sink.writeln('const $className({');
    for (MapEntry<String, $ModelField> entry in model.fields.entries) {
      sink.writeln('required this.${entry.key},');
    }
    sink.writeln('});');
    sink.writeln('}');
  }

  void _writeDataClass(StringSink sink) {
    final String className = naming.dataName;
    sink.writeln('@JsonSerializable(anyMap: true, explicitToJson: true)');
    sink.writeln('class $className {');

    // Fields
    sink.writeln();
    for (MapEntry<String, $ModelField> entry in model.ownFields.entries) {
      final String? name = entry.value.field.name;
      final bool required = !entry.value.data.type.endsWith('?');
      sink
        ..write('@JsonKey(')
        ..writeAll(
          [
            if (name != null) 'name: \'$name\'',
            if (required) 'required: true',
            if (required) 'disallowNullValue: true',
          ],
          ', ',
        )
        ..writeln(')');

      sink
        ..write('final ')
        ..write(entry.value.data.type)
        ..write(' ')
        ..write(entry.key)
        ..writeln(';');

      sink.writeln();
    }
    sink.writeln();

    // Factories
    sink.writeln();
    sink.writeln('factory $className.fromJson(Map json) =>');
    sink.writeln('_\$${className}FromJson(json);');
    sink.writeln();

    // Constructors
    sink.writeln();
    sink.write('const ${naming.dataName}(');
    sink.writeln(model.ownFields.isEmpty ? '' : '{');
    for (MapEntry<String, $ModelField> entry in model.ownFields.entries) {
      sink
        ..write('required this.')
        ..write(entry.key)
        ..writeln(',');
    }
    sink.write(model.ownFields.isEmpty ? '' : '}');
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

    sink.writeln('@JsonSerializable(anyMap: true, explicitToJson: true)');
    sink.writeln('class $className '
        'extends ${naming.dataName} '
        'implements ${naming.schemaName} {');

    // Fields
    sink.writeln();
    sink.writeln('@JsonKey('
        'name: \'_id\', required: true, disallowNullValue: true)');
    sink.writeln('final String id;');

    for (MapEntry<String, $ModelField> entry in model.foreignFields.entries) {
      sink.writeln();
      final String? name = entry.value.field.name;
      final bool required = !entry.value.data.type.endsWith('?');

      sink.writeln('@override');
      sink
        ..write('@JsonKey(')
        ..writeAll(
          [
            if (name != null) 'name: \'$name\'',
            if (required) 'required: true',
            if (required) 'disallowNullValue: true',
          ],
          ', ',
        )
        ..writeln(')');

      sink
        ..write('final ')
        ..write(entry.value.data.type)
        ..write(' ')
        ..write(entry.key)
        ..writeln(';');
    }
    sink.writeln();

    // Factories
    sink.writeln('factory $className.fromJson(String id, Map json) =>');
    sink.writeln("_\$${className}FromJson({...json, '_id': id});");

    // Constructor
    sink.writeln();
    sink.writeln('const $className({');
    sink.writeln('required this.id,');
    for (MapEntry<String, $ModelField> entry in model.fields.entries) {
      final String prefix =
          entry.value.field is ForeignField ? 'this' : 'super';
      sink
        ..write('required $prefix.')
        ..write(entry.key)
        ..writeln(',');
    }
    sink.writeln('});');
    sink.writeln();

    // Methods
    sink.writeln();
    sink.writeln('@override');
    sink.writeln('Map<String, Object?> toJson() {');
    sink.writeln('return {');
    sink.writeln('..._\$${className}ToJson(this)..remove(\'_id\'),');
    bool hasQuery = false;
    for (MapEntry<String, $ModelField> entry in model.fields.entries) {
      final QueryType? type = entry.value.field.queryBy;
      if (type == null) continue;
      if (!hasQuery) {
        sink.writeln("'_query': {");
        hasQuery = true;
      }
      sink.write("'${entry.value.field.name}': ");
      switch (type) {
        case QueryType.text:
          sink
            ..write('\$normalizeText(')
            ..write(entry.key)
            ..write(')');
          break;
        case QueryType.value:
          sink.write(entry.key);
          break;
        case QueryType.date:
          sink
            ..write('\$normalizeDate(')
            ..write(entry.key)
            ..write(')');
          break;
      }
      sink.writeln(',');
    }
    if (hasQuery) sink.writeln('},');

    sink.writeln('};');
    sink.writeln('}');
    sink.writeln();

    sink.writeln('}');
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
      sink.write(model.foreignFields.keys.join(', '));
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
    sink.writeln('const $className._();');
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

    for (String name in model.foreignFields.keys) {
      sink.writeln('$name: dependency.$name,');
    }
    for (String name in model.ownFields.keys) {
      sink.writeln('$name: data.$name,');
    }
    sink.writeln(');');
    sink.writeln('}');
    sink.writeln();

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
    sink.writeln('Map toJson(${naming.dataName} data) => data.toJson();');

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
    for (MapEntry<String, $Model> entry in context.modelDatum.entries) {
      sink.writeln(_OrmWriter(
        model: entry.value,
        naming: SchemaNaming(entry.key),
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

      sink.writeln('Repository<${naming.dataName}, ');
      sink.writeln('${naming.modelName}> get '
          '${model.repositoryName} =>');
      sink.writeln('Repository(root: _root, '
          'entity: const ${naming.entityName}._());');
      sink.writeln();
    }
    sink.writeln('}');

    return '$sink';
  }
}
