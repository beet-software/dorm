// dORM
// Copyright (C) 2023  Beet Software
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

/// A value object for an ordered composite primary key.
class CompositeKey {
  final List<Object?> values;

  CompositeKey(Iterable<Object?> values) : values = List.unmodifiable(values);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CompositeKey && _listEquals(values, other.values);

  @override
  int get hashCode => Object.hashAll(values);

  @override
  String toString() => 'CompositeKey($values)';
}

bool _listEquals(List<Object?> left, List<Object?> right) {
  if (left.length != right.length) return false;
  for (int i = 0; i < left.length; i++) {
    if (left[i] != right[i]) return false;
  }
  return true;
}

/// Encodes and decodes an entity identity for an engine.
abstract class PrimaryKeyCodec<I extends Object> {
  const PrimaryKeyCodec();

  /// Converts an identity into values ordered like the schema key fields.
  List<Object?> encode(I id);

  /// Reconstructs an identity from values ordered like the schema key fields.
  I decode(Iterable<Object?> values);
}

/// Codec for the ordinary one-field identity.
class SinglePrimaryKeyCodec<I extends Object> extends PrimaryKeyCodec<I> {
  const SinglePrimaryKeyCodec();

  @override
  List<Object?> encode(I id) => [id];

  @override
  I decode(Iterable<Object?> values) {
    final List<Object?> parts = values.toList();
    if (parts.length != 1) {
      throw StateError(
        'A single primary-key codec requires exactly one value.',
      );
    }
    return parts.single as I;
  }
}

/// Codec for [CompositeKey] identities.
class CompositePrimaryKeyCodec extends PrimaryKeyCodec<CompositeKey> {
  const CompositePrimaryKeyCodec();

  @override
  List<Object?> encode(CompositeKey id) => id.values;

  @override
  CompositeKey decode(Iterable<Object?> values) => CompositeKey(values);
}
