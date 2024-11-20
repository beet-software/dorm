import 'package:dorm_annotations/dorm_annotations.dart';
import 'package:dorm_framework/dorm_framework.dart';

import 'query.dart';

part 'social_network.dorm.dart';
part 'social_network.g.dart';

@Model(name: 'user', as: #users)
abstract class _User {
  @Field(name: 'name')
  String? get name;

  @Field(name: 'birth-date')
  DateTime get birthDate;

  @Field(name: 'email')
  String get email;

  @Field(name: 'picture-url')
  Uri get pictureUrl;
}

@Model(name: 'post')
abstract class _Post {
  @Field(name: 'contents')
  String get contents;

  @Field(name: 'creation-date')
  DateTime get creationDate;

  @ForeignField(name: 'user-id', referTo: _User)
  String get userId;
}

@Model(name: 'message', as: #messages)
abstract class _Message {
  @Field(name: 'contents')
  String get contents;

  @Field(name: 'creation-date')
  DateTime get creationDate;

  @ForeignField(name: 'sender-id', referTo: _User)
  String get senderId;

  @ForeignField(name: 'receiver-id', referTo: _User)
  String get receiverId;
}
