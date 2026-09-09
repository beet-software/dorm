# dorm_mongo_database example

<p>
  <a href="https://ezgrs.github.io/dorm/"><img src="https://img.shields.io/badge/documentation-dORM-4c8bf5?style=flat" alt="dORM documentation"></a>
  <a href="https://github.com/beet-software/dorm"><img src="https://img.shields.io/badge/repository-GitHub-181717?logo=github&style=flat" alt="dORM repository"></a>
  <a href="https://github.com/beet-software/dorm"><img src="https://img.shields.io/github/license/beet-software/dorm?style=flat" alt="License"></a>
  <a href="https://github.com/beet-software/dorm/actions/workflows/dart.yml"><img src="https://github.com/beet-software/dorm/actions/workflows/dart.yml/badge.svg" alt="Dart CI"></a>
</p>

This pure Dart example connects to MongoDB through the mongo_dart driver. It
uses MONGO_URI when present and otherwise targets a local development database.

## Run it

Execute these commands from this directory:

~~~shell
dart pub get
dart run build_runner build
dart analyze
dart run
~~~

Set the connection URI before running against another database:

~~~powershell
$env:MONGO_URI = 'mongodb://127.0.0.1:27017/dorm_example'
dart run
~~~

The example clears its development collections around the showcase flow. Its
model source is lib/models.dart; generated files are derived from that source.
