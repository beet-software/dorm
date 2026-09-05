import 'package:dorm_framework/dorm_framework.dart';
import 'package:dorm_mysql_database/src/query.dart';

class Relationship implements BaseRelationship<Query> {
  @override
  ManyToManyAssociation<M, I, L, R, Query> manyToMany<M, I extends Object, L, J extends Object, R, K extends Object>(
    Readable<M, I, Query> middle,
    Readable<L, J, Query> left,
    J Function(M p1) onLeft,
    Readable<R, K, Query> right,
    K Function(M p1) onRight,
  ) {
    // TODO: implement manyToMany
    throw UnimplementedError();
  }

  @override
  ManyToOneAssociation<L, I, R, J, Query> manyToOne<L, I extends Object, R, J extends Object>(
    Readable<L, I, Query> left,
    Readable<R, J, Query> right,
    J Function(L p1) on,
  ) {
    // TODO: implement manyToOne
    throw UnimplementedError();
  }

  @override
  OneToManyAssociation<L, I, R, Query> oneToMany<L, I extends Object, R, J extends Object>(
    Readable<L, I, Query> left,
    Readable<R, J, Query> right,
    BaseFilter<Query> Function(L p1) on,
  ) {
    // TODO: implement oneToMany
    throw UnimplementedError();
  }

  @override
  OneToOneAssociation<L, I, R, Query> oneToOne<L, I extends Object, R, J extends Object>(
    Readable<L, I, Query> left,
    Readable<R, J, Query> right,
    J Function(L p1) on,
  ) {
    // TODO: implement oneToOne
    throw UnimplementedError();
  }
}

