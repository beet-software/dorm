import 'dart:convert';

import 'package:dorm/dorm.dart' show Query, Reference;
import 'package:firebase_auth/firebase_auth.dart' as fa;
import 'package:firebase_database/firebase_database.dart' as fd;
import 'package:http/http.dart' as http;

import 'firebase_instance.dart';
import 'offline.dart';

class FirebaseQuery implements Query {
  final FirebaseInstance instance;
  final fd.Query _query;

  const FirebaseQuery(this.instance, this._query);

  FirebaseQuery _using(fd.Query query) => FirebaseQuery(instance, query);

  @override
  Query startAt(Object? value) => _using(_query.startAt(value));

  @override
  Query endAt(Object? value) => _using(_query.endAt(value));

  @override
  Query equalTo(Object? value) => _using(_query.equalTo(value));

  @override
  Query limitToFirst(int limit) => _using(_query.limitToFirst(limit));

  @override
  Query limitToLast(int limit) => _using(_query.limitToLast(limit));

  @override
  Query orderByChild(String key) => _using(_query.orderByChild(key));

  @override
  String get path => _query.path;

  @override
  Future<Object?> get() => _query.get().then((snapshot) => snapshot.value);

  @override
  Future<Map<String, Object>> getChildren() => _query.get().then((snapshot) {
        return {
          for (fd.DataSnapshot child in snapshot.children)
            child.key as String: child.value as Object,
        };
      });

  Stream<fd.DataSnapshot> get _onValue {
    switch (instance.offlineMode) {
      case OfflineMode.exclude:
        return _query.onValue.map((event) => event.snapshot);
      case OfflineMode.include:
        return OfflineAdapter(instance: instance.database, query: _query)
            .stream;
    }
  }

  @override
  Stream<Object?> get onValue => _onValue.map((snapshot) => snapshot.value);

  @override
  Stream<Map<String, Object>> get onChildren => _onValue.map((snapshot) {
        return {
          for (fd.DataSnapshot child in snapshot.children)
            child.key as String: child.value as Object,
        };
      });
}

class FirebaseReference extends FirebaseQuery with Reference {
  FirebaseReference(
    FirebaseInstance instance, [
    String? path,
  ]) : super(instance, instance.database.ref(path));

  const FirebaseReference._(
    FirebaseInstance instance,
    fd.DatabaseReference ref,
  ) : super(instance, ref);

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
