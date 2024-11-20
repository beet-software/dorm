import 'package:dorm_framework/dorm_framework.dart';
import 'package:dorm_mysql_database/src/query.dart';

class Relationship implements BaseRelationship<Query> {
  @override
  ManyToManyAssociation<M, L, R, Query> manyToMany<M, L, R>(
    Readable<M, Query> middle,
    Readable<L, Query> left,
    String Function(M p1) onLeft,
    Readable<R, Query> right,
    String Function(M p1) onRight,
  ) {
    // TODO: implement manyToMany
    throw UnimplementedError();
  }

  @override
  ManyToOneAssociation<L, R, Query> manyToOne<L, R>(
    Readable<L, Query> left,
    Readable<R, Query> right,
    String Function(L p1) on,
  ) {
    // TODO: implement manyToOne
    throw UnimplementedError();
  }

  @override
  OneToManyAssociation<L, R, Query> oneToMany<L, R>(
    Readable<L, Query> left,
    Readable<R, Query> right,
    BaseFilter<Query> Function(L p1) on,
  ) {
    // TODO: implement oneToMany
    throw UnimplementedError();
  }

  @override
  OneToOneAssociation<L, R, Query> oneToOne<L, R>(
    Readable<L, Query> left,
    Readable<R, Query> right,
    String Function(L p1) on,
  ) {
    // TODO: implement oneToOne
    throw UnimplementedError();
  }
}
