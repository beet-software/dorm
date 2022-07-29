// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'social_network.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserData _$UserDataFromJson(Map json) {
  $checkKeys(
    json,
    requiredKeys: const ['birth-date', 'email', 'picture-url'],
    disallowNullValues: const ['birth-date', 'email', 'picture-url'],
  );
  return UserData(
    name: json['name'] as String?,
    birthDate: DateTime.parse(json['birth-date'] as String),
    email: json['email'] as String,
    pictureUrl: Uri.parse(json['picture-url'] as String),
  );
}

Map<String, dynamic> _$UserDataToJson(UserData instance) => <String, dynamic>{
      'name': instance.name,
      'birth-date': instance.birthDate.toIso8601String(),
      'email': instance.email,
      'picture-url': instance.pictureUrl.toString(),
    };

User _$UserFromJson(Map json) {
  $checkKeys(
    json,
    requiredKeys: const ['birth-date', 'email', 'picture-url', '_id'],
    disallowNullValues: const ['birth-date', 'email', 'picture-url', '_id'],
  );
  return User(
    id: json['_id'] as String,
    name: json['name'] as String?,
    birthDate: DateTime.parse(json['birth-date'] as String),
    email: json['email'] as String,
    pictureUrl: Uri.parse(json['picture-url'] as String),
  );
}

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
      'name': instance.name,
      'birth-date': instance.birthDate.toIso8601String(),
      'email': instance.email,
      'picture-url': instance.pictureUrl.toString(),
      '_id': instance.id,
    };

PostData _$PostDataFromJson(Map json) {
  $checkKeys(
    json,
    requiredKeys: const ['contents', 'creation-date'],
    disallowNullValues: const ['contents', 'creation-date'],
  );
  return PostData(
    contents: json['contents'] as String,
    creationDate: DateTime.parse(json['creation-date'] as String),
  );
}

Map<String, dynamic> _$PostDataToJson(PostData instance) => <String, dynamic>{
      'contents': instance.contents,
      'creation-date': instance.creationDate.toIso8601String(),
    };

Post _$PostFromJson(Map json) {
  $checkKeys(
    json,
    requiredKeys: const ['contents', 'creation-date', '_id', 'user-id'],
    disallowNullValues: const ['contents', 'creation-date', '_id', 'user-id'],
  );
  return Post(
    id: json['_id'] as String,
    contents: json['contents'] as String,
    creationDate: DateTime.parse(json['creation-date'] as String),
    userId: json['user-id'] as String,
  );
}

Map<String, dynamic> _$PostToJson(Post instance) => <String, dynamic>{
      'contents': instance.contents,
      'creation-date': instance.creationDate.toIso8601String(),
      '_id': instance.id,
      'user-id': instance.userId,
    };

MessageData _$MessageDataFromJson(Map json) {
  $checkKeys(
    json,
    requiredKeys: const ['contents', 'creation-date'],
    disallowNullValues: const ['contents', 'creation-date'],
  );
  return MessageData(
    contents: json['contents'] as String,
    creationDate: DateTime.parse(json['creation-date'] as String),
  );
}

Map<String, dynamic> _$MessageDataToJson(MessageData instance) =>
    <String, dynamic>{
      'contents': instance.contents,
      'creation-date': instance.creationDate.toIso8601String(),
    };

Message _$MessageFromJson(Map json) {
  $checkKeys(
    json,
    requiredKeys: const [
      'contents',
      'creation-date',
      '_id',
      'sender-id',
      'receiver-id'
    ],
    disallowNullValues: const [
      'contents',
      'creation-date',
      '_id',
      'sender-id',
      'receiver-id'
    ],
  );
  return Message(
    id: json['_id'] as String,
    contents: json['contents'] as String,
    creationDate: DateTime.parse(json['creation-date'] as String),
    senderId: json['sender-id'] as String,
    receiverId: json['receiver-id'] as String,
  );
}

Map<String, dynamic> _$MessageToJson(Message instance) => <String, dynamic>{
      'contents': instance.contents,
      'creation-date': instance.creationDate.toIso8601String(),
      '_id': instance.id,
      'sender-id': instance.senderId,
      'receiver-id': instance.receiverId,
    };
