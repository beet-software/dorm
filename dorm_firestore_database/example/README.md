# Cloud Firestore dORM example

This is a Flutter example using the `dorm_firestore_database` engine. The
application must initialize Firebase before constructing the dORM engine.

Run these commands from this directory:

```shell
flutter pub get
dart run build_runner build
flutter analyze
```

Configure a Firebase application for the target platform before running the
example. To use the Firestore Emulator, start it with:

```shell
firebase emulators:start --only firestore
```

Then set `FIRESTORE_EMULATOR_HOST` to the emulator host and port before
starting the application. On PowerShell:

```powershell
$env:FIRESTORE_EMULATOR_HOST = '127.0.0.1:8080'
flutter run
```

The generated files come from `lib/models.dart`. Edit that file and run the
generator again after changing the annotations.
