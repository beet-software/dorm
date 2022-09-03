import 'package:dorm/dorm.dart';
import 'package:dorm_annotations/dorm_annotations.dart';
import 'package:json_annotation/json_annotation.dart';

part 'social_network.dorm.dart';

part 'social_network.g.dart';

@Model(name: 'user', repositoryName: 'users')
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

@Model(name: 'post', repositoryName: 'posts')
abstract class _Post {
  @Field(name: 'contents')
  String get contents;

  @Field(name: 'creation-date')
  DateTime get creationDate;

  @ForeignField(name: 'user-id', referTo: _User)
  String get userId;
}

@Model(name: 'message', repositoryName: 'messages')
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
