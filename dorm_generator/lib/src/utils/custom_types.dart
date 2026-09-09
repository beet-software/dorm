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

import 'package:analyzer/dart/element/type.dart';
import 'package:dorm_annotations/dorm_annotations.dart';
import 'package:source_gen/source_gen.dart';

import 'orm_node.dart';

extension AdditionalReads on ConstantReader {
  T? enumValueFrom<T extends Enum>(List<T> values) {
    if (isNull) return null;
    return values[objectValue.getField('index')!.toIntValue()!];
  }
}

class $Type implements Type {
  final ConstantReader reader;

  const $Type({required this.reader});

  String? get name {
    if (reader.isNull) return null;
    if (!reader.isType) return null;
    return reader.typeValue.getDisplayString();
  }

  DartType? get dartType {
    if (reader.isNull || !reader.isType) return null;
    return reader.typeValue;
  }

  @override
  String toString() => '\$Type($name)';
}

class $ModelFieldTemplate implements ModelFieldTemplate {
  final ConstantReader reader;

  const $ModelFieldTemplate({required this.reader});

  String? get name {
    if (reader.isNull) return null;
    final String? typeLabel = reader.objectValue.type?.getDisplayString();
    if (typeLabel == null) return null;
    final Match? match = RegExp(
      'ModelFieldTemplate<(.*)>',
    ).matchAsPrefix(typeLabel);
    if (match == null) return null;
    return match.group(1);
  }

  @override
  String toString() => '\$ModelFieldTemplate($name)';
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

class $ConcreteSymbol extends $Symbol {
  final String _defaultName;

  const $ConcreteSymbol({required super.reader, required String defaultName})
    : _defaultName = defaultName;

  @override
  String get name => super.name ?? _defaultName;
}

extension FieldFilter on Field {
  bool isA<F extends Field>() => this is F;

  /// If a field belongs to a schema.
  bool get isConcrete => this is! DerivedField;

  /// If a field is generated from other model fields.
  bool get isDerived => this is DerivedField;

  // If a field belongs exclusively to a dORM model class.
  bool get isForeign => this is ForeignField;

  /// If a field belongs exclusively to a dORM data class.
  bool get isNative => isConcrete && !isForeign;
}

extension FieldFiltering on Map<String, FieldOrmNode> {
  Map<String, FieldOrmNode> where(bool Function(Field field) filter) {
    return {
      for (MapEntry<String, FieldOrmNode> entry in entries)
        if (filter(entry.value.annotation)) entry.key: entry.value,
    };
  }
}

