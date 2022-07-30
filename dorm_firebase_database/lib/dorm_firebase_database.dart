library dorm_firebase_database;

import 'package:dorm_annotations/dorm_annotations.dart' show Query, Reference;
import 'package:firebase_database/firebase_database.dart' as fd;

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
  Future<Object?> get() => _query.get().then((snapshot) => snapshot.value);

  @override
  Stream<Object?> get onValue =>
      _query.onValue.map((event) => event.snapshot.value);
}

class FirebaseReference extends FirebaseQuery with Reference {
  FirebaseReference.path([String? path])
      : this(fd.FirebaseDatabase.instance.ref(path));

  const FirebaseReference(fd.DatabaseReference ref) : super(ref);

  fd.DatabaseReference get _ref => super._query as fd.DatabaseReference;

  @override
  Reference child(String key) => FirebaseReference(_ref.child(key));

  @override
  Reference push() => FirebaseReference(_ref.push());

  @override
  String? get key => _ref.key;

  @override
  Future<void> remove() => _ref.remove();

  @override
  Future<void> set(Object? value) => _ref.set(value);

  @override
  Future<void> update(Map<String, Object?> value) => _ref.update(value);
}
