import 'package:dorm_annotations/dorm_annotations.dart';
import 'package:json_annotation/json_annotation.dart';

part 'school.dorm.dart';

part 'school.g.dart';

@Model(name: 'escola', repositoryName: 'schools')
abstract class _School {
  @Field(name: 'nome', queryBy: QueryType.text)
  String get name;
}

@Model(name: 'aluno', repositoryName: 'students')
abstract class _Student {
  @Field(name: 'nome', queryBy: QueryType.text)
  String get name;

  @ForeignField(name: 'id-escola', referTo: _School)
  String get schoolId;
}

@Model(name: 'professor', repositoryName: 'teachers')
abstract class _Teacher {
  @Field(name: 'nome', queryBy: QueryType.text)
  String get name;
}

@Model(name: 'historico', repositoryName: 'histories')
abstract class _History {
  @ForeignField(name: 'id-aluno', referTo: _Student)
  String get studentId;
}

@Model(name: 'cadastro-professor', repositoryName: 'teachings')
abstract class _Teaching {
  @ForeignField(name: 'id-professor', referTo: _Teacher)
  String get teacherId;

  @ForeignField(name: 'id-escola', referTo: _School)
  String get schoolId;

  @Field(name: 'codigo')
  String get code;
}

@Model(name: 'aula', repositoryName: 'classes')
abstract class _Class {
  @ForeignField(name: 'id-professor', referTo: _Teacher)
  String get teacherId;

  @ForeignField(name: 'id-escola', referTo: _Student)
  String get studentId;

  @Field(name: 'nome-sala')
  String get location;
}
