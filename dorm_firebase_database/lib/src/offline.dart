import 'dart:async';

import 'package:dorm_firebase_database/dorm_firebase_database.dart';
import 'package:firebase_database/firebase_database.dart' as fd;

/// Defines the offline mode to be used while connecting to Firebase.
enum OfflineMode {
  /// Fetches data ONLY when the application is online.
  ///
  /// If you try to [FirebaseQuery.onValue] or [FirebaseQuery.get] while offline,
  /// the query will hang indefinitely.
  exclude,

  /// Fetches data when the application is online, from remote database, and
  /// offline, from local cache.
  ///
  /// If you try to [FirebaseQuery.onValue] or [FirebaseQuery.get] while offline,
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
            final bool isConnected = (event.snapshot.value as bool?) ?? false;
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
