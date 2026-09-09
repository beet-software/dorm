# dorm_http_database example

<p>
  <a href="https://ezgrs.github.io/dorm/"><img src="https://img.shields.io/badge/documentation-dORM-4c8bf5?style=flat" alt="dORM documentation"></a>
  <a href="https://github.com/ezgrs/dorm"><img src="https://img.shields.io/badge/repository-GitHub-181717?logo=github&style=flat" alt="dORM repository"></a>
  <a href="https://github.com/ezgrs/dorm"><img src="https://img.shields.io/github/license/ezgrs/dorm?style=flat" alt="License"></a>
  <a href="https://github.com/ezgrs/dorm/actions/workflows/dart.yml"><img src="https://github.com/ezgrs/dorm/actions/workflows/dart.yml/badge.svg" alt="Dart CI"></a>
</p>

This pure Dart example connects the HTTP engine to a REST-shaped API configured
in lib/main.dart. It expects users and posts resources and uses the generated
mapping for collection and item operations.

## Run it

Execute these commands from this directory:

~~~shell
dart pub get
dart run build_runner build
dart analyze
~~~

Set the API base URI, including its trailing slash:

~~~powershell
$env:HTTP_BASE_URI = 'https://example.test/api/'
dart run
~~~

The generated HTTP engine does not create a server. The remote API must
implement the endpoints and response shapes configured by HttpMapping. The
model source is lib/models.dart.
