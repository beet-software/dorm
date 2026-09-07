import 'package:dorm_test/dorm_test.dart';
import 'package:test/test.dart';

void main() {
  test('capabilities default to unsupported', () {
    const EngineCapabilities capabilities = EngineCapabilities();

    expect(capabilities.compositeIdentities, isFalse);
    expect(capabilities.negativeLimits, isFalse);
    expect(capabilities.reactiveStreams, isFalse);
    expect(capabilities.atomicBatchWrites, isFalse);
    expect(capabilities.atomicPatch, isFalse);
  });
}
