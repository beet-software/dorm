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

import 'query.dart';
import 'reference.dart';
import 'relationship.dart';

class Engine implements BaseEngine<Query> {
  final MySQLConnection connection;

  const Engine(this.connection);

  @override
  BaseReference<Query> createReference() => Reference(connection);

  @override
  BaseRelationship<Query> createRelationship() => Relationship();
}
