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

import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:dorm_annotations/dorm_annotations.dart';
import 'package:source_gen/source_gen.dart';

import 'orm_node.dart';

extension AdditionalReads on ConstantReader {
  T? enumValueFrom<T extends Enum>(List<T> values) {
    if (isNull) return null;
    return values[objectValue.getField('index')!.toIntValue()!];
  }

  String get functionName {
    final DartObject obj = objectValue;
    final ExecutableElement element = obj.toFunctionValue()!;

    final String name = element.name;
    assert(element.isStatic);
    final String? className = element.enclosingElement.name;
    final String prefix = className == null ? '' : '$className.';
    return '$prefix$name';
  }
}

class $Type implements Type {
  final ConstantReader reader;

  const $Type({required this.reader});

  String? get name {
    if (reader.isNull) return null;
    if (!reader.isType) return null;
    return reader.typeValue.getDisplayString(withNullability: false);
  }

  @override
  String toString() => '\$Type($name);';
}

class $Symbol implements Symbol {
  final ConstantReader reader;

  const $Symbol({required this.reader});

  String? get name {
    if (reader.isNull) return null;
    if (!reader.isSymbol) return null;
    return reader.objectValue.toSymbolValue();
  }

  @override
  String toString() => '\$Symbol($name);';
}

abstract class FieldFilter {
  static bool isA<F extends Field>(Field field) => field is F;

  /// If a field belongs to a schema.
  static bool belongsToSchema(Field field) => field is! QueryField;

  // If a field belongs exclusively to a dORM model class.
  static bool belongsToModel(Field field) => field is ForeignField;

  /// If a field belongs exclusively to a dORM data class.
  static bool belongsToData(Field field) {
    return belongsToSchema(field) && !belongsToModel(field);
  }
}

extension FieldFiltering on Map<String, FieldOrmNode> {
  Map<String, FieldOrmNode> where(bool Function(Field field) filter) {
    return {
      for (MapEntry<String, FieldOrmNode> entry in entries)
        if (filter(entry.value.annotation)) entry.key: entry.value,
    };
  }
}

class $CustomUidValue implements CustomUidValue {
  final ConstantReader reader;

  const $CustomUidValue(this.reader);

  @override
  T when<T>({
    required T Function() caseSimple,
    required T Function() caseComposite,
    required T Function(String id) caseValue,
  }) {
    throw UnimplementedError();
  }
}
