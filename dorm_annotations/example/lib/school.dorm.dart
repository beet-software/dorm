// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'school.dart';

// **************************************************************************
// OrmGenerator
// **************************************************************************

// **************************************************
//     DORM: School
// **************************************************

@JsonSerializable(anyMap: true, explicitToJson: true)
class SchoolData {
  @JsonKey(name: 'nome', required: true, disallowNullValue: true)
  final String name;

  factory SchoolData.fromJson(Map json) => _$SchoolDataFromJson(json);

  const SchoolData({
    required this.name,
  });

  Map<String, Object?> toJson() => _$SchoolDataToJson(this);
}

@JsonSerializable(anyMap: true, explicitToJson: true)
class School extends SchoolData implements _School {
  @JsonKey(name: '_id', required: true, disallowNullValue: true)
  final String id;

  factory School.fromJson(String id, Map json) =>
      _$SchoolFromJson({...json, '_id': id});

  const School({
    required this.id,
    required super.name,
  });

  @override
  Map<String, Object?> toJson() {
    return {
      ..._$SchoolToJson(this)..remove('_id'),
      '_query': {
        'nome': $normalizeText(name),
      },
    };
  }
}

class SchoolDependency extends Dependency<SchoolData> {
  const SchoolDependency() : super.strong();
}

class SchoolEntity implements Entity<SchoolData, School> {
  const SchoolEntity._();

  @override
  String get tableName => 'escola';

  @override
  School fromData(
    SchoolDependency dependency,
    String id,
    SchoolData data,
  ) {
    return School(
      id: id,
      name: data.name,
    );
  }

  @override
  School fromJson(String id, Map json) => School.fromJson(id, json);

  @override
  String identify(School model) => model.id;

  @override
  Map toJson(SchoolData data) => data.toJson();
}

// **************************************************
//     DORM: Student
// **************************************************

@JsonSerializable(anyMap: true, explicitToJson: true)
class StudentData {
  @JsonKey(name: 'nome', required: true, disallowNullValue: true)
  final String name;

  factory StudentData.fromJson(Map json) => _$StudentDataFromJson(json);

  const StudentData({
    required this.name,
  });

  Map<String, Object?> toJson() => _$StudentDataToJson(this);
}

@JsonSerializable(anyMap: true, explicitToJson: true)
class Student extends StudentData implements _Student {
  @JsonKey(name: '_id', required: true, disallowNullValue: true)
  final String id;

  @override
  @JsonKey(name: 'id-escola', required: true, disallowNullValue: true)
  final String schoolId;

  factory Student.fromJson(String id, Map json) =>
      _$StudentFromJson({...json, '_id': id});

  const Student({
    required this.id,
    required super.name,
    required this.schoolId,
  });

  @override
  Map<String, Object?> toJson() {
    return {
      ..._$StudentToJson(this)..remove('_id'),
      '_query': {
        'nome': $normalizeText(name),
      },
    };
  }
}

class StudentDependency extends Dependency<StudentData> {
  final String schoolId;

  StudentDependency({
    required this.schoolId,
  }) : super.weak([schoolId]);
}

class StudentEntity implements Entity<StudentData, Student> {
  const StudentEntity._();

  @override
  String get tableName => 'aluno';

  @override
  Student fromData(
    StudentDependency dependency,
    String id,
    StudentData data,
  ) {
    return Student(
      id: dependency.key(id),
      schoolId: dependency.schoolId,
      name: data.name,
    );
  }

  @override
  Student fromJson(String id, Map json) => Student.fromJson(id, json);

  @override
  String identify(Student model) => model.id;

  @override
  Map toJson(StudentData data) => data.toJson();
}

// **************************************************
//     DORM: Teacher
// **************************************************

@JsonSerializable(anyMap: true, explicitToJson: true)
class TeacherData {
  @JsonKey(name: 'nome', required: true, disallowNullValue: true)
  final String name;

  factory TeacherData.fromJson(Map json) => _$TeacherDataFromJson(json);

