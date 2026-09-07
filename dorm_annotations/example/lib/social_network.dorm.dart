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

class UserEntity
    implements
        Entity<UserData, User, String, SimpleCreation<UserData, String>> {
  const UserEntity();

  static const UserFields fields = UserFields();

  static final EntitySchema _schema = EntitySchema(
    tableName: 'user',
    primaryKeys: [fields.id],
    fields: [fields.name, fields.birthDate, fields.email, fields.pictureUrl],
    derivedFields: [],
  );

  @override
  EntitySchema get schema => _schema;

  @override
  PrimaryKeyCodec<String> get primaryKeyCodec => const SinglePrimaryKeyCodec();

  @override
  bool get supportsAutomaticIdentity => true;

  @override
  User fromData(ResolvedCreation<UserData, String> creation) {
    return User(
      id: creation.id,
      name: creation.data.name,
      birthDate: creation.data.birthDate,
      email: creation.data.email,
      pictureUrl: creation.data.pictureUrl,
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

class PostEntity
    implements
        Entity<PostData, Post, String, SimpleCreation<PostData, String>> {
  const PostEntity();

  static const PostFields fields = PostFields();

  static final EntitySchema _schema = EntitySchema(
    tableName: 'post',
    primaryKeys: [fields.id],
    fields: [fields.contents, fields.creationDate, fields.userId],
    derivedFields: [],
  );

  @override
  EntitySchema get schema => _schema;

  @override
  PrimaryKeyCodec<String> get primaryKeyCodec => const SinglePrimaryKeyCodec();

  @override
  bool get supportsAutomaticIdentity => true;

  @override
  Post fromData(ResolvedCreation<PostData, String> creation) {
    return Post(
      id: creation.id,
      contents: creation.data.contents,
      creationDate: creation.data.creationDate,
      userId: (creation.dependency as PostDependency).userId,
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

class MessageEntity
    implements
        Entity<
          MessageData,
          Message,
          String,
          SimpleCreation<MessageData, String>
        > {
  const MessageEntity();

  static const MessageFields fields = MessageFields();

  static final EntitySchema _schema = EntitySchema(
    tableName: 'message',
    primaryKeys: [fields.id],
    fields: [
      fields.contents,
      fields.creationDate,
      fields.senderId,
      fields.receiverId,
    ],
    derivedFields: [],
  );

  @override
  EntitySchema get schema => _schema;

  @override
  PrimaryKeyCodec<String> get primaryKeyCodec => const SinglePrimaryKeyCodec();

  @override
  bool get supportsAutomaticIdentity => true;

  @override
  Message fromData(ResolvedCreation<MessageData, String> creation) {
    return Message(
      id: creation.id,
      contents: creation.data.contents,
      creationDate: creation.data.creationDate,
      senderId: (creation.dependency as MessageDependency).senderId,
      receiverId: (creation.dependency as MessageDependency).receiverId,
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

class Dorm<Q extends BaseQuery<Q>, P extends PageRequest> {
  const Dorm(this._engine);

  final BaseEngine<Q, P> _engine;

  DatabaseEntity<UserData, User, String, Q, SimpleCreation<UserData, String>, P>
  get users => DatabaseEntity(const UserEntity(), engine: _engine);

  DatabaseEntity<PostData, Post, String, Q, SimpleCreation<PostData, String>, P>
  get post => DatabaseEntity(const PostEntity(), engine: _engine);

  DatabaseEntity<
    MessageData,
    Message,
    String,
    Q,
    SimpleCreation<MessageData, String>,
    P
  >
  get messages => DatabaseEntity(const MessageEntity(), engine: _engine);

  DormRelations<Q, P> get relations => DormRelations<Q, P>(this);
}

class DormRelations<Q extends BaseQuery<Q>, P extends PageRequest> {
  const DormRelations(this._dorm);

  final Dorm<Q, P> _dorm;

  RelationPath<Dorm<Q, P>, User, User, Q> get users =>
      RelationPath.root(_dorm.users.repository, context: _dorm);

  RelationPath<Dorm<Q, P>, Post, Post, Q> get post =>
      RelationPath.root(_dorm.post.repository, context: _dorm);

  RelationPath<Dorm<Q, P>, Message, Message, Q> get messages =>
      RelationPath.root(_dorm.messages.repository, context: _dorm);
}

extension UserRelationPaths<Root, Q extends BaseQuery<Q>, P extends PageRequest>
    on RelationPath<Dorm<Q, P>, Root, User, Q> {
  RelationPath<Dorm<Q, P>, Root, Post, Q> get posts {
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

  RelationPath<Dorm<Q, P>, Root, List<Post>, Q> get postsOrEmpty {
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

  RelationPath<Dorm<Q, P>, Root, Message, Q> get sentMessages {
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

  RelationPath<Dorm<Q, P>, Root, List<Message>, Q> get sentMessagesOrEmpty {
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

  RelationPath<Dorm<Q, P>, Root, Message, Q> get receivedMessages {
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

  RelationPath<Dorm<Q, P>, Root, List<Message>, Q> get receivedMessagesOrEmpty {
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

extension PostRelationPaths<Root, Q extends BaseQuery<Q>, P extends PageRequest>
    on RelationPath<Dorm<Q, P>, Root, Post, Q> {
  RelationPath<Dorm<Q, P>, Root, User, Q> get user {
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

  RelationPath<Dorm<Q, P>, Root, User?, Q> get userOrNull {
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

extension MessageRelationPaths<
  Root,
  Q extends BaseQuery<Q>,
  P extends PageRequest
>
    on RelationPath<Dorm<Q, P>, Root, Message, Q> {
  RelationPath<Dorm<Q, P>, Root, User, Q> get sender {
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

  RelationPath<Dorm<Q, P>, Root, User?, Q> get senderOrNull {
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

  RelationPath<Dorm<Q, P>, Root, User, Q> get receiver {
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

  RelationPath<Dorm<Q, P>, Root, User?, Q> get receiverOrNull {
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
