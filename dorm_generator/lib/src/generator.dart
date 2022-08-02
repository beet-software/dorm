import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:build/build.dart';
import 'package:dorm_annotations/dorm_annotations.dart';
import 'package:dorm_generator/src/visitor.dart';
import 'package:source_gen/source_gen.dart';

class _SchemaNaming {
  // _Schema
  final String schemaName;

  const _SchemaNaming(this.schemaName);

  // Schema
  String get modelName => schemaName.substring(1);

  // SchemaData
  String get dataName => '${modelName}Data';

  // SchemaDependency
  String get dependencyName => '${modelName}Dependency';

  // SchemaEntity
  String get entityName => '${modelName}Entity';
}

class _Model extends Model {
  final String displayName;

  const _Model({
    required String name,
    required String displayName,
    required super.uidType,
    required super.repositoryName,
  })  : displayName = name,
        super(
          name: displayName,
        );
}

class _OrmWriter {
  final _Model model;
  final ModelVisitor visitor;
  final String name;

  const _OrmWriter({
    required this.model,
    required this.visitor,
    required this.name,
  });

  void _writeDataClass(StringSink sink) {
    sink.writeln('@JsonSerializable(anyMap: true, explicitToJson: true)');
    sink.writeln('class ${name}Data {');

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
    sink.writeln('factory ${name}Data.fromJson(Map json) =>');
    sink.writeln('_\$${name}DataFromJson(json);');
    sink.writeln();

    // Constructors
    sink.writeln();
    sink.write('const ${name}Data(');
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
    sink.writeln('_\$${name}DataToJson(this);');
    sink.writeln();

    sink.writeln('}');
  }

  void _writeModelClass(StringSink sink) {
    sink.writeln('@JsonSerializable(anyMap: true, explicitToJson: true)');
    sink.writeln('class $name extends ${name}Data implements ${model.name} {');

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
    sink.writeln('factory $name.fromJson(String id, Map json) =>');
    sink.writeln("_\$${name}FromJson({...json, '_id': id});");

    // Constructor
    sink.writeln();
    sink.writeln('const $name({');
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
    sink.writeln('..._\$${name}ToJson(this)..remove(\'_id\'),');
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
    sink.writeln('class ${name}Dependency extends Dependency<${name}Data> {');
    for (FieldElement element in visitor.foreignFields.keys) {
      sink.writeln('final ${element.type} ${element.name};');
    }
    sink.writeln();
    if (visitor.foreignFields.isEmpty) {
      sink.writeln('const ${name}Dependency() : super.strong();');
    } else {
      sink.writeln('${name}Dependency({');
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
    sink.writeln('class ${name}Entity implements ');
    sink.writeln('Entity<${name}Data, $name> {');

    // Constructors
    sink.writeln('const ${name}Entity._();');
    sink.writeln();

    // tableName
    sink.writeln('@override');
    sink.writeln('String get tableName => \'${model.displayName}\';');
    sink.writeln();

    // fromData
    sink.writeln('@override');
    sink.writeln('$name fromData(');
    sink.writeln('${name}Dependency dependency,');
    sink.writeln('String id,');
    sink.writeln('${name}Data data,');
    sink.writeln(') {');
    sink.writeln('return $name(');
    final UidType uidType = model.uidType;
    sink.writeln(uidType.when(
      caseSimple: () => 'id: id,',
      caseComposite: () => 'id: dependency.key(id),',
      caseSameAs: (type) {
        final ForeignReferrer referrer = type as ForeignReferrer;
        for (MapEntry<FieldElement, ForeignField> entry
            in visitor.foreignFields.entries) {
          final ForeignReferrer currentReferrer =
              entry.value.referTo as ForeignReferrer;
          if (currentReferrer.name != referrer.name) continue;
          return 'id: dependency.${entry.key.name},';
        }
        throw StateError('invalid reference on UidType.sameAs: '
            '${referrer.name}');
      },
    ));
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
    sink.writeln('$name fromJson(String id, Map json) =>');
    sink.writeln('$name.fromJson(id, json);');
    sink.writeln();

    // identify
    sink.writeln('@override');
    sink.writeln('String identify($name model) => model.id;');
    sink.writeln();

    // toJson
    sink.writeln('@override');
    sink.writeln('Map toJson(${name}Data data) => data.toJson();');

    sink.writeln('}');
  }

  String write() {
    final StringBuffer buffer = StringBuffer();
    buffer.writeln('// **************************************************');
    buffer.writeln('//     DORM: $name');
    buffer.writeln('// **************************************************');
    buffer.writeln();
    _writeDataClass(buffer);
    _writeModelClass(buffer);
    _writeDependencyClass(buffer);
    _writeEntityClass(buffer);
    return buffer.toString();
  }
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

    final String name = element.name?.substring(1) ?? '';
    final _Model model = _Model(
      name: annotation.read('name').stringValue,
      displayName: element.name ?? '',
      repositoryName: annotation.read('repositoryName').literalValue as String?,
      uidType: () {
        final ConstantReader reader = annotation.read('uidType');
        final String uidTypeName =
            reader.objectValue.type!.getDisplayString(withNullability: false);

        switch (uidTypeName) {
          case '_SimpleUidType':
            return const UidType.simple();
          case '_CompositeUidType':
            return const UidType.composite();
          case '_SameAsUidType':
            final ForeignReferrer referrer = ForeignReferrer(
              name: reader
                  .read('type')
                  .typeValue
                  .getDisplayString(withNullability: false),
            );
            return UidType.sameAs(referrer);
        }
        throw StateError('invalid uid type: $uidTypeName');
      }(),
    );
    _visitedModels.add(_Model(
      name: name,
      displayName: model.name,
      repositoryName: model.repositoryName,
      uidType: model.uidType,
    ));
    return _OrmWriter(model: model, visitor: visitor, name: name).write();
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
      buffer.writeln('Repository<${model.displayName}Data, ');
      buffer.writeln('${model.displayName}> get ${model.repositoryName} =>');
      buffer.writeln('Repository(root: _root, entity: const ');
      buffer.writeln('${model.displayName}Entity._());');
      buffer.writeln();
    }
    buffer.writeln('}');
    _visitedModels.clear();

    return '$buffer';
  }
}
