# Generated Entity

The generated `UserEntity` is the mapping object between one generated model
and the engine-independent framework contracts.

Its main members have these roles:

| Member | Role |
| --- | --- |
| `schema` | Exposes the generated `EntitySchema`. |
| `primaryKeyCodec` | Encodes and decodes simple or composite identities. |
| `identify` | Reads the final identity from a generated model. |
| `fromData` | Combines resolved creation data, dependencies, and identity into a model. |
| `fromJson` | Creates a model from an identity and stored field map. |
| `toJson` | Serializes data or model fields for the engine. |
| `convert` | Applies new data to an existing model while retaining its identity. |

The create path uses `fromData`:

```text
Data + Dependency + identity request
    -> ResolvedCreation
    -> Entity.fromData
    -> identified Model
```

The read path uses `fromJson`:

```text
backend map or row + identity
    -> Entity.fromJson
    -> generated Model
```

The entity knows the generated schema and conversion rules. It does not own a
database connection. The engine supplies the backend reference that invokes
these mapping operations.

See [Framework contracts](../reference/framework-contracts.md) for the public
conversion signatures and [Generated API](../reference/generated-api.md) for
the generated entity surface.
