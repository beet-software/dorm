import 'package:dorm_framework/dorm_framework.dart';

class Relationship implements BaseRelationship {
  @override
  ManyToManyAssociation<M, L, R> manyToMany<M, L, R>(
    Readable<M> middle,
    Readable<L> left,
    String Function(M p1) onLeft,
    Readable<R> right,
    String Function(M p1) onRight,
  ) {
    // TODO: implement manyToMany
    throw UnimplementedError();
  }

  @override
  ManyToOneAssociation<L, R> manyToOne<L, R>(
    Readable<L> left,
    Readable<R> right,
    String Function(L p1) on,
  ) {
    // TODO: implement manyToOne
    throw UnimplementedError();
  }

  @override
  OneToManyAssociation<L, R> oneToMany<L, R>(
    Readable<L> left,
    Readable<R> right,
    Filter Function(L p1) on,
  ) {
    // TODO: implement oneToMany
    throw UnimplementedError();
  }

  @override
  OneToOneAssociation<L, R> oneToOne<L, R>(
      Readable<L> left, Readable<R> right, String Function(L p1) on) {
    // TODO: implement oneToOne
    throw UnimplementedError();
  }
}
