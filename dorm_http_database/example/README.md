# HTTP dORM example

This is a pure Dart example. It expects an HTTP/JSON API whose resources are
available under the URI in `HTTP_BASE_URI`.

The API must provide `users` and `posts` resources. Single-item operations use
`/{resource}/{id}`. Batch creation, batch replacement, and deletion by keys use
the paths configured in `lib/main.dart`.

Run it from this directory:

```shell
dart pub get
dart run build_runner build
dart analyze
```

Set the API base URI, including a trailing slash, then run:

```shell
set HTTP_BASE_URI=https://example.test/api/
dart run
```

On PowerShell, use `$env:HTTP_BASE_URI = 'https://example.test/api/'` instead.

The generated files are produced from `lib/models.dart`. Edit that source and
run `build_runner` again after changing its annotations.
