// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'school.dart';

// **************************************************************************
// OrmGenerator
// **************************************************************************

@JsonSerializable(anyMap: true, explicitToJson: true)
class SchoolAddress implements _SchoolAddress {
  factory SchoolAddress.fromJson(Map json) => _$SchoolAddressFromJson(json);

  const SchoolAddress({
    required this.active,
    required this.district,
    required this.zipCode,
    required this.number,
  });

  @override
  @JsonKey(name: 'ativo', required: true, disallowNullValue: true)
  final bool active;

  @override
  @JsonKey(name: 'bairro', required: true, disallowNullValue: true)
  final String district;

  @override
  @JsonKey(name: 'cep')
  final String? zipCode;

  @override
  @JsonKey(name: 'numero', required: true, disallowNullValue: true)
  final int number;

  Map<String, Object?> toJson() => _$SchoolAddressToJson(this);
}

class _$School implements _School {
  factory _$School.fromData(SchoolDependency dependency, SchoolData data) =>
      _$School(
        name: data.name,
        address: data.address,
        phoneNumbers: data.phoneNumbers,
      );

  const _$School({
    required this.name,
    required this.address,
    required this.phoneNumbers,
  });

  @override
  final String name;

  @override
  final dynamic address;

  @override
  final List<String> phoneNumbers;

  @override
  String get _q0 => [$normalizeText(name)].join('_');

  void get $dorm$privateFields => [_q0];
}

@JsonSerializable(anyMap: true, explicitToJson: true)
class SchoolData {
  factory SchoolData.fromJson(Map json) => _$SchoolDataFromJson(json);

  const SchoolData({
    required this.name,
    required this.address,
    required this.phoneNumbers,
  });

  @JsonKey(name: 'nome', required: true, disallowNullValue: true)
  final String name;

  @JsonKey(name: 'endereco', required: true, disallowNullValue: true)
  final SchoolAddress address;

  @JsonKey(name: 'contatos', defaultValue: [])
  final List<String> phoneNumbers;

  Map<String, Object?> toJson() => _$SchoolDataToJson(this);
}

@JsonSerializable(anyMap: true, explicitToJson: true)
@CopyWith(skipFields: true)
class School extends SchoolData implements _School {
  factory School.fromJson(String id, Map json) =>
      _$SchoolFromJson({...json, '_id': id});

  const School({
    required this.id,
    required super.name,
    required super.address,
    required super.phoneNumbers,
  });

  @JsonKey(name: '_id', required: true, disallowNullValue: true)
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

class SchoolFields {
  const SchoolFields();

  final FieldSchema id = const FieldSchema(fieldName: 'id', columnName: 'id');

  final FieldSchema name = const FieldSchema(
    fieldName: 'name',
    columnName: 'nome',
  );

  final FieldSchema address = const FieldSchema(
    fieldName: 'address',
    columnName: 'endereco',
  );

  final FieldSchema phoneNumbers = const FieldSchema(
    fieldName: 'phoneNumbers',
    columnName: 'contatos',
  );

  final DerivedFieldSchema q0 = const DerivedFieldSchema(
    fieldName: '_q0',
    columnName: '_query/nome',
    path: ['_query', 'nome'],
    storageName: '_query',
  );
}

class SchoolEntity
    implements
        Entity<SchoolData, School, String, SimpleCreation<SchoolData, String>> {
  const SchoolEntity();

  static const SchoolFields fields = SchoolFields();

  static final EntitySchema _schema = EntitySchema(
    tableName: 'escola',
    primaryKeys: [fields.id],
    fields: [fields.name, fields.address, fields.phoneNumbers],
    derivedFields: [fields.q0],
  );

  @override
  EntitySchema get schema => _schema;

  @override
  PrimaryKeyCodec<String> get primaryKeyCodec => const SinglePrimaryKeyCodec();

  @override
  IdentityGenerationStrategy get identityGeneration =>
      IdentityGenerationStrategy.engine;

  @override
  School fromData(ResolvedCreation<SchoolData, String> creation) {
    return School(
      id: creation.identitySource == CreationIdentitySource.generated
          ? _School.$dorm$generateId(
              _$School.fromData(
                creation.dependency as SchoolDependency,
                creation.data,
              ),
              creation.id,
            )
          : creation.id,
      name: creation.data.name,
      address: creation.data.address,
      phoneNumbers: creation.data.phoneNumbers,
    );
  }

  @override
  School convert(School model, SchoolData data) => model.updateWith(data);

  @override
  School fromJson(String id, Map json) => School.fromJson(id, json);

  @override
  String identify(School model) => model.id;

  @override
  Map<String, Object?> toJson(SchoolData data) => data.toJson();
}

extension SchoolProperties on School {
  School updateWith(SchoolData data) {
    return School(
      id: id,
      name: data.name,
      address: data.address,
      phoneNumbers: data.phoneNumbers,
    );
  }
}

@JsonSerializable(anyMap: true, explicitToJson: true)
class StudentData {
  factory StudentData.fromJson(Map json) => _$StudentDataFromJson(json);

