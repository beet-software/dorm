import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:dorm_annotations/dorm_annotations.dart';
import 'package:source_gen/source_gen.dart';

import 'annotation_parser.dart';

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

/// Holds the static analysis data inside [Model].
class $Model extends Model {
  final Map<String, $ModelField> fields;

  Map<String, $ModelField> _filter<T extends Field>() => Map.unmodifiable({
        for (MapEntry<String, $ModelField> entry in fields.entries)
          if (entry.value.field is T) entry.key: entry.value,
      });

  Map<String, $ModelField> get foreignFields => _filter<ForeignField>();

  Map<String, $ModelField> get queryFields => _filter<QueryField>();

  Map<String, $ModelField> get ownFields => Map.unmodifiable({
        for (MapEntry<String, $ModelField> entry in fields.entries)
          if (entry.value.field is! QueryField) entry.key: entry.value,
      });

  Map<String, $ModelField> get dataFields => Map.unmodifiable({
        for (MapEntry<String, $ModelField> entry in fields.entries)
          if (entry.value.field is! ForeignField &&
              entry.value.field is! QueryField)
            entry.key: entry.value,
      });

  const $Model({
    required super.name,
    required super.uidType,
    required super.as,
    required this.fields,
  });
}

/// Holds the static analysis data from a field inside [Field].
class $ModelField {
  final Field field;
  final String type;
  final bool required;

  const $ModelField({
    required this.field,
    required this.type,
    required this.required,
  });
}

/// Holds the static analysis data inside [CustomUidValue].
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

/// Holds the static analysis data inside [PolymorphicData].
class $PolymorphicData extends PolymorphicData {
  final Map<String, $PolymorphicDataField> fields;

  static $PolymorphicData? parse(ClassElement element) {
    const PolymorphicDataParser parser = PolymorphicDataParser();
    final PolymorphicData? annotation = parser.parseElement(element);
    if (annotation == null) return null;
    return $PolymorphicData(
      name: annotation.name,
      fields: Map.fromEntries(
        element.accessors
            .where((accessor) => accessor.isGetter)
            .map<MapEntry<String, $PolymorphicDataField>?>((accessor) {
          final $PolymorphicDataField? field =
              $PolymorphicDataField.parse(accessor);
          if (field == null) return null;
          return MapEntry(accessor.name, field);
        }).whereType<MapEntry<String, $PolymorphicDataField>>(),
      ),
    );
  }

  const $PolymorphicData({
    required super.name,
    required this.fields,
  });

  @override
  String toString() {
    return '\$PolymorphicData{fields: $fields}';
  }
}

/// Holds the static analysis data from a field inside [PolymorphicData].
class $PolymorphicDataField extends Field {
  final String type;
  final bool required;

  static $PolymorphicDataField? parse(PropertyAccessorElement element) {
    final Field? field = const FieldParser().parseElement(element);
    if (field == null) return null;

    return $PolymorphicDataField(
      name: field.name,
      type: element.returnType.getDisplayString(withNullability: true),
      required: element.returnType.nullabilitySuffix == NullabilitySuffix.none,
    );
  }

  const $PolymorphicDataField({
    required super.name,
    required this.type,
    required this.required,
  });

  @override
  String toString() {
    return '\$PolymorphicDataField<$type>($name)';
  }
}
