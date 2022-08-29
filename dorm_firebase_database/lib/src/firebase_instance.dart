import 'package:dorm_firebase_database/src/offline.dart';
import 'package:firebase_auth/firebase_auth.dart' as fa;
import 'package:firebase_core/firebase_core.dart' as fc;
import 'package:firebase_database/firebase_database.dart' as fd;

abstract class FirebaseInstance {
  const factory FirebaseInstance({
    OfflineMode offlineMode,
  }) = _DefaultFirebaseInstance;

  const factory FirebaseInstance.custom(
    fc.FirebaseApp app, {
    OfflineMode offlineMode,
    String? databaseUrl,
  }) = _CustomFirebaseInstance;

  fc.FirebaseApp get app;

  fd.FirebaseDatabase get database;

  fa.FirebaseAuth get auth;

  OfflineMode get offlineMode;
}

class _DefaultFirebaseInstance implements FirebaseInstance {
  @override
  final OfflineMode offlineMode;

  const _DefaultFirebaseInstance({this.offlineMode = OfflineMode.include});

  @override
  fc.FirebaseApp get app => fc.Firebase.app();

  @override
  fa.FirebaseAuth get auth => fa.FirebaseAuth.instance;

  @override
  fd.FirebaseDatabase get database => fd.FirebaseDatabase.instance;
}

class _CustomFirebaseInstance implements FirebaseInstance {
  @override
  final fc.FirebaseApp app;

  @override
  final OfflineMode offlineMode;

  final String? databaseUrl;

  const _CustomFirebaseInstance(
    this.app, {
    this.databaseUrl,
    this.offlineMode = OfflineMode.include,
  });

  @override
  fa.FirebaseAuth get auth => fa.FirebaseAuth.instanceFor(app: app);

  @override
  fd.FirebaseDatabase get database =>
      fd.FirebaseDatabase.instanceFor(app: app, databaseURL: databaseUrl);
}
