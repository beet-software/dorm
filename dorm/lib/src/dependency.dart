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

/// Represents the identifying relationship of a model.
///
/// Defines if a model is a strong or weak entity in the database.
abstract class Dependency<Data> {
  /// A dependency that declares a model is a strong database entity.
  ///
  /// A strong entity refers to an entity that has its own independent existence
  /// and can be uniquely identified without relying on any other entity. This
  /// is enforced by [ids] being an empty list.
  ///
  /// If a model M's dependency calls this constructor, it means that
  ///
  /// - M exists as a separate model in the database and has its own significance
  ///   and purpose. It represents a primary object within the schema.
  /// - M can be uniquely identified by one or more of its attributes or a
  ///   dedicated primary key. It does not require a foreign key reference to
  ///   establish its identity.
  const Dependency.strong() : this._(const []);

  /// A dependency that declares a model is a weak database entity.
  ///
  /// A weak entity refers to an entity that does not have its own unique
  /// existence or identity independent of other entities, therefore it relies
  /// on a related strong entity to establish its identity and existence. This
  /// is represented by [ids] not being an empty list.
  ///
  /// If a model M's dependency calls this constructor, it means that
  ///
  /// - M cannot exist without being associated with a specific instance of the
  ///   strong entity.
  /// - M is identified by a combination of its own attributes and the primary
  ///   key of its associated strong entity. The primary key of the strong
  ///   entity acts as a partial key or discriminator for the weak entity.
  const Dependency.weak(List<String> ids) : this._(ids);

  /// Primary keys of the strong entities the underlying model depends on.
  ///
  /// If it's empty, it means the underlying model is a strong entity.
  final List<String> ids;

  const Dependency._(this.ids);

  /// Creates a primary key for the underlying model.
  String key([String? id]) => [...ids, if (id != null) id].join('&');
}
