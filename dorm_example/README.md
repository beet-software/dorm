# dorm_example

`dorm_example` generates a complete starter project for one dORM engine.

```shell
dart pub global activate dorm_example
dorm_example -e memory
```

The generated project contains annotated models, a runnable showcase, setup
instructions, and the commands required to generate `*.dorm.dart` and
`*.g.dart` files.

Use `--output` to choose another directory:

```shell
dorm_example -e postgres --output store_example
```

The generator never overwrites a non-empty directory and does not execute
package installation, code generation, or Docker commands automatically.

The generated Firebase, Firestore, and HTTP profiles include a local
`docker-compose.yml`. It starts only infrastructure; the Flutter application
still runs on the host. Firebase profiles use `spine3/firebase-emulator` with
the Realtime Database or Firestore emulator and Emulator UI on port `4000`.
The HTTP profile includes a small in-memory Dart server in `server/`.

For the SQLite profile, run the generated Dart application from its project
root. It reads `sql/schema.sql` and executes that rendered file before creating
the engine; the schema is a demonstration setup, not a migration system.
