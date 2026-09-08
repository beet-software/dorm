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

import 'query.dart';
import 'schema.dart';

enum SortDirection { ascending, descending }

class OrderBy {
  final FieldSchema field;
  final SortDirection direction;

  const OrderBy(this.field, {this.direction = SortDirection.ascending});
}

class QueryOptions {
  final List<OrderBy> orderBy;
  final int? limit;
  final int offset;

  const QueryOptions({this.orderBy = const [], this.limit, this.offset = 0})
    : assert(offset >= 0),
      assert(limit == null || limit > 0);

  Q apply<Q extends BaseQuery<Q>>(Q query) {
    Q result = query;
    for (final OrderBy order in orderBy) {
      result = result.sorted(
        order.field.columnName,
        ascending: order.direction == SortDirection.ascending,
      );
    }
    if (limit != null) result = result.limit(limit!);
    if (offset > 0) result = result.offset(offset);
    return result;
  }
}

sealed class PageRequest {
  final int size;
  final List<OrderBy> orderBy;

  const PageRequest({required this.size, this.orderBy = const []})
    : assert(size > 0);
}

final class OffsetPageRequest extends PageRequest {
  final int offset;

  const OffsetPageRequest({required super.size, this.offset = 0, super.orderBy})
    : assert(offset >= 0);
}

final class CursorPageRequest extends PageRequest {
  final String? cursor;

  const CursorPageRequest({required super.size, this.cursor, super.orderBy});
}

class Page<T> {
  final List<T> items;
  final bool hasNext;
  final String? nextCursor;

  const Page({required this.items, required this.hasNext, this.nextCursor});
}

typedef PageResult<T> = Page<T>;
