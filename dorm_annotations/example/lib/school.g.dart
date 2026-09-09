// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'school.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SchoolCWProxy {
  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored.
  ///
  /// Example:
  /// ```dart
  /// School(...).copyWith(id: 12, name: "My name")
  /// ```
  School call({
    String id,
    String name,
    SchoolAddress address,
    List<String> phoneNumbers,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfSchool.copyWith(...)`.
class _$SchoolCWProxyImpl implements _$SchoolCWProxy {
  const _$SchoolCWProxyImpl(this._value);

  final School _value;

  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored.
  ///
  /// Example:
  /// ```dart
  /// School(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  School call({
    Object? id = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? address = const $CopyWithPlaceholder(),
    Object? phoneNumbers = const $CopyWithPlaceholder(),
  }) {
    return School(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      address: address == const $CopyWithPlaceholder() || address == null
          ? _value.address
          // ignore: cast_nullable_to_non_nullable
          : address as SchoolAddress,
      phoneNumbers:
          phoneNumbers == const $CopyWithPlaceholder() || phoneNumbers == null
          ? _value.phoneNumbers
          // ignore: cast_nullable_to_non_nullable
          : phoneNumbers as List<String>,
    );
  }
}

extension $SchoolCopyWith on School {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfSchool.copyWith(...)`.
  // ignore: library_private_types_in_public_api
  _$SchoolCWProxy get copyWith => _$SchoolCWProxyImpl(this);
}

abstract class _$StudentCWProxy {
  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored.
  ///
  /// Example:
  /// ```dart
  /// Student(...).copyWith(id: 12, name: "My name")
  /// ```
  Student call({
    String id,
    String name,
    StudentType hasDisabilities,
    String schoolId,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfStudent.copyWith(...)`.
class _$StudentCWProxyImpl implements _$StudentCWProxy {
  const _$StudentCWProxyImpl(this._value);

  final Student _value;

  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored.
  ///
  /// Example:
  /// ```dart
  /// Student(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  Student call({
    Object? id = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? hasDisabilities = const $CopyWithPlaceholder(),
    Object? schoolId = const $CopyWithPlaceholder(),
  }) {
    return Student(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      hasDisabilities:
          hasDisabilities == const $CopyWithPlaceholder() ||
              hasDisabilities == null
          ? _value.hasDisabilities
          // ignore: cast_nullable_to_non_nullable
          : hasDisabilities as StudentType,
      schoolId: schoolId == const $CopyWithPlaceholder() || schoolId == null
          ? _value.schoolId
          // ignore: cast_nullable_to_non_nullable
          : schoolId as String,
    );
  }
}

extension $StudentCopyWith on Student {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfStudent.copyWith(...)`.
  // ignore: library_private_types_in_public_api
  _$StudentCWProxy get copyWith => _$StudentCWProxyImpl(this);
}

abstract class _$TeacherCWProxy {
  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored.
  ///
  /// Example:
  /// ```dart
  /// Teacher(...).copyWith(id: 12, name: "My name")
  /// ```
  Teacher call({String id, String name, String? ssn});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfTeacher.copyWith(...)`.
class _$TeacherCWProxyImpl implements _$TeacherCWProxy {
  const _$TeacherCWProxyImpl(this._value);

  final Teacher _value;

  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored.
  ///
  /// Example:
  /// ```dart
  /// Teacher(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  Teacher call({
    Object? id = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? ssn = const $CopyWithPlaceholder(),
  }) {
    return Teacher(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      ssn: ssn == const $CopyWithPlaceholder()
          ? _value.ssn
          // ignore: cast_nullable_to_non_nullable
          : ssn as String?,
    );
  }
}

extension $TeacherCopyWith on Teacher {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfTeacher.copyWith(...)`.
  // ignore: library_private_types_in_public_api
  _$TeacherCWProxy get copyWith => _$TeacherCWProxyImpl(this);
}

abstract class _$HistoryCWProxy {
  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored.
  ///
  /// Example:
  /// ```dart
  /// History(...).copyWith(id: 12, name: "My name")
  /// ```
  History call({String id, String studentId});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfHistory.copyWith(...)`.
class _$HistoryCWProxyImpl implements _$HistoryCWProxy {
  const _$HistoryCWProxyImpl(this._value);

  final History _value;

  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored.
  ///
  /// Example:
  /// ```dart
  /// History(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  History call({
    Object? id = const $CopyWithPlaceholder(),
    Object? studentId = const $CopyWithPlaceholder(),
  }) {
    return History(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      studentId: studentId == const $CopyWithPlaceholder() || studentId == null
          ? _value.studentId
          // ignore: cast_nullable_to_non_nullable
          : studentId as String,
    );
  }
}

