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
import 'package:mongo_dart/mongo_dart.dart';

final class MongoErrorMapper implements DormErrorMapper {
  const MongoErrorMapper();

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
      final ConnectionException _ => (
        DormErrorKind.unavailable,
        DormRetryability.unknown,
        null,
      ),
      final MongoDartError error => _mongo(error),
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
      engine: 'mongo',
      operation: operation,
      providerCode: code,
      cause: error,
      stackTrace: stackTrace,
    );
  }

  (DormErrorKind, DormRetryability, Object?) _mongo(MongoDartError error) {
    final Object? code =
        error.mongoCode ?? error.errorCode ?? error.errorCodeName;
    if (error.mongoCode == 11000 || error.errorCodeName == 'DuplicateKey') {
      return (DormErrorKind.conflict, DormRetryability.never, code);
    }
    if (error.errorCodeName == 'Unauthorized' ||
        error.errorCodeName == 'AuthenticationFailed') {
      return (DormErrorKind.authentication, DormRetryability.never, code);
    }
    return (DormErrorKind.unknown, DormRetryability.unknown, code);
  }
}
