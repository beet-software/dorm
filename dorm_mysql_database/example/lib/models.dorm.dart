// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'models.dart';

// **************************************************************************
// OrmGenerator
// **************************************************************************

@JsonSerializable(anyMap: true, explicitToJson: true)
class UserData {
  factory UserData.fromJson(Map json) => _$UserDataFromJson(json);

  const UserData({required this.name, required this.active, required this.age});

  @JsonKey(name: 'name', required: true, disallowNullValue: true)
  final String name;

  @JsonKey(name: 'active', required: true, disallowNullValue: true)
  final bool active;

  @JsonKey(name: 'age')
  final int? age;

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
    required super.active,
    required super.age,
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

  final FieldSchema active = const FieldSchema(
    fieldName: 'active',
    columnName: 'active',
  );

  final FieldSchema age = const FieldSchema(
    fieldName: 'age',
    columnName: 'age',
  );
}

class UserEntity
    implements
        Entity<UserData, User, String, SimpleCreation<UserData, String>> {
  const UserEntity();

  static const UserFields fields = UserFields();

  static final EntitySchema _schema = EntitySchema(
    tableName: 'Users',
    primaryKeys: [fields.id],
    fields: [fields.name, fields.active, fields.age],
    derivedFields: [],
  );

  @override
  EntitySchema get schema => _schema;

  @override
  PrimaryKeyCodec<String> get primaryKeyCodec => const SinglePrimaryKeyCodec();

  @override
  IdentityGenerationStrategy get identityGeneration =>
      IdentityGenerationStrategy.engine;

  @override
  User fromData(ResolvedCreation<UserData, String> creation) {
    return User(
      id: creation.id,
      name: creation.data.name,
      active: creation.data.active,
      age: creation.data.age,
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
    return User(id: id, name: data.name, active: data.active, age: data.age);
  }
}

class Dorm<Q extends BaseQuery<Q>, P extends PageRequest> {
  const Dorm(this._engine);

  final BaseEngine<Q, P> _engine;

  DatabaseEntity<UserData, User, String, Q, SimpleCreation<UserData, String>, P>
  get users => DatabaseEntity(const UserEntity(), engine: _engine);
}

class TransactionalDorm<Q extends BaseQuery<Q>, P extends PageRequest>
    extends Dorm<Q, P> {
  const TransactionalDorm(this._transactionalEngine)
    : super(_transactionalEngine);

  final TransactionalEngine<Q, P> _transactionalEngine;

  Future<T> transaction<T>(Future<T> Function(Dorm<Q, P>) action) =>
      _transactionalEngine.transaction((engine) => action(Dorm<Q, P>(engine)));
}
