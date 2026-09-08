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

import 'dependency.dart';

/// Identifies the source of the final identity in a resolved creation.
enum CreationIdentitySource {
  /// The dORM engine generated the identity before persistence.
  generated,

  /// The database or remote backend generated the identity during persistence.
  database,

  /// The caller supplied the final identity explicitly.
  explicit,
}

/// Describes the data and identity strategy used to create one model.
sealed class Creation<Data, I extends Object> {
  const Creation._({required this.dependency, required this.data});

  /// Creates a request that follows the entity's declared automatic identity
  /// strategy.
  static AutoCreation<Data, I> auto<Data, I extends Object>({
    required Dependency<Data> dependency,
    required Data data,
  }) {
    return AutoCreation._(dependency: dependency, data: data);
  }

  /// Creates a request with an explicit identity.
  static ExplicitCreation<Data, I> explicit<Data, I extends Object>({
    required Dependency<Data> dependency,
    required Data data,
    required I identity,
  }) {
    return ExplicitCreation._(
      dependency: dependency,
      data: data,
      identity: identity,
    );
  }

  /// The dependency context used to construct the model.
  final Dependency<Data> dependency;

  /// The input data used to construct the model.
  final Data data;
}

/// A creation request accepted by entities with a single primary key.
sealed class SimpleCreation<Data, I extends Object> extends Creation<Data, I> {
  const SimpleCreation._({required super.dependency, required super.data})
    : super._();
}

/// A creation request that delegates identity generation to an engine.
final class AutoCreation<Data, I extends Object>
    extends SimpleCreation<Data, I> {
  const AutoCreation._({required super.dependency, required super.data})
    : super._();
}

/// A creation request that supplies the final identity explicitly.
final class ExplicitCreation<Data, I extends Object>
    extends SimpleCreation<Data, I> {
  ExplicitCreation._({
    required super.dependency,
    required super.data,
    required this.identity,
  }) : super._();

  /// The final identity to use for the model.
  final I identity;
}

/// Contains a resolved identity and the inputs used to construct a model.
class ResolvedCreation<Data, I extends Object> {
  /// Creates a resolved creation context.
  const ResolvedCreation({
    required this.dependency,
    required this.data,
    required this.id,
    required this.identitySource,
  });

  /// The dependency context used to construct the model.
  final Dependency<Data> dependency;

  /// The input data used to construct the model.
  final Data data;

  /// The final identity assigned to the model.
  final I id;

  /// The source that supplied the final identity.
  final CreationIdentitySource identitySource;
}
