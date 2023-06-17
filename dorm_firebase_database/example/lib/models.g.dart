// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserData _$UserDataFromJson(Map json) {
  $checkKeys(
    json,
    requiredKeys: const ['name'],
    disallowNullValues: const ['name'],
  );
  return UserData(
    name: json['name'] as String,
  );
}

Map<String, dynamic> _$UserDataToJson(UserData instance) => <String, dynamic>{
      'name': instance.name,
    };

User _$UserFromJson(Map json) {
  $checkKeys(
    json,
    requiredKeys: const ['name', '_id'],
    disallowNullValues: const ['name', '_id'],
  );
  return User(
    id: json['_id'] as String,
    name: json['name'] as String,
  );
}

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
      'name': instance.name,
      '_id': instance.id,
    };
