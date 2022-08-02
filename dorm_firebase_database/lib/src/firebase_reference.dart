import 'dart:convert';

import 'package:dorm_annotations/dorm_annotations.dart' show Query, Reference;
import 'package:firebase_auth/firebase_auth.dart' as fa;
import 'package:firebase_database/firebase_database.dart' as fd;
import 'package:http/http.dart' as http;

import 'firebase_instance.dart';

class FirebaseQuery implements Query {
  final fd.Query _query;

  const FirebaseQuery(this._query);

  @override
  Query startAt(Object? value) => FirebaseQuery(_query.startAt(value));

  @override
  Query endAt(Object? value) => FirebaseQuery(_query.endAt(value));

  @override
  Query equalTo(Object? value) => FirebaseQuery(_query.equalTo(value));

  @override
  Query limitToFirst(int limit) => FirebaseQuery(_query.limitToFirst(limit));

  @override
  Query limitToLast(int limit) => FirebaseQuery(_query.limitToLast(limit));

  @override
  Query orderByChild(String key) => FirebaseQuery(_query.orderByChild(key));

  @override
  String get path => _query.path;

  @override
  Future<Object?> get() => _query.get().then((snapshot) => snapshot.value);

  @override
  Stream<Object?> get onValue =>
      _query.onValue.map((event) => event.snapshot.value);
}

class FirebaseReference extends FirebaseQuery with Reference {
  final FirebaseInstance instance;

  FirebaseReference(this.instance, [String? path])
      : super(instance.database.ref(path));

  const FirebaseReference._(this.instance, fd.DatabaseReference ref)
      : super(ref);

  fd.DatabaseReference get _ref => super._query as fd.DatabaseReference;

  @override
  Reference child(String key) => FirebaseReference._(instance, _ref.child(key));

  @override
  Reference push() => FirebaseReference._(instance, _ref.push());

  @override
  String? get key => _ref.key;

  @override
  Future<void> remove() => _ref.remove();

  @override
  Future<void> set(Object? value) => _ref.set(value);

  @override
  Future<void> update(Map<String, Object?> value) => _ref.update(value);

  @override
  Future<List<String>> shallow() async {
    final String projectId = instance.app.options.projectId;
    final fa.User? user = instance.auth.currentUser;
    final http.Response response = await http.get(Uri(
      scheme: 'https',
      host: '$projectId-default-rtdb.firebaseio.com',
      path: '$path.json',
      queryParameters: {
        if (user != null) 'auth': await user.getIdToken(),
        'shallow': 'true',
      },
    ));
    final Map? data = json.decode(response.body) as Map?;
    if (data == null) return [];
    return data.keys.cast<String>().toList();
  }
}
