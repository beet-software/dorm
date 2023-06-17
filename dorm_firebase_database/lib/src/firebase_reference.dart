import 'dart:convert';

import 'package:dorm/dorm.dart';
import 'package:firebase_auth/firebase_auth.dart' as fa;
import 'package:firebase_database/firebase_database.dart' as fd;
import 'package:http/http.dart' as http;

import 'firebase_instance.dart';

class Query implements BaseQuery<Query> {
  static String normalizeText(String text) {
    const t0 = 'ÀÁÂÃÄÅàáâãäåÒÓÔÕÕÖØòóôõöøÈÉÊËèéêëðÇçÐÌÍÎÏìíîïÙÚÛÜùúûüÑñŠšŸÿýŽž';
    const t1 = 'AAAAAAaaaaaaOOOOOOOooooooEEEEeeeeeCcDIIIIiiiiUUUUuuuuNnSsYyyZz';

    String result = text;
    for (int i = 0; i < t0.length; i++) {
      result = result.replaceAll(t0[i], t1[i]);
    }
    result = result.toUpperCase();
    result = result.replaceAll(RegExp(r'[^A-Z]'), '');
    return result;
  }

  static String? _dateAsPrefixQuery(DateTime? dt, {DateFilterUnit? unit}) {
    if (dt == null) return null;

    // yyyy-MM-ddTHH:mm:ss.mmmuuuZ
    final String value = dt.toIso8601String();
    switch (unit) {
      case null:
        return value;
      case DateFilterUnit.year:
        return value.substring(0, 4);
      case DateFilterUnit.month:
        return value.substring(0, 7);
      case DateFilterUnit.day:
        return value.substring(0, 10);
      case DateFilterUnit.hour:
        return value.substring(0, 13);
      case DateFilterUnit.minute:
        return value.substring(0, 16);
      case DateFilterUnit.second:
        return value.substring(0, 19);
      case DateFilterUnit.milliseconds:
        return value.substring(0, 23);
    }
  }

  final fd.Query query;

  const Query(this.query);

  @override
  Query whereValue(String key, Object? value) {
    return Query(query.orderByChild(key).equalTo(value));
  }

  @override
  Query whereText(String key, String prefix) {
    final String value = prefix;
    return Query(query.orderByChild(key).startAt(value).endAt('$value\uf8ff'));
  }

  @override
  Query whereDate(String key, DateTime date, DateFilterUnit unit) {
    final String? prefix = _dateAsPrefixQuery(date, unit: unit);
    if (prefix == null) return this;
    return whereText(key, prefix);
  }

  @override
  Query whereRange<T>(String key, FilterRange<T> range) {
    final T? from = range.from;
    final T? to = range.to;

    if (from == null && to == null) return this;
    fd.Query ref = query.orderByChild(key);
    if (from != null) ref = ref.startAt(from);
    if (to != null) ref = ref.endAt(to);
    return Query(ref);
  }

  @override
  Query limit(int count) {
    if (count == 0) return this;
    if (count < 0) return Query(query.limitToLast(count.abs()));
    return Query(query.limitToFirst(count));
  }
}

class Reference implements BaseReference {
  final FirebaseInstance instance;
  final fd.DatabaseReference _ref;

  Reference(
    FirebaseInstance instance, [
    String? path,
  ]) : this._(instance, instance.database.ref(path));

  const Reference._(this.instance, this._ref);

  fd.DatabaseReference _refOf<Data, Model extends Data>(
      Entity<Data, Model> entity) {
    return _ref.child(entity.tableName);
  }

  @override
  Future<Model?> peek<Data, Model extends Data>(
    Entity<Data, Model> entity,
    String id,
  ) {
    return _refOf(entity) //
        .child(id)
        .get()
        .then((snapshot) => snapshot.value)
        .then((value) =>
            value == null ? null : entity.fromJson(id, value as Map));
  }

  @override
  Future<List<Model>> peekAll<Data, Model extends Data>(
    Entity<Data, Model> entity,
    Filter filter,
  ) {
    final Query query = filter.accept(Query(_refOf(entity)));
    return query.query.get().then((snapshot) {
      return {
        for (fd.DataSnapshot child in snapshot.children)
          child.key as String: child.value as Object,
      };
    }).then((values) {
      if (values.isEmpty) return [];
      return values.entries.map((entry) {
        final String key = entry.key;
        final Map value = entry.value as Map;
        return entity.fromJson(key, value);
      }).toList();
    });
  }

  @override
  Future<void> pop<Data, Model extends Data>(
    Entity<Data, Model> entity,
    String id,
  ) {
    return _refOf(entity).child(id).remove();
  }

  @override
  Future<void> popAll<Data, Model extends Data>(
    Entity<Data, Model> entity,
    Iterable<String> ids,
  ) {
    return _refOf(entity).update({for (String id in ids) id: null});
  }

  @override
  Stream<Model?> pull<Data, Model extends Data>(
    Entity<Data, Model> entity,
    String id,
  ) {
    return _refOf(entity)
        .child(id)
        .onValue
        .map((event) => event.snapshot.value)
        .map((value) =>
            value == null ? null : entity.fromJson(id, value as Map));
  }

  @override
  Stream<List<Model>> pullAll<Data, Model extends Data>(
    Entity<Data, Model> entity,
    Filter filter,
  ) {
    final Query query = filter.accept(Query(_refOf(entity)));
    return query.query.onValue.map((event) => event.snapshot).map((snapshot) {
      return {
        for (fd.DataSnapshot child in snapshot.children)
          child.key as String: child.value as Object,
      };
    }).map((values) {
      if (values.isEmpty) return [];
      return values.entries.map((entry) {
        final String key = entry.key;
        final Map value = entry.value as Map;
        return entity.fromJson(key, value);
      }).toList();
    });
  }

  @override
  Future<Model> put<Data, Model extends Data>(
    Entity<Data, Model> entity,
    Dependency<Data> dependency,
    Data data,
  ) {
    return putAll(entity, dependency, [data]).then((models) => models.single);
  }

  @override
  Future<List<Model>> putAll<Data, Model extends Data>(
    Entity<Data, Model> entity,
    Dependency<Data> dependency,
    List<Data> datum,
  ) async {
    final List<Model> models = [];
    for (Data data in datum) {
      final fd.DatabaseReference ref = _refOf(entity).push();
      final String id = ref.key as String;
      final Model model = entity.fromData(dependency, id, data);
      models.add(model);
    }
    _refOf(entity).update({
      for (Model model in models) entity.identify(model): entity.toJson(model),
    });
    return models;
  }

  @override
  Future<void> push<Data, Model extends Data>(
    Entity<Data, Model> entity,
    Model model,
  ) {
    return pushAll(entity, [model]);
  }

  @override
  Future<void> pushAll<Data, Model extends Data>(
    Entity<Data, Model> entity,
    List<Model> models,
  ) {
    return _refOf(entity).update({
      for (Model model in models) entity.identify(model): entity.toJson(model),
    });
  }

  @override
  Future<List<String>> peekAllKeys<Data, Model extends Data>(
    Entity<Data, Model> entity,
  ) async {
    final String path = _refOf(entity).path;
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
