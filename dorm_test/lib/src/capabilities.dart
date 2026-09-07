/// Optional behaviors whose semantics are not shared by every dORM engine.
class EngineCapabilities {
  /// Creates a capability description.
  const EngineCapabilities({
    this.compositeIdentities = false,
    this.negativeLimits = false,
    this.reactiveStreams = false,
    this.atomicBatchWrites = false,
    this.atomicPatch = false,
  });

  /// Whether explicit composite identities are supported by the engine.
  final bool compositeIdentities;

  /// Whether [BaseQuery.limit] accepts negative values.
  final bool negativeLimits;

  /// Whether pull operations emit changes after their initial value.
  final bool reactiveStreams;

  /// Whether batch write operations provide the framework's atomicity
  /// contract.
  final bool atomicBatchWrites;

  /// Whether patch evaluates and persists its callback atomically.
  final bool atomicPatch;
}
