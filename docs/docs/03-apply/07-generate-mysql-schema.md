# Generate MySQL table definitions

The MySQL package includes a command-line tool that reads annotated Dart source and prints `CREATE TABLE IF NOT EXISTS` statements. It is a schema-definition generator, not a general migration command.

## Use a compatible annotated source

The tool accepts one source-file path:

```shell
dart run dorm_mysql_database:generate lib/models.dart
```

The source file must contain `@Model` declarations. The current tool reads:

- the model table name from `@Model(name: ...)`;
- primary-key specifications from `@Model(primaryKey: ...)`;
- scalar `@Field` and `@ForeignField` declarations;
- Dart field types mapped by the tool to SQL types.

The type mapping implemented by the tool is:

| Dart type | Generated SQL type |
| --- | --- |
| `String` | `VARCHAR` |
| `int` | `INTEGER` |
| `bool` | `BOOLEAN` |
| `double` | `DOUBLE` |
| another type | `VARCHAR` in primary-key fallback paths; other field cases can fail during generation |

The tool reads the annotated source syntax directly. It does not consume the generated `.dorm.dart` file.

## Generate SQL for a simple model

For a model containing only supported scalar fields:

```dart
@Model(name: 'Users', as: #users)
abstract class _User {
  @Field(name: 'name')
  String get name;

  @Field(name: 'active')
  bool get active;

  @Field(name: 'age')
  int? get age;
}
```

Run the command from the application directory:

```shell
dart run dorm_mysql_database:generate lib/models.dart
```

The output is written to standard output. Save it to a file when the next database command needs a file:

```shell
dart run dorm_mysql_database:generate lib/models.dart > schema.sql
```

Apply the resulting SQL with the MySQL client or database administration tool used by your environment.

## Read the generated table shape

The generated statement contains:

- a primary-key column for each parsed primary-key specification;
- one column for each top-level `@Field` or `@ForeignField` getter recognized by the analyzer;
- `NOT NULL` for non-nullable recognized fields;
- a `PRIMARY KEY` clause containing the parsed primary-key columns.

The tool defaults to an `id CHAR(36)` primary key when it does not find a parsed primary-key specification.

## Treat the schema output separately from runtime generation

The normal dORM generator creates Dart model, entity, repository, and JSON-related output:

```shell
dart run build_runner build
```

The MySQL command instead parses the annotated source and prints SQL. Run both workflows when a project needs generated Dart APIs and a database schema.

## Preserve the tool's current scope

The tool does not read every dORM annotation. Embedded `@ModelField` values, polymorphic payloads, and complex value conversions are not represented by a general migration plan in the current implementation. Derived fields are emitted as scalar columns or JSON roots according to their declared path; the tool does not create indexes.

The command also does not compare an existing database with a new model, rename columns, drop columns, or record migration history. Its current output is a fresh `CREATE TABLE IF NOT EXISTS` statement derived from the declarations it recognizes.
