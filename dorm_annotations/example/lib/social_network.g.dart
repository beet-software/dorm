// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'social_network.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$UserCWProxy {
  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored.
  ///
  /// Example:
  /// ```dart
  /// User(...).copyWith(id: 12, name: "My name")
  /// ```
  User call({
    String id,
    String? name,
    DateTime birthDate,
    String email,
    Uri pictureUrl,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfUser.copyWith(...)`.
class _$UserCWProxyImpl implements _$UserCWProxy {
  const _$UserCWProxyImpl(this._value);

  final User _value;

  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored.
  ///
  /// Example:
  /// ```dart
  /// User(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
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
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfUser.copyWith(...)`.
  // ignore: library_private_types_in_public_api
  _$UserCWProxy get copyWith => _$UserCWProxyImpl(this);
}

abstract class _$PostCWProxy {
  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored.
  ///
  /// Example:
  /// ```dart
  /// Post(...).copyWith(id: 12, name: "My name")
  /// ```
  Post call({String id, String contents, DateTime creationDate, String userId});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfPost.copyWith(...)`.
class _$PostCWProxyImpl implements _$PostCWProxy {
  const _$PostCWProxyImpl(this._value);

  final Post _value;

  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored.
  ///
  /// Example:
  /// ```dart
  /// Post(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
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
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfPost.copyWith(...)`.
  // ignore: library_private_types_in_public_api
  _$PostCWProxy get copyWith => _$PostCWProxyImpl(this);
}

abstract class _$MessageCWProxy {
  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored.
  ///
  /// Example:
  /// ```dart
  /// Message(...).copyWith(id: 12, name: "My name")
  /// ```
  Message call({
    String id,
    String contents,
    DateTime creationDate,
    String senderId,
    String receiverId,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfMessage.copyWith(...)`.
class _$MessageCWProxyImpl implements _$MessageCWProxy {
  const _$MessageCWProxyImpl(this._value);

  final Message _value;

  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored.
  ///
  /// Example:
  /// ```dart
  /// Message(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
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
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfMessage.copyWith(...)`.
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
      'receiver-id',
    ],
    disallowNullValues: const [
      'contents',
      'creation-date',
      '_id',
      'sender-id',
      'receiver-id',
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