extension $HistoryCopyWith on History {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfHistory.copyWith(...)`.
  // ignore: library_private_types_in_public_api
  _$HistoryCWProxy get copyWith => _$HistoryCWProxyImpl(this);
}

abstract class _$TeachingCWProxy {
  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored.
  ///
  /// Example:
  /// ```dart
  /// Teaching(...).copyWith(id: 12, name: "My name")
  /// ```
  Teaching call({String id, String teacherId, String? schoolId, String code});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfTeaching.copyWith(...)`.
class _$TeachingCWProxyImpl implements _$TeachingCWProxy {
  const _$TeachingCWProxyImpl(this._value);

  final Teaching _value;

  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored.
  ///
  /// Example:
  /// ```dart
  /// Teaching(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  Teaching call({
    Object? id = const $CopyWithPlaceholder(),
    Object? teacherId = const $CopyWithPlaceholder(),
    Object? schoolId = const $CopyWithPlaceholder(),
    Object? code = const $CopyWithPlaceholder(),
  }) {
    return Teaching(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      teacherId: teacherId == const $CopyWithPlaceholder() || teacherId == null
          ? _value.teacherId
          // ignore: cast_nullable_to_non_nullable
          : teacherId as String,
      schoolId: schoolId == const $CopyWithPlaceholder()
          ? _value.schoolId
          // ignore: cast_nullable_to_non_nullable
          : schoolId as String?,
      code: code == const $CopyWithPlaceholder() || code == null
          ? _value.code
          // ignore: cast_nullable_to_non_nullable
          : code as String,
    );
  }
}

extension $TeachingCopyWith on Teaching {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfTeaching.copyWith(...)`.
  // ignore: library_private_types_in_public_api
  _$TeachingCWProxy get copyWith => _$TeachingCWProxyImpl(this);
}

abstract class _$ClassCWProxy {
  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored.
  ///
  /// Example:
  /// ```dart
  /// Class(...).copyWith(id: 12, name: "My name")
  /// ```
  Class call({
    String id,
    TeacherData patron,
    String teacherId,
    String studentId,
    String location,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfClass.copyWith(...)`.
class _$ClassCWProxyImpl implements _$ClassCWProxy {
  const _$ClassCWProxyImpl(this._value);

  final Class _value;

  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored.
  ///
  /// Example:
  /// ```dart
  /// Class(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  Class call({
    Object? id = const $CopyWithPlaceholder(),
    Object? patron = const $CopyWithPlaceholder(),
    Object? teacherId = const $CopyWithPlaceholder(),
    Object? studentId = const $CopyWithPlaceholder(),
    Object? location = const $CopyWithPlaceholder(),
  }) {
    return Class(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      patron: patron == const $CopyWithPlaceholder() || patron == null
          ? _value.patron
          // ignore: cast_nullable_to_non_nullable
          : patron as TeacherData,
      teacherId: teacherId == const $CopyWithPlaceholder() || teacherId == null
          ? _value.teacherId
          // ignore: cast_nullable_to_non_nullable
          : teacherId as String,
      studentId: studentId == const $CopyWithPlaceholder() || studentId == null
          ? _value.studentId
          // ignore: cast_nullable_to_non_nullable
          : studentId as String,
      location: location == const $CopyWithPlaceholder() || location == null
          ? _value.location
          // ignore: cast_nullable_to_non_nullable
          : location as String,
    );
  }
}

extension $ClassCopyWith on Class {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfClass.copyWith(...)`.
  // ignore: library_private_types_in_public_api
  _$ClassCWProxy get copyWith => _$ClassCWProxyImpl(this);
}

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
    phoneNumbers:
        (json['contatos'] as List<dynamic>?)
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
    phoneNumbers:
        (json['contatos'] as List<dynamic>?)
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
    hasDisabilities:
        $enumDecodeNullable(
          _$StudentTypeEnumMap,
          json['possui-deficiencias'],
        ) ??
        StudentType.regular,
  );
}

Map<String, dynamic> _$StudentDataToJson(StudentData instance) =>
    <String, dynamic>{
      'nome': instance.name,
      'possui-deficiencias': _$StudentTypeEnumMap[instance.hasDisabilities]!,
    };

const _$StudentTypeEnumMap = {
  StudentType.regular: 'regular',
  StudentType.special: 'special',
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
    hasDisabilities:
        $enumDecodeNullable(
          _$StudentTypeEnumMap,
          json['possui-deficiencias'],
        ) ??
        StudentType.regular,
    schoolId: json['id-escola'] as String,
  );
}

Map<String, dynamic> _$StudentToJson(Student instance) => <String, dynamic>{
  'nome': instance.name,
  'possui-deficiencias': _$StudentTypeEnumMap[instance.hasDisabilities]!,
  '_id': instance.id,
  'id-escola': instance.schoolId,
};

TeacherData _$TeacherDataFromJson(Map json) {
  $checkKeys(
    json,
    requiredKeys: const ['nome'],
    disallowNullValues: const ['nome'],
  );
  return TeacherData(name: json['nome'] as String, ssn: json['cpf'] as String?);
}

Map<String, dynamic> _$TeacherDataToJson(TeacherData instance) =>
    <String, dynamic>{'nome': instance.name, 'cpf': instance.ssn};

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
  return TeachingData(code: json['codigo'] as String);
}

Map<String, dynamic> _$TeachingDataToJson(TeachingData instance) =>
    <String, dynamic>{'codigo': instance.code};

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
      'id-escola',
    ],
    disallowNullValues: const [
      'paraninfo',
      'nome-sala',
      '_id',
      'id-professor',
      'id-escola',
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