  const TeacherData({
    required this.name,
  });

  Map<String, Object?> toJson() => _$TeacherDataToJson(this);
}

@JsonSerializable(anyMap: true, explicitToJson: true)
class Teacher extends TeacherData implements _Teacher {
  @JsonKey(name: '_id', required: true, disallowNullValue: true)
  final String id;

  factory Teacher.fromJson(String id, Map json) =>
      _$TeacherFromJson({...json, '_id': id});

  const Teacher({
    required this.id,
    required super.name,
  });

  @override
  Map<String, Object?> toJson() {
    return {
      ..._$TeacherToJson(this)..remove('_id'),
      '_query': {
        'nome': $normalizeText(name),
      },
    };
  }
}

class TeacherDependency extends Dependency<TeacherData> {
  const TeacherDependency() : super.strong();
}

class TeacherEntity implements Entity<TeacherData, Teacher> {
  const TeacherEntity._();

  @override
  String get tableName => 'professor';

  @override
  Teacher fromData(
    TeacherDependency dependency,
    String id,
    TeacherData data,
  ) {
    return Teacher(
      id: id,
      name: data.name,
    );
  }

  @override
  Teacher fromJson(String id, Map json) => Teacher.fromJson(id, json);

  @override
  String identify(Teacher model) => model.id;

  @override
  Map toJson(TeacherData data) => data.toJson();
}

// **************************************************
//     DORM: History
// **************************************************

@JsonSerializable(anyMap: true, explicitToJson: true)
class HistoryData {
  factory HistoryData.fromJson(Map json) => _$HistoryDataFromJson(json);

  const HistoryData();

  Map<String, Object?> toJson() => _$HistoryDataToJson(this);
}

@JsonSerializable(anyMap: true, explicitToJson: true)
class History extends HistoryData implements _History {
  @JsonKey(name: '_id', required: true, disallowNullValue: true)
  final String id;

  @override
  @JsonKey(name: 'id-aluno', required: true, disallowNullValue: true)
  final String studentId;

  factory History.fromJson(String id, Map json) =>
      _$HistoryFromJson({...json, '_id': id});

  const History({
    required this.id,
    required this.studentId,
  });

  @override
  Map<String, Object?> toJson() {
    return {
      ..._$HistoryToJson(this)..remove('_id'),
    };
  }
}

class HistoryDependency extends Dependency<HistoryData> {
  final String studentId;

  HistoryDependency({
    required this.studentId,
  }) : super.weak([studentId]);
}

class HistoryEntity implements Entity<HistoryData, History> {
  const HistoryEntity._();

  @override
  String get tableName => 'historico';

  @override
  History fromData(
    HistoryDependency dependency,
    String id,
    HistoryData data,
  ) {
    return History(
      id: dependency.studentId,
      studentId: dependency.studentId,
    );
  }

  @override
  History fromJson(String id, Map json) => History.fromJson(id, json);

  @override
  String identify(History model) => model.id;

  @override
  Map toJson(HistoryData data) => data.toJson();
}

// **************************************************
//     DORM: Teaching
// **************************************************

@JsonSerializable(anyMap: true, explicitToJson: true)
class TeachingData {
  @JsonKey(name: 'codigo', required: true, disallowNullValue: true)
  final String code;

  factory TeachingData.fromJson(Map json) => _$TeachingDataFromJson(json);

  const TeachingData({
    required this.code,
  });

  Map<String, Object?> toJson() => _$TeachingDataToJson(this);
}

@JsonSerializable(anyMap: true, explicitToJson: true)
class Teaching extends TeachingData implements _Teaching {
  @JsonKey(name: '_id', required: true, disallowNullValue: true)
  final String id;

  @override
  @JsonKey(name: 'id-professor', required: true, disallowNullValue: true)
  final String teacherId;

  @override
  @JsonKey(name: 'id-escola', required: true, disallowNullValue: true)
  final String schoolId;

  factory Teaching.fromJson(String id, Map json) =>
      _$TeachingFromJson({...json, '_id': id});

