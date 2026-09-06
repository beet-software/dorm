import 'package:dorm_annotations/dorm_annotations.dart';
import 'package:dorm_framework/dorm_framework.dart';
import 'package:dorm_mongo_database/dorm_mongo_database.dart';

part 'models.dorm.dart';
part 'models.g.dart';

@Model(name: 'users', as: #users)
abstract class _User {
  @Field(name: 'name')
  String get name;
}

@Model(name: 'posts', as: #posts)
abstract class _Post {
  @Field(name: 'title')
  String get title;

  @ForeignField(name: 'user_id', referTo: _User, inverseAs: #posts)
  String get userId;
}
