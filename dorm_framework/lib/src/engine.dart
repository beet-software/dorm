import 'reference.dart';
import 'relationship.dart';

abstract class BaseEngine {
  BaseReference createReference();

  BaseRelationship createRelationship();
}
