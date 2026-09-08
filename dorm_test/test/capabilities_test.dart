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
  });

  test('transaction capability can be declared', () {
    const EngineCapabilities capabilities = EngineCapabilities(
      transactions: true,
    );

    expect(capabilities.transactions, isTrue);
  });
}
