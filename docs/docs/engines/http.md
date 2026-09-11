# Run the store with HTTP/JSON

This page configures `dorm_http_database` for a REST-shaped JSON API. The
engine translates dORM repository operations into HTTP requests; it does not
discover routes or infer an API contract from a URL.

## Add the engine package

From the Dart application directory, execute:

```shell
dart pub add dorm_http_database
```

Add the HTTP package because the application creates and owns the client:

```shell
dart pub add http
```

The application owns the `http.Client`. This lets the application select the
client implementation and apply authentication, retry, or other transport
wrappers before passing it to dORM.

### Run the generated local server

The `dorm_example -e http` profile includes a small Dart server under
`server/`. Start it with the generated Compose file, then run Flutter on the
host:

```shell
docker compose up -d
flutter pub get
dart run build_runner build
flutter run -d chrome --dart-define=HTTP_BASE_URI=http://localhost:8080/api/
```

The server stores data in memory and loses it when its container restarts. It
implements the resource paths and basic query parameters used by that
generated mapping. It is a local demonstration backend, not a convention for
an arbitrary remote API.

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
| `purge` | `DELETE` | `users` |

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

For a resource whose backend assigns the identity, declare
`DatabaseGeneratedIdSpec` on the model and use `HttpIdentityLocation.none`.
The create request then omits the identity from both the route and the JSON
body. The response must contain either the scalar identity or the complete
created object:

```dart
final HttpResourceMapping users = HttpResourceMapping(
  path: 'users',
  identityLocation: HttpIdentityLocation.none,
);

final HttpMapping mapping = HttpMapping.byTableName({'users': users});
```

The default `HttpCreationCodec` treats a JSON object as complete model data
and a scalar JSON value as the identity. Use `HttpCreationCodec.single` to
decode an API-specific response such as `{ "id": 42 }`. `putAll` requires a
configured batch endpoint and one resolvable response item for each request
item, in the same order.

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
  Filter.text('Ad', field: UserEntity.fields.name),
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

## Configure authentication and transport boundaries

The application owns the `http.Client`, base URI, and default headers. Use
those boundaries for authentication headers, transport configuration, and any
client wrapper required by the API. The dORM engine does not define an
authentication, retry, cache, or secrets-store abstraction.

Keep credentials and tokens in application deployment configuration. The
configured client and mapping determine which headers and endpoint values are
sent with repository operations.

## Observe performance characteristics

Each mapped repository operation produces the HTTP request configured for that
operation. `putAll`, `pushAll`, and `popKeys` require their own configured
batch endpoints; the engine does not simulate a batch by presenting multiple
independent requests as one atomic operation.

Relationship paths use readable sources. A relationship can therefore issue a
request for the source and additional requests for related models. `pull` and
`pullAll` perform one read and complete; the engine does not poll or maintain a
server-event subscription. Caching, retries, and connection behavior belong to
the supplied `http.Client` and application mapping.
