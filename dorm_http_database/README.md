# dorm_http_database

`dorm_http_database` maps dORM repositories to a configured REST-shaped
HTTP/JSON API. It accepts an application-owned `package:http` client, a base
URI, and one `HttpResourceMapping` per entity.

The engine uses generated entity serialization, configurable query parameters,
direct JSON objects/lists or `data` envelopes, readable-operation relationship
fallbacks, and initial-read-only streams. Batch operations require explicit
batch endpoints. Non-success HTTP responses are represented by
`HttpDatabaseException`.

For a backend-generated identity, declare `DatabaseGeneratedIdSpec` on the
model and configure `HttpIdentityLocation.none`. The creation endpoint must
return a scalar identity or a complete JSON representation. Customize that
interpretation with `HttpCreationCodec` when the API uses another response
shape.

See [`example/`](example/) for a pure Dart generated-model example and the
public documentation for the complete endpoint configuration.
