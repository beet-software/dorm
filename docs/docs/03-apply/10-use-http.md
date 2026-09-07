# Run the store with HTTP/JSON

This page configures `dorm_http_database` for a REST-shaped JSON API. The
engine translates dORM repository operations into HTTP requests; it does not
discover routes or infer an API contract from a URL.

## Add the packages

From the Dart application directory, execute:

```shell
dart pub add dorm_framework
dart pub add dorm_annotations
dart pub add dorm_http_database
dart pub add http
dart pub add dev:dorm_generator
dart pub add dev:build_runner
dart pub add dev:json_serializable
```

The application owns the `http.Client`. This lets the application select the
client implementation and apply authentication, retry, or other transport
wrappers before passing it to dORM.

## Configure a resource

Use one `HttpResourceMapping` for each generated entity. The resource path is
relative to the base URI and the default item path appends `/{id}`:

```dart
final http.Client client = http.Client();
final Engine engine = Engine(
  client: client,
  baseUri: Uri.parse('https://api.example.test/v1/'),
  mapping: HttpMapping.byTableName({
    'users': HttpResourceMapping(
      path: 'users',
      createAll: const HttpEndpoint('POST', 'users/batch'),
      updateAll: const HttpEndpoint('PUT', 'users/batch'),
      deleteKeys: const HttpEndpoint('POST', 'users/delete'),
    ),
  }),
);
final Dorm<Query, OffsetPageRequest> dorm = Dorm(engine);
```

The default endpoints are:

| Operation | Method | Path |
| --- | --- | --- |
| collection reads | `GET` | `users` |
| single read | `GET` | `users/{id}` |
| create | `POST` | `users` |
| identified write | `PUT` | `users/{id}` |
| single delete | `DELETE` | `users/{id}` |
| filtered delete | `DELETE` | `users` |
| key read | `GET` | `users` |
| purge | `DELETE` | `users` |

Configure `createAll`, `updateAll`, and `deleteKeys` when the application uses
`putAll`, `pushAll`, or `popKeys`. Those operations fail with
`UnsupportedError` when the corresponding endpoint is absent.

## Use JSON responses

Single reads accept a JSON object. Collection reads accept a JSON list. Key
reads accept a list of identity values or objects containing the schema's
primary-key fields.

For an API that wraps responses in `data`, configure the response codec:

```dart
final HttpMapping mapping = HttpMapping.byTableName(
  {
    'users': HttpResourceMapping(path: 'users'),
  },
  jsonCodec: HttpJsonCodec.envelope(),
);
```

The default query codec maps filters and read windows to parameters such as
`name__startsWith`, `created_at__gte`, `created_at__lte`, `sort`,
`limit`, and `offset`.
Replace it with an `HttpQueryCodec` when the API uses different parameter
names or formats.

The engine uses generated `Entity.toJson` and `Entity.fromJson` methods. The
identity is written to the body by default and is also available in the item
path. Change this with `HttpIdentityLocation.path` when the API keeps identity
only in the route, or provide a custom identity encoder for composite routes.

## Use repositories and relationships

After creating the engine, repository and relationship calls use the common
dORM API:

```dart
final User user = await dorm.users.repository.put(
  Creation.auto(
    dependency: const UserDependency(),
    data: const UserData(name: 'Ada'),
  ),
);

final List<User> users = await dorm.users.repository.peekAll(
  const Filter.text('Ad', key: 'name'),
);

final List<Join<User, Post>> posts = await dorm.relations.users.posts
    .peekAll();
```

HTTP relationships resolve through readable sources. A relationship can
therefore issue one request for the source and additional requests for related
models. The returned `Join` types remain the same as with other engines.

## Handle the client lifecycle

The engine does not close the client. Close it after all repositories and
relationship reads have finished:

```dart
try {
  // Use the generated Dorm instance.
} finally {
  client.close();
}
```

`pull` and `pullAll` perform one HTTP read and then complete. They do not poll
the API or subscribe to server events. `patch` performs a read, invokes the
callback, and then writes or deletes the resulting model; HTTP does not make
that sequence atomic.

The engine raises `HttpDatabaseException` for non-success HTTP responses. The
exception includes the status code, method, URI, and response body. Transport
errors from `http.Client` are propagated unchanged.
