import 'package:dorm_framework/dorm_framework.dart';
import 'package:sqlite_async/sqlite_async.dart';

import 'query.dart';
import 'reference.dart';
import 'relationship.dart';

class Engine
    implements
        BaseEngine<Query, OffsetPageRequest>,
        TransactionalEngine<Query, OffsetPageRequest> {
  final SqliteDatabase database;
  bool _transactionActive = false;

  Engine(this.database);

  @override
  BaseReference<Query, OffsetPageRequest> createReference() =>
      Reference(database);

  @override
  BaseRelationship<Query> createRelationship() => const Relationship();

  @override
  Future<T> transaction<T>(
    Future<T> Function(BaseEngine<Query, OffsetPageRequest> engine) action,
  ) async {
    if (_transactionActive) {
      throw StateError('Nested transactions are not supported.');
    }
    _transactionActive = true;
    _TransactionEngine? transactionEngine;
    final T result = await database
        .writeTransaction((context) {
          transactionEngine = _TransactionEngine(database, context);
          return action(transactionEngine!);
        })
        .whenComplete(() {
          transactionEngine?.active = false;
          _transactionActive = false;
        });
    return result;
  }
}

class _TransactionEngine implements BaseEngine<Query, OffsetPageRequest> {
  final SqliteDatabase database;
  final SqliteWriteContext context;
  bool active = true;

  _TransactionEngine(this.database, this.context);

  @override
  BaseReference<Query, OffsetPageRequest> createReference() {
    _checkActive();
    return Reference(database, transaction: context);
  }

  @override
  BaseRelationship<Query> createRelationship() {
    _checkActive();
    return const Relationship();
  }

  void _checkActive() {
    if (!active) {
      throw StateError('The transaction context is no longer active.');
    }
  }
}
