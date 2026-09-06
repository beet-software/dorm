import 'dart:io';

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:dartx/dartx.dart';

extension _Props<T extends Object> on T {
  R? ifType<R extends Object>() {
    final T value = this;
    return value is R ? value : null;
  }
}

void main(List<String> args) {
  final String? path = args.singleOrNull;
  if (path == null) throw StateError('a single argument must be passed (path)');

  final ParseStringResult result = parseFile(
    path: path,
    featureSet: FeatureSet.latestLanguageVersion(),
  );

  final List<String> statements = [];

  for (CompilationUnitMember classElement in result.unit.declarations) {
    if (classElement is! ClassDeclaration) continue;

    final String? tableName = classElement.metadata
        .firstOrNullWhere((annotation) => annotation.name.name == 'Model')
        ?.arguments
        ?.arguments
        .whereType<NamedArgument>()
        .firstOrNullWhere((expression) => expression.name.lexeme == 'name')
        ?.argumentExpression
        .ifType<SimpleStringLiteral>()
        ?.value;

    final List<_PrimaryKey> primaryKeys = _primaryKeys(classElement);

    final StringBuffer buffer = StringBuffer();
    buffer
      ..write('CREATE TABLE IF NOT EXISTS ')
      ..write(tableName)
      ..writeln(' (');
    for (final _PrimaryKey primaryKey in primaryKeys) {
      buffer
        ..write('  ')
        ..write(primaryKey.columnName)
        ..write(' ')
        ..write(primaryKey.sqlType)
        ..writeln(' NOT NULL,');
    }
    for (ClassMember classMemberElement in classElement.body.members) {
      if (classMemberElement is! MethodDeclaration) continue;
      if (!classMemberElement.isGetter) continue;

      if (primaryKeys.any(
        (primaryKey) => primaryKey.fieldName == classMemberElement.name?.lexeme,
      )) {
        continue;
      }

      final String? columnName = classMemberElement.metadata
          .firstOrNullWhere(
              (annotation) =>
                  annotation.name.name == 'Field' ||
                  annotation.name.name == 'ForeignField')
          ?.arguments
          ?.arguments
          .whereType<NamedArgument>()
          .firstOrNullWhere(
              (expression) => expression.name.lexeme == 'name')
          ?.argumentExpression
          .ifType<SimpleStringLiteral>()
          ?.value;
      if (columnName == null) continue;

      final TypeAnnotation? methodReturnType = classMemberElement.returnType;
      if (methodReturnType == null) continue;

      final String typeName = methodReturnType.beginToken.lexeme;
      final bool nullable = methodReturnType.question != null;
      final String columnType = const {
        'String': 'VARCHAR',
        'int': 'INTEGER',
        'bool': 'BOOLEAN',
        'double': 'DOUBLE',
      }[typeName]!;

      buffer
        ..write('  ')
        ..write(columnName)
        ..write(' ')
        ..write(columnType)
        ..write(nullable ? '' : ' NOT NULL')
        ..writeln(',');
    }
    buffer
      ..write('  PRIMARY KEY (')
      ..writeAll(primaryKeys.map((primaryKey) => primaryKey.columnName), ', ')
      ..writeln(')');
    buffer.write(');');
    statements.add('$buffer');
  }
  stdout.write(statements.join('\n'));
}

class _PrimaryKey {
  final String? fieldName;
  final String columnName;
  final String sqlType;

  const _PrimaryKey({
    required this.fieldName,
    required this.columnName,
    required this.sqlType,
  });
}

List<_PrimaryKey> _primaryKeys(ClassDeclaration declaration) {
  final Annotation? model = declaration.metadata.firstOrNullWhere(
    (annotation) => annotation.name.name == 'Model',
  );
  final Expression? primaryKey = model?.arguments?.arguments
      .whereType<NamedArgument>()
      .firstOrNullWhere((argument) => argument.name.lexeme == 'primaryKey')
      ?.argumentExpression;
  final List<Expression> specs = primaryKey
          ?.ifType<ListLiteral>()
          ?.elements
          .whereType<Expression>()
          .toList() ??
      const [];

  final List<_PrimaryKey> result = [
    for (final Expression spec in specs)
      if (spec is InstanceCreationExpression) _primaryKey(spec, declaration),
  ];
  if (result.isNotEmpty) return result;
  return const [
    _PrimaryKey(fieldName: null, columnName: 'id', sqlType: 'CHAR(36)'),
  ];
}

_PrimaryKey _primaryKey(
  InstanceCreationExpression spec,
  ClassDeclaration declaration,
) {
  final String specName = spec.constructorName.type.name.lexeme;
  if (specName == 'GeneratedIdSpec') {
    final String columnName = _stringArgument(spec, 'name') ?? 'id';
    final String typeName = _typeArgument(spec, 'type') ?? 'String';
    return _PrimaryKey(
      fieldName: _symbolArgument(spec, 'as') ?? 'id',
      columnName: columnName,
      sqlType: _sqlType(typeName),
    );
  }

  if (specName == 'ExistingIdSpec') {
    final String fieldName = _symbolArgument(spec, 'referTo') ?? 'id';
    final MethodDeclaration? field = declaration.body.members
        .whereType<MethodDeclaration>()
        .firstOrNullWhere((member) => member.name?.lexeme == fieldName);
    final String columnName = field == null
        ? fieldName
        : _fieldColumnName(field) ?? fieldName;
    final String typeName = field?.returnType?.beginToken.lexeme ?? 'String';
    return _PrimaryKey(
      fieldName: fieldName,
      columnName: columnName,
      sqlType: _sqlType(typeName),
    );
  }

  return const _PrimaryKey(
    fieldName: null,
    columnName: 'id',
    sqlType: 'CHAR(36)',
  );
}

String? _stringArgument(InstanceCreationExpression expression, String name) {
  return expression.argumentList.arguments
      .whereType<NamedArgument>()
      .firstOrNullWhere((argument) => argument.name.lexeme == name)
      ?.argumentExpression
      .ifType<SimpleStringLiteral>()
      ?.value;
}

String? _typeArgument(InstanceCreationExpression expression, String name) {
  final Expression? argument = expression.argumentList.arguments
      .whereType<NamedArgument>()
      .firstOrNullWhere((argument) => argument.name.lexeme == name)
      ?.argumentExpression;
  return argument?.toSource().split('.').last;
}

String? _symbolArgument(InstanceCreationExpression expression, String name) {
  final Expression? argument = expression.argumentList.arguments
      .whereType<NamedArgument>()
      .firstOrNullWhere((argument) => argument.name.lexeme == name)
      ?.argumentExpression;
  final String? source = argument?.toSource();
  return source?.startsWith('#') == true ? source!.substring(1) : null;
}

String? _fieldColumnName(MethodDeclaration field) {
  return field.metadata
      .firstOrNullWhere(
          (annotation) =>
              annotation.name.name == 'Field' ||
              annotation.name.name == 'ForeignField')
      ?.arguments
      ?.arguments
      .whereType<NamedArgument>()
      .firstOrNullWhere((argument) => argument.name.lexeme == 'name')
      ?.argumentExpression
      .ifType<SimpleStringLiteral>()
      ?.value;
}

String _sqlType(String typeName) {
  return const {
        'String': 'VARCHAR',
        'int': 'INTEGER',
        'bool': 'BOOLEAN',
        'double': 'DOUBLE',
      }[typeName] ??
      'VARCHAR';
}
