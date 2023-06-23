// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'school.dart';

// **************************************************************************
// OrmGenerator
// **************************************************************************

@JsonSerializable(
  anyMap: true,
  explicitToJson: true,
)
class SchoolAddress {
  factory SchoolAddress.fromJson(Map json) => _$SchoolAddressFromJson(json);

  const SchoolAddress({
    required this.active,
    required this.district,
    required this.zipCode,
    required this.number,
  });

  @JsonKey(
    name: 'ativo',
    required: true,
    disallowNullValue: true,
  )
  final bool active;

  @JsonKey(
    name: 'bairro',
    required: true,
    disallowNullValue: true,
  )
  final String district;

  @JsonKey(name: 'cep')
  final String? zipCode;

  @JsonKey(
    name: 'numero',
    required: true,
    disallowNullValue: true,
  )
  final int number;

  Map<String, Object?> toJson() => _$SchoolAddressToJson(this);
}

@JsonSerializable(
  anyMap: true,
  explicitToJson: true,
)
class SchoolData {
  factory SchoolData.fromJson(Map json) => _$SchoolDataFromJson(json);

  const SchoolData({
    required this.name,
    required this.address,
    required this.phoneNumbers,
  });

  @JsonKey(
    name: 'nome',
    required: true,
    disallowNullValue: true,
  )
  final String name;

  @JsonKey(
    name: 'endereco',
    required: true,
    disallowNullValue: true,
  )
  final SchoolAddress address;

  @JsonKey(
    name: 'contatos',
    defaultValue: [],
  )
  final List<String> phoneNumbers;

  Map<String, Object?> toJson() => _$SchoolDataToJson(this);
}

@JsonSerializable(
  anyMap: true,
  explicitToJson: true,
)
class School extends SchoolData implements _School {
  factory School.fromJson(
    String id,
    Map json,
  ) =>
      _$SchoolFromJson({
        ...json,
        '_id': id,
      });

  const School({
    required this.id,
    required super.name,
    required super.address,
    required super.phoneNumbers,
  });

  @JsonKey(
    name: '_id',
    required: true,
    disallowNullValue: true,
  )
  final String id;

  @override
  String get _q0 => [$normalizeText(name)].join('_');
  @override
  Map<String, Object?> toJson() {
    return {
      ..._$SchoolToJson(this)..remove('_id'),
      '_query': {'nome': _q0},
    };
  }
}

class SchoolDependency extends Dependency<SchoolData> {
  const SchoolDependency() : super.strong();
}

class SchoolEntity implements Entity<SchoolData, School> {
  const SchoolEntity();

  @override
  final String tableName = 'escola';

  @override
  School fromData(
    SchoolDependency dependency,
    String id,
    SchoolData data,
  ) {
    return School(
      id: id,
      name: data.name,
      address: data.address,
      phoneNumbers: data.phoneNumbers,
    );
  }

  @override
  School convert(
    School model,
    SchoolData data,
  ) {
    return School(
      id: model.id,
      name: data.name,
      address: data.address,
      phoneNumbers: data.phoneNumbers,
    );
  }

  @override
  School fromJson(
    String id,
    Map json,
  ) =>
      School.fromJson(
        id,
        json,
      );
  @override
  String identify(School model) => model.id;
  @override
  Map<String, Object?> toJson(SchoolData data) => data.toJson();
}

@JsonSerializable(
  anyMap: true,
  explicitToJson: true,
)
class StudentData {
  factory StudentData.fromJson(Map json) => _$StudentDataFromJson(json);

  const StudentData({
    required this.name,
    required this.hasDisabilities,
  });

  @JsonKey(
    name: 'nome',
    required: true,
    disallowNullValue: true,
  )
  final String name;

  @JsonKey(
    name: 'possui-deficiencias',
    defaultValue: false,
  )
  final bool hasDisabilities;

  Map<String, Object?> toJson() => _$StudentDataToJson(this);
}

@JsonSerializable(
  anyMap: true,
  explicitToJson: true,
)
class Student extends StudentData implements _Student {
  factory Student.fromJson(
    String id,
    Map json,
  ) =>
      _$StudentFromJson({
        ...json,
        '_id': id,
      });

