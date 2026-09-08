# Run the store with Firebase Realtime Database

`dorm_firebase_database` connects generated dORM repositories to Firebase Realtime Database. This package depends on Flutter Firebase packages, so this setup is a Flutter/Firebase integration.

The repository API remains the same after the engine changes. The setup adds Firebase initialization, a Firebase dependency object, and a database root path.

## Add the Firebase packages

From the Flutter application directory, run:

```shell
flutter pub add dorm_firebase_database
flutter pub add firebase_core
flutter pub add firebase_database
flutter pub add firebase_auth
flutter pub get
```

The Firebase engine uses Firebase Core, Realtime Database, and Authentication dependencies. A Firebase project configuration is required before the application can connect to a hosted database.

## Initialize Firebase before creating the engine

Initialize the Firebase app before accessing `FirebaseInstance`:

```dart
import 'package:dorm_firebase_database/dorm_firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';

import 'models.dart';

Future<Dorm<Query, OffsetPageRequest>> createDorm() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  const FirebaseInstance instance = FirebaseInstance();
  const Engine engine = Engine(instance, path: 'prod');
  return Dorm(engine);
}
```

`FirebaseInstance()` uses the default Firebase app and default Firebase Database/Auth instances. `FirebaseInstance.custom` selects another `FirebaseApp` and can receive a database URL. `Engine` accepts the instance and an optional root path; `path: 'prod'` stores the entity tables below that path.

The Firebase platform configuration is supplied by the Flutter application. Use `[PLACEHOLDER: add the Firebase platform configuration for the target platforms]` before running the application if `Firebase.initializeApp()` cannot find a configured default app.

## Use the repository with Firebase

After `createDorm` completes, repository calls use Firebase storage:

```dart
final Dorm<Query, OffsetPageRequest> dorm = await createDorm();

final User user = await dorm.users.repository.put(
  Creation.auto(
    dependency: const UserDependency(),
    data: userData,
  ),
);

final User? loaded = await dorm.users.repository.peek(user.id);
```

Firebase creates the identity for `put` with a Firebase push key. The Firebase adapter accepts only `String` identities; passing another identity type to a Firebase reference raises `ArgumentError`.

## Configure offline behavior

`FirebaseInstance` accepts an `OfflineMode`:

```dart
const FirebaseInstance cached = FirebaseInstance(
  offlineMode: OfflineMode.include,
);

const FirebaseInstance remoteOnly = FirebaseInstance(
  offlineMode: OfflineMode.exclude,
);
```

With `OfflineMode.include`, the adapter reads Firebase's local cache while offline. With `OfflineMode.exclude`, the Firebase query waits for online data; the source documentation states that `get` and `onValue` can hang indefinitely while offline.

The default mode is `OfflineMode.include`.

## Run against the local emulator

From the Flutter application directory, configure the Firebase Database Emulator with port `9000`:

```shell
firebase init
```

Select Realtime Database and Emulators during initialization. Use `database.rules.json` for the Realtime Database rules and port `9000` for the Database Emulator.

Start the emulator in a separate terminal:

```shell
firebase emulators:start --only database
```

Point the Firebase Database SDK at the emulator before creating the dORM engine:

```dart
await Firebase.initializeApp();
FirebaseDatabase.instance.useDatabaseEmulator('localhost', 9000);

const FirebaseInstance instance = FirebaseInstance();
const Dorm<Query, OffsetPageRequest> dorm = Dorm(Engine(instance, path: 'prod'));
```

The emulator connection changes the Firebase endpoint. It does not change the generated repository API.

## Subscribe to Firebase changes

Firebase `pull` and `pullAll` are backed by Realtime Database value events:

```dart
final subscription = dorm.users.repository.pullAll().listen((users) {
  print('Users: ${users.length}');
});

await subscription.cancel();
```

The selected `OfflineMode` affects how the adapter obtains snapshots while connectivity changes. Cancel subscriptions when the consuming application component is disposed.

## Regenerate and run

After changing annotated models, regenerate the generated parts before launching Flutter:

```shell
flutter pub run build_runner build
flutter run
```

The Firebase initialization, database rules, and network/emulator connection are separate from dORM code generation.

## Understand the transaction boundary

Firebase Realtime Database provides `runTransaction` for a single
`DatabaseReference`. The dORM engine uses that mechanism internally for
`patch`, but it does not expose `TransactionalDorm` for composing operations
across repositories.

Filtered reads cannot be moved into the current Firebase transaction handler,
so operations such as `popAll` read the matching models first and then remove
their identities. This is not the same as one public multi-repository
transaction.

## Configure authentication and database rules

Firebase Authentication and Realtime Database rules define whether a repository
operation is allowed. The dORM engine does not log a user in and does not
create or deploy rules.

For a local authenticated-only setup, the rules file can contain:

```json
{
  "rules": {
    ".read": "auth != null",
    ".write": "auth != null"
  }
}
```

The application must establish the Firebase Authentication state before reads
and writes that depend on these rules. Keep Firebase configuration and any
deployment credentials in the application or platform configuration.

## Observe performance characteristics

The current Firebase reference maps direct operations to backend calls and
snapshot materialization:

| Operation | Current backend work |
| --- | --- |
| `peek` | One child read followed by model deserialization. |
| `peekAll` | One filtered query followed by snapshot collection materialization. |
| `putAll` / `pushAll` | One Firebase update containing the serialized values. |
| `popAll` | A read of matching identities followed by removal. |
| `patch` | A Firebase transaction on the model child. |

`pull` and `pullAll` transform Firebase value events into generated models.
Offline mode changes the underlying event source. The dORM engine does not
expose a separate query-result cache or invalidation policy.
