import 'package:dorm_framework/dorm_framework.dart';
import 'package:dorm_annotations/dorm_annotations.dart';

part 'models.g.dart';
part 'models.dorm.dart';

@Model(name: 'users', as: #users)
abstract class _User {
  @Field(name: 'name')
  String get name;
}