import 'dart:io';

import 'package:dorm_firebase_database/dorm_firebase_database.dart';
import 'package:dorm_framework/dorm_framework.dart';
import 'package:dorm_test/dorm_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart' as fd;
import 'package:test/test.dart';

class _FirebaseAdapter implements EngineTestAdapter<Query> {
  _FirebaseAdapter(this.url);

  final String url;

  @override
  String get name => 'Firebase Realtime Database';

  @override
  Future<EngineTestSession<Query>> open() async {
    final String name =
        'dorm-compliance-${DateTime.now().microsecondsSinceEpoch}';
    final FirebaseApp app = await Firebase.initializeApp(
      name: name,
      options: FirebaseOptions(
        apiKey: 'dorm-test',
        appId: '1:1234567890:android:dormtest',
        messagingSenderId: '1234567890',
        projectId: Platform.environment['FIREBASE_PROJECT_ID'] ?? 'dorm-test',
        databaseURL: url,
      ),
    );
    final fd.FirebaseDatabase database = fd.FirebaseDatabase.instanceFor(
      app: app,
      databaseURL: url,
    );
    database.useDatabaseEmulator(
      Platform.environment['FIREBASE_EMULATOR_HOST'] ?? '127.0.0.1',
      int.parse(Platform.environment['FIREBASE_EMULATOR_PORT'] ?? '9000'),
    );
    final FirebaseInstance instance = FirebaseInstance.custom(
      app,
      databaseUrl: url,
      offlineMode: OfflineMode.exclude,
    );
    return _FirebaseSession(app, database, Engine(instance));
  }
}

class _FirebaseSession implements EngineTestSession<Query> {
  _FirebaseSession(this.app, this.database, this._engine);

  final FirebaseApp app;
  final fd.FirebaseDatabase database;
  final Engine _engine;

  static const List<String> _paths = [
    'dorm_compliance_items',
    'dorm_compliance_parents',
    'dorm_compliance_profiles',
    'dorm_compliance_children',
    'dorm_compliance_links',
  ];

  @override
  BaseEngine<Query, OffsetPageRequest> get engine => _engine;

  @override
  EngineCapabilities get capabilities =>
      const EngineCapabilities(reactiveStreams: true);

  @override
  Future<void> reset() async {
    for (final String path in _paths) {
      await database.ref(path).remove();
    }
  }

  @override
  Future<void> close() => app.delete();
}

void main() {
  final String? url = Platform.environment['FIREBASE_DATABASE_URL'];
  if (url == null) {
    test(
      'Firebase compliance requires FIREBASE_DATABASE_URL',
      () {},
      skip: 'Set FIREBASE_DATABASE_URL and start the Firebase emulator.',
    );
    return;
  }
  defineEngineComplianceTests(_FirebaseAdapter(url));
}
