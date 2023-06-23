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

import 'package:firebase_database/firebase_database.dart' as fd;

/// Defines the offline mode to be used while connecting to Firebase.
enum OfflineMode {
  /// Fetches data ONLY when the application is online.
  ///
  /// If you try to [Query.onValue] or [Query.get] while offline,
  /// the query will hang indefinitely.
  exclude,

  /// Fetches data when the application is online, from remote database, and
  /// offline, from local cache.
  ///
  /// If you try to [Query.onValue] or [Query.get] while offline,
  /// the query will return the cached instances, if any.
  include,
}

class OfflineAdapter {
  final fd.FirebaseDatabase instance;
  final fd.Query query;

  late final StreamController<fd.DataSnapshot> _controller;
  StreamSubscription<void>? _connectivitySubscription;
  StreamSubscription<void>? _querySubscription;

  OfflineAdapter({required this.instance, required this.query}) {
    _controller = StreamController.broadcast(
      onListen: () {
        _connectivitySubscription =
            instance.ref('.info/connected').onValue.listen(
          (event) {
            final bool isConnected = (event.snapshot.value as bool?) ?? true;
            final Stream<fd.DatabaseEvent> stream =
                isConnected ? query.onValue : query.onChildAdded;

            _querySubscription = stream
                .map((event) => event.snapshot)
                .listen((snapshot) => _controller.add(snapshot));
          },
          cancelOnError: true,
          onError: (e, s) => _controller.addError(e, s),
        );
      },
      onCancel: () async {
        await _connectivitySubscription?.cancel();
        await _querySubscription?.cancel();
        _connectivitySubscription = null;
        _querySubscription = null;
      },
    );
  }

  Stream<fd.DataSnapshot> get stream => _controller.stream;
}
