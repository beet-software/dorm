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
import 'package:mysql_client/exception.dart';

final class MySqlErrorMapper implements DormErrorMapper {
  const MySqlErrorMapper();

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
      final MySQLServerException error => _server(error.errorCode),
      final MySQLClientException _ => (
        DormErrorKind.unavailable,
        DormRetryability.unknown,
        null,
      ),
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
      _ => (DormErrorKind.unknown, DormRetryability.unknown, null),
    };
    return DormDatabaseException(
      kind: kind,
      retryability: retryability,
      message: error.toString(),
      engine: 'mysql',
      operation: operation,
      providerCode: code,
      cause: error,
      stackTrace: stackTrace,
    );
  }

  (DormErrorKind, DormRetryability, int) _server(int code) {
    return switch (code) {
      1044 ||
      1142 ||
      1227 => (DormErrorKind.authorization, DormRetryability.never, code),
      1045 => (DormErrorKind.authentication, DormRetryability.never, code),
      1062 => (DormErrorKind.conflict, DormRetryability.never, code),
      1064 ||
      1149 => (DormErrorKind.invalidQuery, DormRetryability.never, code),
      1205 || 1213 => (DormErrorKind.transaction, DormRetryability.safe, code),
      1451 || 1452 => (DormErrorKind.constraint, DormRetryability.never, code),
      2002 ||
      2003 ||
      2005 ||
      2006 ||
      2013 => (DormErrorKind.unavailable, DormRetryability.unknown, code),
      _ => (DormErrorKind.unknown, DormRetryability.unknown, code),
    };
  }
}