  const Student({
    required this.id,
    required super.name,
    required super.hasDisabilities,
    required this.schoolId,
  });

  @JsonKey(
    name: '_id',
    required: true,
    disallowNullValue: true,
  )
  final String id;

  @override
  @JsonKey(
    name: 'id-escola',
    required: true,
    disallowNullValue: true,
  )
  final String schoolId;

  @override
  String get _q0 => [$normalizeText(name)].join('_');
  @override
  String get _q1 => [
        schoolId,
        $normalizeText(name),
      ].join('_');
  @override
  Map<String, Object?> toJson() {
    return {
      ..._$StudentToJson(this)..remove('_id'),
      '_query': {
        'nome': _q0,
        'id-escola_nome': _q1,
      },
    };
  }
}

class StudentDependency extends Dependency<StudentData> {
  StudentDependency({required this.schoolId}) : super.weak([schoolId]);

  final String schoolId;
}

class StudentEntity implements Entity<StudentData, Student> {
  const StudentEntity();

  @override
  final String tableName = 'aluno';

  @override
  Student fromData(
    StudentDependency dependency,
    String id,
    StudentData data,
  ) {
    return Student(
      id: dependency.key(id),
      name: data.name,
      hasDisabilities: data.hasDisabilities,
      schoolId: dependency.schoolId,
    );
  }

  @override
  Student convert(
    Student model,
    StudentData data,
  ) {
    return Student(
      id: model.id,
      name: data.name,
      hasDisabilities: data.hasDisabilities,
      schoolId: model.schoolId,
    );
  }

  @override
  Student fromJson(
    String id,
    Map json,
  ) =>
      Student.fromJson(
        id,
        json,
      );
  @override
  String identify(Student model) => model.id;
  @override
  Map<String, Object?> toJson(StudentData data) => data.toJson();
}

class _$Teacher implements _Teacher {
  factory _$Teacher.fromData(
    TeacherDependency dependency,
    TeacherData data,
  ) =>
      _$Teacher(
        name: data.name,
        ssn: data.ssn,
      );

  const _$Teacher({
    required this.name,
    required this.ssn,
  });

  @override
  final String name;

  @override
  final String? ssn;

  @override
  String get _q0 => [ssn ?? ''].join('_');
}

@JsonSerializable(
  anyMap: true,
  explicitToJson: true,
)
class TeacherData {
  factory TeacherData.fromJson(Map json) => _$TeacherDataFromJson(json);

  const TeacherData({
    required this.name,
    required this.ssn,
  });

  @JsonKey(
    name: 'nome',
    required: true,
    disallowNullValue: true,
  )
  final String name;

  @JsonKey(name: 'cpf')
  final String? ssn;

  Map<String, Object?> toJson() => _$TeacherDataToJson(this);
}

@JsonSerializable(
  anyMap: true,
  explicitToJson: true,
)
class Teacher extends TeacherData implements _Teacher {
  factory Teacher.fromJson(
    String id,
    Map json,
  ) =>
      _$TeacherFromJson({
        ...json,
        '_id': id,
      });

  const Teacher({
    required this.id,
    required super.name,
    required super.ssn,
  });

  @JsonKey(
    name: '_id',
    required: true,
    disallowNullValue: true,
  )
  final String id;

  @override
  String get _q0 => [ssn ?? ''].join('_');
  @override
  Map<String, Object?> toJson() {
    return {
      ..._$TeacherToJson(this)..remove('_id'),
      '_query': {'cpf': _q0},
    };
  }
}

class TeacherDependency extends Dependency<TeacherData> {
  const TeacherDependency() : super.strong();
}

class TeacherEntity implements Entity<TeacherData, Teacher> {
  const TeacherEntity();

  @override
  final String tableName = 'professor';

