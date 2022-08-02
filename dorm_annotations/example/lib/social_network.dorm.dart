// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'social_network.dart';

// **************************************************************************
// OrmGenerator
// **************************************************************************

// **************************************************
//     DORM: User
// **************************************************

@JsonSerializable(anyMap: true, explicitToJson: true)
class UserData {
  @JsonKey(name: 'name')
  final String? name;

  @JsonKey(name: 'birth-date', required: true, disallowNullValue: true)
  final DateTime birthDate;

  @JsonKey(name: 'email', required: true, disallowNullValue: true)
  final String email;

  @JsonKey(name: 'picture-url', required: true, disallowNullValue: true)
  final Uri pictureUrl;

  factory UserData.fromJson(Map json) => _$UserDataFromJson(json);

  const UserData({
    required this.name,
    required this.birthDate,
    required this.email,
    required this.pictureUrl,
  });

  Map<String, Object?> toJson() => _$UserDataToJson(this);
}

@JsonSerializable(anyMap: true, explicitToJson: true)
class User extends UserData implements _User {
  @JsonKey(name: '_id', required: true, disallowNullValue: true)
  final String id;

  factory User.fromJson(String id, Map json) =>
      _$UserFromJson({...json, '_id': id});

  const User({
    required this.id,
    required super.name,
    required super.birthDate,
    required super.email,
    required super.pictureUrl,
  });

  @override
  Map<String, Object?> toJson() {
    return {
      ..._$UserToJson(this)..remove('_id'),
    };
  }
}

class UserDependency extends Dependency<UserData> {
  const UserDependency() : super.strong();
}

class UserEntity implements Entity<UserData, User> {
  const UserEntity._();

  @override
  String get tableName => 'user';

  @override
  User fromData(
    UserDependency dependency,
    String id,
    UserData data,
  ) {
    return User(
      id: id,
      name: data.name,
      birthDate: data.birthDate,
      email: data.email,
      pictureUrl: data.pictureUrl,
    );
  }

  @override
  User fromJson(String id, Map json) => User.fromJson(id, json);

  @override
  String identify(User model) => model.id;

  @override
  Map toJson(UserData data) => data.toJson();
}

// **************************************************
//     DORM: Post
// **************************************************

@JsonSerializable(anyMap: true, explicitToJson: true)
class PostData {
  @JsonKey(name: 'contents', required: true, disallowNullValue: true)
  final String contents;

  @JsonKey(name: 'creation-date', required: true, disallowNullValue: true)
  final DateTime creationDate;

  factory PostData.fromJson(Map json) => _$PostDataFromJson(json);

  const PostData({
    required this.contents,
    required this.creationDate,
  });

  Map<String, Object?> toJson() => _$PostDataToJson(this);
}

@JsonSerializable(anyMap: true, explicitToJson: true)
class Post extends PostData implements _Post {
  @JsonKey(name: '_id', required: true, disallowNullValue: true)
  final String id;

  @override
  @JsonKey(name: 'user-id', required: true, disallowNullValue: true)
  final String userId;

  factory Post.fromJson(String id, Map json) =>
      _$PostFromJson({...json, '_id': id});

  const Post({
    required this.id,
    required super.contents,
    required super.creationDate,
    required this.userId,
  });

  @override
  Map<String, Object?> toJson() {
    return {
      ..._$PostToJson(this)..remove('_id'),
    };
  }
}

class PostDependency extends Dependency<PostData> {
  final String userId;

  PostDependency({
    required this.userId,
  }) : super.weak([userId]);
}

class PostEntity implements Entity<PostData, Post> {
  const PostEntity._();

  @override
  String get tableName => 'post';

  @override
  Post fromData(
    PostDependency dependency,
    String id,
    PostData data,
  ) {
    return Post(
      id: id,
      userId: dependency.userId,
      contents: data.contents,
      creationDate: data.creationDate,
    );
  }

  @override
  Post fromJson(String id, Map json) => Post.fromJson(id, json);

  @override
  String identify(Post model) => model.id;

  @override
  Map toJson(PostData data) => data.toJson();
}

// **************************************************
//     DORM: Message
// **************************************************

@JsonSerializable(anyMap: true, explicitToJson: true)
class MessageData {
  @JsonKey(name: 'contents', required: true, disallowNullValue: true)
  final String contents;

  @JsonKey(name: 'creation-date', required: true, disallowNullValue: true)
  final DateTime creationDate;

  factory MessageData.fromJson(Map json) => _$MessageDataFromJson(json);

  const MessageData({
    required this.contents,
    required this.creationDate,
  });

  Map<String, Object?> toJson() => _$MessageDataToJson(this);
}

@JsonSerializable(anyMap: true, explicitToJson: true)
class Message extends MessageData implements _Message {
  @JsonKey(name: '_id', required: true, disallowNullValue: true)
  final String id;

  @override
  @JsonKey(name: 'sender-id', required: true, disallowNullValue: true)
  final String senderId;

  @override
  @JsonKey(name: 'receiver-id', required: true, disallowNullValue: true)
  final String receiverId;

  factory Message.fromJson(String id, Map json) =>
      _$MessageFromJson({...json, '_id': id});

  const Message({
    required this.id,
    required super.contents,
    required super.creationDate,
    required this.senderId,
    required this.receiverId,
  });

  @override
  Map<String, Object?> toJson() {
    return {
      ..._$MessageToJson(this)..remove('_id'),
    };
  }
}

class MessageDependency extends Dependency<MessageData> {
  final String senderId;
  final String receiverId;

  MessageDependency({
    required this.senderId,
    required this.receiverId,
  }) : super.weak([senderId, receiverId]);
}

class MessageEntity implements Entity<MessageData, Message> {
  const MessageEntity._();

  @override
  String get tableName => 'message';

  @override
  Message fromData(
    MessageDependency dependency,
    String id,
    MessageData data,
  ) {
    return Message(
      id: id,
      senderId: dependency.senderId,
      receiverId: dependency.receiverId,
      contents: data.contents,
      creationDate: data.creationDate,
    );
  }

  @override
  Message fromJson(String id, Map json) => Message.fromJson(id, json);

  @override
  String identify(Message model) => model.id;

  @override
  Map toJson(MessageData data) => data.toJson();
}

// **************************************************
//     DORM
// **************************************************

class Dorm {
  final Reference _root;

  const Dorm(this._root);

  Repository<UserData, User> get users =>
      Repository(root: _root, entity: const UserEntity._());

  Repository<PostData, Post> get posts =>
      Repository(root: _root, entity: const PostEntity._());

  Repository<MessageData, Message> get messages =>
      Repository(root: _root, entity: const MessageEntity._());
}
