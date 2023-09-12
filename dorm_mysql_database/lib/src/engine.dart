// dORM
// Copyright (C) 2023  Beet Software
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

import 'package:dorm_framework/dorm_framework.dart';
import 'package:mysql_client/mysql_client.dart';

import 'reference.dart';

class _Relationship implements BaseRelationship {
  @override
  ManyToManyAssociation<M, L, R> manyToMany<M, L, R>(
      Readable<M> middle,
      Readable<L> left,
      String Function(M p1) onLeft,
      Readable<R> right,
      String Function(M p1) onRight) {
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

class Engine implements BaseEngine {
  final MySQLConnection connection;

  const Engine(this.connection);

  @override
  BaseReference createReference() => Reference(connection);

  @override
  BaseRelationship createRelationship() => _Relationship();
}
