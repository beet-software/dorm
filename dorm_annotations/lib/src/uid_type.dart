// dORM
// Copyright (C) 2023  Beet Software
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

/// Represents a unique-identification strategy.
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

  /// Uniquely identifies a model based on another model [type].
  ///
  /// If Student depends on School and 'unique-id' is a unique identifier for
  /// Student, using `UidType.sameAs(School)` guarantees that, whenever a student
  /// belonging to a school with id 'school-id' is inserted, the id of this
  /// student will be 'school-id'.
  ///
  /// This is suitable for 1:1 relationships.
  const factory UidType.sameAs(Type type) = _SameAsUidType;

  /// Identifies a model based on [builder].
  const factory UidType.custom(CustomUidValue Function(Object) builder) =
      _CustomUidType;

  T when<T>({
    required T Function() caseSimple,
    required T Function() caseComposite,
    required T Function(Type type) caseSameAs,
    required T Function(CustomUidValue Function(Object) builder) caseCustom,
  });
}

class _SimpleUidType implements UidType {
  const _SimpleUidType();

  @override
  T when<T>({
    required T Function() caseSimple,
    required T Function() caseComposite,
    required T Function(Type type) caseSameAs,
    required T Function(CustomUidValue Function(Object) builder) caseCustom,
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
    required T Function(CustomUidValue Function(Object) builder) caseCustom,
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
    required T Function(CustomUidValue Function(Object) builder) caseCustom,
  }) {
    return caseSameAs(type);
  }
}

class _CustomUidType implements UidType {
  final CustomUidValue Function(Object) builder;

  const _CustomUidType(this.builder);

  @override
  T when<T>({
    required T Function() caseSimple,
    required T Function() caseComposite,
    required T Function(Type type) caseSameAs,
    required T Function(CustomUidValue Function(Object) builder) caseCustom,
  }) {
    return caseCustom(builder);
  }
}

/// Represents a value to be returned by [UidType.custom];
abstract class CustomUidValue {
  const factory CustomUidValue.simple() = _SimpleCustomUidValue;

  const factory CustomUidValue.composite() = _CompositeCustomUidValue;

  const factory CustomUidValue.value(String id) = _ValueCustomUidValue;

  T when<T>({
    required T Function() caseSimple,
    required T Function() caseComposite,
    required T Function(String id) caseValue,
  });
}

class _SimpleCustomUidValue implements CustomUidValue {
  const _SimpleCustomUidValue();

  @override
  T when<T>({
    required T Function() caseSimple,
    required T Function() caseComposite,
    required T Function(String id) caseValue,
  }) {
    return caseSimple();
  }
}

class _CompositeCustomUidValue implements CustomUidValue {
  const _CompositeCustomUidValue();

  @override
  T when<T>({
    required T Function() caseSimple,
    required T Function() caseComposite,
    required T Function(String id) caseValue,
  }) {
    return caseComposite();
  }
}

class _ValueCustomUidValue implements CustomUidValue {
  final String id;

  const _ValueCustomUidValue(this.id);

  @override
  T when<T>({
    required T Function() caseSimple,
    required T Function() caseComposite,
    required T Function(String id) caseValue,
  }) {
    return caseValue(id);
  }
}
