import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:build/build.dart';
import 'package:dorm_annotations/dorm_annotations.dart';
import 'package:dorm_generator/src/utils.dart';
import 'package:dorm_generator/src/visitor.dart';
import 'package:source_gen/source_gen.dart';

class _SchemaNaming {
  /// _Schema
  final String schemaName;

  const _SchemaNaming(this.schemaName);

  /// Schema
  String get modelName => schemaName.substring(1);

  /// SchemaData
  String get dataName => '${modelName}Data';

  /// SchemaDependency
  String get dependencyName => '${modelName}Dependency';

  /// SchemaEntity
  String get entityName => '${modelName}Entity';
}

class _Model extends Model {
  final _SchemaNaming naming;

  const _Model({
    required super.name,
    required super.uidType,
    required super.repositoryName,
    required this.naming,
  });
}

class _OrmWriter {
  final _Model model;
  final ModelVisitor visitor;

  const _OrmWriter({
    required this.model,
    required this.visitor,
  });

  void _writeDataClass(StringSink sink) {
    final String className = model.naming.dataName;
    sink.writeln('@JsonSerializable(anyMap: true, explicitToJson: true)');
    sink.writeln('class $className {');

    // Fields
    sink.writeln();
    for (MapEntry<FieldElement, Field> entry in visitor.ownFields.entries) {
      final String? name = entry.value.name;
      final bool required =
          entry.key.type.nullabilitySuffix == NullabilitySuffix.none;
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
        ..write(entry.key.type)
        ..write(' ')
        ..write(entry.key.name)
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
    sink.write('const ${model.naming.dataName}(');
    sink.writeln(visitor.ownFields.isEmpty ? '' : '{');
    for (MapEntry<FieldElement, Field> entry in visitor.ownFields.entries) {
      sink
        ..write('required this.')
        ..write(entry.key.name)
        ..writeln(',');
    }
    sink.write(visitor.ownFields.isEmpty ? '' : '}');
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
    final String className = model.naming.modelName;

    sink.writeln('@JsonSerializable(anyMap: true, explicitToJson: true)');
    sink.writeln('class $className '
        'extends ${model.naming.dataName} '
        'implements ${model.naming.schemaName} {');

    // Fields
    sink.writeln();
    sink.writeln('@JsonKey('
        'name: \'_id\', required: true, disallowNullValue: true)');
    sink.writeln('final String id;');

    for (MapEntry<FieldElement, Field> entry in visitor.foreignFields.entries) {
      sink.writeln();
      final String? name = entry.value.name;
      final bool required =
          entry.key.type.nullabilitySuffix == NullabilitySuffix.none;

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
        ..write(entry.key.type)
        ..write(' ')
        ..write(entry.key.name)
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
    for (MapEntry<FieldElement, Field> entry in visitor.allFields.entries) {
      final String prefix = entry.value is ForeignField ? 'this' : 'super';
      sink
        ..write('required $prefix.')
        ..write(entry.key.name)
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
    for (MapEntry<FieldElement, Field> entry in visitor.allFields.entries) {
      final QueryType? type = entry.value.queryBy;
      if (type == null) continue;
      if (!hasQuery) {
        sink.writeln("'_query': {");
        hasQuery = true;
      }
      sink.write("'${entry.value.name}': ");
      switch (type) {
        case QueryType.text:
          sink
            ..write('\$normalizeText(')
            ..write(entry.key.name)
            ..write(')');
          break;
        case QueryType.value:
          sink.write(entry.key.name);
          break;
        case QueryType.date:
          sink
            ..write('\$normalizeDate(')
            ..write(entry.key.name)
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
    final String className = model.naming.dependencyName;

    sink.writeln('class $className '
        'extends Dependency<${model.naming.dataName}> {');
    for (FieldElement element in visitor.foreignFields.keys) {
      sink.writeln('final ${element.type} ${element.name};');
    }
    sink.writeln();
    if (visitor.foreignFields.isEmpty) {
      sink.writeln('const $className() : super.strong();');
    } else {
      sink.writeln('$className({');
      for (FieldElement element in visitor.foreignFields.keys) {
        sink.writeln('required this.${element.name},');
      }
      sink.write('}) : super.weak([');
      sink.write(
          visitor.foreignFields.keys.map((element) => element.name).join(', '));
      sink.writeln(']);');
    }
    sink.writeln('}');
  }

  void _writeEntityClass(StringSink sink) {
    final String className = model.naming.entityName;

    sink.writeln('class $className '
        'implements Entity<${model.naming.dataName}, '
        '${model.naming.modelName}> {');

    // Constructors
    sink.writeln('const $className._();');
    sink.writeln();

    // tableName
    sink.writeln('@override');
    sink.writeln('String get tableName => \'${model.name}\';');
    sink.writeln();

    // fromData
    sink.writeln('@override');
    sink.writeln('${model.naming.modelName} fromData(');
    sink.writeln('${model.naming.dependencyName} dependency,');
    sink.writeln('String id,');
    sink.writeln('${model.naming.dataName} data,');
    sink.writeln(') {');
    sink.writeln('return ${model.naming.modelName}(');

    final UidType uidType = model.uidType;
    sink
      ..write('id: ')
      ..write(encodeUidType(visitor, uidType))
      ..writeln(',');

    for (FieldElement element in visitor.foreignFields.keys) {
      sink.writeln('${element.name}: dependency.${element.name},');
    }
    for (FieldElement element in visitor.ownFields.keys) {
      sink.writeln('${element.name}: data.${element.name},');
    }
    sink.writeln(');');
    sink.writeln('}');
    sink.writeln();

    // fromJson
    sink.writeln('@override');
    sink.writeln('${model.naming.modelName} fromJson(String id, Map json) =>');
    sink.writeln('${model.naming.modelName}.fromJson(id, json);');
    sink.writeln();

    // identify
    sink.writeln('@override');
    sink.writeln('String identify(${model.naming.modelName} '
        'model) => model.id;');
    sink.writeln();

    // toJson
    sink.writeln('@override');
    sink.writeln('Map toJson(${model.naming.dataName} data) => data.toJson();');

    sink.writeln('}');
  }

  String write() {
    final StringBuffer buffer = StringBuffer();
    buffer.writeln('// **************************************************');
    buffer.writeln('//     DORM: ${model.naming.modelName}');
    buffer.writeln('// **************************************************');
    buffer.writeln();
    _writeDataClass(buffer);
    _writeModelClass(buffer);
    _writeDependencyClass(buffer);
    _writeEntityClass(buffer);
    return buffer.toString();
  }
}

class _$CustomUidValue implements CustomUidValue {
  final ConstantReader reader;

  const _$CustomUidValue(this.reader);

  @override
  T when<T>({
    required T Function() caseSimple,
    required T Function() caseComposite,
    required T Function(String id) caseValue,
  }) {
    throw UnimplementedError();
  }
}

UidType? decodeUidType(ConstantReader reader) {
  if (reader.isNull) return null;
  final String? uidTypeName =
      reader.objectValue.type?.getDisplayString(withNullability: false);
  if (uidTypeName == null) return null;

  switch (uidTypeName) {
    case '_SimpleUidType':
      return const UidType.simple();
    case '_CompositeUidType':
      return const UidType.composite();
    case '_SameAsUidType':
      final Type type = $Type(reader: reader.read('type'));
      return UidType.sameAs(type);
    case '_CustomUidType':
      return UidType.custom((_) => _$CustomUidValue(reader.read('builder')));
  }
  return null;
}

String encodeUidType(ModelVisitor visitor, UidType uidType) {
  return uidType.when(
    caseSimple: () => 'id',
    caseComposite: () => 'dependency.key(id)',
    caseSameAs: (type) {
      type as $Type;
      for (MapEntry<FieldElement, ForeignField> entry
          in visitor.foreignFields.entries) {
        final $Type currentType = entry.value.referTo as $Type;
        if (currentType.name != type.name) continue;
        return 'dependency.${entry.key.name}';
      }
      throw StateError('invalid reference on UidType.sameAs: ${type.name}');
    },
    caseCustom: (builder) {
      final _$CustomUidValue value = builder(0) as _$CustomUidValue;
      final String name = $Function.name(value.reader);
      return '\$parseCustomUidValue(dependency, id, $name(data))';
    },
  );
}

class OrmGenerator extends GeneratorForAnnotation<Model> {
  final List<_Model> _visitedModels = [];

  @override
  String generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    final ModelVisitor visitor = ModelVisitor();
    element.visitChildren(visitor);

    final _Model model = _Model(
      name: annotation.read('name').stringValue,
      repositoryName: annotation.read('repositoryName').literalValue as String?,
      uidType: decodeUidType(annotation.read('uidType')) ?? UidType.simple(),
      naming: _SchemaNaming(element.name as String),
    );
    _visitedModels.add(model);
    return _OrmWriter(model: model, visitor: visitor).write();
  }

  @override
  Future<String> generate(LibraryReader library, BuildStep buildStep) async {
    final String result = await super.generate(library, buildStep);

    final StringBuffer buffer = StringBuffer(result);
    buffer.writeln();
    buffer.writeln();
    buffer.writeln('// **************************************************');
    buffer.writeln('//     DORM');
    buffer.writeln('// **************************************************');
    buffer.writeln();

    buffer.writeln('class Dorm {');
    buffer.writeln('final Reference _root;');
    buffer.writeln();
    buffer.writeln('const Dorm(this._root);');
    buffer.writeln();
    for (_Model model in _visitedModels) {
      buffer.writeln('Repository<${model.naming.dataName}, ');
      buffer.writeln('${model.naming.modelName}> get '
          '${model.repositoryName} =>');
      buffer.writeln('Repository(root: _root, '
          'entity: const ${model.naming.entityName}._());');
      buffer.writeln();
    }
    buffer.writeln('}');
    _visitedModels.clear();

    return '$buffer';
  }
}
