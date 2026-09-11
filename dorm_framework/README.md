# dorm_framework

<p>
  <a href="https://pub.dev/packages/dorm_framework"><img src="https://img.shields.io/pub/v/dorm_framework.svg?label=dorm_framework" alt="dorm_framework on pub.dev"></a>
  <a href="https://pub.dev/packages/dorm_framework"><img src="https://img.shields.io/pub/points/dorm_framework?logo=dart" alt="dorm_framework pub points"></a>
  <a href="https://pub.dev/packages/dorm_framework"><img src="https://img.shields.io/pub/popularity/dorm_framework?logo=dart" alt="dorm_framework popularity"></a>
  <a href="https://pub.dev/packages/dorm_framework"><img src="https://img.shields.io/pub/likes/dorm_framework?logo=dart" alt="dorm_framework likes"></a>
  <a href="https://ezgrs.github.io/dorm/reference/framework-contracts/"><img src="https://img.shields.io/badge/documentation-dORM-4c8bf5?style=flat" alt="dorm_framework documentation"></a>
  <a href="https://github.com/ezgrs/dorm"><img src="https://img.shields.io/badge/repository-GitHub-181717?logo=github&style=flat" alt="dORM repository"></a>
  <a href="https://github.com/ezgrs/dorm"><img src="https://img.shields.io/github/license/ezgrs/dorm?style=flat" alt="License"></a>
  <a href="https://github.com/ezgrs/dorm/actions/workflows/dart.yml"><img src="https://github.com/ezgrs/dorm/actions/workflows/dart.yml/badge.svg" alt="Dart CI"></a>
</p>

<p>
  <a href="https://pub.dev/packages/dorm_annotations"><img src="https://img.shields.io/pub/v/dorm_annotations.svg?label=annotations" alt="dorm_annotations"></a>
  <a href="https://pub.dev/packages/dorm_generator"><img src="https://img.shields.io/pub/v/dorm_generator.svg?label=generator" alt="dorm_generator"></a>
  <a href="https://pub.dev/packages/dorm_memory_database"><img src="https://img.shields.io/pub/v/dorm_memory_database.svg?label=memory" alt="dorm_memory_database"></a>
  <a href="https://pub.dev/packages/dorm_bloc_database"><img src="https://img.shields.io/pub/v/dorm_bloc_database.svg?label=bloc" alt="dorm_bloc_database"></a>
  <a href="https://pub.dev/packages/dorm_firebase_database"><img src="https://img.shields.io/pub/v/dorm_firebase_database.svg?label=firebase" alt="dorm_firebase_database"></a>
  <a href="https://pub.dev/packages/dorm_firestore_database"><img src="https://img.shields.io/pub/v/dorm_firestore_database.svg?label=firestore" alt="dorm_firestore_database"></a>
  <a href="https://pub.dev/packages/dorm_http_database"><img src="https://img.shields.io/pub/v/dorm_http_database.svg?label=http" alt="dorm_http_database"></a>
  <a href="https://pub.dev/packages/dorm_mongo_database"><img src="https://img.shields.io/pub/v/dorm_mongo_database.svg?label=mongo" alt="dorm_mongo_database"></a>
  <a href="https://pub.dev/packages/dorm_mysql_database"><img src="https://img.shields.io/pub/v/dorm_mysql_database.svg?label=mysql" alt="dorm_mysql_database"></a>
  <a href="https://pub.dev/packages/dorm_postgres_database"><img src="https://img.shields.io/pub/v/dorm_postgres_database.svg?label=postgres" alt="dorm_postgres_database"></a>
  <a href="https://pub.dev/packages/dorm_sqlite_database"><img src="https://img.shields.io/pub/v/dorm_sqlite_database.svg?label=sqlite" alt="dorm_sqlite_database"></a>
  <a href="https://pub.dev/packages/dorm_example"><img src="https://img.shields.io/pub/v/dorm_example.svg?label=showcase" alt="dorm_example"></a>
</p>

dorm_framework defines the engine-independent types used by dORM
applications. It describes how generated models become entities and
repositories, how reads and writes are expressed, and how engines expose
their backend-specific execution through one common contract.

## Install

Add the framework to the application:

~~~shell
dart pub add dorm_framework
~~~

A working generated model also needs dorm_annotations, dorm_generator,
build_runner, and one engine. The framework package is the center of those
contracts; it does not open a database by itself.

## The model and repository boundary

dORM separates three values that are easy to confuse:

- Data is input used to create or update a model.
- Model is an identified value that can be persisted or returned by a read.
- Dependency carries identities needed to construct related data.
- Entity connects generated data/model types to schema and repository behavior.
- Repository is the application-facing object for CRUD and reads.

A typical generated flow looks like this:

~~~dart
final User user = await dorm.users.repository.put(
  Creation.auto(
    dependency: const UserDependency(),
    data: UserData(
      username: 'ada',
      email: 'ada@example.com',
      profile: Profile(
        name: 'Ada Lovelace',
        birthDate: DateTime(1815, 12, 10),
        bio: 'Mathematician',
      ),
    ),
  ),
);

