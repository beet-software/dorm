// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'drawing.dart';

// **************************************************************************
// OrmGenerator
// **************************************************************************

enum ShapeType {
  rectangle,
  circle,
}

abstract class Shape implements _Shape {
  factory Shape.fromType(ShapeType type, Map json) {
    switch (type) {
      case ShapeType.rectangle:
        return Rectangle.fromJson(json);
      case ShapeType.circle:
        return Circle.fromJson(json);
    }
  }

  const Shape._();

  ShapeType get type;

  Map<String, Object?> toJson();
}

@JsonSerializable(anyMap: true, explicitToJson: true)
class Rectangle extends Shape implements _Rectangle {
  @override
  @JsonKey(name: 'largura', required: true, disallowNullValue: true)
  final double width;

  @override
  @JsonKey(name: 'altura', required: true, disallowNullValue: true)
  final double height;

  factory Rectangle.fromJson(Map json) => _$RectangleFromJson(json);

  const Rectangle({
    required this.width,
    required this.height,
  }) : super._();

  @override
  ShapeType get type => ShapeType.rectangle;

  @override
  Map<String, Object?> toJson() => _$RectangleToJson(this);
}

@JsonSerializable(anyMap: true, explicitToJson: true)
class Circle extends Shape implements _Circle {
  @override
  @JsonKey(name: 'raio', required: true, disallowNullValue: true)
  final double radius;

  factory Circle.fromJson(Map json) => _$CircleFromJson(json);

  const Circle({
    required this.radius,
  }) : super._();

  @override
  ShapeType get type => ShapeType.circle;

  @override
  Map<String, Object?> toJson() => _$CircleToJson(this);
}

// **************************************************
//     DORM: Drawing
// **************************************************

@JsonSerializable(anyMap: true, explicitToJson: true, constructor: '_')
class DrawingData {
  @JsonKey(name: 'cor', required: true, disallowNullValue: true)
  final String color;

  @JsonKey(name: 'tipo', required: true, disallowNullValue: true)
  final ShapeType type;

  @JsonKey(name: 'formato', required: true, disallowNullValue: true)
  final Shape shape;

  factory DrawingData.fromJson(Map json) => _$DrawingDataFromJson(json);

  factory DrawingData._({
    required String color,
    required ShapeType type,
    required Map shape,
  }) {
    return DrawingData(
      color: color,
      type: type,
      shape: Shape.fromType(type, shape),
    );
  }

  const DrawingData({
    required this.color,
    required this.shape,
    required this.type,
  });

  Map<String, Object?> toJson() => _$DrawingDataToJson(this);
}

@JsonSerializable(anyMap: true, explicitToJson: true, constructor: '_')
class Drawing extends DrawingData implements _Drawing {
  @JsonKey(name: '_id', required: true, disallowNullValue: true)
  final String id;

  factory Drawing.fromJson(String id, Map json) =>
      _$DrawingFromJson({...json, '_id': id});

  factory Drawing._({
    required String id,
    required String color,
    required ShapeType type,
    required Map shape,
  }) {
    final DrawingData data = DrawingData._(
      color: color,
      type: type,
      shape: shape,
    );
    return Drawing(
      id: id,
      color: data.color,
      type: data.type,
      shape: data.shape,
    );
  }

  const Drawing({
    required this.id,
    required super.color,
    required super.type,
    required super.shape,
  });

  @override
  Map<String, Object?> toJson() {
    return {
      ..._$DrawingToJson(this)..remove('_id'),
    };
  }
}

class DrawingDependency extends Dependency<DrawingData> {
  const DrawingDependency() : super.strong();
}

class DrawingEntity implements Entity<DrawingData, Drawing> {
  const DrawingEntity._();

  @override
  String get tableName => 'desenho';

  @override
  Drawing fromData(
    DrawingDependency dependency,
    String id,
    DrawingData data,
  ) {
    return Drawing(
      id: id,
      color: data.color,
      type: data.type,
      shape: data.shape,
    );
  }

  @override
  Drawing fromJson(String id, Map json) => Drawing.fromJson(id, json);

  @override
  String identify(Drawing model) => model.id;

  @override
  Map toJson(DrawingData data) => data.toJson();
}

// **************************************************
//     DORM
// **************************************************

class Dorm {
  final Reference _root;

  const Dorm(this._root);

  Repository<DrawingData, Drawing> get drawings =>
      Repository(root: _root, entity: const DrawingEntity._());
}