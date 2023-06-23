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

import 'package:firebase_auth/firebase_auth.dart' as fa;
import 'package:firebase_core/firebase_core.dart' as fc;
import 'package:firebase_database/firebase_database.dart' as fd;

import 'offline.dart';

abstract class FirebaseInstance {
  const factory FirebaseInstance({
    OfflineMode offlineMode,
  }) = _DefaultFirebaseInstance;

  const factory FirebaseInstance.custom(
    fc.FirebaseApp app, {
    OfflineMode offlineMode,
    String? databaseUrl,
  }) = _CustomFirebaseInstance;

  fc.FirebaseApp get app;

  fd.FirebaseDatabase get database;

  fa.FirebaseAuth get auth;

  OfflineMode get offlineMode;
}

class _DefaultFirebaseInstance implements FirebaseInstance {
  @override
  final OfflineMode offlineMode;

  const _DefaultFirebaseInstance({this.offlineMode = OfflineMode.include});

  @override
  fc.FirebaseApp get app => fc.Firebase.app();

  @override
  fa.FirebaseAuth get auth => fa.FirebaseAuth.instance;

  @override
  fd.FirebaseDatabase get database => fd.FirebaseDatabase.instance;
}

class _CustomFirebaseInstance implements FirebaseInstance {
  @override
  final fc.FirebaseApp app;

  @override
  final OfflineMode offlineMode;

  final String? databaseUrl;

  const _CustomFirebaseInstance(
    this.app, {
    this.databaseUrl,
    this.offlineMode = OfflineMode.include,
  });

  @override
  fa.FirebaseAuth get auth => fa.FirebaseAuth.instanceFor(app: app);

  @override
  fd.FirebaseDatabase get database =>
      fd.FirebaseDatabase.instanceFor(app: app, databaseURL: databaseUrl);
}
