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

The create path combines `Data`, `Dependency`, and the identity strategy into a
`ResolvedCreation`. `Entity.fromData` uses that resolved value to produce the
identified `Model` returned to the application.

The read path gives `Entity.fromJson` the backend map or row together with its
identity. The entity then creates the generated `Model` that the repository
returns.

The entity knows the generated schema and conversion rules. It does not own a
database connection. The engine supplies the backend reference that invokes
these mapping operations.

See [Framework contracts](../reference/framework-contracts.md) for the public
conversion signatures and [Generated output contract](../reference/generated-contract.md) for
the generated entity surface.
