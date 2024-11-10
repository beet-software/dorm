// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'social_network.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$UserDataCWProxy {
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored.
  ///
  /// Usage
  /// ```dart
  /// UserData(...).copyWith(id: 12, name: "My name")
  /// ````
  UserData call({
    String? name,
    DateTime? birthDate,
    String? email,
    Uri? pictureUrl,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfUserData.copyWith(...)`.
class _$UserDataCWProxyImpl implements _$UserDataCWProxy {
  const _$UserDataCWProxyImpl(this._value);

  final UserData _value;

  @override

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored.
  ///
  /// Usage
  /// ```dart
  /// UserData(...).copyWith(id: 12, name: "My name")
  /// ````
  UserData call({
    Object? name = const $CopyWithPlaceholder(),
    Object? birthDate = const $CopyWithPlaceholder(),
    Object? email = const $CopyWithPlaceholder(),
    Object? pictureUrl = const $CopyWithPlaceholder(),
  }) {
    return UserData(
      name: name == const $CopyWithPlaceholder()
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String?,
      birthDate: birthDate == const $CopyWithPlaceholder() || birthDate == null
          ? _value.birthDate
          // ignore: cast_nullable_to_non_nullable
          : birthDate as DateTime,
      email: email == const $CopyWithPlaceholder() || email == null
          ? _value.email
          // ignore: cast_nullable_to_non_nullable
          : email as String,
      pictureUrl:
          pictureUrl == const $CopyWithPlaceholder() || pictureUrl == null
              ? _value.pictureUrl
              // ignore: cast_nullable_to_non_nullable
              : pictureUrl as Uri,
    );
  }
}

extension $UserDataCopyWith on UserData {
  /// Returns a callable class that can be used as follows: `instanceOfUserData.copyWith(...)`.
  // ignore: library_private_types_in_public_api
  _$UserDataCWProxy get copyWith => _$UserDataCWProxyImpl(this);
}

abstract class _$UserCWProxy {
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored.
  ///
  /// Usage
  /// ```dart
  /// User(...).copyWith(id: 12, name: "My name")
  /// ````
  User call({
    String? id,
    String? name,
    DateTime? birthDate,
    String? email,
    Uri? pictureUrl,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfUser.copyWith(...)`.
class _$UserCWProxyImpl implements _$UserCWProxy {
  const _$UserCWProxyImpl(this._value);

  final User _value;

  @override

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored.
  ///
  /// Usage
  /// ```dart
  /// User(...).copyWith(id: 12, name: "My name")
  /// ````
  User call({
    Object? id = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? birthDate = const $CopyWithPlaceholder(),
    Object? email = const $CopyWithPlaceholder(),
    Object? pictureUrl = const $CopyWithPlaceholder(),
  }) {
    return User(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      name: name == const $CopyWithPlaceholder()
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String?,
      birthDate: birthDate == const $CopyWithPlaceholder() || birthDate == null
          ? _value.birthDate
          // ignore: cast_nullable_to_non_nullable
          : birthDate as DateTime,
      email: email == const $CopyWithPlaceholder() || email == null
          ? _value.email
          // ignore: cast_nullable_to_non_nullable
          : email as String,
      pictureUrl:
          pictureUrl == const $CopyWithPlaceholder() || pictureUrl == null
              ? _value.pictureUrl
              // ignore: cast_nullable_to_non_nullable
              : pictureUrl as Uri,
    );
  }
}

extension $UserCopyWith on User {
  /// Returns a callable class that can be used as follows: `instanceOfUser.copyWith(...)`.
  // ignore: library_private_types_in_public_api
  _$UserCWProxy get copyWith => _$UserCWProxyImpl(this);
}

abstract class _$PostDataCWProxy {
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored.
  ///
  /// Usage
  /// ```dart
  /// PostData(...).copyWith(id: 12, name: "My name")
  /// ````
  PostData call({
    String? contents,
    DateTime? creationDate,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfPostData.copyWith(...)`.
class _$PostDataCWProxyImpl implements _$PostDataCWProxy {
  const _$PostDataCWProxyImpl(this._value);

  final PostData _value;

  @override

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored.
  ///
  /// Usage
  /// ```dart
  /// PostData(...).copyWith(id: 12, name: "My name")
  /// ````
  PostData call({
    Object? contents = const $CopyWithPlaceholder(),
    Object? creationDate = const $CopyWithPlaceholder(),
  }) {
    return PostData(
      contents: contents == const $CopyWithPlaceholder() || contents == null
          ? _value.contents
          // ignore: cast_nullable_to_non_nullable
          : contents as String,
      creationDate:
          creationDate == const $CopyWithPlaceholder() || creationDate == null
              ? _value.creationDate
              // ignore: cast_nullable_to_non_nullable
              : creationDate as DateTime,
    );
  }
}

extension $PostDataCopyWith on PostData {
  /// Returns a callable class that can be used as follows: `instanceOfPostData.copyWith(...)`.
  // ignore: library_private_types_in_public_api
  _$PostDataCWProxy get copyWith => _$PostDataCWProxyImpl(this);
}

abstract class _$PostCWProxy {
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored.
  ///
  /// Usage
  /// ```dart
  /// Post(...).copyWith(id: 12, name: "My name")
  /// ````
  Post call({
    String? id,
    String? contents,
    DateTime? creationDate,
    String? userId,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfPost.copyWith(...)`.
class _$PostCWProxyImpl implements _$PostCWProxy {
  const _$PostCWProxyImpl(this._value);

  final Post _value;

  @override

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored.
  ///
  /// Usage
  /// ```dart
  /// Post(...).copyWith(id: 12, name: "My name")
  /// ````
  Post call({
    Object? id = const $CopyWithPlaceholder(),
    Object? contents = const $CopyWithPlaceholder(),
    Object? creationDate = const $CopyWithPlaceholder(),
    Object? userId = const $CopyWithPlaceholder(),
  }) {
    return Post(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      contents: contents == const $CopyWithPlaceholder() || contents == null
          ? _value.contents
          // ignore: cast_nullable_to_non_nullable
          : contents as String,
      creationDate:
          creationDate == const $CopyWithPlaceholder() || creationDate == null
              ? _value.creationDate
              // ignore: cast_nullable_to_non_nullable
              : creationDate as DateTime,
      userId: userId == const $CopyWithPlaceholder() || userId == null
          ? _value.userId
          // ignore: cast_nullable_to_non_nullable
          : userId as String,
    );
  }
}

extension $PostCopyWith on Post {
  /// Returns a callable class that can be used as follows: `instanceOfPost.copyWith(...)`.
  // ignore: library_private_types_in_public_api
  _$PostCWProxy get copyWith => _$PostCWProxyImpl(this);
}

abstract class _$MessageDataCWProxy {
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored.
  ///
  /// Usage
  /// ```dart
  /// MessageData(...).copyWith(id: 12, name: "My name")
  /// ````
  MessageData call({
    String? contents,
    DateTime? creationDate,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfMessageData.copyWith(...)`.
class _$MessageDataCWProxyImpl implements _$MessageDataCWProxy {
  const _$MessageDataCWProxyImpl(this._value);

  final MessageData _value;

  @override

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored.
  ///
  /// Usage
  /// ```dart
  /// MessageData(...).copyWith(id: 12, name: "My name")
  /// ````
  MessageData call({
    Object? contents = const $CopyWithPlaceholder(),
    Object? creationDate = const $CopyWithPlaceholder(),
  }) {
    return MessageData(
      contents: contents == const $CopyWithPlaceholder() || contents == null
          ? _value.contents
          // ignore: cast_nullable_to_non_nullable
          : contents as String,
      creationDate:
          creationDate == const $CopyWithPlaceholder() || creationDate == null
              ? _value.creationDate
              // ignore: cast_nullable_to_non_nullable
              : creationDate as DateTime,
    );
  }
}

extension $MessageDataCopyWith on MessageData {
  /// Returns a callable class that can be used as follows: `instanceOfMessageData.copyWith(...)`.
  // ignore: library_private_types_in_public_api
  _$MessageDataCWProxy get copyWith => _$MessageDataCWProxyImpl(this);
}

abstract class _$MessageCWProxy {
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored.
  ///
  /// Usage
  /// ```dart
  /// Message(...).copyWith(id: 12, name: "My name")
  /// ````
  Message call({
    String? id,
    String? contents,
    DateTime? creationDate,
    String? senderId,
    String? receiverId,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfMessage.copyWith(...)`.
class _$MessageCWProxyImpl implements _$MessageCWProxy {
  const _$MessageCWProxyImpl(this._value);

  final Message _value;

  @override

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored.
  ///
  /// Usage
  /// ```dart
  /// Message(...).copyWith(id: 12, name: "My name")
  /// ````
  Message call({
    Object? id = const $CopyWithPlaceholder(),
    Object? contents = const $CopyWithPlaceholder(),
    Object? creationDate = const $CopyWithPlaceholder(),
    Object? senderId = const $CopyWithPlaceholder(),
    Object? receiverId = const $CopyWithPlaceholder(),
  }) {
    return Message(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      contents: contents == const $CopyWithPlaceholder() || contents == null
          ? _value.contents
          // ignore: cast_nullable_to_non_nullable
          : contents as String,
      creationDate:
          creationDate == const $CopyWithPlaceholder() || creationDate == null
              ? _value.creationDate
              // ignore: cast_nullable_to_non_nullable
              : creationDate as DateTime,
      senderId: senderId == const $CopyWithPlaceholder() || senderId == null
          ? _value.senderId
          // ignore: cast_nullable_to_non_nullable
          : senderId as String,
      receiverId:
          receiverId == const $CopyWithPlaceholder() || receiverId == null
              ? _value.receiverId
              // ignore: cast_nullable_to_non_nullable
              : receiverId as String,
    );
  }
}

extension $MessageCopyWith on Message {
  /// Returns a callable class that can be used as follows: `instanceOfMessage.copyWith(...)`.
  // ignore: library_private_types_in_public_api
  _$MessageCWProxy get copyWith => _$MessageCWProxyImpl(this);
}

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
