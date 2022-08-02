import 'package:dorm_annotations/dorm_annotations.dart';
import 'package:json_annotation/json_annotation.dart';

part 'school.dorm.dart';

part 'school.g.dart';

@Model(
  name: 'escola',
  repositoryName: 'schools',
  uidType: UidType.simple(),
)
abstract class _School {
  @Field(name: 'nome', queryBy: QueryType.text)
  String get name;
}

@Model(
  name: 'aluno',
  repositoryName: 'students',
  uidType: UidType.composite(),
)
abstract class _Student {
  @Field(name: 'nome', queryBy: QueryType.text)
  String get name;

  @ForeignField(name: 'id-escola', referTo: _School)
  String get schoolId;
}

@Model(
  name: 'professor',
  repositoryName: 'teachers',
  uidType: UidType.custom(_Teacher._id),
)
abstract class _Teacher {
  static CustomUidValue _id(Object data) {
    data as TeacherData;
    final String? ssn = data.ssn;
    if (ssn == null) return const CustomUidValue.composite();
    return CustomUidValue.value(ssn.replaceAll('[^0-9]', ''));
  }

  @Field(name: 'nome', queryBy: QueryType.text)
  String get name;

  @Field(name: 'cpf')
  String? get ssn;
}

@Model(
  name: 'historico',
  repositoryName: 'histories',
  uidType: UidType.sameAs(_Student),
)
abstract class _History {
  @ForeignField(name: 'id-aluno', referTo: _Student)
  String get studentId;
}

@Model(
  name: 'cadastro-professor',
  repositoryName: 'teachings',
)
abstract class _Teaching {
  @ForeignField(name: 'id-professor', referTo: _Teacher)
  String get teacherId;

  @ForeignField(name: 'id-escola', referTo: _School)
  String get schoolId;

  @Field(name: 'codigo')
  String get code;
}

@Model(
  name: 'aula',
  repositoryName: 'classes',
  uidType: UidType.composite(),
)
abstract class _Class {
  @ForeignField(name: 'id-professor', referTo: _Teacher)
  String get teacherId;

  @ForeignField(name: 'id-escola', referTo: _Student)
  String get studentId;

  @Field(name: 'nome-sala')
  String get location;
}
