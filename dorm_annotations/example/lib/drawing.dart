import 'package:dorm_framework/dorm_framework.dart';
import 'package:dorm_annotations/dorm_annotations.dart';

part 'drawing.dorm.dart';

part 'drawing.g.dart';

abstract class _Shape {}

@PolymorphicData(name: 'retangulo')
abstract class _Rectangle implements _Shape {
  @Field(name: 'largura')
  double get width;

  @Field(name: 'altura')
  double get height;
}

@PolymorphicData(name: 'circulo', as: #circular)
abstract class _Circle implements _Shape {
  @Field(name: 'raio')
  double get radius;
}

@Model(name: 'desenho', as: #drawings)
abstract class _Drawing {
  @Field(name: 'cor')
  String get color;

  @PolymorphicField(name: 'formato', pivotName: 'tipo')
  _Shape get shape;
}
