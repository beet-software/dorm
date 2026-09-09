/// Optional behaviors whose semantics are not shared by every dORM engine.
class EngineCapabilities {
  /// Creates a capability description.
  const EngineCapabilities({
    this.compositeIdentities = false,
    this.reactiveStreams = false,
    this.atomicBatchWrites = false,
    this.atomicPatch = false,
    this.transactions = false,
    this.comparisonFilters = false,
    this.logicalFilters = false,
    this.negationFilters = false,
    this.collectionFilters = false,
  });

  /// Whether explicit composite identities are supported by the engine.
  final bool compositeIdentities;

  /// Whether pull operations emit changes after their initial value.
  final bool reactiveStreams;

  /// Whether batch write operations provide the framework's atomicity
  /// contract.
  final bool atomicBatchWrites;

  /// Whether patch evaluates and persists its callback atomically.
  final bool atomicPatch;

  /// Whether the engine exposes the portable multi-operation transaction API.
  final bool transactions;

  /// Whether scalar comparisons, set membership, and null filters are
  /// supported by the engine query.
  final bool comparisonFilters;

  /// Whether the engine supports all-of and any-of filter composition.
  final bool logicalFilters;

  /// Whether the engine supports negating a filter expression.
  final bool negationFilters;

  /// Whether the engine supports filters over persisted collections.
  final bool collectionFilters;
}
