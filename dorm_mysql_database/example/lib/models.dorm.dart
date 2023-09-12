// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

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
    required this.active,
    required this.age,
  });

  @JsonKey(
    name: 'name',
    required: true,
    disallowNullValue: true,
  )
  final String name;

  @JsonKey(
    name: 'active',
    required: true,
    disallowNullValue: true,
  )
  final bool active;

  @JsonKey(name: 'age')
  final int? age;

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
    required super.active,
    required super.age,
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
  final String tableName = 'Users';

  @override
  User fromData(
    UserDependency dependency,
    String id,
    UserData data,
  ) {
    return User(
      id: id,
      name: data.name,
      active: data.active,
      age: data.age,
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
      active: data.active,
      age: data.age,
    );
  }
}

class Dorm {
  const Dorm(this._engine);

  final BaseEngine _engine;

  DatabaseEntity<UserData, User> get users => DatabaseEntity(
        const UserEntity(),
        engine: _engine,
      );
}
