import 'package:dorm_firebase_database/dorm_firebase_database.dart';
import 'package:dorm_framework/dorm_framework.dart';

import 'reference.dart';
import 'relationship.dart';

class Engine implements BaseEngine {
  final FirebaseInstance instance;
  final String? path;

  const Engine(this.instance, {this.path});

  @override
  BaseReference createReference() => Reference(instance, path);

  @override
  BaseRelationship createRelationship() => const Relationship();
}
