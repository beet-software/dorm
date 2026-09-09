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
import 'package:postgres/postgres.dart';

import 'query.dart';
import 'reference.dart';
import 'relationship.dart';

class Engine
    implements
        BaseEngine<Query, OffsetPageRequest>,
        TransactionalEngine<Query, OffsetPageRequest> {
  final SessionExecutor executor;
  bool _transactionActive = false;

  Engine(this.executor);

  @override
  BaseReference<Query, OffsetPageRequest> createReference() =>
      Reference(executor);

  @override
  BaseRelationship<Query> createRelationship() => Relationship(executor);

  @override
  Future<T> transaction<T>(
    Future<T> Function(BaseEngine<Query, OffsetPageRequest> engine) action,
  ) {
    if (_transactionActive) {
      throw StateError('Nested transactions are not supported.');
    }
    _transactionActive = true;
    _TransactionEngine? transactionEngine;
    return executor
        .runTx((session) {
          transactionEngine = _TransactionEngine(executor, session);
          return action(transactionEngine!);
        })
        .whenComplete(() {
          transactionEngine?.active = false;
          _transactionActive = false;
        });
  }
}

class _TransactionEngine implements BaseEngine<Query, OffsetPageRequest> {
  final SessionExecutor executor;
  final TxSession session;
  bool active = true;

  _TransactionEngine(this.executor, this.session);

  @override
  BaseReference<Query, OffsetPageRequest> createReference() {
    _checkActive();
    return Reference(executor, session: session);
  }

  @override
  BaseRelationship<Query> createRelationship() {
    _checkActive();
    return Relationship(executor, session: session);
  }

  void _checkActive() {
    if (!active) {
      throw StateError('The transaction context is no longer active.');
    }
  }
}
