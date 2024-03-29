import 'package:dorm_framework/dorm_framework.dart';
import 'package:dorm_annotations/dorm_annotations.dart';

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

@Model(name: 'escola', as: #schools, uidType: UidType.simple())
abstract class _School {
  @Field(name: 'nome')
  String get name;

  @ModelField(name: 'endereco', referTo: _SchoolAddress)
  get address;

  @Field(name: 'contatos', defaultValue: [])
  List<String> get phoneNumbers;

  @QueryField(
    name: '_query/nome',
    referTo: [QueryToken(#name, QueryType.text)],
  )
  // ignore: unused_element
  String get _q0;
}

@Model(name: 'aluno', as: #students, uidType: UidType.composite())
abstract class _Student {
  @Field(name: 'nome')
  String get name;

  @Field(name: 'possui-deficiencias', defaultValue: false)
  bool get hasDisabilities;

  @ForeignField(name: 'id-escola', referTo: _School)
  String get schoolId;

  @QueryField(
    name: '_query/nome',
    referTo: [QueryToken(#name, QueryType.text)],
  )
  // ignore: unused_element
  String get _q0;

  @QueryField(
    name: '_query/id-escola_nome',
    referTo: [QueryToken(#schoolId), QueryToken(#name, QueryType.text)],
  )
  // ignore: unused_element
  String get _q1;
}

@Model(name: 'professor', as: #teachers, uidType: UidType.custom(_Teacher._id))
abstract class _Teacher {
  static CustomUidValue _id(Object data) {
    data as _Teacher;
    final String? ssn = data.ssn;
    if (ssn == null) return const CustomUidValue.composite();
    return CustomUidValue.value(ssn.replaceAll(RegExp(r'\D'), ''));
  }

  @Field(name: 'nome')
  String get name;

  @Field(name: 'cpf')
  String? get ssn;

  @QueryField(name: '_query/cpf', referTo: [QueryToken(#ssn)])
  // ignore: unused_element
  String get _q0;
}

@Model(name: 'historico', as: #histories, uidType: UidType.sameAs(_Student))
abstract class _History {
  @ForeignField(name: 'id-aluno', referTo: _Student)
  String get studentId;
}

@Model(name: 'cadastro-professor', as: #teachings)
abstract class _Teaching {
  @ForeignField(name: 'id-professor', referTo: _Teacher)
  String get teacherId;

  @ForeignField(name: 'id-escola', referTo: _School)
  String? get schoolId;

  @Field(name: 'codigo')
  String get code;
}

@Model(name: 'aula', as: #classes, uidType: UidType.composite())
abstract class _Class {
  @ModelField(name: 'paraninfo', referTo: _Teacher)
  get patron;

  @ForeignField(name: 'id-professor', referTo: _Teacher)
  String get teacherId;

  @ForeignField(name: 'id-escola', referTo: _Student)
  String get studentId;

  @Field(name: 'nome-sala')
  String get location;
}
