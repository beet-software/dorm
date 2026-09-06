// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'social_network.dart';

// **************************************************************************
// OrmGenerator
// **************************************************************************

@JsonSerializable(anyMap: true, explicitToJson: true)
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

  @JsonKey(name: 'birth-date', required: true, disallowNullValue: true)
  final DateTime birthDate;

  @JsonKey(name: 'email', required: true, disallowNullValue: true)
  final String email;

  @JsonKey(name: 'picture-url', required: true, disallowNullValue: true)
  final Uri pictureUrl;

  Map<String, Object?> toJson() => _$UserDataToJson(this);
}

@JsonSerializable(anyMap: true, explicitToJson: true)
@CopyWith(skipFields: true)
class User extends UserData implements _User {
  factory User.fromJson(String id, Map json) =>
      _$UserFromJson({...json, '_id': id});

  const User({
    required this.id,
    required super.name,
    required super.birthDate,
    required super.email,
    required super.pictureUrl,
  });

  @JsonKey(name: '_id', required: true, disallowNullValue: true)
  final String id;

  @override
  Map<String, Object?> toJson() {
    return {..._$UserToJson(this)..remove('_id')};
  }
}

class UserDependency extends Dependency<UserData> {
  const UserDependency() : super.strong();
}

class UserFields {
  const UserFields();

  final FieldSchema id = const FieldSchema(fieldName: 'id', columnName: 'id');

  final FieldSchema name = const FieldSchema(
    fieldName: 'name',
    columnName: 'name',
  );

  final FieldSchema birthDate = const FieldSchema(
    fieldName: 'birthDate',
    columnName: 'birth-date',
  );

  final FieldSchema email = const FieldSchema(
    fieldName: 'email',
    columnName: 'email',
  );

  final FieldSchema pictureUrl = const FieldSchema(
    fieldName: 'pictureUrl',
    columnName: 'picture-url',
  );
}

class UserEntity implements Entity<UserData, User, String> {
  const UserEntity();

  static const UserFields fields = UserFields();

  static final EntitySchema _schema = EntitySchema(
    tableName: 'user',
    primaryKey: fields.id,
    fields: [fields.name, fields.birthDate, fields.email, fields.pictureUrl],
  );

  @override
  EntitySchema get schema => _schema;

  @override
  PrimaryKeyCodec<String> get primaryKeyCodec => const SinglePrimaryKeyCodec();

  @override
  User fromData(UserDependency dependency, String id, UserData data) {
    return User(
      id: id,
      name: data.name,
      birthDate: data.birthDate,
      email: data.email,
      pictureUrl: data.pictureUrl,
    );
  }

  @override
  User convert(User model, UserData data) => model.updateWith(data);

  @override
  User fromJson(String id, Map json) => User.fromJson(id, json);

  @override
  String identify(User model) => model.id;

  @override
  Map<String, Object?> toJson(UserData data) => data.toJson();
}

extension UserProperties on User {
  User updateWith(UserData data) {
    return User(
      id: id,
      name: data.name,
      birthDate: data.birthDate,
      email: data.email,
      pictureUrl: data.pictureUrl,
    );
  }
}

@JsonSerializable(anyMap: true, explicitToJson: true)
class PostData {
  factory PostData.fromJson(Map json) => _$PostDataFromJson(json);

  const PostData({required this.contents, required this.creationDate});

  @JsonKey(name: 'contents', required: true, disallowNullValue: true)
  final String contents;

  @JsonKey(name: 'creation-date', required: true, disallowNullValue: true)
  final DateTime creationDate;

  Map<String, Object?> toJson() => _$PostDataToJson(this);
}

@JsonSerializable(anyMap: true, explicitToJson: true)
@CopyWith(skipFields: true)
class Post extends PostData implements _Post {
  factory Post.fromJson(String id, Map json) =>
      _$PostFromJson({...json, '_id': id});

  const Post({
    required this.id,
    required super.contents,
    required super.creationDate,
    required this.userId,
  });

  @JsonKey(name: '_id', required: true, disallowNullValue: true)
  final String id;

  @override
  @JsonKey(name: 'user-id', required: true, disallowNullValue: true)
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

class PostFields {
  const PostFields();

  final FieldSchema id = const FieldSchema(fieldName: 'id', columnName: 'id');

  final FieldSchema contents = const FieldSchema(
    fieldName: 'contents',
    columnName: 'contents',
  );

  final FieldSchema creationDate = const FieldSchema(
    fieldName: 'creationDate',
    columnName: 'creation-date',
  );

  final ForeignKeySchema userId = const ForeignKeySchema(
    fieldName: 'userId',
    columnName: 'user-id',
    targetTableName: 'user',
    targetColumnName: 'id',
    unique: false,
  );
}

class PostEntity implements Entity<PostData, Post, String> {
  const PostEntity();

  static const PostFields fields = PostFields();

  static final EntitySchema _schema = EntitySchema(
    tableName: 'post',
    primaryKey: fields.id,
    fields: [fields.contents, fields.creationDate, fields.userId],
  );