  @override
  Teacher fromData(
    TeacherDependency dependency,
    String id,
    TeacherData data,
  ) {
    return Teacher(
      id: _Teacher._id(_$Teacher.fromData(
        dependency,
        data,
      )).when(
        caseSimple: () => id,
        caseComposite: () => dependency.key(id),
        caseValue: (id) => id,
      ),
      name: data.name,
      ssn: data.ssn,
    );
  }

  @override
  Teacher convert(
    Teacher model,
    TeacherData data,
  ) {
    return Teacher(
      id: model.id,
      name: data.name,
      ssn: data.ssn,
    );
  }

  @override
  Teacher fromJson(
    String id,
    Map json,
  ) =>
      Teacher.fromJson(
        id,
        json,
      );
  @override
  String identify(Teacher model) => model.id;
  @override
  Map<String, Object?> toJson(TeacherData data) => data.toJson();
}

@JsonSerializable(
  anyMap: true,
  explicitToJson: true,
)
class HistoryData {
  factory HistoryData.fromJson(Map json) => _$HistoryDataFromJson(json);

  const HistoryData();

  Map<String, Object?> toJson() => _$HistoryDataToJson(this);
}

@JsonSerializable(
  anyMap: true,
  explicitToJson: true,
)
class History extends HistoryData implements _History {
  factory History.fromJson(
    String id,
    Map json,
  ) =>
      _$HistoryFromJson({
        ...json,
        '_id': id,
      });

  const History({
    required this.id,
    required this.studentId,
  });

  @JsonKey(
    name: '_id',
    required: true,
    disallowNullValue: true,
  )
  final String id;

  @override
  @JsonKey(
    name: 'id-aluno',
    required: true,
    disallowNullValue: true,
  )
  final String studentId;

  @override
  Map<String, Object?> toJson() {
    return {..._$HistoryToJson(this)..remove('_id')};
  }
}

class HistoryDependency extends Dependency<HistoryData> {
  HistoryDependency({required this.studentId}) : super.weak([studentId]);

  final String studentId;
}

class HistoryEntity implements Entity<HistoryData, History> {
  const HistoryEntity();

  @override
  final String tableName = 'historico';

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
  History convert(
    History model,
    HistoryData data,
  ) {
    return History(
      id: model.id,
      studentId: model.studentId,
    );
  }

  @override
  History fromJson(
    String id,
    Map json,
  ) =>
      History.fromJson(
        id,
        json,
      );
  @override
  String identify(History model) => model.id;
  @override
  Map<String, Object?> toJson(HistoryData data) => data.toJson();
}

@JsonSerializable(
  anyMap: true,
  explicitToJson: true,
)
class TeachingData {
  factory TeachingData.fromJson(Map json) => _$TeachingDataFromJson(json);

  const TeachingData({required this.code});

  @JsonKey(
    name: 'codigo',
    required: true,
    disallowNullValue: true,
  )
  final String code;

  Map<String, Object?> toJson() => _$TeachingDataToJson(this);
}

@JsonSerializable(
  anyMap: true,
  explicitToJson: true,
)
class Teaching extends TeachingData implements _Teaching {
  factory Teaching.fromJson(
    String id,
    Map json,
  ) =>
      _$TeachingFromJson({
        ...json,
        '_id': id,
      });

  const Teaching({
    required this.id,
    required this.teacherId,
    required this.schoolId,
    required super.code,
  });

  @JsonKey(
    name: '_id',
    required: true,
    disallowNullValue: true,
  )
  final String id;

  @override
  @JsonKey(
    name: 'id-professor',
    required: true,
    disallowNullValue: true,
  )
  final String teacherId;

  @override
  @JsonKey(name: 'id-escola')
  final String? schoolId;

  @override
  Map<String, Object?> toJson() {
    return {..._$TeachingToJson(this)..remove('_id')};
  }
}

class TeachingDependency extends Dependency<TeachingData> {
  TeachingDependency({
    required this.teacherId,
    required this.schoolId,
  }) : super.weak([
          teacherId,
          schoolId ?? '',
        ]);

  final String teacherId;

  final String? schoolId;
}

class TeachingEntity implements Entity<TeachingData, Teaching> {
  const TeachingEntity();

