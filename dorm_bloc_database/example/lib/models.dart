import 'package:dorm/dorm.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:dorm_annotations/dorm_annotations.dart';

part 'models.g.dart';
part 'models.dorm.dart';

@Model(name: 'users', as: #users)
abstract class _User {
  @Field(name: 'name')
  String get name;
}