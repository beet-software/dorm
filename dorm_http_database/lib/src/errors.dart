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

import 'dart:async';
import 'dart:io';

import 'package:dorm_framework/dorm_framework.dart';
import 'package:http/http.dart' as http;

import 'error.dart';

final class HttpErrorMapper implements DormErrorMapper {
  const HttpErrorMapper();

  @override
  DormDatabaseException map(
    Object error,
    StackTrace stackTrace, {
    String? operation,
  }) {
    final (
      DormErrorKind kind,
      DormRetryability retryability,
      Object? code,
    ) = switch (error) {
      final HttpDatabaseException error => _status(error.statusCode),
      final TimeoutException _ => (
        DormErrorKind.timeout,
        DormRetryability.unknown,
        null,
      ),
      final SocketException _ => (
        DormErrorKind.unavailable,
        DormRetryability.unknown,
        null,
      ),
      final http.ClientException _ => (
        DormErrorKind.unavailable,
        DormRetryability.unknown,
        null,
      ),
      final FormatException _ => (
        DormErrorKind.invalidData,
        DormRetryability.never,
        null,
      ),
      _ => (DormErrorKind.unknown, DormRetryability.unknown, null),
    };
    return DormDatabaseException(
      kind: kind,
      retryability: retryability,
      message: error.toString(),
      engine: 'http',
      operation: operation,
      providerCode: code,
      cause: error,
      stackTrace: stackTrace,
    );
  }

  (DormErrorKind, DormRetryability, int) _status(int statusCode) {
    return switch (statusCode) {
      401 => (DormErrorKind.authentication, DormRetryability.never, statusCode),
      403 => (DormErrorKind.authorization, DormRetryability.never, statusCode),
      404 => (DormErrorKind.notFound, DormRetryability.never, statusCode),
      408 => (DormErrorKind.timeout, DormRetryability.unknown, statusCode),
      409 => (DormErrorKind.conflict, DormRetryability.never, statusCode),
      422 => (DormErrorKind.invalidData, DormRetryability.never, statusCode),
      429 => (DormErrorKind.unavailable, DormRetryability.unknown, statusCode),
      >= 500 => (
        DormErrorKind.unavailable,
        DormRetryability.unknown,
        statusCode,
      ),
      400 => (DormErrorKind.invalidQuery, DormRetryability.never, statusCode),
      _ => (DormErrorKind.unknown, DormRetryability.unknown, statusCode),
    };
  }
}
