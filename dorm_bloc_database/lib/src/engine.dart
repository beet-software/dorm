import 'package:dorm_framework/dorm_framework.dart';

import 'reference.dart';
import 'relationship.dart';

class Engine implements BaseEngine {
  final Reference _reference = Reference();

  @override
  BaseReference createReference() => _reference;

  @override
  BaseRelationship createRelationship() => const Relationship();
}
