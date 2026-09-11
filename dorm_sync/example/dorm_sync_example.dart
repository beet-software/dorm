import 'package:dorm_sync/dorm_sync.dart';

Future<void> main() async {
  final SyncOutbox outbox = MemorySyncOutbox();

  // Configure an EngineSyncTarget and EngineReplicaTarget in the application,
  // then pass them to SynchronizedEngine with this outbox.
  print(isDormAvailabilityFailure(StateError('example'), StackTrace.current));

  await outbox.close();
}