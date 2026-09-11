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
import 'package:postgres/postgres.dart';

final class PostgresErrorMapper implements DormErrorMapper {
  const PostgresErrorMapper();

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
      final ServerException error => _server(error),
      final PgException error => _pg(error),
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
      engine: 'postgres',
      operation: operation,
      providerCode: code,
      cause: error,
      stackTrace: stackTrace,
    );
  }

  (DormErrorKind, DormRetryability, String?) _server(ServerException error) {
    final String? code = error.code;
    if (code == null) {
      return (DormErrorKind.unknown, DormRetryability.unknown, null);
    }
    if (code == '23505') {
      return (DormErrorKind.conflict, DormRetryability.never, code);
    }
    if (code == '23503' || code.startsWith('23')) {
      return (DormErrorKind.constraint, DormRetryability.never, code);
    }
    if (code.startsWith('08')) {
      return (DormErrorKind.unavailable, DormRetryability.unknown, code);
    }
    if (code.startsWith('28')) {
      return (DormErrorKind.authentication, DormRetryability.never, code);
    }
    if (code == '57014') {
      return (DormErrorKind.timeout, DormRetryability.unknown, code);
    }
    if (code == '40001' || code == '40P01') {
      return (DormErrorKind.transaction, DormRetryability.safe, code);
    }
    if (code.startsWith('40')) {
      return (DormErrorKind.transaction, DormRetryability.unknown, code);
    }
    if (code.startsWith('42')) {
      return (DormErrorKind.invalidQuery, DormRetryability.never, code);
    }
    return (DormErrorKind.unknown, DormRetryability.unknown, code);
  }

  (DormErrorKind, DormRetryability, Object?) _pg(PgException error) {
    return switch (error.severity) {
      Severity.panic || Severity.fatal => (
        DormErrorKind.unavailable,
        DormRetryability.unknown,
        null,
      ),
      _ => (DormErrorKind.unknown, DormRetryability.unknown, null),
    };
  }
}
