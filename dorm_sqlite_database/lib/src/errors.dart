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
import 'package:sqlite3/sqlite3.dart';

final class SqliteErrorMapper implements DormErrorMapper {
  const SqliteErrorMapper();

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
      final SqliteException error => _sqlite(error.resultCode),
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
      engine: 'sqlite',
      operation: operation,
      providerCode: code,
      cause: error,
      stackTrace: stackTrace,
    );
  }

  (DormErrorKind, DormRetryability, int) _sqlite(int code) {
    return switch (code) {
      SqlError.SQLITE_BUSY || SqlError.SQLITE_LOCKED => (
        DormErrorKind.transaction,
        DormRetryability.safe,
        code,
      ),
      SqlError.SQLITE_CONSTRAINT => (
        DormErrorKind.constraint,
        DormRetryability.never,
        code,
      ),
      SqlError.SQLITE_INTERRUPT => (
        DormErrorKind.cancelled,
        DormRetryability.never,
        code,
      ),
      SqlError.SQLITE_IOERR || SqlError.SQLITE_CANTOPEN => (
        DormErrorKind.unavailable,
        DormRetryability.unknown,
        code,
      ),
      SqlError.SQLITE_AUTH => (
        DormErrorKind.authorization,
        DormRetryability.never,
        code,
      ),
      SqlError.SQLITE_ERROR || SqlError.SQLITE_SCHEMA => (
        DormErrorKind.invalidQuery,
        DormRetryability.never,
        code,
      ),
      _ => (DormErrorKind.unknown, DormRetryability.unknown, code),
    };
  }
}