  @override
  final String tableName = 'cadastro-professor';

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
  Teaching convert(
    Teaching model,
    TeachingData data,
  ) {
    return Teaching(
      id: model.id,
      teacherId: model.teacherId,
      schoolId: model.schoolId,
      code: data.code,
    );
  }

  @override
  Teaching fromJson(
    String id,
    Map json,
  ) =>
      Teaching.fromJson(
        id,
        json,
      );
  @override
  String identify(Teaching model) => model.id;
  @override
  Map<String, Object?> toJson(TeachingData data) => data.toJson();
}

@JsonSerializable(
  anyMap: true,
  explicitToJson: true,
)
class ClassData {
  factory ClassData.fromJson(Map json) => _$ClassDataFromJson(json);

  const ClassData({
    required this.patron,
    required this.location,
  });

  @JsonKey(
    name: 'paraninfo',
    required: true,
    disallowNullValue: true,
  )
  final TeacherData patron;

  @JsonKey(
    name: 'nome-sala',
    required: true,
    disallowNullValue: true,
  )
  final String location;

  Map<String, Object?> toJson() => _$ClassDataToJson(this);
}

@JsonSerializable(
  anyMap: true,
  explicitToJson: true,
)
class Class extends ClassData implements _Class {
  factory Class.fromJson(
    String id,
    Map json,
  ) =>
      _$ClassFromJson({
        ...json,
        '_id': id,
      });

  const Class({
    required this.id,
    required super.patron,
    required this.teacherId,
    required this.studentId,
    required super.location,
  });

  @JsonKey(
    name: '_id',
    required: true,
    disallowNullValue: true,
  )
  final String id;

  @override
  @JsonKey(
    name: 'id-professor',
    required: true,
    disallowNullValue: true,
  )
  final String teacherId;

  @override
  @JsonKey(
    name: 'id-escola',
    required: true,
    disallowNullValue: true,
  )
  final String studentId;

  @override
  Map<String, Object?> toJson() {
    return {..._$ClassToJson(this)..remove('_id')};
  }
}

class ClassDependency extends Dependency<ClassData> {
  ClassDependency({
    required this.teacherId,
    required this.studentId,
  }) : super.weak([
          teacherId,
          studentId,
        ]);

  final String teacherId;

  final String studentId;
}

class ClassEntity implements Entity<ClassData, Class> {
  const ClassEntity();

  @override
  final String tableName = 'aula';

  @override
  Class fromData(
    ClassDependency dependency,
    String id,
    ClassData data,
  ) {
    return Class(
      id: dependency.key(id),
      patron: data.patron,
      teacherId: dependency.teacherId,
      studentId: dependency.studentId,
      location: data.location,
    );
  }

  @override
  Class convert(
    Class model,
    ClassData data,
  ) {
    return Class(
      id: model.id,
      patron: data.patron,
      teacherId: model.teacherId,
      studentId: model.studentId,
      location: data.location,
    );
  }

  @override
  Class fromJson(
    String id,
    Map json,
  ) =>
      Class.fromJson(
        id,
        json,
      );
  @override
  String identify(Class model) => model.id;
  @override
  Map<String, Object?> toJson(ClassData data) => data.toJson();
}

class Dorm {
  const Dorm(this._root);

  final BaseReference _root;

  DatabaseEntity<SchoolData, School> get schools => DatabaseEntity(
        const SchoolEntity(),
        reference: _root,
      );
  DatabaseEntity<StudentData, Student> get students => DatabaseEntity(
        const StudentEntity(),
        reference: _root,
      );
  DatabaseEntity<TeacherData, Teacher> get teachers => DatabaseEntity(
        const TeacherEntity(),
        reference: _root,
      );
  DatabaseEntity<HistoryData, History> get histories => DatabaseEntity(
        const HistoryEntity(),
        reference: _root,
      );
  DatabaseEntity<TeachingData, Teaching> get teachings => DatabaseEntity(
        const TeachingEntity(),
        reference: _root,
      );
  DatabaseEntity<ClassData, Class> get classes => DatabaseEntity(
        const ClassEntity(),
        reference: _root,
      );
}
