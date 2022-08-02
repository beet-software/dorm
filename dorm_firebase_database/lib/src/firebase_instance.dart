import 'package:firebase_auth/firebase_auth.dart' as fa;
import 'package:firebase_core/firebase_core.dart' as fc;
import 'package:firebase_database/firebase_database.dart' as fd;

abstract class FirebaseInstance {
  const factory FirebaseInstance() = _DefaultFirebaseInstance;

  const factory FirebaseInstance.custom(
    fc.FirebaseApp app, {
    String? databaseUrl,
  }) = _CustomFirebaseInstance;

  fc.FirebaseApp get app;

  fd.FirebaseDatabase get database;

  fa.FirebaseAuth get auth;
}

class _DefaultFirebaseInstance implements FirebaseInstance {
  const _DefaultFirebaseInstance();

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
  final String? databaseUrl;

  const _CustomFirebaseInstance(this.app, {this.databaseUrl});

  @override
  fa.FirebaseAuth get auth => fa.FirebaseAuth.instanceFor(app: app);

  @override
  fd.FirebaseDatabase get database =>
      fd.FirebaseDatabase.instanceFor(app: app, databaseURL: databaseUrl);
}