  const StudentData({required this.name, required this.hasDisabilities});

  @JsonKey(name: 'nome', required: true, disallowNullValue: true)
  final String name;

  @JsonKey(name: 'possui-deficiencias', defaultValue: StudentType.regular)
  final StudentType hasDisabilities;

  Map<String, Object?> toJson() => _$StudentDataToJson(this);
}

@JsonSerializable(anyMap: true, explicitToJson: true)
@CopyWith(skipFields: true)
class Student extends StudentData implements _Student {
  factory Student.fromJson(String id, Map json) =>
      _$StudentFromJson({...json, '_id': id});

  const Student({
    required this.id,
    required super.name,
    required super.hasDisabilities,
    required this.schoolId,
  });

  @JsonKey(name: '_id', required: true, disallowNullValue: true)
  final String id;

  @override
  @JsonKey(name: 'id-escola', required: true, disallowNullValue: true)
  final String schoolId;

  @override
  String get _q0 => [$normalizeText(name)].join('_');

  @override
  String get _q1 => [schoolId, $normalizeText(name)].join('_');

  @override
  Map<String, Object?> toJson() {
    return {
      ..._$StudentToJson(this)..remove('_id'),
      '_query': {'nome': _q0, 'id-escola_nome': _q1},
    };
  }
}

class StudentDependency extends Dependency<StudentData> {
  StudentDependency({required this.schoolId}) : super.weak([schoolId]);

  final String schoolId;
}

class StudentFields {
  const StudentFields();

  final FieldSchema id = const FieldSchema(fieldName: 'id', columnName: 'id');

  final FieldSchema name = const FieldSchema(
    fieldName: 'name',
    columnName: 'nome',
  );

  final FieldSchema hasDisabilities = const FieldSchema(
    fieldName: 'hasDisabilities',
    columnName: 'possui-deficiencias',
  );

  final ForeignKeySchema schoolId = const ForeignKeySchema(
    fieldName: 'schoolId',
    columnName: 'id-escola',
    targetTableName: 'escola',
    targetColumnName: 'id',
    unique: false,
  );

  final DerivedFieldSchema q0 = const DerivedFieldSchema(
    fieldName: '_q0',
    columnName: '_query/nome',
    path: ['_query', 'nome'],
    storageName: '_query',
  );

  final DerivedFieldSchema q1 = const DerivedFieldSchema(
    fieldName: '_q1',
    columnName: '_query/id-escola_nome',
    path: ['_query', 'id-escola_nome'],
    storageName: '_query',
  );
}

class StudentEntity
    implements
        Entity<
          StudentData,
          Student,
          String,
          SimpleCreation<StudentData, String>
        > {
  const StudentEntity();

  static const StudentFields fields = StudentFields();

  static final EntitySchema _schema = EntitySchema(
    tableName: 'aluno',
    primaryKeys: [fields.id],
    fields: [fields.name, fields.hasDisabilities, fields.schoolId],
    derivedFields: [fields.q0, fields.q1],
  );

  @override
  EntitySchema get schema => _schema;

  @override
  PrimaryKeyCodec<String> get primaryKeyCodec => const SinglePrimaryKeyCodec();

  @override
  IdentityGenerationStrategy get identityGeneration =>
      IdentityGenerationStrategy.engine;

  @override
  Student fromData(ResolvedCreation<StudentData, String> creation) {
    return Student(
      id: creation.id,
      name: creation.data.name,
      hasDisabilities: creation.data.hasDisabilities,
      schoolId: (creation.dependency as StudentDependency).schoolId,
    );
  }

  @override
  Student convert(Student model, StudentData data) => model.updateWith(data);

  @override
  Student fromJson(String id, Map json) => Student.fromJson(id, json);

  @override
  String identify(Student model) => model.id;

  @override
  Map<String, Object?> toJson(StudentData data) => data.toJson();
}

extension StudentProperties on Student {
  Student updateWith(StudentData data) {
    return Student(
      id: id,
      name: data.name,
      hasDisabilities: data.hasDisabilities,
      schoolId: schoolId,
    );
  }
}

@JsonSerializable(anyMap: true, explicitToJson: true)
class TeacherData {
  factory TeacherData.fromJson(Map json) => _$TeacherDataFromJson(json);

