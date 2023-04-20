// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'school.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SchoolData _$SchoolDataFromJson(Map json) {
  $checkKeys(
    json,
    requiredKeys: const ['nome'],
    disallowNullValues: const ['nome'],
  );
  return SchoolData(
    name: json['nome'] as String,
    phoneNumbers: (json['contatos'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList() ??
        [],
  );
}

Map<String, dynamic> _$SchoolDataToJson(SchoolData instance) =>
    <String, dynamic>{
      'nome': instance.name,
      'contatos': instance.phoneNumbers,
    };

School _$SchoolFromJson(Map json) {
  $checkKeys(
    json,
    requiredKeys: const ['nome', '_id'],
    disallowNullValues: const ['nome', '_id'],
  );
  return School(
    id: json['_id'] as String,
    name: json['nome'] as String,
    phoneNumbers: (json['contatos'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList() ??
        [],
  );
}

Map<String, dynamic> _$SchoolToJson(School instance) => <String, dynamic>{
      'nome': instance.name,
      'contatos': instance.phoneNumbers,
      '_id': instance.id,
    };

StudentData _$StudentDataFromJson(Map json) {
  $checkKeys(
    json,
    requiredKeys: const ['nome'],
    disallowNullValues: const ['nome'],
  );
  return StudentData(
    name: json['nome'] as String,
    hasDisabilities: json['possui-deficiencias'] as bool? ?? false,
  );
}

Map<String, dynamic> _$StudentDataToJson(StudentData instance) =>
    <String, dynamic>{
      'nome': instance.name,
      'possui-deficiencias': instance.hasDisabilities,
    };

Student _$StudentFromJson(Map json) {
  $checkKeys(
    json,
    requiredKeys: const ['nome', '_id', 'id-escola'],
    disallowNullValues: const ['nome', '_id', 'id-escola'],
  );
  return Student(
    id: json['_id'] as String,
    name: json['nome'] as String,
    hasDisabilities: json['possui-deficiencias'] as bool? ?? false,
    schoolId: json['id-escola'] as String,
  );
}

Map<String, dynamic> _$StudentToJson(Student instance) => <String, dynamic>{
      'nome': instance.name,
      'possui-deficiencias': instance.hasDisabilities,
      '_id': instance.id,
      'id-escola': instance.schoolId,
    };

TeacherData _$TeacherDataFromJson(Map json) {
  $checkKeys(
    json,
    requiredKeys: const ['nome'],
    disallowNullValues: const ['nome'],
  );
  return TeacherData(
    name: json['nome'] as String,
    ssn: json['cpf'] as String?,
  );
}

Map<String, dynamic> _$TeacherDataToJson(TeacherData instance) =>
    <String, dynamic>{
      'nome': instance.name,
      'cpf': instance.ssn,
    };

Teacher _$TeacherFromJson(Map json) {
  $checkKeys(
    json,
    requiredKeys: const ['nome', '_id'],
    disallowNullValues: const ['nome', '_id'],
  );
  return Teacher(
    id: json['_id'] as String,
    name: json['nome'] as String,
    ssn: json['cpf'] as String?,
  );
}

Map<String, dynamic> _$TeacherToJson(Teacher instance) => <String, dynamic>{
      'nome': instance.name,
      'cpf': instance.ssn,
      '_id': instance.id,
    };

HistoryData _$HistoryDataFromJson(Map json) => HistoryData();

Map<String, dynamic> _$HistoryDataToJson(HistoryData instance) =>
    <String, dynamic>{};

History _$HistoryFromJson(Map json) {
  $checkKeys(
    json,
    requiredKeys: const ['_id', 'id-aluno'],
    disallowNullValues: const ['_id', 'id-aluno'],
  );
  return History(
    id: json['_id'] as String,
    studentId: json['id-aluno'] as String,
  );
}

Map<String, dynamic> _$HistoryToJson(History instance) => <String, dynamic>{
      '_id': instance.id,
      'id-aluno': instance.studentId,
    };

TeachingData _$TeachingDataFromJson(Map json) {
  $checkKeys(
    json,
    requiredKeys: const ['codigo'],
    disallowNullValues: const ['codigo'],
  );
  return TeachingData(
    code: json['codigo'] as String,
  );
}

Map<String, dynamic> _$TeachingDataToJson(TeachingData instance) =>
    <String, dynamic>{
      'codigo': instance.code,
    };

Teaching _$TeachingFromJson(Map json) {
  $checkKeys(
    json,
    requiredKeys: const ['codigo', '_id', 'id-professor'],
    disallowNullValues: const ['codigo', '_id', 'id-professor'],
  );
  return Teaching(
    id: json['_id'] as String,
    teacherId: json['id-professor'] as String,
    schoolId: json['id-escola'] as String?,
    code: json['codigo'] as String,
  );
}

Map<String, dynamic> _$TeachingToJson(Teaching instance) => <String, dynamic>{
      'codigo': instance.code,
      '_id': instance.id,
      'id-professor': instance.teacherId,
      'id-escola': instance.schoolId,
    };

ClassData _$ClassDataFromJson(Map json) {
  $checkKeys(
    json,
    requiredKeys: const ['man', 'mans', 'nome-sala'],
    disallowNullValues: const ['man', 'mans', 'nome-sala'],
  );
  return ClassData(
    data: json['man'],
    datum: json['mans'] as List<dynamic>,
    location: json['nome-sala'] as String,
  );
}

Map<String, dynamic> _$ClassDataToJson(ClassData instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('man', instance.data);
  val['mans'] = instance.datum;
  val['nome-sala'] = instance.location;
  return val;
}

Class _$ClassFromJson(Map json) {
  $checkKeys(
    json,
    requiredKeys: const [
      'man',
      'mans',
      'nome-sala',
      '_id',
      'id-professor',
      'id-escola'
    ],
    disallowNullValues: const [
      'man',
      'mans',
      'nome-sala',
      '_id',
      'id-professor',
      'id-escola'
    ],
  );
  return Class(
    id: json['_id'] as String,
    data: json['man'],
    datum: json['mans'] as List<dynamic>,
    teacherId: json['id-professor'] as String,
    studentId: json['id-escola'] as String,
    location: json['nome-sala'] as String,
  );
}

Map<String, dynamic> _$ClassToJson(Class instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('man', instance.data);
  val['mans'] = instance.datum;
  val['nome-sala'] = instance.location;
  val['_id'] = instance.id;
  val['id-professor'] = instance.teacherId;
  val['id-escola'] = instance.studentId;
  return val;
}
