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
import 'package:mongo_dart/mongo_dart.dart';

import 'query.dart';
import 'reference.dart';
import 'relationship.dart';

class Engine implements BaseEngine<Query, OffsetPageRequest> {
  final Db database;

  const Engine(this.database);

  @override
  BaseReference<Query, OffsetPageRequest> createReference() =>
      Reference(database);

  @override
  BaseRelationship<Query> createRelationship() => Relationship(database);
}