final User? loaded = await dorm.users.repository.peek(user.id);
~~~

Creation resolves the identity and passes a ResolvedCreation to the generated
Entity. The resulting Model is the identified form returned by the repository.

## Creating the generated facade

The generated Dorm class is parameterized by the engine query and page types.
Type inference normally handles both:

~~~dart
final Engine engine = Engine();
final dorm = Dorm(engine);
~~~

The facade exposes generated accessors such as dorm.users and dorm.products.
Each accessor carries its Entity, Repository, schema fields, and relationship
paths.

## Creating and updating data

Use put for new Data values. Use push when a Model already has its final
identity:

~~~dart
final User created = await dorm.users.repository.put(
  Creation.auto(
    dependency: const UserDependency(),
    data: UserData(
      username: 'ada',
      email: 'ada@example.com',
      profile: Profile(
        name: 'Ada Lovelace',
        birthDate: DateTime(1815, 12, 10),
        bio: 'Mathematician',
      ),
    ),
  ),
);

await dorm.users.repository.push(
  created.copyWith(email: 'ada@lovelace.org'),
);
~~~

Use Creation.explicit when the application already owns the final identity:

~~~dart
final User imported = await dorm.users.repository.put(
  Creation.explicit(
    dependency: const UserDependency(),
    data: UserData(
      username: 'grace',
      email: 'grace@example.com',
      profile: Profile(
        name: 'Grace Hopper',
        birthDate: DateTime(1906, 12, 9),
        bio: 'Computer scientist',
      ),
    ),
    identity: 'external-user-42',
  ),
);
~~~

For a model whose backend supplies its identity, Creation.auto uses the
declared DatabaseGeneratedIdSpec and returns the model after the backend has
returned the key.

## Reading, filtering, sorting, and pages

Filters resolve application fields through generated FieldSchema values:

~~~dart
final List<User> users = await dorm.users.repository.peekAll(
  Filter.text('ada', field: UserEntity.fields.username),
  QueryOptions(
    orderBy: [
      OrderBy(UserEntity.fields.username),
    ],
  ),
);
~~~

The filter API describes the condition. The engine Query turns the resolved
field name into SQL, a selector, a Firebase query, or an HTTP parameter.
OffsetPageRequest is the page request accepted by current engines:

~~~dart
final Page<User> page = await dorm.users.repository.peekPage(
  const BaseFilter.empty(),
  const OffsetPageRequest(size: 20, offset: 0),
);
~~~

## Relationships

Foreign fields become generated relationship paths. The application uses
the same relationship vocabulary regardless of whether the selected engine
joins SQL tables, reads documents, or performs several repository reads:

~~~dart
final List<Join<Cart, CartItem>> items = await dorm
    .relations
    .carts
    .items
    .peekAll();
~~~

Relationship cardinality is declared by the model metadata and the generated
path. Backend query counts and relation optimizations can differ by engine.

## Transactions

Engines that implement TransactionalEngine also generate TransactionalDorm:

~~~dart
final txDorm = TransactionalDorm(engine);

await txDorm.transaction((tx) async {
  final User? user = await tx.users.repository.peek(userId);
  if (user != null) {
    await tx.users.repository.push(user.copyWith(email: 'new@example.com'));
  }
});
~~~

The callback receives a temporary Dorm context. Streams are not available in
that context. Engines without the capability keep the normal Dorm API.

## Swapping engines

The generated model source is independent of the backend object. To change
engines, construct a different Engine and regenerate only when the selected
engine changes the generated type context:

~~~dart
final engine = Engine(databaseOrClient);
final dorm = Dorm(engine);
~~~

The repository calls stay the same. Backend-specific capabilities do not:
identity types, live streams, transactions, query operators, schema setup, and
atomicity depend on the selected engine.

## Implementing an engine

A custom engine implements BaseEngine<Q, P>, creates references and
relationships, and provides a concrete BaseQuery<Q>. Reference methods receive
generated Entity metadata and perform the backend operation. The engine owns
connection setup and backend-specific serialization details; the framework does
not create or close external connections.

Use dorm_test from development code to exercise the portable contract. Keep
engine-specific behavior in separate tests.

## Important boundaries

dorm_framework does not create schemas or migrations. It does not make every
backend transactional or reactive. A stream may represent a live subscription
or only the initial read, depending on the engine. Query features must be
supported by the selected backend; dORM does not silently download and filter
data on the client.

## Learn more

- [Framework contracts](https://ezgrs.github.io/dorm/reference/framework-contracts/)
- [Public API](https://ezgrs.github.io/dorm/reference/public-api/)
- [Model anatomy](https://ezgrs.github.io/dorm/model-anatomy/)
- [dorm_annotations](https://pub.dev/packages/dorm_annotations)
- [dorm_generator](https://pub.dev/packages/dorm_generator)
- [Choose an engine](https://ezgrs.github.io/dorm/engines/)
- [GitHub repository](https://github.com/ezgrs/dorm)
