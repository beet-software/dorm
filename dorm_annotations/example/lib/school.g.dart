// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'school.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SchoolAddress _$SchoolAddressFromJson(Map json) {
  $checkKeys(
    json,
    requiredKeys: const ['ativo', 'bairro', 'numero'],
    disallowNullValues: const ['ativo', 'bairro', 'numero'],
  );
  return SchoolAddress(
    active: json['ativo'] as bool,
    district: json['bairro'] as String,
    zipCode: json['cep'] as String?,
    number: (json['numero'] as num).toInt(),
  );
}

Map<String, dynamic> _$SchoolAddressToJson(SchoolAddress instance) =>
    <String, dynamic>{
      'ativo': instance.active,
      'bairro': instance.district,
      'cep': instance.zipCode,
      'numero': instance.number,
    };

SchoolData _$SchoolDataFromJson(Map json) {
  $checkKeys(
    json,
    requiredKeys: const ['nome', 'endereco'],
    disallowNullValues: const ['nome', 'endereco'],
  );
  return SchoolData(
    name: json['nome'] as String,
    address: SchoolAddress.fromJson(json['endereco'] as Map),
    phoneNumbers: (json['contatos'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList() ??
        [],
  );
}

Map<String, dynamic> _$SchoolDataToJson(SchoolData instance) =>
    <String, dynamic>{
      'nome': instance.name,
      'endereco': instance.address.toJson(),
      'contatos': instance.phoneNumbers,
    };

School _$SchoolFromJson(Map json) {
  $checkKeys(
    json,
    requiredKeys: const ['nome', 'endereco', '_id'],
    disallowNullValues: const ['nome', 'endereco', '_id'],
  );
  return School(
    id: json['_id'] as String,
    name: json['nome'] as String,
    address: SchoolAddress.fromJson(json['endereco'] as Map),
    phoneNumbers: (json['contatos'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList() ??
        [],
  );
}

Map<String, dynamic> _$SchoolToJson(School instance) => <String, dynamic>{
      'nome': instance.name,
      'endereco': instance.address.toJson(),
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
    requiredKeys: const ['paraninfo', 'nome-sala'],
    disallowNullValues: const ['paraninfo', 'nome-sala'],
  );
  return ClassData(
    patron: TeacherData.fromJson(json['paraninfo'] as Map),
    location: json['nome-sala'] as String,
  );
}

Map<String, dynamic> _$ClassDataToJson(ClassData instance) => <String, dynamic>{
      'paraninfo': instance.patron.toJson(),
      'nome-sala': instance.location,
    };

Class _$ClassFromJson(Map json) {
  $checkKeys(
    json,
    requiredKeys: const [
      'paraninfo',
      'nome-sala',
      '_id',
      'id-professor',
      'id-escola'
    ],
    disallowNullValues: const [
      'paraninfo',
      'nome-sala',
      '_id',
      'id-professor',
      'id-escola'
    ],
  );
  return Class(
    id: json['_id'] as String,
    patron: TeacherData.fromJson(json['paraninfo'] as Map),
    teacherId: json['id-professor'] as String,
    studentId: json['id-escola'] as String,
    location: json['nome-sala'] as String,
  );
}

Map<String, dynamic> _$ClassToJson(Class instance) => <String, dynamic>{
      'paraninfo': instance.patron.toJson(),
      'nome-sala': instance.location,
      '_id': instance.id,
      'id-professor': instance.teacherId,
      'id-escola': instance.studentId,
    };
