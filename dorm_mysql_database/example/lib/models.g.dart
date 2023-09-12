// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserData _$UserDataFromJson(Map json) {
  $checkKeys(
    json,
    requiredKeys: const ['name', 'active'],
    disallowNullValues: const ['name', 'active'],
  );
  return UserData(
    name: json['name'] as String,
    active: json['active'] as bool,
    age: json['age'] as int?,
  );
}

Map<String, dynamic> _$UserDataToJson(UserData instance) => <String, dynamic>{
      'name': instance.name,
      'active': instance.active,
      'age': instance.age,
    };

User _$UserFromJson(Map json) {
  $checkKeys(
    json,
    requiredKeys: const ['name', 'active', '_id'],
    disallowNullValues: const ['name', 'active', '_id'],
  );
  return User(
    id: json['_id'] as String,
    name: json['name'] as String,
    active: json['active'] as bool,
    age: json['age'] as int?,
  );
}

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
      'name': instance.name,
      'active': instance.active,
      'age': instance.age,
      '_id': instance.id,
    };