  @override
  EntitySchema get schema => _schema;

  @override
  PrimaryKeyCodec<String> get primaryKeyCodec => const SinglePrimaryKeyCodec();

  @override
  Post fromData(PostDependency dependency, String id, PostData data) {
    return Post(
      id: id,
      contents: data.contents,
      creationDate: data.creationDate,
      userId: dependency.userId,
    );
  }

  @override
  Post convert(Post model, PostData data) => model.updateWith(data);

  @override
  Post fromJson(String id, Map json) => Post.fromJson(id, json);

  @override
  String identify(Post model) => model.id;

  @override
  Map<String, Object?> toJson(PostData data) => data.toJson();
}

extension PostProperties on Post {
  Post updateWith(PostData data) {
    return Post(
      id: id,
      contents: data.contents,
      creationDate: data.creationDate,
      userId: userId,
    );
  }
}

@JsonSerializable(anyMap: true, explicitToJson: true)
class MessageData {
  factory MessageData.fromJson(Map json) => _$MessageDataFromJson(json);

  const MessageData({required this.contents, required this.creationDate});

  @JsonKey(name: 'contents', required: true, disallowNullValue: true)
  final String contents;

  @JsonKey(name: 'creation-date', required: true, disallowNullValue: true)
  final DateTime creationDate;

  Map<String, Object?> toJson() => _$MessageDataToJson(this);
}

@JsonSerializable(anyMap: true, explicitToJson: true)
@CopyWith(skipFields: true)
class Message extends MessageData implements _Message {
  factory Message.fromJson(String id, Map json) =>
      _$MessageFromJson({...json, '_id': id});

  const Message({
    required this.id,
    required super.contents,
    required super.creationDate,
    required this.senderId,
    required this.receiverId,
  });

  @JsonKey(name: '_id', required: true, disallowNullValue: true)
  final String id;

  @override
  @JsonKey(name: 'sender-id', required: true, disallowNullValue: true)
  final String senderId;

  @override
  @JsonKey(name: 'receiver-id', required: true, disallowNullValue: true)
  final String receiverId;

  @override
  Map<String, Object?> toJson() {
    return {..._$MessageToJson(this)..remove('_id')};
  }
}

class MessageDependency extends Dependency<MessageData> {
  MessageDependency({required this.senderId, required this.receiverId})
    : super.weak([senderId, receiverId]);

  final String senderId;

  final String receiverId;
}

class MessageFields {
  const MessageFields();

  final FieldSchema id = const FieldSchema(fieldName: 'id', columnName: 'id');

  final FieldSchema contents = const FieldSchema(
    fieldName: 'contents',
    columnName: 'contents',
  );

  final FieldSchema creationDate = const FieldSchema(
    fieldName: 'creationDate',
    columnName: 'creation-date',
  );

  final ForeignKeySchema senderId = const ForeignKeySchema(
    fieldName: 'senderId',
    columnName: 'sender-id',
    targetTableName: 'user',
    targetColumnName: 'id',
    unique: false,
  );

  final ForeignKeySchema receiverId = const ForeignKeySchema(
    fieldName: 'receiverId',
    columnName: 'receiver-id',
    targetTableName: 'user',
    targetColumnName: 'id',
    unique: false,
  );
}

class MessageEntity implements Entity<MessageData, Message, String> {
  const MessageEntity();

  static const MessageFields fields = MessageFields();

  static final EntitySchema _schema = EntitySchema(
    tableName: 'message',
    primaryKey: fields.id,
    fields: [
      fields.contents,
      fields.creationDate,
      fields.senderId,
      fields.receiverId,
    ],
  );

  @override
  EntitySchema get schema => _schema;

  @override
  PrimaryKeyCodec<String> get primaryKeyCodec => const SinglePrimaryKeyCodec();

  @override
  Message fromData(MessageDependency dependency, String id, MessageData data) {
    return Message(
      id: id,
      contents: data.contents,
      creationDate: data.creationDate,
      senderId: dependency.senderId,
      receiverId: dependency.receiverId,
    );
  }

  @override
  Message convert(Message model, MessageData data) => model.updateWith(data);

  @override
  Message fromJson(String id, Map json) => Message.fromJson(id, json);

  @override
  String identify(Message model) => model.id;

  @override
  Map<String, Object?> toJson(MessageData data) => data.toJson();
}

extension MessageProperties on Message {
  Message updateWith(MessageData data) {
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

  DatabaseEntity<UserData, User, String, Query> get users =>
      DatabaseEntity(const UserEntity(), engine: _engine);

  DatabaseEntity<PostData, Post, String, Query> get post =>
      DatabaseEntity(const PostEntity(), engine: _engine);

  DatabaseEntity<MessageData, Message, String, Query> get messages =>
      DatabaseEntity(const MessageEntity(), engine: _engine);

  DormRelations get relations => DormRelations(this);
}

class DormRelations {
  const DormRelations(this._dorm);
  final Dorm _dorm;
  RelationPath<Dorm, User, User, Query> get users =>
      RelationPath.root(_dorm.users.repository, context: _dorm);
  RelationPath<Dorm, Post, Post, Query> get post =>
      RelationPath.root(_dorm.post.repository, context: _dorm);
  RelationPath<Dorm, Message, Message, Query> get messages =>
      RelationPath.root(_dorm.messages.repository, context: _dorm);
}

extension UserRelationPaths<Root> on RelationPath<Dorm, Root, User, Query> {
  RelationPath<Dorm, Root, Post, Query> get posts {
    return toMany(
      context.post.repository,
      spec: RelationSpec(
        cardinality: RelationCardinality.many,
        source: UserEntity.fields.id,
        target: PostEntity.fields.userId,
      ),
      on: (model) =>
          BaseFilter.value(model.id, field: PostEntity.fields.userId),
    );
  }

