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

/// An HTTP response that the dORM engine could not accept.
class HttpDatabaseException implements Exception {
  final int statusCode;
  final String method;
  final Uri uri;
  final String body;

  const HttpDatabaseException({
    required this.statusCode,
    required this.method,
    required this.uri,
    required this.body,
  });

  @override
  String toString() {
    return 'HttpDatabaseException($statusCode $method $uri: $body)';
  }
}
