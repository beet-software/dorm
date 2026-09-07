import 'package:dorm_framework/dorm_framework.dart';

import 'capabilities.dart';

/// Opens an isolated session used by the engine conformance suite.
abstract interface class EngineTestAdapter<Q extends BaseQuery<Q>> {
  /// A name used to identify the engine in test descriptions.
  String get name;

  /// Opens the engine, prepares its test storage, and returns a session.
  Future<EngineTestSession<Q>> open();
}

/// A configured engine session used by the conformance suite.
abstract interface class EngineTestSession<Q extends BaseQuery<Q>> {
  /// The engine under test.
  BaseEngine<Q, OffsetPageRequest> get engine;

  /// Behaviors that are supported by this engine and session.
  EngineCapabilities get capabilities;

  /// Removes test data and restores the session to its initial state.
  Future<void> reset();

  /// Closes the backend resources owned by the session.
  Future<void> close();
}
