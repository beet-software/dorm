import 'package:dorm_test/dorm_test.dart';
import 'package:test/test.dart';

void main() {
  test('capabilities default to unsupported', () {
    const EngineCapabilities capabilities = EngineCapabilities();

    expect(capabilities.compositeIdentities, isFalse);
    expect(capabilities.reactiveStreams, isFalse);
    expect(capabilities.atomicBatchWrites, isFalse);
    expect(capabilities.atomicPatch, isFalse);
    expect(capabilities.transactions, isFalse);
    expect(capabilities.comparisonFilters, isFalse);
    expect(capabilities.logicalFilters, isFalse);
    expect(capabilities.negationFilters, isFalse);
    expect(capabilities.collectionFilters, isFalse);
  });

  test('transaction capability can be declared', () {
    const EngineCapabilities capabilities = EngineCapabilities(
      transactions: true,
      comparisonFilters: true,
      logicalFilters: true,
      negationFilters: true,
      collectionFilters: true,
    );

    expect(capabilities.transactions, isTrue);
    expect(capabilities.comparisonFilters, isTrue);
    expect(capabilities.logicalFilters, isTrue);
    expect(capabilities.negationFilters, isTrue);
    expect(capabilities.collectionFilters, isTrue);
  });
}
