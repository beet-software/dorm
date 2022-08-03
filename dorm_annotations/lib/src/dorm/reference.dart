part of '../dorm.dart';

abstract class Reference implements Query {
  Reference child(String key);

  Reference push();

  String? get key;

  Future<void> remove();

  Future<void> set(Object? value);

  Future<void> update(Map<String, Object?> value);

  Future<List<String>> shallow();
}
