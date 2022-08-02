/// Defines a unique-identification strategy.
abstract class UidType {
  /// Uniquely identifies a model based on the default autoincrement strategy
  /// provided by the database.
  ///
  /// If Student depends on School and 'unique-id' is a unique identifier for
  /// Student, using `UidType.simple()` guarantees that, whenever a student
  /// belonging to a school with id 'school-id' is inserted, the id of this
  /// student will be 'unique-id'.
  const factory UidType.simple() = _SimpleUidType;

  /// Uniquely identifies a model based on its dependencies AND the default
  /// autoincrement strategy provided by the database.
  ///
  /// If Student depends on School and 'unique-id' is a unique identifier for
  /// Student, using `UidType.composite()` guarantees that, whenever a student
  /// belonging to a school with id 'school-id' is inserted, the id of this
  /// student will be 'school-id&unique-id'.
  const factory UidType.composite() = _CompositeUidType;

  /// Uniquely identifies a model based on another model.
  ///
  /// If Student depends on School and 'unique-id' is a unique identifier for
  /// Student, using `UidType.sameAs(School)` guarantees that, whenever a student
  /// belonging to a school with id 'school-id' is inserted, the id of this
  /// student will be 'school-id'.
  ///
  /// This is suitable for 1:1 relationships.
  const factory UidType.sameAs(Type type) = _SameAsUidType;

  T when<T>({
    required T Function() caseSimple,
    required T Function() caseComposite,
    required T Function(Type type) caseSameAs,
  });
}

class _SimpleUidType implements UidType {
  const _SimpleUidType();

  @override
  T when<T>({
    required T Function() caseSimple,
    required T Function() caseComposite,
    required T Function(Type type) caseSameAs,
  }) {
    return caseSimple();
  }
}

class _CompositeUidType implements UidType {
  const _CompositeUidType();

  @override
  T when<T>({
    required T Function() caseSimple,
    required T Function() caseComposite,
    required T Function(Type type) caseSameAs,
  }) {
    return caseComposite();
  }
}

class _SameAsUidType implements UidType {
  final Type type;

  const _SameAsUidType(this.type);

  @override
  T when<T>({
    required T Function() caseSimple,
    required T Function() caseComposite,
    required T Function(Type type) caseSameAs,
  }) {
    return caseSameAs(type);
  }
}
