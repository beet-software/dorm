import 'package:dorm_annotations/dorm_annotations.dart';
import 'package:dorm_framework/dorm_framework.dart';
import 'package:dorm_mysql_database/dorm_mysql_database.dart';

part 'models.dorm.dart';

part 'models.g.dart';

@Model(name: 'Users', as: #users)
abstract class _User {
  @Field(name: 'name')
  String get name;

  @Field(name: 'active')
  bool get active;

  @Field(name: 'age')
  int? get age;
}
