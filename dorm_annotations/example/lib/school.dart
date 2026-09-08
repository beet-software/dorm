import 'package:dorm_annotations/dorm_annotations.dart';
import 'package:dorm_framework/dorm_framework.dart';

part 'school.dorm.dart';
part 'school.g.dart';

@Data()
abstract class _SchoolAddress {
  @Field(name: 'ativo')
  bool get active;

  @Field(name: 'bairro')
  String get district;

  @Field(name: 'cep')
  String? get zipCode;

  @Field(name: 'numero')
  int get number;
}

@Model(name: 'escola', as: #schools)
abstract class _School {
  static String $dorm$generateId(_School school, String id) => school.name;

  @Field(name: 'nome')
  String get name;

  @ModelField(name: 'endereco', referTo: _SchoolAddress)
  get address;

  @Field(name: 'contatos', defaultValue: [])
  List<String> get phoneNumbers;

  @DerivedField(name: '_query/nome')
  static String $dorm$derived$q0(
    _School model,
    DerivedTransformations transformations,
  ) => transformations.text(model.name) ?? '';
}

enum StudentType { regular, special }

@Model(name: 'aluno', as: #students)
abstract class _Student {
  @Field(name: 'nome')
  String get name;

  @Field(name: 'possui-deficiencias', defaultValue: StudentType.regular)
  StudentType get hasDisabilities;

  @ForeignField(name: 'id-escola', referTo: _School, inverseAs: #students)
  String get schoolId;

  @DerivedField(name: '_query/nome')
  static String $dorm$derived$q0(
    _Student model,
    DerivedTransformations transformations,
  ) => transformations.text(model.name) ?? '';

  @DerivedField(name: '_query/id-escola_nome')
  static String $dorm$derived$q1(
    _Student model,
    DerivedTransformations transformations,
  ) => '${model.schoolId}_${transformations.text(model.name) ?? ''}';
}

@Model(name: 'professor', as: #teachers)
abstract class _Teacher {
  @Field(name: 'nome')
  String get name;

  @Field(name: 'cpf')
  String? get ssn;

  @DerivedField(name: '_query/cpf')
  static String $dorm$derived$q0(
    _Teacher model,
    DerivedTransformations transformations,
  ) => model.ssn ?? '';
}

@Model(name: 'historico', as: #histories)
abstract class _History {
  @ForeignField(name: 'id-aluno', referTo: _Student, inverseAs: #histories)
  String get studentId;
}

@Model(name: 'cadastro-professor', as: #teachings)
abstract class _Teaching {
  @ForeignField(name: 'id-professor', referTo: _Teacher, inverseAs: #teachings)
  String get teacherId;

  @ForeignField(name: 'id-escola', referTo: _School, inverseAs: #teachings)
  String? get schoolId;

  @Field(name: 'codigo')
  String get code;
}

@Model(name: 'aula', as: #classes)
abstract class _Class {
  @ModelField(name: 'paraninfo', referTo: _Teacher)
  get patron;

  @ForeignField(name: 'id-professor', referTo: _Teacher, inverseAs: #classes)
  String get teacherId;

  @ForeignField(name: 'id-escola', referTo: _Student, inverseAs: #classes)
  String get studentId;

  @Field(name: 'nome-sala')
  String get location;
}