  const TeacherData({required this.name, required this.ssn});

  @JsonKey(name: 'nome', required: true, disallowNullValue: true)
  final String name;

  @JsonKey(name: 'cpf')
  final String? ssn;

  Map<String, Object?> toJson() => _$TeacherDataToJson(this);
}

@JsonSerializable(anyMap: true, explicitToJson: true)
@CopyWith(skipFields: true)
class Teacher extends TeacherData implements _Teacher {
  factory Teacher.fromJson(String id, Map json) =>
      _$TeacherFromJson({...json, '_id': id});

  const Teacher({required this.id, required super.name, required super.ssn});

  @JsonKey(name: '_id', required: true, disallowNullValue: true)
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

class TeacherFields {
  const TeacherFields();

  final FieldSchema id = const FieldSchema(fieldName: 'id', columnName: 'id');

  final FieldSchema name = const FieldSchema(
    fieldName: 'name',
    columnName: 'nome',
  );

  final FieldSchema ssn = const FieldSchema(
    fieldName: 'ssn',
    columnName: 'cpf',
  );

  final DerivedFieldSchema q0 = const DerivedFieldSchema(
    fieldName: '_q0',
    columnName: '_query/cpf',
    path: ['_query', 'cpf'],
    storageName: '_query',
  );
}

class TeacherEntity
    implements
        Entity<
          TeacherData,
          Teacher,
          String,
          SimpleCreation<TeacherData, String>
        > {
  const TeacherEntity();

  static const TeacherFields fields = TeacherFields();

  static final EntitySchema _schema = EntitySchema(
    tableName: 'professor',
    primaryKeys: [fields.id],
    fields: [fields.name, fields.ssn],
    derivedFields: [fields.q0],
  );

  @override
  EntitySchema get schema => _schema;

  @override
  PrimaryKeyCodec<String> get primaryKeyCodec => const SinglePrimaryKeyCodec();

  @override
  IdentityGenerationStrategy get identityGeneration =>
      IdentityGenerationStrategy.engine;

  @override
  Teacher fromData(ResolvedCreation<TeacherData, String> creation) {
    return Teacher(
      id: creation.id,
      name: creation.data.name,
      ssn: creation.data.ssn,
    );
  }

  @override
  Teacher convert(Teacher model, TeacherData data) => model.updateWith(data);

  @override
  Teacher fromJson(String id, Map json) => Teacher.fromJson(id, json);

  @override
  String identify(Teacher model) => model.id;

  @override
  Map<String, Object?> toJson(TeacherData data) => data.toJson();
}

extension TeacherProperties on Teacher {
  Teacher updateWith(TeacherData data) {
    return Teacher(id: id, name: data.name, ssn: data.ssn);
  }
}

class HistoryData {
  const HistoryData();

  Map<String, Object?> toJson() => const {};
}

@JsonSerializable(anyMap: true, explicitToJson: true)
@CopyWith(skipFields: true)
class History extends HistoryData implements _History {
  factory History.fromJson(String id, Map json) =>
      _$HistoryFromJson({...json, '_id': id});

  const History({required this.id, required this.studentId});

  @JsonKey(name: '_id', required: true, disallowNullValue: true)
  final String id;

  @override
  @JsonKey(name: 'id-aluno', required: true, disallowNullValue: true)
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

class HistoryFields {
  const HistoryFields();

  final FieldSchema id = const FieldSchema(fieldName: 'id', columnName: 'id');

