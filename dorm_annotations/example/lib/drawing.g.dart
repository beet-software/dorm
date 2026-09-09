// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'drawing.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$DrawingCWProxy {
  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored.
  ///
  /// Example:
  /// ```dart
  /// Drawing(...).copyWith(id: 12, name: "My name")
  /// ```
  Drawing call({String id, String color, ShapeType type, Shape shape});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfDrawing.copyWith(...)`.
class _$DrawingCWProxyImpl implements _$DrawingCWProxy {
  const _$DrawingCWProxyImpl(this._value);

  final Drawing _value;

  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored.
  ///
  /// Example:
  /// ```dart
  /// Drawing(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  Drawing call({
    Object? id = const $CopyWithPlaceholder(),
    Object? color = const $CopyWithPlaceholder(),
    Object? type = const $CopyWithPlaceholder(),
    Object? shape = const $CopyWithPlaceholder(),
  }) {
    return Drawing(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      color: color == const $CopyWithPlaceholder() || color == null
          ? _value.color
          // ignore: cast_nullable_to_non_nullable
          : color as String,
      type: type == const $CopyWithPlaceholder() || type == null
          ? _value.type
          // ignore: cast_nullable_to_non_nullable
          : type as ShapeType,
      shape: shape == const $CopyWithPlaceholder() || shape == null
          ? _value.shape
          // ignore: cast_nullable_to_non_nullable
          : shape as Shape,
    );
  }
}

extension $DrawingCopyWith on Drawing {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfDrawing.copyWith(...)`.
  // ignore: library_private_types_in_public_api
  _$DrawingCWProxy get copyWith => _$DrawingCWProxyImpl(this);
}

abstract class _$RectangleCWProxy {
  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored.
  ///
  /// Example:
  /// ```dart
  /// Rectangle(...).copyWith(id: 12, name: "My name")
  /// ```
  Rectangle call({double width, double height});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfRectangle.copyWith(...)`.
class _$RectangleCWProxyImpl implements _$RectangleCWProxy {
  const _$RectangleCWProxyImpl(this._value);

  final Rectangle _value;

  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored.
  ///
  /// Example:
  /// ```dart
  /// Rectangle(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  Rectangle call({
    Object? width = const $CopyWithPlaceholder(),
    Object? height = const $CopyWithPlaceholder(),
  }) {
    return Rectangle(
      width: width == const $CopyWithPlaceholder() || width == null
          ? _value.width
          // ignore: cast_nullable_to_non_nullable
          : width as double,
      height: height == const $CopyWithPlaceholder() || height == null
          ? _value.height
          // ignore: cast_nullable_to_non_nullable
          : height as double,
    );
  }
}

extension $RectangleCopyWith on Rectangle {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfRectangle.copyWith(...)`.
  // ignore: library_private_types_in_public_api
  _$RectangleCWProxy get copyWith => _$RectangleCWProxyImpl(this);
}

abstract class _$CircleCWProxy {
  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored.
  ///
  /// Example:
  /// ```dart
  /// Circle(...).copyWith(id: 12, name: "My name")
  /// ```
  Circle call({double radius});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfCircle.copyWith(...)`.
class _$CircleCWProxyImpl implements _$CircleCWProxy {
  const _$CircleCWProxyImpl(this._value);

  final Circle _value;

  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored.
  ///
  /// Example:
  /// ```dart
  /// Circle(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  Circle call({Object? radius = const $CopyWithPlaceholder()}) {
    return Circle(
      radius: radius == const $CopyWithPlaceholder() || radius == null
          ? _value.radius
          // ignore: cast_nullable_to_non_nullable
          : radius as double,
    );
  }
}

extension $CircleCopyWith on Circle {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfCircle.copyWith(...)`.
  // ignore: library_private_types_in_public_api
  _$CircleCWProxy get copyWith => _$CircleCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DrawingData _$DrawingDataFromJson(Map json) {
  $checkKeys(
    json,
    requiredKeys: const ['cor', 'tipo', 'formato'],
    disallowNullValues: const ['cor', 'tipo', 'formato'],
  );
  return DrawingData._(
    color: json['cor'] as String,
    type: $enumDecode(_$ShapeTypeEnumMap, json['tipo']),
    shape: json['formato'] as Map,
  );
}

Map<String, dynamic> _$DrawingDataToJson(DrawingData instance) =>
    <String, dynamic>{
      'cor': instance.color,
      'tipo': _$ShapeTypeEnumMap[instance.type]!,
      'formato': instance.shape.toJson(),
    };

const _$ShapeTypeEnumMap = {
  ShapeType.rectangle: 'rectangle',
  ShapeType.circular: 'circular',
};

Drawing _$DrawingFromJson(Map json) {
  $checkKeys(
    json,
    requiredKeys: const ['cor', 'tipo', 'formato', '_id'],
    disallowNullValues: const ['cor', 'tipo', 'formato', '_id'],
  );
  return Drawing._(
    id: json['_id'] as String,
    color: json['cor'] as String,
    type: $enumDecode(_$ShapeTypeEnumMap, json['tipo']),
    shape: json['formato'] as Map,
  );
}

Map<String, dynamic> _$DrawingToJson(Drawing instance) => <String, dynamic>{
  'cor': instance.color,
  'tipo': _$ShapeTypeEnumMap[instance.type]!,
  'formato': instance.shape.toJson(),
  '_id': instance.id,
};

Rectangle _$RectangleFromJson(Map json) {
  $checkKeys(
    json,
    requiredKeys: const ['largura', 'altura'],
    disallowNullValues: const ['largura', 'altura'],
  );
  return Rectangle(
    width: (json['largura'] as num).toDouble(),
    height: (json['altura'] as num).toDouble(),
  );
}

Map<String, dynamic> _$RectangleToJson(Rectangle instance) => <String, dynamic>{
  'largura': instance.width,
  'altura': instance.height,
};

Circle _$CircleFromJson(Map json) {
  $checkKeys(
    json,
    requiredKeys: const ['raio'],
    disallowNullValues: const ['raio'],
  );
  return Circle(radius: (json['raio'] as num).toDouble());
}

Map<String, dynamic> _$CircleToJson(Circle instance) => <String, dynamic>{
  'raio': instance.radius,
};
