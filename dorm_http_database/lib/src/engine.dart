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

import 'package:dorm_framework/dorm_framework.dart';
import 'package:http/http.dart' as http;

import 'errors.dart';
import 'mapping.dart';
import 'query.dart';
import 'reference.dart';
import 'relationship.dart';

/// An HTTP/JSON engine for REST-shaped APIs.
class Engine implements BaseEngine<Query, OffsetPageRequest>, ErrorAwareEngine {
  final http.Client client;
  final Uri baseUri;
  final HttpMapping mapping;
  final Map<String, String> headers;

  @override
  DormErrorMapper get errorMapper => const HttpErrorMapper();

  /// Creates an engine using an application-owned HTTP [client].
  const Engine({
    required this.client,
    required this.baseUri,
    required this.mapping,
    this.headers = const {},
  });

  @override
  BaseReference<Query, OffsetPageRequest> createReference() =>
      ErrorMappedReference(
        Reference(
          client: client,
          baseUri: baseUri,
          mapping: mapping,
          headers: headers,
        ),
        errorMapper,
        mapFormatExceptions: true,
      );

  @override
  BaseRelationship<Query> createRelationship() => ErrorMappedRelationship(
    const Relationship(),
    errorMapper,
    mapFormatExceptions: true,
  );
}
