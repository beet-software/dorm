# dorm_postgres_database example

<p>
  <a href="https://ezgrs.github.io/dorm/"><img src="https://img.shields.io/badge/documentation-dORM-4c8bf5?style=flat" alt="dORM documentation"></a>
  <a href="https://github.com/beet-software/dorm"><img src="https://img.shields.io/badge/repository-GitHub-181717?logo=github&style=flat" alt="dORM repository"></a>
  <a href="https://github.com/beet-software/dorm"><img src="https://img.shields.io/github/license/beet-software/dorm?style=flat" alt="License"></a>
  <a href="https://github.com/beet-software/dorm/actions/workflows/dart.yml"><img src="https://github.com/beet-software/dorm/actions/workflows/dart.yml/badge.svg" alt="Dart CI"></a>
</p>

This pure Dart example uses an opened PostgreSQL Connection and creates its
demonstration tables with explicit SQL when it starts.

## Run it

Execute these commands from this directory:

~~~shell
dart pub get
dart run build_runner build
dart analyze
~~~

Set the database variables before running:

~~~powershell
$env:POSTGRES_HOST = '127.0.0.1'
$env:POSTGRES_PORT = '5432'
$env:POSTGRES_DATABASE = 'dorm_example'
$env:POSTGRES_USERNAME = 'postgres'
$env:POSTGRES_PASSWORD = '[PLACEHOLDER: password]'
dart run
~~~

The model source is lib/models.dart. The application opens the connection,
creates the demonstration schema, constructs Engine, and runs generated
repository operations. Schema creation in this example is setup code, not a
migration system.
