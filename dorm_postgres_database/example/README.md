# PostgreSQL dORM example

This is a pure Dart example. It expects a PostgreSQL database to be available
and creates the two example tables with SQL when it starts.

Run it from this directory:

```shell
dart pub get
dart run build_runner build
dart analyze
```

Set `POSTGRES_HOST`, `POSTGRES_PORT`, `POSTGRES_DATABASE`,
`POSTGRES_USERNAME`, and `POSTGRES_PASSWORD`, then run:

```shell
dart run
```

The generated files are produced from `lib/models.dart`; edit that source and
run `build_runner` again after changing its annotations.
