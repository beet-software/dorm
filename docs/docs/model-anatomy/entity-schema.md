# Generated EntitySchema

`EntitySchema` is the engine-neutral description of one stored entity. The
generated entity exposes it through `UserEntity.schema`.

The schema contains information such as:

- the table, collection, or resource name;
- ordered `primaryKeys` metadata;
- ordinary field metadata;
- foreign-field and relationship metadata;
- generated derived-field metadata.

The primary-key list contains one field for a simple identity and multiple
ordered fields for a composite identity. The corresponding codec converts
between the framework identity object and backend key values.

The selected engine maps this metadata to its own representation. For example,
SQL engines use it for columns, Firebase uses it for map paths, MongoDB uses
it for document fields, HTTP uses it with the resource mapping, and the
In-memory engine uses it to organize entity tables.

`EntitySchema` does not open a connection, create a table, or execute a query.
It supplies metadata to references, queries, serializers, and relationship
implementations.

The schema fields originate in [Annotations](../annotations/index.md). The
public framework contract is listed in [Framework contracts](../reference/framework-contracts.md).
