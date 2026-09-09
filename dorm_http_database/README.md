# dorm_http_database

<p>
  <a href="https://pub.dev/packages/dorm_http_database"><img src="https://img.shields.io/pub/v/dorm_http_database.svg?label=dorm_http_database" alt="dorm_http_database on pub.dev"></a>
  <a href="https://pub.dev/packages/dorm_http_database"><img src="https://img.shields.io/pub/points/dorm_http_database?logo=dart" alt="dorm_http_database pub points"></a>
  <a href="https://pub.dev/packages/dorm_http_database"><img src="https://img.shields.io/pub/popularity/dorm_http_database?logo=dart" alt="dorm_http_database popularity"></a>
  <a href="https://pub.dev/packages/dorm_http_database"><img src="https://img.shields.io/pub/likes/dorm_http_database?logo=dart" alt="dorm_http_database likes"></a>
  <a href="https://ezgrs.github.io/dorm/apply/use-http/"><img src="https://img.shields.io/badge/documentation-dORM-4c8bf5?style=flat" alt="dorm_http_database documentation"></a>
  <a href="https://github.com/beet-software/dorm"><img src="https://img.shields.io/badge/repository-GitHub-181717?logo=github&style=flat" alt="dORM repository"></a>
  <a href="https://github.com/beet-software/dorm"><img src="https://img.shields.io/github/license/beet-software/dorm?style=flat" alt="License"></a>
  <a href="https://github.com/beet-software/dorm/actions/workflows/dart.yml"><img src="https://github.com/beet-software/dorm/actions/workflows/dart.yml/badge.svg" alt="Dart CI"></a>
</p>

dorm_http_database maps dORM repositories to a configured REST-shaped
HTTP/JSON API. It uses an application-owned http.Client and does not assume
one universal REST convention.

## Backend and runtime

The backend is an HTTP server that implements the mapping supplied by the
application. The package can run wherever `package:http` is supported.

## Install

~~~shell
dart pub add dorm_framework
dart pub add dorm_http_database
dart pub add http
dart pub add dorm_annotations
dart pub add --dev dorm_generator
dart pub add --dev build_runner
~~~

## Create the engine and Dorm facade

The mapping is part of the engine configuration, so the generated `Dorm`
facade can remain independent of one particular REST convention.

## Configure the mapping

The mapping declares how each entity becomes an HTTP resource:

~~~dart
import 'package:http/http.dart' as http;
import 'package:dorm_http_database/dorm_http_database.dart';

final mapping = HttpMapping.byTableName({
  'users': HttpResourceMapping(path: 'users'),
});

final engine = Engine(
  client: http.Client(),
  baseUri: Uri.parse('https://api.example.test/'),
  mapping: mapping,
  headers: const {'Authorization': 'Bearer [PLACEHOLDER: token]'},
);

final dorm = Dorm(engine);
~~~

The application owns and closes the http.Client. Configure batch endpoints,
identity placement, response envelopes, and query parameter conventions through
HttpResourceMapping and HttpMapping.

## Use repositories

~~~dart
final User user = await dorm.users.repository.put(
  Creation.auto(
    dependency: const UserDependency(),
    data: UserData(name: 'Ada'),
  ),
);

final List<User> users = await dorm.users.repository.peekAll(
  Filter.text('Ada', field: UserEntity.fields.name),
);
~~~

The default codec maps dORM fields to REST query parameters. HttpJsonCodec can
read an object, a list, or a configured data envelope.

## Identities, filters, pages, and relationships

The mapping controls resource paths, query parameters, ordering, limits,
offsets, and response envelopes. Relationships use readable-operation
fallbacks and may make several requests.

## Backend-generated identities

When the remote API creates the identity, declare DatabaseGeneratedIdSpec and
configure the resource with HttpIdentityLocation.none. The creation response
must be a scalar identity or a complete JSON representation. Use
HttpCreationCodec for an envelope such as a response containing id.

## Transactions

The HTTP engine does not implement the portable `TransactionalDorm` capability.

## Streams

Relationships use readable-operation fallbacks and can make several HTTP
requests. pull and pullAll emit the initial read only; they do not poll or use
SSE/WebSocket connections.

Batch operations require configured batch endpoints. The engine never simulates
a batch by sending independent requests and presenting them as atomic.

Non-success responses produce HttpDatabaseException with status, method, URI,
and available response body. Transport errors from http.Client are propagated.

## Schema, errors, and limitations

The server must implement the endpoint contract configured by the application.
Authentication, retries, caching, observability, and authorization remain
client or server concerns. The package does not provide HTTP transactions,
schema migrations, arbitrary selectors, or a universal API convention.

## Run the example

See the [package example](example/README.md) for the local HTTP contract,
environment configuration, generation, and Dart commands.

## Links

- [Run with HTTP/JSON](https://ezgrs.github.io/dorm/apply/use-http/)
- [http](https://pub.dev/packages/http)
- [dorm_framework](https://pub.dev/packages/dorm_framework)
- [GitHub repository](https://github.com/beet-software/dorm)
