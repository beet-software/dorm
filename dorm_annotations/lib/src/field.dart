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

import 'package:meta/meta_meta.dart';

@Target({TargetKind.getter})
class Field {
  final String? name;
  final Object? defaultValue;

  const Field({
    this.name,
    this.defaultValue,
  });
}

@Target({TargetKind.getter})
class ForeignField extends Field {
  final Type referTo;

  const ForeignField({
    required super.name,
    required this.referTo,
  });
}

@Target({TargetKind.getter})
class ModelField extends Field {
  final Type referTo;

  const ModelField({
    required super.name,
    required this.referTo,
  });
}
