// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'social_network.dart';

// **************************************************************************
// OrmGenerator
// **************************************************************************

@JsonSerializable(
  anyMap: true,
  explicitToJson: true,
)
class UserData {
  factory UserData.fromJson(Map json) => _$UserDataFromJson(json);

  const UserData({
    required this.name,
    required this.birthDate,
    required this.email,
    required this.pictureUrl,
  });

  @JsonKey(name: 'name')
  final String? name;

  @JsonKey(
    name: 'birth-date',
    required: true,
    disallowNullValue: true,
  )
  final DateTime birthDate;

  @JsonKey(
    name: 'email',
    required: true,
    disallowNullValue: true,
  )
  final String email;

  @JsonKey(
    name: 'picture-url',
    required: true,
    disallowNullValue: true,
  )
  final Uri pictureUrl;

  Map<String, Object?> toJson() => _$UserDataToJson(this);
}

@JsonSerializable(
  anyMap: true,
  explicitToJson: true,
)
class User extends UserData implements _User {
  factory User.fromJson(
    String id,
    Map json,
  ) =>
      _$UserFromJson({
        ...json,
        '_id': id,
      });

  const User({
    required this.id,
    required super.name,
    required super.birthDate,
    required super.email,
    required super.pictureUrl,
  });

  @JsonKey(
    name: '_id',
    required: true,
    disallowNullValue: true,
  )
  final String id;

  @override
  Map<String, Object?> toJson() {
    return {..._$UserToJson(this)..remove('_id')};
  }
}

class UserDependency extends Dependency<UserData> {
  const UserDependency() : super.strong();
}

class UserEntity implements Entity<UserData, User> {
  const UserEntity();

  @override
  final String tableName = 'user';

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
  User convert(
    User model,
    UserData data,
  ) =>
      model.copyWith(data);

  @override
  User fromJson(
    String id,
    Map json,
  ) =>
      User.fromJson(
        id,
        json,
      );

  @override
  String identify(User model) => model.id;

  @override
  Map<String, Object?> toJson(UserData data) => data.toJson();
}

extension UserProperties on User {
  User copyWith(UserData data) {
    return User(
      id: id,
      name: data.name,
      birthDate: data.birthDate,
      email: data.email,
      pictureUrl: data.pictureUrl,
    );
  }
}

@JsonSerializable(
  anyMap: true,
  explicitToJson: true,
)
class PostData {
  factory PostData.fromJson(Map json) => _$PostDataFromJson(json);

  const PostData({
    required this.contents,
    required this.creationDate,
  });

  @JsonKey(
    name: 'contents',
    required: true,
    disallowNullValue: true,
  )
  final String contents;

  @JsonKey(
    name: 'creation-date',
    required: true,
    disallowNullValue: true,
  )
  final DateTime creationDate;

  Map<String, Object?> toJson() => _$PostDataToJson(this);
}

@JsonSerializable(
  anyMap: true,
  explicitToJson: true,
)
class Post extends PostData implements _Post {
  factory Post.fromJson(
    String id,
    Map json,
  ) =>
      _$PostFromJson({
        ...json,
        '_id': id,
      });

  const Post({
    required this.id,
    required super.contents,
    required super.creationDate,
    required this.userId,
  });

  @JsonKey(
    name: '_id',
    required: true,
    disallowNullValue: true,
  )
  final String id;

  @override
  @JsonKey(
    name: 'user-id',
    required: true,
    disallowNullValue: true,
  )
  final String userId;

  @override
  Map<String, Object?> toJson() {
    return {..._$PostToJson(this)..remove('_id')};
  }
}

class PostDependency extends Dependency<PostData> {
  PostDependency({required this.userId}) : super.weak([userId]);

  final String userId;
}

class PostEntity implements Entity<PostData, Post> {
  const PostEntity();

  @override
  final String tableName = 'post';

