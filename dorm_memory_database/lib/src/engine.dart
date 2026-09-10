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

import 'query.dart';
import 'reference.dart';
import 'relationship.dart';

/// An in-memory dORM engine with no external database connection.
class Engine
    implements
        ChangeTrackedEngine<Query, OffsetPageRequest>,
        TransactionalEngine<Query, OffsetPageRequest> {
  final Reference _reference = Reference();

  @override
  BaseReference<Query, OffsetPageRequest> createReference() => _reference;

  @override
  ChangeTrackedReference<Query, OffsetPageRequest>
  createChangeTrackedReference() => _reference;

  @override
  BaseRelationship<Query> createRelationship() => const Relationship();

  @override
  Future<T> transaction<T>(
    Future<T> Function(BaseEngine<Query, OffsetPageRequest> engine) action,
  ) => _reference.transaction(action);
}
