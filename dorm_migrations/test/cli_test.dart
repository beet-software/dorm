import 'package:dorm_migrations/dorm_migrations.dart';
import 'package:test/test.dart';

void main() {
  const Migration migration = Migration(
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
    ],
  );

  test(
    'applies pending migrations, skips them on retry, and closes runtime',
    () async {
      final MemoryMigrationAdapter adapter = MemoryMigrationAdapter();
      int opened = 0;
      int closed = 0;

      Future<int> run() {
        return runMigrationCommand(
          const ['apply'],
          open: () {
            opened++;
            return MigrationRuntime(
              adapter: adapter,
              close: () async {
                closed++;
              },
            );
          },
          migrations: [migration],
        );
      }

      expect(await run(), 0);
      expect(await run(), 0);
      expect(opened, 2);
      expect(closed, 2);
      expect(adapter.operations, hasLength(1));
      expect(adapter.recordedMigrations, [migration]);
    },
  );

  test('rejects destructive operations unless explicitly allowed', () async {
    const Migration destructive = Migration(
      version: 1,
      name: 'remove-users',
      operations: [DropEntityOperation(entityName: 'users')],
    );
    final MemoryMigrationAdapter adapter = MemoryMigrationAdapter();
    bool closed = false;

    Future<int> run(List<String> arguments) {
      return runMigrationCommand(
        arguments,
        open: () => MigrationRuntime(
          adapter: adapter,
          close: () async {
            closed = true;
          },
        ),
        migrations: [destructive],
      );
    }

    expect(await run(const ['apply']), 1);
    expect(adapter.operations, isEmpty);
    expect(closed, isTrue);

    closed = false;
    expect(await run(const ['apply', '--allow-destructive']), 0);
    expect(adapter.operations, hasLength(1));
    expect(closed, isTrue);
  });

  test('returns usage errors without opening the runtime', () async {
    bool opened = false;

    Future<int> run(List<String> arguments) {
      return runMigrationCommand(
        arguments,
        open: () {
          opened = true;
          return MigrationRuntime(adapter: MemoryMigrationAdapter());
        },
        migrations: const [],
      );
    }

    expect(await run(const []), 64);
    expect(await run(const ['unknown']), 64);
    expect(await run(const ['--help']), 0);
    expect(opened, isFalse);
  });

  test('returns failure and closes resources when applying fails', () async {
    final MemoryMigrationAdapter adapter = MemoryMigrationAdapter(
      onApply: (_) => Future<void>.error(StateError('backend failed')),
    );
    bool closed = false;

    final int result = await runMigrationCommand(
      const ['apply'],
      open: () => MigrationRuntime(
        adapter: adapter,
        close: () async {
          closed = true;
        },
      ),
      migrations: [migration],
    );

    expect(result, 1);
    expect(closed, isTrue);
    expect(adapter.recordedMigrations, isEmpty);
  });

  test('returns failure when closing resources fails', () async {
    final int result = await runMigrationCommand(
      const ['apply'],
      open: () => MigrationRuntime(
        adapter: MemoryMigrationAdapter(),
        close: () => Future<void>.error(StateError('close failed')),
      ),
      migrations: [migration],
    );

    expect(result, 1);
  });

  test('supports status, validate, baseline, and resolve', () async {
    final MemoryMigrationAdapter adapter = MemoryMigrationAdapter();
    const Migration second = Migration(
      version: 2,
      name: 'second',
      operations: [],
    );
    bool opened = false;

    Future<int> run(List<String> arguments) => runMigrationCommand(
      arguments,
      open: () {
        opened = true;
        return MigrationRuntime(
          adapter: adapter,
          validateSchema: () async => const MigrationSchemaValidationResult([]),
        );
      },
      migrations: [migration, second],
    );

    expect(await run(const ['baseline', '--through', '1']), 64);
    expect(opened, isFalse);
    expect(await run(const ['baseline', '--through', '1', '--confirm']), 0);
    expect(adapter.operations, isEmpty);
    expect(await run(const ['status']), 0);
    expect(await run(const ['validate']), 0);
    expect(await run(const ['resolve', '--version', '2', '--confirm']), 0);
    expect(await run(const ['status']), 0);
  });
  test('forwards observability callbacks from the runtime', () async {
    final List<MigrationProgress> progress = [];
    final List<MigrationLogEntry> logs = [];
    final List<MigrationMetric> metrics = [];

    final int result = await runMigrationCommand(
      const ['apply'],
      open: () => MigrationRuntime(
        adapter: MemoryMigrationAdapter(),
        onProgress: progress.add,
        onLog: logs.add,
        onMetric: metrics.add,
      ),
      migrations: [migration],
    );

    expect(result, 0);
    expect(progress.last.stage, MigrationProgressStage.completed);
    expect(logs.map((entry) => entry.event), contains('completed'));
    expect(metrics.map((metric) => metric.name), contains('run'));
  });
}
