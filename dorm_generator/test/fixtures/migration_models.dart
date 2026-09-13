// ignore_for_file: unused_element

import 'package:dorm_annotations/dorm_annotations.dart';

@Model(name: 'users', as: #users)
abstract class _User {
  @Field(name: 'name')
  String get name;

  @Field(name: 'active')
  bool get active;
}
