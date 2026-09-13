import 'package:dorm_migrations/dorm_migrations.dart';

Future<void> main() async {
  final MemoryMigrationAdapter adapter = MemoryMigrationAdapter();
  final MigrationRunResult result = await MigrationRunner(adapter).run([
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
  print('Applied ${result.applied.length} migration.');
}
