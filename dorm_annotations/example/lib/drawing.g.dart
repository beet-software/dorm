// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'drawing.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

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
  return Circle(
    radius: (json['raio'] as num).toDouble(),
  );
}

Map<String, dynamic> _$CircleToJson(Circle instance) => <String, dynamic>{
      'raio': instance.radius,
    };

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
  ShapeType.circle: 'circle',
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
