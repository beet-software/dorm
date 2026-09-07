// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'models.dart';

// **************************************************************************
// OrmGenerator
// **************************************************************************

@JsonSerializable(anyMap: true, explicitToJson: true)
class UserData {
  factory UserData.fromJson(Map json) => _$UserDataFromJson(json);

  const UserData({required this.name});

  @JsonKey(name: 'name', required: true, disallowNullValue: true)
  final String name;

  Map<String, Object?> toJson() => _$UserDataToJson(this);
}

@JsonSerializable(anyMap: true, explicitToJson: true)
@CopyWith(skipFields: true)
class User extends UserData implements _User {
  factory User.fromJson(String id, Map json) =>
      _$UserFromJson({...json, '_id': id});

  const User({required this.id, required super.name});

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
}

class UserEntity
    implements
        Entity<UserData, User, String, SimpleCreation<UserData, String>> {
  const UserEntity();

  static const UserFields fields = UserFields();

  static final EntitySchema _schema = EntitySchema(
    tableName: 'users',
    primaryKeys: [fields.id],
    fields: [fields.name],
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
    return User(id: creation.id, name: creation.data.name);
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
    return User(id: id, name: data.name);
  }
}

@JsonSerializable(anyMap: true, explicitToJson: true)
class PostData {
  factory PostData.fromJson(Map json) => _$PostDataFromJson(json);

  const PostData({required this.title});

  @JsonKey(name: 'title', required: true, disallowNullValue: true)
  final String title;

  Map<String, Object?> toJson() => _$PostDataToJson(this);
}

@JsonSerializable(anyMap: true, explicitToJson: true)
@CopyWith(skipFields: true)
class Post extends PostData implements _Post {
  factory Post.fromJson(String id, Map json) =>
      _$PostFromJson({...json, '_id': id});

  const Post({required this.id, required super.title, required this.userId});

  @JsonKey(name: '_id', required: true, disallowNullValue: true)
  final String id;

  @override
  @JsonKey(name: 'user_id', required: true, disallowNullValue: true)
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

  final FieldSchema title = const FieldSchema(
    fieldName: 'title',
    columnName: 'title',
  );

  final ForeignKeySchema userId = const ForeignKeySchema(
    fieldName: 'userId',
    columnName: 'user_id',
    targetTableName: 'users',
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
    tableName: 'posts',
    primaryKeys: [fields.id],
    fields: [fields.title, fields.userId],
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
      title: creation.data.title,
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
    return Post(id: id, title: data.title, userId: userId);
  }
}

class Dorm {
  const Dorm(this._engine);

  final BaseEngine<Query> _engine;

  DatabaseEntity<
    UserData,
    User,
    String,
    Query,
    SimpleCreation<UserData, String>
  >
  get users => DatabaseEntity(const UserEntity(), engine: _engine);

  DatabaseEntity<
    PostData,
    Post,
    String,
    Query,
    SimpleCreation<PostData, String>
  >
  get posts => DatabaseEntity(const PostEntity(), engine: _engine);

  DormRelations get relations => DormRelations(this);
}

class DormRelations {
  const DormRelations(this._dorm);

  final Dorm _dorm;

  RelationPath<Dorm, User, User, Query> get users =>
      RelationPath.root(_dorm.users.repository, context: _dorm);

  RelationPath<Dorm, Post, Post, Query> get posts =>
      RelationPath.root(_dorm.posts.repository, context: _dorm);
}

extension UserRelationPaths<Root> on RelationPath<Dorm, Root, User, Query> {
  RelationPath<Dorm, Root, Post, Query> get posts {
    return toMany(
      context.posts.repository,
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
      context.posts.repository,
      spec: RelationSpec(
        cardinality: RelationCardinality.many,
        source: UserEntity.fields.id,
        target: PostEntity.fields.userId,
      ),
      on: (model) =>
          BaseFilter.value(model.id, field: PostEntity.fields.userId),
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
