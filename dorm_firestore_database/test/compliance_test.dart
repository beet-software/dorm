import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart' as fs;
import 'package:dorm_firestore_database/dorm_firestore_database.dart';
import 'package:dorm_framework/dorm_framework.dart';
import 'package:dorm_test/dorm_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:test/test.dart';

class _FirestoreAdapter implements EngineTestAdapter<Query> {
  @override
  String get name => 'Cloud Firestore';

  @override
  Future<EngineTestSession<Query>> open() async {
    final String name =
        'dorm-firestore-${DateTime.now().microsecondsSinceEpoch}';
    final FirebaseApp app = await Firebase.initializeApp(
      name: name,
      options: FirebaseOptions(
        apiKey: 'dorm-test',
        appId: '1:1234567890:android:dormfirestoretest',
        messagingSenderId: '1234567890',
        projectId: Platform.environment['FIREBASE_PROJECT_ID'] ?? 'dorm-test',
      ),
    );
    final fs.FirebaseFirestore firestore = fs.FirebaseFirestore.instanceFor(
      app: app,
    );
    final String emulator =
        Platform.environment['FIRESTORE_EMULATOR_HOST'] ?? '127.0.0.1:8080';
    final List<String> parts = emulator.split(':');
    firestore.useFirestoreEmulator(
      parts.first,
      int.parse(parts.length == 1 ? '8080' : parts.last),
    );
    return _FirestoreSession(app, firestore, Engine(firestore));
  }
}

class _FirestoreSession implements EngineTestSession<Query> {
  _FirestoreSession(this.app, this.firestore, this._engine);

  final FirebaseApp app;
  final fs.FirebaseFirestore firestore;
  final Engine _engine;

  static const List<String> _collections = [
    'dorm_compliance_items',
    'dorm_compliance_parents',
    'dorm_compliance_profiles',
    'dorm_compliance_children',
    'dorm_compliance_links',
  ];

  @override
  BaseEngine<Query, OffsetPageRequest> get engine => _engine;

  @override
  EngineCapabilities get capabilities => const EngineCapabilities(
    reactiveStreams: true,
    atomicBatchWrites: true,
    atomicPatch: true,
    comparisonFilters: true,
    logicalFilters: true,
    collectionFilters: true,
  );

  @override
  Future<void> reset() async {
    for (final String collection in _collections) {
      final fs.QuerySnapshot<Map<String, dynamic>> snapshot = await firestore
          .collection(collection)
          .get();
      if (snapshot.docs.isEmpty) continue;
      final fs.WriteBatch batch = firestore.batch();
      for (final fs.QueryDocumentSnapshot<Map<String, dynamic>> document
          in snapshot.docs) {
        batch.delete(document.reference);
      }
      await batch.commit();
    }
  }

  @override
  Future<void> close() => app.delete();
}

void main() {
  if (Platform.environment['FIRESTORE_EMULATOR_HOST'] == null) {
    test(
      'Firestore compliance requires FIRESTORE_EMULATOR_HOST',
      () {},
      skip: 'Set FIRESTORE_EMULATOR_HOST and start the Firestore emulator.',
    );
    return;
  }
  defineEngineComplianceTests(_FirestoreAdapter());
  defineEngineComparisonFilterTests(_FirestoreAdapter());
  defineEngineLogicalFilterTests(_FirestoreAdapter());
}
