import 'package:dorm_framework/dorm_framework.dart';
import 'package:postgres/postgres.dart';

import 'query.dart';
import 'reference.dart';
import 'relationship.dart';

class Engine implements BaseEngine<Query> {
  final SessionExecutor executor;

  const Engine(this.executor);

  @override
  BaseReference<Query> createReference() => Reference(executor);

  @override
  BaseRelationship<Query> createRelationship() => Relationship(executor);
}
