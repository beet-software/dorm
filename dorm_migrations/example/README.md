# dorm_migrations example

This example shows the portable operation model with the in-memory adapter.
Production applications should use the adapter for their selected database. See the [migration guide](https://ezgrs.github.io/dorm/operations/using-migrations/) for the project entrypoint, safety checks, retries, and backend limits.

```dart
import 'package:dorm_migrations/dorm_migrations.dart';

Future<void> main() async {
  final adapter = MemoryMigrationAdapter();
  final result = await MigrationRunner(adapter).run([
    const Migration(
      version: 1,
      name: 'add-active',
      operations: [
        AddFieldOperation(
          entityName: 'users',
          field: MigrationFieldDefinition(
            fieldName: 'active',
            columnName: 'active',
            type: MigrationValueType.boolean,
          ),
        ),
        BackfillFieldOperation(
          entityName: 'users',
          field: 'active',
          value: true,
        ),
      ],
    ),
  ]);
  print(result.applied.length);
}
```