  const Teaching({
    required this.id,
    required this.teacherId,
    required this.schoolId,
    required super.code,
  });

  @override
  Map<String, Object?> toJson() {
    return {
      ..._$TeachingToJson(this)..remove('_id'),
    };
  }
}

class TeachingDependency extends Dependency<TeachingData> {
  final String teacherId;
  final String schoolId;

  TeachingDependency({
    required this.teacherId,
    required this.schoolId,
  }) : super.weak([teacherId, schoolId]);
}

class TeachingEntity implements Entity<TeachingData, Teaching> {
  const TeachingEntity._();

  @override
  String get tableName => 'cadastro-professor';

  @override
  Teaching fromData(
    TeachingDependency dependency,
    String id,
    TeachingData data,
  ) {
    return Teaching(
      id: id,
      teacherId: dependency.teacherId,
      schoolId: dependency.schoolId,
      code: data.code,
    );
  }

  @override
  Teaching fromJson(String id, Map json) => Teaching.fromJson(id, json);

  @override
  String identify(Teaching model) => model.id;

  @override
  Map toJson(TeachingData data) => data.toJson();
}

// **************************************************
//     DORM: Class
// **************************************************

@JsonSerializable(anyMap: true, explicitToJson: true)
class ClassData {
  @JsonKey(name: 'nome-sala', required: true, disallowNullValue: true)
  final String location;

  factory ClassData.fromJson(Map json) => _$ClassDataFromJson(json);

  const ClassData({
    required this.location,
  });

  Map<String, Object?> toJson() => _$ClassDataToJson(this);
}

@JsonSerializable(anyMap: true, explicitToJson: true)
class Class extends ClassData implements _Class {
  @JsonKey(name: '_id', required: true, disallowNullValue: true)
  final String id;

  @override
  @JsonKey(name: 'id-professor', required: true, disallowNullValue: true)
  final String teacherId;

  @override
  @JsonKey(name: 'id-escola', required: true, disallowNullValue: true)
  final String studentId;

  factory Class.fromJson(String id, Map json) =>
      _$ClassFromJson({...json, '_id': id});

  const Class({
    required this.id,
    required this.teacherId,
    required this.studentId,
    required super.location,
  });

  @override
  Map<String, Object?> toJson() {
    return {
      ..._$ClassToJson(this)..remove('_id'),
    };
  }
}

class ClassDependency extends Dependency<ClassData> {
  final String teacherId;
  final String studentId;

  ClassDependency({
    required this.teacherId,
    required this.studentId,
  }) : super.weak([teacherId, studentId]);
}

class ClassEntity implements Entity<ClassData, Class> {
  const ClassEntity._();

  @override
  String get tableName => 'aula';

  @override
  Class fromData(
    ClassDependency dependency,
    String id,
    ClassData data,
  ) {
    return Class(
      id: dependency.key(id),
      teacherId: dependency.teacherId,
      studentId: dependency.studentId,
      location: data.location,
    );
  }

  @override
  Class fromJson(String id, Map json) => Class.fromJson(id, json);

  @override
  String identify(Class model) => model.id;

  @override
  Map toJson(ClassData data) => data.toJson();
}

// **************************************************
//     DORM
// **************************************************

class Dorm {
  final Reference _root;

  const Dorm(this._root);

  Repository<SchoolData, School> get schools =>
      Repository(root: _root, entity: const SchoolEntity._());

  Repository<StudentData, Student> get students =>
      Repository(root: _root, entity: const StudentEntity._());

  Repository<TeacherData, Teacher> get teachers =>
      Repository(root: _root, entity: const TeacherEntity._());

  Repository<HistoryData, History> get histories =>
      Repository(root: _root, entity: const HistoryEntity._());

  Repository<TeachingData, Teaching> get teachings =>
      Repository(root: _root, entity: const TeachingEntity._());

  Repository<ClassData, Class> get classes =>
      Repository(root: _root, entity: const ClassEntity._());
}
