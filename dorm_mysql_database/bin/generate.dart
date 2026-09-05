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
        .whereType<NamedExpression>()
        .firstOrNullWhere((expression) => expression.name.label.name == 'name')
        ?.expression
        .ifType<SimpleStringLiteral>()
        ?.value;

    final StringBuffer buffer = StringBuffer();
    buffer
      ..write('CREATE TABLE IF NOT EXISTS ')
      ..write(tableName)
      ..writeln(' (');
    buffer.writeln('  id CHAR(36) NOT NULL,');
    for (ClassMember classMemberElement in classElement.members) {
      if (classMemberElement is! MethodDeclaration) continue;
      if (!classMemberElement.isGetter) continue;

      final String? columnName = classMemberElement.metadata
          .firstOrNullWhere((annotation) => annotation.name.name == 'Field')
          ?.arguments
          ?.arguments
          .whereType<NamedExpression>()
          .firstOrNullWhere(
              (expression) => expression.name.label.name == 'name')
          ?.expression
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
    buffer.writeln('  PRIMARY KEY (id)');
    buffer.write(');');
    statements.add('$buffer');
  }
  stdout.write(statements.join('\n'));
}
