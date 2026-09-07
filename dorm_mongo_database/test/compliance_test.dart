import 'dart:io';

import 'package:dorm_framework/dorm_framework.dart';
import 'package:dorm_mongo_database/dorm_mongo_database.dart';
import 'package:dorm_test/dorm_test.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:test/test.dart';

class _MongoAdapter implements EngineTestAdapter<Query> {
  _MongoAdapter(this.uri);

  final String uri;

  @override
  String get name => 'MongoDB';

  @override
  Future<EngineTestSession<Query>> open() async {
    final Db database = Db(uri);
    await database.open();
    return _MongoSession(database);
  }
}

class _MongoSession implements EngineTestSession<Query> {
  _MongoSession(this.database) : _engine = Engine(database);

  final Db database;
  final Engine _engine;

  static const List<String> _collections = [
    'dorm_compliance_items',
    'dorm_compliance_parents',
    'dorm_compliance_profiles',
    'dorm_compliance_children',
    'dorm_compliance_links',
    'dorm_compliance_composites',
  ];

  @override
  BaseEngine<Query> get engine => _engine;

  @override
  EngineCapabilities get capabilities =>
      const EngineCapabilities(compositeIdentities: true);

  @override
  Future<void> reset() async {
    for (final String name in _collections) {
      await database.collection(name).deleteMany({});
    }
  }

  @override
  Future<void> close() => database.close();
}

void main() {
  final String? uri = Platform.environment['MONGO_URI'];
  if (uri == null) {
    test(
      'MongoDB compliance requires MONGO_URI',
      () {},
      skip: 'Set MONGO_URI to run MongoDB compliance tests.',
    );
    return;
  }
  defineEngineComplianceTests(_MongoAdapter(uri));
}
