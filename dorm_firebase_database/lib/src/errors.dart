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

import 'package:dorm_framework/dorm_framework.dart';
import 'package:firebase_core/firebase_core.dart';

final class FirebaseDatabaseErrorMapper implements DormErrorMapper {
  const FirebaseDatabaseErrorMapper();

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
      final FirebaseException error => _firebase(error.code),
      final TimeoutException _ => (
        DormErrorKind.timeout,
        DormRetryability.unknown,
        null,
      ),
      _ => (DormErrorKind.unknown, DormRetryability.unknown, null),
    };
    return DormDatabaseException(
      kind: kind,
      retryability: retryability,
      message: error.toString(),
      engine: 'firebase_database',
      operation: operation,
      providerCode: code,
      cause: error,
      stackTrace: stackTrace,
    );
  }

  (DormErrorKind, DormRetryability, String) _firebase(String code) {
    return switch (code) {
      'permission-denied' => (
        DormErrorKind.authorization,
        DormRetryability.never,
        code,
      ),
      'unauthenticated' || 'invalid-credential' => (
        DormErrorKind.authentication,
        DormRetryability.never,
        code,
      ),
      'unavailable' || 'network-request-failed' => (
        DormErrorKind.unavailable,
        DormRetryability.unknown,
        code,
      ),
      'deadline-exceeded' => (
        DormErrorKind.timeout,
        DormRetryability.unknown,
        code,
      ),
      'aborted' => (DormErrorKind.transaction, DormRetryability.safe, code),
      'already-exists' => (
        DormErrorKind.conflict,
        DormRetryability.never,
        code,
      ),
      'failed-precondition' => (
        DormErrorKind.constraint,
        DormRetryability.never,
        code,
      ),
      'invalid-argument' => (
        DormErrorKind.invalidData,
        DormRetryability.never,
        code,
      ),
      'not-found' => (DormErrorKind.notFound, DormRetryability.never, code),
      'cancelled' => (DormErrorKind.cancelled, DormRetryability.never, code),
      _ => (DormErrorKind.unknown, DormRetryability.unknown, code),
    };
  }
}
