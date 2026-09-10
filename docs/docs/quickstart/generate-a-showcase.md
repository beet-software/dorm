# Generate a showcase project

Use `dorm_example` when you want to see the portable ORM workflow before
connecting it to your own application. The command creates a complete project
with annotated models, generated repositories, the store domain used
throughout the showcase, and setup instructions for the selected engine.

Choose `memory` to focus on the generated application surface without external
infrastructure. Choose another profile when you want to see the same store
operations connected to PostgreSQL, MySQL, MongoDB, SQLite, Firebase,
Firestore, or HTTP. The profile changes the backend setup and capabilities;
the recurring model and repository operations remain recognizable.

## Install the generator

Install the executable once:

```shell
dart pub global activate dorm_example
```

The command becomes available as `dorm_example` after Dart's global executable
directory is on your `PATH`.

## Generate a project

Pass one engine with `-e` and choose the destination with `-o`:

```shell
dorm_example -e memory
dorm_example -e postgres -o store_example
```

The default destination is `dorm_example`. The generator refuses to write into
a non-empty directory, so select a new directory or remove the existing
project before generating another one.

The generated project contains the annotated source in `lib/models.dart`.
Run `build_runner` after creation to produce `lib/models.dorm.dart` and
`lib/models.g.dart`; those files are derived from the annotated source.

## Choose a project profile

| Engine | Generated project | External setup |
| --- | --- | --- |
| In-memory | Flutter Web | None |
| BLoC | Flutter Web | None |
| Firebase | Flutter Web | Docker Compose with a local Firebase emulator |
| Firestore | Flutter Web | Docker Compose with a local Firestore emulator |
| HTTP | Flutter Web | Docker Compose with the generated local REST server |
| PostgreSQL | Pure Dart | Docker Compose and environment variables |
| MySQL | Pure Dart | Docker Compose and environment variables |
| MongoDB | Pure Dart | Docker Compose and `MONGO_URI` |
| SQLite | Pure Dart | Local database file |

The platform is selected by the engine profile. Direct PostgreSQL, MySQL,
MongoDB, and SQLite drivers are not used directly from a Flutter Web browser;
their generated projects run as Dart applications.

Firebase, Firestore, and HTTP profiles include a `docker-compose.yml` that
starts infrastructure only. The generated Flutter application continues to
run on the host, so browser access and hot reload remain part of the normal
Flutter workflow.

Flutter profiles require Flutter **3.47.1 or newer**. This requirement comes
from the `build_runner`/analyzer dependency chain used by the generated
project; pure Dart profiles are not affected.

## Run the Firebase profile locally

Generate the Flutter project and start its local emulator:

```shell
dorm_example -e firebase -o store_firebase
cd store_firebase
docker compose up -d
flutter pub get
dart run build_runner build
flutter run -d chrome
```

The generated Firebase options use the fictional project ID `dorm-example`.
Realtime Database is published on port `9000`, and Emulator UI is available at
<http://localhost:4000>. No Firebase project or credentials are needed for
this generated profile.

## Run the Firestore profile locally

Use the same host/container split for Firestore:

```shell
dorm_example -e firestore -o store_firestore
cd store_firestore
docker compose up -d
flutter pub get
dart run build_runner build
flutter run -d chrome
```

Firestore is published on port `8080` and Emulator UI is available at
<http://localhost:4000>. The generated application calls
`useFirestoreEmulator` before constructing the dORM engine.

## Run the HTTP profile locally

The HTTP profile includes a small Dart server in `server/`. It stores data in
memory and is intended to make the generated project runnable without an
external API:

```shell
dorm_example -e http -o store_http
cd store_http
docker compose up -d
flutter pub get
dart run build_runner build
flutter run -d chrome --dart-define=HTTP_BASE_URI=http://localhost:8080/api/
```

The server listens on port `8080`, accepts the resource mappings generated in
the Flutter application, and loses its data when its container restarts. The
default `HTTP_BASE_URI` already points to this local service.

## Run the in-memory profile

Generate and enter the project:

```shell
dorm_example -e memory -o store_memory
cd store_memory
```

Install dependencies and generate the source files:

```shell
flutter pub get
dart run build_runner build
flutter run -d chrome
```

The Flutter application uses the same store domain as the other profiles:
users, categories, products, carts, cart items, reviews, and wishlist items.
Its pages demonstrate CRUD, relationships, filters, sorting, pagination, and
live reads supported by the selected engine.

## Run the PostgreSQL profile

Generate the pure Dart profile:

```shell
dorm_example -e postgres -o store_postgres
cd store_postgres
```

Start PostgreSQL with the generated Compose file:

```shell
docker compose up -d
```

The Compose file mounts `sql/schema.sql` into a fresh database volume. Use
`.env.example` as the list of variables required by the generated Dart
application. Copying that file alone does not load it automatically; export
the variables in your shell or configure them in your IDE. For example, in
PowerShell:

```shell
$env:POSTGRES_HOST = '127.0.0.1'
$env:POSTGRES_PORT = '5432'
$env:POSTGRES_DATABASE = 'dorm_example'
$env:POSTGRES_USERNAME = 'dorm'
$env:POSTGRES_PASSWORD = 'dorm'
```

On macOS or Linux, export the same names:

```shell
export POSTGRES_HOST=127.0.0.1
export POSTGRES_PORT=5432
export POSTGRES_DATABASE=dorm_example
export POSTGRES_USERNAME=dorm
export POSTGRES_PASSWORD=dorm
```

Then install dependencies, generate the model API, and run the showcase:

```shell
dart pub get
dart run build_runner build
dart analyze
dart run
```

The generated SQL profiles keep the model declarations relational. They use
scalar fields, foreign keys, and SQL-compatible identities instead of
JSON-oriented annotations such as `ModelField`, `PolymorphicField`, and
`DerivedField`.

## Inspect the generated project

Start with these files:

- `lib/models.dart`: the source of the model and relationship declarations;
- `lib/models.dorm.dart`: generated entities, repositories, schema metadata,
  and the `Dorm` facade;
- `lib/models.g.dart`: generated JSON and copy-with support;
- `README.md`: commands and backend-specific setup;
- `docker-compose.yml`, `.env.example`, and `sql/schema.sql` for service-backed
  profiles.

For SQLite, the generated Dart program reads the final `sql/schema.sql` file at
startup and executes it before creating the engine. Run the program from the
generated project root so that this relative path resolves correctly.

Edit `lib/models.dart` when changing the domain. Regenerate the derived files
after every annotation or field change.
