// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'drawing.dart';

// **************************************************************************
// OrmGenerator
// **************************************************************************

@JsonSerializable(
  anyMap: true,
  explicitToJson: true,
  constructor: '_',
)
class DrawingData {
  factory DrawingData.fromJson(Map json) => _$DrawingDataFromJson(json);

  factory DrawingData._({
    required String color,
    required ShapeType type,
    required Map shape,
  }) {
    return DrawingData(
      color: color,
      type: type,
      shape: Shape.fromType(
        type,
        shape,
      ),
    );
  }

  const DrawingData({
    required this.color,
    required this.shape,
    required this.type,
  });

  @JsonKey(
    name: 'cor',
    required: true,
    disallowNullValue: true,
  )
  final String color;

  @JsonKey(
    name: 'tipo',
    required: true,
    disallowNullValue: true,
  )
  final ShapeType type;

  @JsonKey(
    name: 'formato',
    required: true,
    disallowNullValue: true,
  )
  final Shape shape;

  Map<String, Object?> toJson() => _$DrawingDataToJson(this);
}

@JsonSerializable(
  anyMap: true,
  explicitToJson: true,
  constructor: '_',
)
class Drawing extends DrawingData implements _Drawing {
  factory Drawing.fromJson(
    String id,
    Map json,
  ) =>
      _$DrawingFromJson({
        ...json,
        '_id': id,
      });

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

  @JsonKey(
    name: '_id',
    required: true,
    disallowNullValue: true,
  )
  final String id;

  @override
  Map<String, Object?> toJson() {
    return {..._$DrawingToJson(this)..remove('_id')};
  }
}

class DrawingDependency extends Dependency<DrawingData> {
  const DrawingDependency() : super.strong();
}

class DrawingEntity implements Entity<DrawingData, Drawing> {
  const DrawingEntity();

  @override
  final String tableName = 'desenho';

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
  Drawing convert(
    Drawing model,
    DrawingData data,
  ) =>
      model.copyWith(data);
  @override
  Drawing fromJson(
    String id,
    Map json,
  ) =>
      Drawing.fromJson(
        id,
        json,
      );
  @override
  String identify(Drawing model) => model.id;
  @override
  Map<String, Object?> toJson(DrawingData data) => data.toJson();
}

extension DrawingProperties on Drawing {
  Drawing copyWith(DrawingData data) {
    return Drawing(
      id: id,
      color: data.color,
      type: data.type,
      shape: data.shape,
    );
  }
}

enum ShapeType { rectangle, circular }

abstract class Shape implements _Shape {
  factory Shape.fromType(
    ShapeType type,
    Map json,
  ) {
    switch (type) {
      case ShapeType.rectangle:
        return Rectangle.fromJson(json);
      case ShapeType.circular:
        return Circle.fromJson(json);
    }
  }

  ShapeType get type;
  Map<String, Object?> toJson();
}

@JsonSerializable(
  anyMap: true,
  explicitToJson: true,
)
class Rectangle implements Shape, _Rectangle {
  factory Rectangle.fromJson(Map json) => _$RectangleFromJson(json);

  const Rectangle({
    required this.width,
    required this.height,
  });

  @override
  @JsonKey(
    name: 'largura',
    required: true,
    disallowNullValue: true,
  )
  final double width;

  @override
  @JsonKey(
    name: 'altura',
    required: true,
    disallowNullValue: true,
  )
  final double height;

  @override
  final ShapeType type = ShapeType.rectangle;

  @override
  Map<String, Object?> toJson() => _$RectangleToJson(this);
}

@JsonSerializable(
  anyMap: true,
  explicitToJson: true,
)
class Circle implements Shape, _Circle {
  factory Circle.fromJson(Map json) => _$CircleFromJson(json);

  const Circle({required this.radius});

  @override
  @JsonKey(
    name: 'raio',
    required: true,
    disallowNullValue: true,
  )
  final double radius;

  @override
  final ShapeType type = ShapeType.circular;

  @override
  Map<String, Object?> toJson() => _$CircleToJson(this);
}

class Dorm {
  const Dorm(this._engine);

  final BaseEngine _engine;

  DatabaseEntity<DrawingData, Drawing> get drawings => DatabaseEntity(
        const DrawingEntity(),
        engine: _engine,
      );
}