  final ForeignKeySchema studentId = const ForeignKeySchema(
    fieldName: 'studentId',
    columnName: 'id-aluno',
    targetTableName: 'aluno',
    targetColumnName: 'id',
    unique: false,
  );
}

class HistoryEntity
    implements
        Entity<
          HistoryData,
          History,
          String,
          SimpleCreation<HistoryData, String>
        > {
  const HistoryEntity();

  static const HistoryFields fields = HistoryFields();

  static final EntitySchema _schema = EntitySchema(
    tableName: 'historico',
    primaryKeys: [fields.id],
    fields: [fields.studentId],
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
  History fromData(ResolvedCreation<HistoryData, String> creation) {
    return History(
      id: creation.id,
      studentId: (creation.dependency as HistoryDependency).studentId,
    );
  }

  @override
  History convert(History model, HistoryData data) => model;

  @override
  History fromJson(String id, Map json) => History.fromJson(id, json);

  @override
  String identify(History model) => model.id;

  @override
  Map<String, Object?> toJson(HistoryData data) => data.toJson();
}

@JsonSerializable(anyMap: true, explicitToJson: true)
class TeachingData {
  factory TeachingData.fromJson(Map json) => _$TeachingDataFromJson(json);

  const TeachingData({required this.code});

  @JsonKey(name: 'codigo', required: true, disallowNullValue: true)
  final String code;

  Map<String, Object?> toJson() => _$TeachingDataToJson(this);
}

@JsonSerializable(anyMap: true, explicitToJson: true)
@CopyWith(skipFields: true)
class Teaching extends TeachingData implements _Teaching {
  factory Teaching.fromJson(String id, Map json) =>
      _$TeachingFromJson({...json, '_id': id});

  const Teaching({
    required this.id,
    required this.teacherId,
    required this.schoolId,
    required super.code,
  });

  @JsonKey(name: '_id', required: true, disallowNullValue: true)
  final String id;

  @override
  @JsonKey(name: 'id-professor', required: true, disallowNullValue: true)
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
  TeachingDependency({required this.teacherId, required this.schoolId})
    : super.weak([teacherId, schoolId]);

  final String teacherId;

  final String? schoolId;
}

class TeachingFields {
  const TeachingFields();

  final FieldSchema id = const FieldSchema(fieldName: 'id', columnName: 'id');

  final ForeignKeySchema teacherId = const ForeignKeySchema(
    fieldName: 'teacherId',
    columnName: 'id-professor',
    targetTableName: 'professor',
    targetColumnName: 'id',
    unique: false,
  );

  final ForeignKeySchema schoolId = const ForeignKeySchema(
    fieldName: 'schoolId',
    columnName: 'id-escola',
    targetTableName: 'escola',
    targetColumnName: 'id',
    unique: false,
  );

  final FieldSchema code = const FieldSchema(
    fieldName: 'code',
    columnName: 'codigo',
  );
}

class TeachingEntity
    implements
        Entity<
          TeachingData,
          Teaching,
          String,
          SimpleCreation<TeachingData, String>
        > {
  const TeachingEntity();

  static const TeachingFields fields = TeachingFields();

  static final EntitySchema _schema = EntitySchema(
    tableName: 'cadastro-professor',
    primaryKeys: [fields.id],
    fields: [fields.teacherId, fields.schoolId, fields.code],
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
  Teaching fromData(ResolvedCreation<TeachingData, String> creation) {
    return Teaching(
      id: creation.id,
      teacherId: (creation.dependency as TeachingDependency).teacherId,
      schoolId: (creation.dependency as TeachingDependency).schoolId,
      code: creation.data.code,
    );
  }

  @override
  Teaching convert(Teaching model, TeachingData data) => model.updateWith(data);

  @override
  Teaching fromJson(String id, Map json) => Teaching.fromJson(id, json);

  @override
  String identify(Teaching model) => model.id;

  @override
  Map<String, Object?> toJson(TeachingData data) => data.toJson();
}

extension TeachingProperties on Teaching {
  Teaching updateWith(TeachingData data) {
    return Teaching(
      id: id,
      teacherId: teacherId,
      schoolId: schoolId,
      code: data.code,
    );
  }
}

@JsonSerializable(anyMap: true, explicitToJson: true)
class ClassData {
  factory ClassData.fromJson(Map json) => _$ClassDataFromJson(json);

  const ClassData({required this.patron, required this.location});

  @JsonKey(name: 'paraninfo', required: true, disallowNullValue: true)
  final TeacherData patron;

  @JsonKey(name: 'nome-sala', required: true, disallowNullValue: true)
  final String location;

  Map<String, Object?> toJson() => _$ClassDataToJson(this);
}

@JsonSerializable(anyMap: true, explicitToJson: true)
@CopyWith(skipFields: true)
class Class extends ClassData implements _Class {
  factory Class.fromJson(String id, Map json) =>
      _$ClassFromJson({...json, '_id': id});

  const Class({
    required this.id,
    required super.patron,
    required this.teacherId,
    required this.studentId,
    required super.location,
  });

  @JsonKey(name: '_id', required: true, disallowNullValue: true)
  final String id;

  @override
  @JsonKey(name: 'id-professor', required: true, disallowNullValue: true)
  final String teacherId;

  @override
  @JsonKey(name: 'id-escola', required: true, disallowNullValue: true)
  final String studentId;

  @override
  Map<String, Object?> toJson() {
    return {..._$ClassToJson(this)..remove('_id')};
  }
}

class ClassDependency extends Dependency<ClassData> {
  ClassDependency({required this.teacherId, required this.studentId})
    : super.weak([teacherId, studentId]);

  final String teacherId;

  final String studentId;
}

class ClassFields {
  const ClassFields();

  final FieldSchema id = const FieldSchema(fieldName: 'id', columnName: 'id');

  final FieldSchema patron = const FieldSchema(
    fieldName: 'patron',
    columnName: 'paraninfo',
  );

  final ForeignKeySchema teacherId = const ForeignKeySchema(
    fieldName: 'teacherId',
    columnName: 'id-professor',
    targetTableName: 'professor',
    targetColumnName: 'id',
    unique: false,
  );

  final ForeignKeySchema studentId = const ForeignKeySchema(
    fieldName: 'studentId',
    columnName: 'id-escola',
    targetTableName: 'aluno',
    targetColumnName: 'id',
    unique: false,
  );

  final FieldSchema location = const FieldSchema(
    fieldName: 'location',
    columnName: 'nome-sala',
  );
}

class ClassEntity
    implements
        Entity<ClassData, Class, String, SimpleCreation<ClassData, String>> {
  const ClassEntity();

  static const ClassFields fields = ClassFields();

  static final EntitySchema _schema = EntitySchema(
    tableName: 'aula',
    primaryKeys: [fields.id],
    fields: [
      fields.patron,
      fields.teacherId,
      fields.studentId,
      fields.location,
    ],
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
  Class fromData(ResolvedCreation<ClassData, String> creation) {
    return Class(
      id: creation.id,
      patron: creation.data.patron,
      teacherId: (creation.dependency as ClassDependency).teacherId,
      studentId: (creation.dependency as ClassDependency).studentId,
      location: creation.data.location,
    );
  }

  @override
  Class convert(Class model, ClassData data) => model.updateWith(data);

  @override
  Class fromJson(String id, Map json) => Class.fromJson(id, json);

  @override
  String identify(Class model) => model.id;

  @override
  Map<String, Object?> toJson(ClassData data) => data.toJson();
}

extension ClassProperties on Class {
  Class updateWith(ClassData data) {
    return Class(
      id: id,
      patron: data.patron,
      teacherId: teacherId,
      studentId: studentId,
      location: data.location,
    );
  }
}

class Dorm<Q extends BaseQuery<Q>, P extends PageRequest> {
  const Dorm(this._engine);

  final BaseEngine<Q, P> _engine;

  DatabaseEntity<
    SchoolData,
    School,
    String,
    Q,
    SimpleCreation<SchoolData, String>,
    P
  >
  get schools => DatabaseEntity(const SchoolEntity(), engine: _engine);

  DatabaseEntity<
    StudentData,
    Student,
    String,
    Q,
    SimpleCreation<StudentData, String>,
    P
  >
  get students => DatabaseEntity(const StudentEntity(), engine: _engine);

  DatabaseEntity<
    TeacherData,
    Teacher,
    String,
    Q,
    SimpleCreation<TeacherData, String>,
    P
  >
  get teachers => DatabaseEntity(const TeacherEntity(), engine: _engine);

  DatabaseEntity<
    HistoryData,
    History,
    String,
    Q,
    SimpleCreation<HistoryData, String>,
    P
  >
  get histories => DatabaseEntity(const HistoryEntity(), engine: _engine);

  DatabaseEntity<
    TeachingData,
    Teaching,
    String,
    Q,
    SimpleCreation<TeachingData, String>,
    P
  >
  get teachings => DatabaseEntity(const TeachingEntity(), engine: _engine);

  DatabaseEntity<
    ClassData,
    Class,
    String,
    Q,
    SimpleCreation<ClassData, String>,
    P
  >
  get classes => DatabaseEntity(const ClassEntity(), engine: _engine);

  DormRelations<Q, P> get relations => DormRelations<Q, P>(this);
}

class TransactionalDorm<Q extends BaseQuery<Q>, P extends PageRequest>
    extends Dorm<Q, P> {
  const TransactionalDorm(this._transactionalEngine)
    : super(_transactionalEngine);

  final TransactionalEngine<Q, P> _transactionalEngine;

  Future<T> transaction<T>(Future<T> Function(Dorm<Q, P>) action) =>
      _transactionalEngine.transaction((engine) => action(Dorm<Q, P>(engine)));
}

class DormRelations<Q extends BaseQuery<Q>, P extends PageRequest> {
  const DormRelations(this._dorm);

  final Dorm<Q, P> _dorm;

  RelationPath<Dorm<Q, P>, School, School, Q> get schools =>
      RelationPath.root(_dorm.schools.repository, context: _dorm);

  RelationPath<Dorm<Q, P>, Student, Student, Q> get students =>
      RelationPath.root(_dorm.students.repository, context: _dorm);

  RelationPath<Dorm<Q, P>, Teacher, Teacher, Q> get teachers =>
      RelationPath.root(_dorm.teachers.repository, context: _dorm);

  RelationPath<Dorm<Q, P>, History, History, Q> get histories =>
      RelationPath.root(_dorm.histories.repository, context: _dorm);

  RelationPath<Dorm<Q, P>, Teaching, Teaching, Q> get teachings =>
      RelationPath.root(_dorm.teachings.repository, context: _dorm);

  RelationPath<Dorm<Q, P>, Class, Class, Q> get classes =>
      RelationPath.root(_dorm.classes.repository, context: _dorm);
}

extension SchoolRelationPaths<
  Root,
  Q extends BaseQuery<Q>,
  P extends PageRequest
>
    on RelationPath<Dorm<Q, P>, Root, School, Q> {
  RelationPath<Dorm<Q, P>, Root, Student, Q> get students {
    return toMany(
      context.students.repository,
      spec: RelationSpec(
        cardinality: RelationCardinality.many,
        source: SchoolEntity.fields.id,
        target: StudentEntity.fields.schoolId,
      ),
      on: (model) =>
          BaseFilter.value(model.id, field: StudentEntity.fields.schoolId),
    );
  }

  RelationPath<Dorm<Q, P>, Root, List<Student>, Q> get studentsOrEmpty {
    return toManyOrEmpty(
      context.students.repository,
      spec: RelationSpec(
        cardinality: RelationCardinality.many,
        source: SchoolEntity.fields.id,
        target: StudentEntity.fields.schoolId,
      ),
      on: (model) =>
          BaseFilter.value(model.id, field: StudentEntity.fields.schoolId),
    );
  }

  RelationPath<Dorm<Q, P>, Root, Teaching, Q> get teachings {
    return toMany(
      context.teachings.repository,
      spec: RelationSpec(
        cardinality: RelationCardinality.many,
        source: SchoolEntity.fields.id,
        target: TeachingEntity.fields.schoolId,
      ),
      on: (model) =>
          BaseFilter.value(model.id, field: TeachingEntity.fields.schoolId),
    );
  }

  RelationPath<Dorm<Q, P>, Root, List<Teaching>, Q> get teachingsOrEmpty {
    return toManyOrEmpty(
      context.teachings.repository,
      spec: RelationSpec(
        cardinality: RelationCardinality.many,
        source: SchoolEntity.fields.id,
        target: TeachingEntity.fields.schoolId,
      ),
      on: (model) =>
          BaseFilter.value(model.id, field: TeachingEntity.fields.schoolId),
    );
  }
}

extension StudentRelationPaths<
  Root,
  Q extends BaseQuery<Q>,
  P extends PageRequest
>
    on RelationPath<Dorm<Q, P>, Root, Student, Q> {
  RelationPath<Dorm<Q, P>, Root, School, Q> get school {
    return toOne(
      context.schools.repository,
      spec: RelationSpec(
        cardinality: RelationCardinality.one,
        source: StudentEntity.fields.schoolId,
        target: SchoolEntity.fields.id,
      ),
      on: (model) => model.schoolId,
    );
  }

  RelationPath<Dorm<Q, P>, Root, School?, Q> get schoolOrNull {
    return toOneOrNull(
      context.schools.repository,
      spec: RelationSpec(
        cardinality: RelationCardinality.one,
        source: StudentEntity.fields.schoolId,
        target: SchoolEntity.fields.id,
      ),
      on: (model) => model.schoolId,
    );
  }

  RelationPath<Dorm<Q, P>, Root, History, Q> get histories {
    return toMany(
      context.histories.repository,
      spec: RelationSpec(
        cardinality: RelationCardinality.many,
        source: StudentEntity.fields.id,
        target: HistoryEntity.fields.studentId,
      ),
      on: (model) =>
          BaseFilter.value(model.id, field: HistoryEntity.fields.studentId),
    );
  }

  RelationPath<Dorm<Q, P>, Root, List<History>, Q> get historiesOrEmpty {
    return toManyOrEmpty(
      context.histories.repository,
      spec: RelationSpec(
        cardinality: RelationCardinality.many,
        source: StudentEntity.fields.id,
        target: HistoryEntity.fields.studentId,
      ),
      on: (model) =>
          BaseFilter.value(model.id, field: HistoryEntity.fields.studentId),
    );
  }

  RelationPath<Dorm<Q, P>, Root, Class, Q> get classes {
    return toMany(
      context.classes.repository,
      spec: RelationSpec(
        cardinality: RelationCardinality.many,
        source: StudentEntity.fields.id,
        target: ClassEntity.fields.studentId,
      ),
      on: (model) =>
          BaseFilter.value(model.id, field: ClassEntity.fields.studentId),
    );
  }

  RelationPath<Dorm<Q, P>, Root, List<Class>, Q> get classesOrEmpty {
    return toManyOrEmpty(
      context.classes.repository,
      spec: RelationSpec(
        cardinality: RelationCardinality.many,
        source: StudentEntity.fields.id,
        target: ClassEntity.fields.studentId,
      ),
      on: (model) =>
          BaseFilter.value(model.id, field: ClassEntity.fields.studentId),
    );
  }
}

extension TeacherRelationPaths<
  Root,
  Q extends BaseQuery<Q>,
  P extends PageRequest
>
    on RelationPath<Dorm<Q, P>, Root, Teacher, Q> {
  RelationPath<Dorm<Q, P>, Root, Teaching, Q> get teachings {
    return toMany(
      context.teachings.repository,
      spec: RelationSpec(
        cardinality: RelationCardinality.many,
        source: TeacherEntity.fields.id,
        target: TeachingEntity.fields.teacherId,
      ),
      on: (model) =>
          BaseFilter.value(model.id, field: TeachingEntity.fields.teacherId),
    );
  }

  RelationPath<Dorm<Q, P>, Root, List<Teaching>, Q> get teachingsOrEmpty {
    return toManyOrEmpty(
      context.teachings.repository,
      spec: RelationSpec(
        cardinality: RelationCardinality.many,
        source: TeacherEntity.fields.id,
        target: TeachingEntity.fields.teacherId,
      ),
      on: (model) =>
          BaseFilter.value(model.id, field: TeachingEntity.fields.teacherId),
    );
  }

  RelationPath<Dorm<Q, P>, Root, Class, Q> get classes {
    return toMany(
      context.classes.repository,
      spec: RelationSpec(
        cardinality: RelationCardinality.many,
        source: TeacherEntity.fields.id,
        target: ClassEntity.fields.teacherId,
      ),
      on: (model) =>
          BaseFilter.value(model.id, field: ClassEntity.fields.teacherId),
    );
  }

  RelationPath<Dorm<Q, P>, Root, List<Class>, Q> get classesOrEmpty {
    return toManyOrEmpty(
      context.classes.repository,
      spec: RelationSpec(
        cardinality: RelationCardinality.many,
        source: TeacherEntity.fields.id,
        target: ClassEntity.fields.teacherId,
      ),
      on: (model) =>
          BaseFilter.value(model.id, field: ClassEntity.fields.teacherId),
    );
  }
}

extension HistoryRelationPaths<
  Root,
  Q extends BaseQuery<Q>,
  P extends PageRequest
>
    on RelationPath<Dorm<Q, P>, Root, History, Q> {
  RelationPath<Dorm<Q, P>, Root, Student, Q> get student {
    return toOne(
      context.students.repository,
      spec: RelationSpec(
        cardinality: RelationCardinality.one,
        source: HistoryEntity.fields.studentId,
        target: StudentEntity.fields.id,
      ),
      on: (model) => model.studentId,
    );
  }

  RelationPath<Dorm<Q, P>, Root, Student?, Q> get studentOrNull {
    return toOneOrNull(
      context.students.repository,
      spec: RelationSpec(
        cardinality: RelationCardinality.one,
        source: HistoryEntity.fields.studentId,
        target: StudentEntity.fields.id,
      ),
      on: (model) => model.studentId,
    );
  }
}

extension TeachingRelationPaths<
  Root,
  Q extends BaseQuery<Q>,
  P extends PageRequest
>
    on RelationPath<Dorm<Q, P>, Root, Teaching, Q> {
  RelationPath<Dorm<Q, P>, Root, Teacher, Q> get teacher {
    return toOne(
      context.teachers.repository,
      spec: RelationSpec(
        cardinality: RelationCardinality.one,
        source: TeachingEntity.fields.teacherId,
        target: TeacherEntity.fields.id,
      ),
      on: (model) => model.teacherId,
    );
  }

  RelationPath<Dorm<Q, P>, Root, Teacher?, Q> get teacherOrNull {
    return toOneOrNull(
      context.teachers.repository,
      spec: RelationSpec(
        cardinality: RelationCardinality.one,
        source: TeachingEntity.fields.teacherId,
        target: TeacherEntity.fields.id,
      ),
      on: (model) => model.teacherId,
    );
  }

  RelationPath<Dorm<Q, P>, Root, School, Q> get school {
    return toOne(
      context.schools.repository,
      spec: RelationSpec(
        cardinality: RelationCardinality.one,
        source: TeachingEntity.fields.schoolId,
        target: SchoolEntity.fields.id,
      ),
      on: (model) => model.schoolId,
    );
  }

  RelationPath<Dorm<Q, P>, Root, School?, Q> get schoolOrNull {
    return toOneOrNull(
      context.schools.repository,
      spec: RelationSpec(
        cardinality: RelationCardinality.one,
        source: TeachingEntity.fields.schoolId,
        target: SchoolEntity.fields.id,
      ),
      on: (model) => model.schoolId,
    );
  }
}

extension ClassRelationPaths<
  Root,
  Q extends BaseQuery<Q>,
  P extends PageRequest
>
    on RelationPath<Dorm<Q, P>, Root, Class, Q> {
  RelationPath<Dorm<Q, P>, Root, Teacher, Q> get teacher {
    return toOne(
      context.teachers.repository,
      spec: RelationSpec(
        cardinality: RelationCardinality.one,
        source: ClassEntity.fields.teacherId,
        target: TeacherEntity.fields.id,
      ),
      on: (model) => model.teacherId,
    );
  }

  RelationPath<Dorm<Q, P>, Root, Teacher?, Q> get teacherOrNull {
    return toOneOrNull(
      context.teachers.repository,
      spec: RelationSpec(
        cardinality: RelationCardinality.one,
        source: ClassEntity.fields.teacherId,
        target: TeacherEntity.fields.id,
      ),
      on: (model) => model.teacherId,
    );
  }

  RelationPath<Dorm<Q, P>, Root, Student, Q> get student {
    return toOne(
      context.students.repository,
      spec: RelationSpec(
        cardinality: RelationCardinality.one,
        source: ClassEntity.fields.studentId,
        target: StudentEntity.fields.id,
      ),
      on: (model) => model.studentId,
    );
  }

  RelationPath<Dorm<Q, P>, Root, Student?, Q> get studentOrNull {
    return toOneOrNull(
      context.students.repository,
      spec: RelationSpec(
        cardinality: RelationCardinality.one,
        source: ClassEntity.fields.studentId,
        target: StudentEntity.fields.id,
      ),
      on: (model) => model.studentId,
    );
  }
}
