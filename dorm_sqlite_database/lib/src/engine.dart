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
import 'package:sqlite_async/sqlite_async.dart';

import 'errors.dart';
import 'query.dart';
import 'reference.dart';
import 'relationship.dart';

class Engine
    implements
        BaseEngine<Query, OffsetPageRequest>,
        TransactionalEngine<Query, OffsetPageRequest>,
        ErrorAwareEngine {
  final SqliteDatabase database;
  bool _transactionActive = false;

  Engine(this.database);

  @override
  DormErrorMapper get errorMapper => const SqliteErrorMapper();

  @override
  BaseReference<Query, OffsetPageRequest> createReference() =>
      ErrorMappedReference(Reference(database), errorMapper);

  @override
  BaseRelationship<Query> createRelationship() =>
      ErrorMappedRelationship(const Relationship(), errorMapper);

  @override
  Future<T> transaction<T>(
    Future<T> Function(BaseEngine<Query, OffsetPageRequest> engine) action,
  ) async {
    if (_transactionActive) {
      throw StateError('Nested transactions are not supported.');
    }
    _transactionActive = true;
    _TransactionEngine? transactionEngine;
    final Future<T> transaction = database
        .writeTransaction((context) {
          transactionEngine = _TransactionEngine(database, context);
          return action(transactionEngine!);
        })
        .whenComplete(() {
          transactionEngine?.active = false;
          _transactionActive = false;
        });
    return mapDormErrors(
      () => transaction,
      errorMapper,
      operation: 'transaction',
    );
  }
}

class _TransactionEngine
    implements BaseEngine<Query, OffsetPageRequest>, ErrorAwareEngine {
  final SqliteDatabase database;
  final SqliteWriteContext context;
  bool active = true;

  _TransactionEngine(this.database, this.context);

  @override
  DormErrorMapper get errorMapper => const SqliteErrorMapper();

  @override
  BaseReference<Query, OffsetPageRequest> createReference() {
    _checkActive();
    return ErrorMappedReference(
      Reference(database, transaction: context),
      errorMapper,
    );
  }

  @override
  BaseRelationship<Query> createRelationship() {
    _checkActive();
    return ErrorMappedRelationship(const Relationship(), errorMapper);
  }

  void _checkActive() {
    if (!active) {
      throw StateError('The transaction context is no longer active.');
    }
  }
}
