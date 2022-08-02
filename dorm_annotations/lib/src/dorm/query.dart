part of '../dorm.dart';

abstract class Query {
  Query orderByChild(String key);

  Query limitToFirst(int limit);

  Query limitToLast(int limit);

  Query equalTo(Object? value);

  Query startAt(Object? value);

  Query endAt(Object? value);

  String get path;

  Stream<Object?> get onValue;

  Future<Object?> get();
}
