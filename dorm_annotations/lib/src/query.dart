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

import 'field.dart';

enum QueryType { text, enumeration }

@Target({TargetKind.getter})
class QueryField extends Field {
  final List<QueryToken> referTo;
  final String joinBy;

  const QueryField({
    required super.name,
    required this.referTo,
    this.joinBy = '_',
  });
}

class QueryToken {
  final Symbol field;
  final QueryType? type;

  const QueryToken(this.field, [this.type]);
}
