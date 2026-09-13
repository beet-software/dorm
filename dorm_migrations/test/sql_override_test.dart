import 'package:dorm_migrations/dorm_migrations.dart';
import 'package:test/test.dart';

void main() {
  test('uses the physical type override for the selected dialect', () async {
    final _Backend backend = _Backend();
    final SqlMigrationAdapter adapter = SqlMigrationAdapter(
      backend,
      dialect: SqlMigrationDialect.mysql,
    );

    await adapter.apply(
      const AddFieldOperation(
        entityName: 'users',
        field: SqlMigrationFieldDefinition(
          fieldName: 'name',
          columnName: 'name',
          type: MigrationValueType.text,
          typeOverrides: {SqlMigrationDialect.mysql: 'VARCHAR(255)'},
        ),
      ),
    );

    expect(backend.statements.single, contains('VARCHAR(255)'));
  });

  test('executes a provider-specific PostgreSQL operation', () async {
    final _Backend backend = _Backend();
    final SqlMigrationAdapter adapter = SqlMigrationAdapter(
      backend,
      dialect: SqlMigrationDialect.postgresql,
    );

    await adapter.apply(
      ProviderMigrationOperation(
        provider: 'postgresql',
        name: 'enable_extension',
        statement: 'CREATE EXTENSION IF NOT EXISTS pgcrypto',
      ),
    );

    expect(backend.statements.single, contains('CREATE EXTENSION'));
  });

  test('rejects a provider-specific operation for another dialect', () async {
    final SqlMigrationAdapter adapter = SqlMigrationAdapter(
      _Backend(),
      dialect: SqlMigrationDialect.mysql,
    );

    expect(
      () => adapter.apply(
        ProviderMigrationOperation(
          provider: 'postgresql',
          name: 'enable_extension',
          statement: 'CREATE EXTENSION IF NOT EXISTS pgcrypto',
        ),
      ),
      throwsA(isA<MigrationUnsupportedException>()),
    );
  });

  test('creates a PostgreSQL sequence explicitly', () async {
    final _Backend backend = _Backend();
    final SqlMigrationAdapter adapter = SqlMigrationAdapter(
      backend,
      dialect: SqlMigrationDialect.postgresql,
    );

    await adapter.apply(
      CreateSequenceOperation(
        sequence: const MigrationSequenceDefinition(
          name: 'users_id_seq',
          startWith: 10,
          incrementBy: 5,
        ),
      ),
    );

    expect(
      backend.statements.single,
      contains('CREATE SEQUENCE IF NOT EXISTS'),
    );
    expect(backend.statements.single, contains('START WITH 10'));
    expect(backend.statements.single, contains('INCREMENT BY 5'));
  });

  test('rejects sequences on MySQL', () async {
    final SqlMigrationAdapter adapter = SqlMigrationAdapter(
      _Backend(),
      dialect: SqlMigrationDialect.mysql,
    );

    expect(
      () => adapter.apply(
        CreateSequenceOperation(
          sequence: const MigrationSequenceDefinition(name: 'users_id_seq'),
        ),
      ),
      throwsA(isA<MigrationUnsupportedException>()),
    );
  });

  test('creates a PostgreSQL trigger explicitly', () async {
    final _Backend backend = _Backend();
    final SqlMigrationAdapter adapter = SqlMigrationAdapter(
      backend,
      dialect: SqlMigrationDialect.postgresql,
    );

    await adapter.apply(
      CreateTriggerOperation(
        trigger: const MigrationTriggerDefinition(
          entityName: 'users',
          name: 'users_updated_at_trigger',
          createStatement:
              'CREATE TRIGGER users_updated_at_trigger '
              'BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION '
              'set_updated_at()',
        ),
      ),
    );

    expect(backend.statements.single, contains('CREATE TRIGGER'));
    expect(backend.statements.single, contains('set_updated_at()'));
  });

  test('creates a SQLite trigger explicitly', () async {
    final _Backend backend = _Backend();
    final SqlMigrationAdapter adapter = SqlMigrationAdapter(
      backend,
      dialect: SqlMigrationDialect.sqlite,
    );

    await adapter.apply(
      CreateTriggerOperation(
        trigger: const MigrationTriggerDefinition(
          entityName: 'users',
          name: 'users_insert_trigger',
          createStatement:
              'CREATE TRIGGER users_insert_trigger '
              'AFTER INSERT ON users BEGIN SELECT 1; END',
        ),
      ),
    );

    expect(backend.statements.single, contains('CREATE TRIGGER'));
  });

  test('creates a PostgreSQL view explicitly', () async {
    final _Backend backend = _Backend();
    final SqlMigrationAdapter adapter = SqlMigrationAdapter(
      backend,
      dialect: SqlMigrationDialect.postgresql,
    );

    await adapter.apply(
      CreateViewOperation(
        view: const MigrationViewDefinition(
          name: 'active_users',
          query: 'SELECT * FROM users WHERE active = TRUE',
        ),
      ),
    );

    expect(backend.statements.single, contains('CREATE VIEW'));
    expect(backend.statements.single, contains('active_users'));
    expect(backend.statements.single, contains('SELECT * FROM users'));
  });

  test('creates a SQLite view explicitly', () async {
    final _Backend backend = _Backend();
    final SqlMigrationAdapter adapter = SqlMigrationAdapter(
      backend,
      dialect: SqlMigrationDialect.sqlite,
    );

    await adapter.apply(
      CreateViewOperation(
        view: const MigrationViewDefinition(
          name: 'active_users',
          query: 'SELECT * FROM users WHERE active = 1',
        ),
      ),
    );

    expect(backend.statements.single, contains('CREATE VIEW IF NOT EXISTS'));
  });

  test('creates a unique index explicitly', () async {
    final _Backend backend = _Backend();
    final SqlMigrationAdapter adapter = SqlMigrationAdapter(
      backend,
      dialect: SqlMigrationDialect.mysql,
    );

    await adapter.apply(
      CreateIndexOperation(
        index: const MigrationIndexDefinition(
          entityName: 'users',
          name: 'users_email_unique',
          fields: ['email'],
          unique: true,
        ),
      ),
    );

    expect(backend.statements.single, contains('CREATE UNIQUE INDEX'));
    expect(backend.statements.single, contains('users_email_unique'));
  });

  test('creates a PostgreSQL unique constraint explicitly', () async {
    final _Backend backend = _Backend();
    final SqlMigrationAdapter adapter = SqlMigrationAdapter(
      backend,
      dialect: SqlMigrationDialect.postgresql,
    );

    await adapter.apply(
      CreateUniqueConstraintOperation(
        constraint: const MigrationUniqueConstraintDefinition(
          entityName: 'users',
          name: 'users_email_key',
          fields: ['email'],
        ),
      ),
    );

    expect(backend.statements.single, contains('ADD CONSTRAINT'));
    expect(backend.statements.single, contains('UNIQUE'));
  });

  test('creates a PostgreSQL check constraint explicitly', () async {
    final _Backend backend = _Backend();
    final SqlMigrationAdapter adapter = SqlMigrationAdapter(
      backend,
      dialect: SqlMigrationDialect.postgresql,
    );

    await adapter.apply(
      CreateCheckConstraintOperation(
        constraint: MigrationCheckConstraintDefinition(
          entityName: 'users',
          name: 'users_age_check',
          expression: 'age >= 0',
        ),
      ),
    );

    expect(backend.statements.single, contains('ADD CONSTRAINT'));
    expect(backend.statements.single, contains('CHECK (age >= 0)'));
  });

  test('rejects check constraints on SQLite', () async {
    final SqlMigrationAdapter adapter = SqlMigrationAdapter(
      _Backend(),
      dialect: SqlMigrationDialect.sqlite,
    );

    expect(
      () => adapter.apply(
        CreateCheckConstraintOperation(
          constraint: MigrationCheckConstraintDefinition(
            entityName: 'users',
            name: 'users_age_check',
            expression: 'age >= 0',
          ),
        ),
      ),
      throwsA(isA<MigrationUnsupportedException>()),
    );
  });

  test('rejects unique constraints on SQLite', () async {
    final SqlMigrationAdapter adapter = SqlMigrationAdapter(
      _Backend(),
      dialect: SqlMigrationDialect.sqlite,
    );

    expect(
      () => adapter.apply(
        CreateUniqueConstraintOperation(
          constraint: const MigrationUniqueConstraintDefinition(
            entityName: 'users',
            name: 'users_email_key',
            fields: ['email'],
          ),
        ),
      ),
      throwsA(isA<MigrationUnsupportedException>()),
    );
  });
  test('creates a PostgreSQL foreign key explicitly', () async {
    final _Backend backend = _Backend();
    final SqlMigrationAdapter adapter = SqlMigrationAdapter(
      backend,
      dialect: SqlMigrationDialect.postgresql,
    );

    await adapter.apply(
      CreateForeignKeyOperation(
        foreignKey: const MigrationForeignKeyDefinition(
          entityName: 'orders',
          name: 'orders_user_id_fkey',
          fields: ['user_id'],
          referencedEntity: 'users',
          referencedFields: ['id'],
          onDelete: MigrationReferentialAction.cascade,
          onUpdate: MigrationReferentialAction.restrict,
        ),
      ),
    );

    expect(backend.statements.single, contains('ADD CONSTRAINT'));
    expect(backend.statements.single, contains('REFERENCES'));
    expect(backend.statements.single, contains('ON DELETE CASCADE'));
    expect(backend.statements.single, contains('ON UPDATE RESTRICT'));
  });

  test('rejects foreign keys on SQLite', () async {
    final SqlMigrationAdapter adapter = SqlMigrationAdapter(
      _Backend(),
      dialect: SqlMigrationDialect.sqlite,
    );

    expect(
      () => adapter.apply(
        CreateForeignKeyOperation(
          foreignKey: const MigrationForeignKeyDefinition(
            entityName: 'orders',
            name: 'orders_user_id_fkey',
            fields: ['user_id'],
            referencedEntity: 'users',
            referencedFields: ['id'],
          ),
        ),
      ),
      throwsA(isA<MigrationUnsupportedException>()),
    );
  });

  test('alters PostgreSQL type, nullability, and default', () async {
    final _Backend backend = _Backend();
    final SqlMigrationAdapter adapter = SqlMigrationAdapter(
      backend,
      dialect: SqlMigrationDialect.postgresql,
    );

    await adapter.apply(
      const AlterFieldOperation(
        entityName: 'users',
        field: MigrationFieldDefinition(
          fieldName: 'active',
          columnName: 'active',
          type: MigrationValueType.boolean,
          nullable: false,
          hasDefault: true,
          defaultValue: false,
        ),
      ),
    );

    expect(backend.statements, hasLength(3));
    expect(backend.statements[0], contains('TYPE BOOLEAN'));
    expect(backend.statements[1], contains('SET NOT NULL'));
    expect(backend.statements[2], contains('SET DEFAULT FALSE'));
  });

  test('previews SQL without calling the provider', () async {
    final _Backend backend = _Backend();
    final SqlMigrationAdapter adapter = SqlMigrationAdapter(
      backend,
      dialect: SqlMigrationDialect.postgresql,
    );

    final SqlMigrationScript script = await adapter.preview([
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

    expect(backend.statements, isEmpty);
    expect(script.statements, hasLength(2));
    expect(script.statements.first.migrationVersion, 1);
    expect(script.statements.first.operationIndex, 0);
    expect(script.sql, contains('ALTER TABLE'));
    expect(script.sql, contains('UPDATE'));
    expect(script.statements.last.parameters, {'p0': true});
  });
}

final class _Backend implements SqlMigrationBackend {
  final List<String> statements = [];

  @override
  Future<List<Map<String, Object?>>> query(
    String sql, [
    Object? parameters = const [],
  ]) async => const [];

  @override
  Future<void> execute(String sql, [Object? parameters = const []]) async {
    statements.add(sql);
  }

  @override
  Future<T> lock<T>(Future<T> Function() action) => action();
}