  RelationPath<Dorm, Root, List<Post>, Query> get postsOrEmpty {
    return toManyOrEmpty(
      context.post.repository,
      spec: RelationSpec(
        cardinality: RelationCardinality.many,
        source: UserEntity.fields.id,
        target: PostEntity.fields.userId,
      ),
      on: (model) =>
          BaseFilter.value(model.id, field: PostEntity.fields.userId),
    );
  }

  RelationPath<Dorm, Root, Message, Query> get sentMessages {
    return toMany(
      context.messages.repository,
      spec: RelationSpec(
        cardinality: RelationCardinality.many,
        source: UserEntity.fields.id,
        target: MessageEntity.fields.senderId,
      ),
      on: (model) =>
          BaseFilter.value(model.id, field: MessageEntity.fields.senderId),
    );
  }

  RelationPath<Dorm, Root, List<Message>, Query> get sentMessagesOrEmpty {
    return toManyOrEmpty(
      context.messages.repository,
      spec: RelationSpec(
        cardinality: RelationCardinality.many,
        source: UserEntity.fields.id,
        target: MessageEntity.fields.senderId,
      ),
      on: (model) =>
          BaseFilter.value(model.id, field: MessageEntity.fields.senderId),
    );
  }

  RelationPath<Dorm, Root, Message, Query> get receivedMessages {
    return toMany(
      context.messages.repository,
      spec: RelationSpec(
        cardinality: RelationCardinality.many,
        source: UserEntity.fields.id,
        target: MessageEntity.fields.receiverId,
      ),
      on: (model) =>
          BaseFilter.value(model.id, field: MessageEntity.fields.receiverId),
    );
  }

  RelationPath<Dorm, Root, List<Message>, Query> get receivedMessagesOrEmpty {
    return toManyOrEmpty(
      context.messages.repository,
      spec: RelationSpec(
        cardinality: RelationCardinality.many,
        source: UserEntity.fields.id,
        target: MessageEntity.fields.receiverId,
      ),
      on: (model) =>
          BaseFilter.value(model.id, field: MessageEntity.fields.receiverId),
    );
  }
}

extension PostRelationPaths<Root> on RelationPath<Dorm, Root, Post, Query> {
  RelationPath<Dorm, Root, User, Query> get user {
    return toOne(
      context.users.repository,
      spec: RelationSpec(
        cardinality: RelationCardinality.one,
        source: PostEntity.fields.userId,
        target: UserEntity.fields.id,
      ),
      on: (model) => model.userId,
    );
  }

  RelationPath<Dorm, Root, User?, Query> get userOrNull {
    return toOneOrNull(
      context.users.repository,
      spec: RelationSpec(
        cardinality: RelationCardinality.one,
        source: PostEntity.fields.userId,
        target: UserEntity.fields.id,
      ),
      on: (model) => model.userId,
    );
  }
}

extension MessageRelationPaths<Root>
    on RelationPath<Dorm, Root, Message, Query> {
  RelationPath<Dorm, Root, User, Query> get sender {
    return toOne(
      context.users.repository,
      spec: RelationSpec(
        cardinality: RelationCardinality.one,
        source: MessageEntity.fields.senderId,
        target: UserEntity.fields.id,
      ),
      on: (model) => model.senderId,
    );
  }

  RelationPath<Dorm, Root, User?, Query> get senderOrNull {
    return toOneOrNull(
      context.users.repository,
      spec: RelationSpec(
        cardinality: RelationCardinality.one,
        source: MessageEntity.fields.senderId,
        target: UserEntity.fields.id,
      ),
      on: (model) => model.senderId,
    );
  }

  RelationPath<Dorm, Root, User, Query> get receiver {
    return toOne(
      context.users.repository,
      spec: RelationSpec(
        cardinality: RelationCardinality.one,
        source: MessageEntity.fields.receiverId,
        target: UserEntity.fields.id,
      ),
      on: (model) => model.receiverId,
    );
  }

  RelationPath<Dorm, Root, User?, Query> get receiverOrNull {
    return toOneOrNull(
      context.users.repository,
      spec: RelationSpec(
        cardinality: RelationCardinality.one,
        source: MessageEntity.fields.receiverId,
        target: UserEntity.fields.id,
      ),
      on: (model) => model.receiverId,
    );
  }
}
