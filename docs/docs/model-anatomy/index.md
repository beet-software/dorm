# Model anatomy

An annotated source model produces several generated components. Each one has
a separate role in the path from application input to backend storage.

Use these pages after [Annotations](../annotations/index.md) when you need to
understand the generated pieces, or use the [Generated API reference](../reference/generated-api.md)
when you already know which type or member you need.

## Follow the generated pieces

1. [Data](data.md) contains creation and update values.
2. [Model](model.md) represents an identified persisted value.
3. [Dependency](dependency.md) carries related identities during creation.
4. [Fields](fields.md) exposes generated field metadata for filters and paths.
5. [EntitySchema](entity-schema.md) describes the engine-neutral stored shape.
6. [Entity](entity.md) maps generated values to framework contracts.
7. [Repository](repository.md) exposes operations for one entity.
8. [Dorm](dorm.md) groups generated entities and engine access.
9. [Relationship paths](relations.md) resolve related models through generated metadata.

## How the pieces work together

The annotated source is where the application declares its model shape. The
generator turns that source into `Data`, `Model`, `Dependency`, field metadata,
`Entity`, `Repository`, and `Dorm` types. The generated repository then uses
the selected engine to perform the operation against its backend or in-memory
store.

The application normally edits the annotated source and uses the generated
types. Generated files are outputs of the builder and should be regenerated
after source declarations change.
