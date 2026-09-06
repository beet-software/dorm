import 'package:dorm_framework/dorm_framework.dart';
import 'package:mongo_dart/mongo_dart.dart';

import 'query.dart';
import 'reference.dart';
import 'relationship.dart';

class Engine implements BaseEngine<Query> {
  final Db database;

  const Engine(this.database);

  @override
  BaseReference<Query> createReference() => Reference(database);

  @override
  BaseRelationship<Query> createRelationship() => Relationship(database);
}