  @override
  Post fromData(
    PostDependency dependency,
    String id,
    PostData data,
  ) {
    return Post(
      id: id,
      contents: data.contents,
      creationDate: data.creationDate,
      userId: dependency.userId,
    );
  }

  @override
  Post convert(
    Post model,
    PostData data,
  ) =>
      model.copyWith(data);

  @override
  Post fromJson(
    String id,
    Map json,
  ) =>
      Post.fromJson(
        id,
        json,
      );

  @override
  String identify(Post model) => model.id;

  @override
  Map<String, Object?> toJson(PostData data) => data.toJson();
}

extension PostProperties on Post {
  Post copyWith(PostData data) {
    return Post(
      id: id,
      contents: data.contents,
      creationDate: data.creationDate,
      userId: userId,
    );
  }
}

@JsonSerializable(
  anyMap: true,
  explicitToJson: true,
)
class MessageData {
  factory MessageData.fromJson(Map json) => _$MessageDataFromJson(json);

  const MessageData({
    required this.contents,
    required this.creationDate,
  });

  @JsonKey(
    name: 'contents',
    required: true,
    disallowNullValue: true,
  )
  final String contents;

  @JsonKey(
    name: 'creation-date',
    required: true,
    disallowNullValue: true,
  )
  final DateTime creationDate;

  Map<String, Object?> toJson() => _$MessageDataToJson(this);
}

@JsonSerializable(
  anyMap: true,
  explicitToJson: true,
)
class Message extends MessageData implements _Message {
  factory Message.fromJson(
    String id,
    Map json,
  ) =>
      _$MessageFromJson({
        ...json,
        '_id': id,
      });

  const Message({
    required this.id,
    required super.contents,
    required super.creationDate,
    required this.senderId,
    required this.receiverId,
  });

  @JsonKey(
    name: '_id',
    required: true,
    disallowNullValue: true,
  )
  final String id;

  @override
  @JsonKey(
    name: 'sender-id',
    required: true,
    disallowNullValue: true,
  )
  final String senderId;

  @override
  @JsonKey(
    name: 'receiver-id',
    required: true,
    disallowNullValue: true,
  )
  final String receiverId;

  @override
  Map<String, Object?> toJson() {
    return {..._$MessageToJson(this)..remove('_id')};
  }
}

class MessageDependency extends Dependency<MessageData> {
  MessageDependency({
    required this.senderId,
    required this.receiverId,
  }) : super.weak([
          senderId,
          receiverId,
        ]);

  final String senderId;

  final String receiverId;
}

class MessageEntity implements Entity<MessageData, Message> {
  const MessageEntity();

  @override
  final String tableName = 'message';

  @override
  Message fromData(
    MessageDependency dependency,
    String id,
    MessageData data,
  ) {
    return Message(
      id: id,
      contents: data.contents,
      creationDate: data.creationDate,
      senderId: dependency.senderId,
      receiverId: dependency.receiverId,
    );
  }

  @override
  Message convert(
    Message model,
    MessageData data,
  ) =>
      model.copyWith(data);

  @override
  Message fromJson(
    String id,
    Map json,
  ) =>
      Message.fromJson(
        id,
        json,
      );

  @override
  String identify(Message model) => model.id;

  @override
  Map<String, Object?> toJson(MessageData data) => data.toJson();
}

extension MessageProperties on Message {
  Message copyWith(MessageData data) {
    return Message(
      id: id,
      contents: data.contents,
      creationDate: data.creationDate,
      senderId: senderId,
      receiverId: receiverId,
    );
  }
}

class Dorm {
  const Dorm(this._engine);

  final BaseEngine<Query> _engine;

  DatabaseEntity<UserData, User, Query> get users => DatabaseEntity(
        const UserEntity(),
        engine: _engine,
      );

  DatabaseEntity<PostData, Post, Query> get post => DatabaseEntity(
        const PostEntity(),
        engine: _engine,
      );

  DatabaseEntity<MessageData, Message, Query> get messages => DatabaseEntity(
        const MessageEntity(),
        engine: _engine,
      );
}
