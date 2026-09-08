# Run the store with PostgreSQL

This page uses a pure Dart application and the `dorm_postgres_database` engine.
The application supplies an opened `Connection` or `Pool`; the engine does
not open or close that object for you.

## Add the engine package

From the Dart application directory, execute:

```shell title="Add the PostgreSQL engine"
dart pub add dorm_postgres_database
```

Add the PostgreSQL driver because the application creates and owns the
`Connection` or `Pool`:

```shell title="Add the PostgreSQL driver"
dart pub add postgres
```

The application imports `postgres` directly for connection setup. The dORM
engine barrel exports `Engine`, `Filter`, and `Query`, but does not re-export
all driver types.

## Configure the connection

Read the PostgreSQL endpoint from the application configuration and open it
before constructing the generated `Dorm`:

```dart
final Connection connection = await Connection.open(
  Endpoint(
    host: host,
    port: port,
    database: database,
    username: username,
    password: password,
  ),
);

final Dorm<Query, OffsetPageRequest> dorm = Dorm(Engine(connection));
```

To use pooling, open a `Pool` instead. `Connection` and `Pool` both satisfy
the `SessionExecutor` boundary accepted by the engine.

Keep the executor open for as long as the generated repositories may issue
operations. Close it from the application lifecycle after those operations are
finished.

## Create the tables

Create tables with PostgreSQL SQL before using the repositories. The package
does not expose a schema generator or migration command.

For a generated model with a `String` identity and a `String` field, the table
contains a primary-key column and the mapped model columns. Foreign fields
must reference the corresponding target primary-key column when PostgreSQL
constraints are enabled.

For a database-generated identity, define the key column with PostgreSQL's
identity or sequence-backed syntax and annotate the model with
`DatabaseGeneratedIdSpec`. Do not include that column in the `Data` input. The
engine uses `INSERT ... RETURNING` to obtain the value before returning the
model.

## Generate the model API

Declare the model source with `part` directives and run:

```shell title="Generate the PostgreSQL model API"
dart run build_runner build
```

The generator writes the `.dorm.dart` and `.g.dart` parts from the annotated
source. Edit the annotated source and regenerate after changing fields,
relationships, or serialization declarations.

## Execute CRUD, filters, and relationships

Use the generated repositories in the same way as other dORM engines:

```dart
final User user = await dorm.users.repository.put(
  Creation.auto(
    dependency: UserDependency(),
    data: UserData(name: 'Ada'),
  ),
);

await dorm.posts.repository.push(
  Post(id: 'post-1', title: 'First post', userId: user.id),
);

final List<User> users = await dorm.users.repository.peekAll(
  Filter.text('Ad', field: UserEntity.fields.name),
);

final List<Join<User, Post>> posts =
    await dorm.relations.users.posts.peekAll();
```

`push` and `pushAll` use PostgreSQL `INSERT ... ON CONFLICT` statements. The
conflict target contains all primary-key columns. `patch`, `putAll`, and
`pushAll` use an internal driver transaction. `TransactionalDorm` exposes a
transaction callback for composing repository operations without exposing the
driver transaction object.

## Close the executor

Close the `Connection` or `Pool` from the application after the repositories
are no longer needed:

```dart
await connection.close();
```

The complete pure Dart example is in the package's `example/` directory and
uses `POSTGRES_HOST`, `POSTGRES_PORT`, `POSTGRES_DATABASE`,
`POSTGRES_USERNAME`, and `POSTGRES_PASSWORD` for its endpoint values.

## Configure credentials and query boundaries

The application owns the PostgreSQL endpoint credentials and supplies them to
`Connection.open` or `Pool`. Keep those values in deployment configuration.
The dORM engine does not provide an authentication, roles, or secrets-store
abstraction.

Filter values and model values are sent through the PostgreSQL driver's
parameterized execution path. Table and column identifiers come from the
generated schema metadata rather than from filter values.

## Observe performance characteristics

The PostgreSQL engine builds parameterized SQL for direct operations. Its
`putAll`, `pushAll`, and `patch` paths use the driver's internal transaction
boundary described on this page. `TransactionalDorm` reuses the same driver
transaction for its callback.

Relationship reads can use direct relation plans or fall back to readable
operations. The fallback can perform additional repository reads. PostgreSQL
`pull` and `pullAll` emit the initial read only and do not maintain a database
subscription.
