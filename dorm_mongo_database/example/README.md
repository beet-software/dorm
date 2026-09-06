# MongoDB dORM example

This is a pure Dart example. It connects to the MongoDB URI in `MONGO_URI`,
or to `mongodb://127.0.0.1:27017/dorm_example` when the variable is absent.
The example clears its two development collections before and after running.

Run it from this directory:

```shell
dart pub get
dart run build_runner build
dart analyze
dart run
```

The generated files come from `lib/models.dart`. Edit that source and run
`build_runner` again after changing model annotations or fields.
