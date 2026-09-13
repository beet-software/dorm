import 'package:dorm_migrations/dorm_migrations.dart';
import 'package:test/test.dart';

void main() {
  group('MigrationRunner', () {
    test(
      'applies migrations in version order and skips recorded versions',
      () async {
        final MemoryMigrationAdapter adapter = MemoryMigrationAdapter();
        final MigrationRunner runner = MigrationRunner(
          adapter,
          destructivePolicy: MigrationDestructivePolicy.allow,
        );
        final Migration first = const Migration(
          version: 1,
          name: 'first',
          operations: [DropEntityOperation(entityName: 'users')],
        );
        final Migration second = const Migration(
          version: 2,
          name: 'second',
          operations: [DropEntityOperation(entityName: 'posts')],
        );

        final MigrationRunResult initial = await runner.run([second, first]);
        final MigrationRunResult retry = await runner.run([first, second]);

        expect(initial.applied, [first, second]);
        expect(retry.applied, isEmpty);
        expect(retry.skipped, [first, second]);
        expect(adapter.operations, hasLength(2));
      },
    );

    test('rejects duplicate versions', () async {
      final Migration migration = const Migration(
        version: 1,
        name: 'same',
        operations: [],
      );
      expect(
        () => MigrationRunner(
          MemoryMigrationAdapter(),
        ).run([migration, migration]),
        throwsA(isA<MigrationValidationException>()),
      );
    });
  });

  test('reports status and supports explicit baseline and resolve', () async {
    final MemoryMigrationAdapter adapter = MemoryMigrationAdapter();
    final Migration first = const Migration(
      version: 1,
      name: 'first',
      operations: [
        AddFieldOperation(
          entityName: 'users',
          field: MigrationFieldDefinition(
            fieldName: 'name',
            columnName: 'name',
            type: MigrationValueType.text,
          ),
        ),
      ],
    );
    final Migration second = const Migration(
      version: 2,
      name: 'second',
      operations: [],
    );
    final MigrationRunner runner = MigrationRunner(adapter);

    final MigrationRunResult baseline = await runner.baseline([
      second,
      first,
    ], through: 1);
    expect(baseline.applied, [first]);
    expect(adapter.operations, isEmpty);

    final MigrationStatusReport beforeResolve = await runner.status([
      first,
      second,
    ]);
    expect(beforeResolve.applied, [first]);
    expect(beforeResolve.pending, [second]);
    expect(beforeResolve.isValid, isTrue);

    final MigrationRunResult resolved = await runner.resolve([
      first,
      second,
    ], version: 2);
    expect(resolved.applied, [second]);
    expect((await runner.validate([first, second])).isValid, isTrue);
  });

  test('does not overwrite a different checksum during resolve', () async {
    final MemoryMigrationAdapter adapter = MemoryMigrationAdapter();
    const Migration original = Migration(
      version: 1,
      name: 'original',
      operations: [],
    );
    const Migration changed = Migration(
      version: 1,
      name: 'changed',
      operations: [],
    );

    await MigrationRunner(adapter).run([original]);

    expect(
      () => MigrationRunner(adapter).resolve([changed], version: 1),
      throwsA(isA<MigrationValidationException>()),
    );
  });
  test('resumes paginated document entity removal after a failure', () async {
    final _PagedDocumentsBackend backend = _PagedDocumentsBackend({
      'users': [
        const MigrationDocument(key: '1', data: {'name': 'Ada'}),
        const MigrationDocument(key: '2', data: {'name': 'Grace'}),
        const MigrationDocument(key: '3', data: {'name': 'Linus'}),
        const MigrationDocument(key: '4', data: {'name': 'Katherine'}),
      ],
    })..failDeleteKey = '3';
    final Migration migration = const Migration(
      version: 1,
      name: 'drop-users',
      operations: [DropEntityOperation(entityName: 'users')],
    );
    final MigrationRunner runner = MigrationRunner(
      DocumentMigrationAdapter(backend, pageSize: 2),
      destructivePolicy: MigrationDestructivePolicy.allow,
    );

    await expectLater(runner.run([migration]), throwsA(isA<StateError>()));
    expect(backend.documents('users').map((document) => document.key), [
      '3',
      '4',
    ]);

    await runner.run([migration]);
    expect(backend.documents('users'), isEmpty);
  });
  test('runs the project operation validator before applying', () async {
    final MemoryMigrationAdapter adapter = MemoryMigrationAdapter();
    final List<int> indexes = [];
    const Migration migration = Migration(
      version: 1,
      name: 'checked',
      operations: [
        AlterFieldOperation(
          entityName: 'users',
          field: MigrationFieldDefinition(
            fieldName: 'active',
            columnName: 'active',
            type: MigrationValueType.boolean,
          ),
        ),
      ],
    );

    await expectLater(
      MigrationRunner(
        adapter,
        operationValidator: (migration, index, operation) async {
          indexes.add(index);
          expect(operation, isA<AlterFieldOperation>());
          throw StateError('data validation failed');
        },
      ).run([migration]),
      throwsA(isA<StateError>()),
    );
    expect(indexes, [0]);
    expect(adapter.operations, isEmpty);
    expect(adapter.recordedMigrations, isEmpty);
  });
  test('rejects destructive operations without explicit opt-in', () async {
    final Migration migration = const Migration(
      version: 1,
      name: 'remove-users',
      operations: [DropEntityOperation(entityName: 'users')],
    );

    expect(
      () => MigrationRunner(MemoryMigrationAdapter()).run([migration]),
      throwsA(
        isA<MigrationDestructiveOperationException>().having(
          (error) => error.operationIndex,
          'operationIndex',
          0,
        ),
      ),
    );
  });

  test('allows destructive operations with explicit opt-in', () async {
    final Migration migration = const Migration(
      version: 1,
      name: 'remove-users',
      operations: [DropEntityOperation(entityName: 'users')],
    );

    final MigrationRunResult result = await MigrationRunner(
      MemoryMigrationAdapter(),
      destructivePolicy: MigrationDestructivePolicy.allow,
    ).run([migration]);

    expect(result.applied, [migration]);
  });
  test('records and validates migration checksums', () async {
    final MemoryMigrationAdapter adapter = MemoryMigrationAdapter();
    final Migration migration = const Migration(
      version: 1,
      name: 'first',
      operations: [DropEntityOperation(entityName: 'users')],
    );
    final MigrationRunner runner = MigrationRunner(
      adapter,
      destructivePolicy: MigrationDestructivePolicy.allow,
    );

    await runner.run([migration]);
    final List<MigrationHistoryEntry> history = await adapter
        .appliedMigrations();
    expect(history.single.checksum, MigrationChecksum.of(migration));

    final Migration changed = const Migration(
      version: 1,
      name: 'first',
      operations: [DropEntityOperation(entityName: 'posts')],
    );
    expect(
      () => runner.run([changed]),
      throwsA(
        isA<MigrationValidationException>().having(
          (error) => error.message,
          'message',
          contains('different checksum'),
        ),
      ),
    );
  });
  test('rejects legacy history without a checksum', () async {
    final Migration migration = const Migration(
      version: 1,
      name: 'first',
      operations: [],
    );

    expect(
      () => MigrationRunner(_LegacyHistoryAdapter()).run([migration]),
      throwsA(
        isA<MigrationValidationException>().having(
          (error) => error.message,
          'message',
          contains('legacy history'),
        ),
      ),
    );
  });
  test('document adapter rejects persistent indexes and constraints', () async {
    final DocumentMigrationAdapter adapter = DocumentMigrationAdapter(
      _DocumentsBackend({}),
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
    expect(
      () => adapter.apply(
        ProviderMigrationOperation(
          provider: 'postgresql',
          name: 'custom',
          statement: 'CREATE EXTENSION pgcrypto',
        ),
      ),
      throwsA(isA<MigrationUnsupportedException>()),
    );
    expect(
      () => adapter.apply(
        CreateSequenceOperation(
          sequence: const MigrationSequenceDefinition(name: 'ids'),
        ),
      ),
      throwsA(isA<MigrationUnsupportedException>()),
    );
    expect(
      () => adapter.apply(
        CreateTriggerOperation(
          trigger: const MigrationTriggerDefinition(
            entityName: 'users',
            name: 'users_trigger',
            createStatement: 'CREATE TRIGGER users_trigger',
          ),
        ),
      ),
      throwsA(isA<MigrationUnsupportedException>()),
    );
    expect(
      () => adapter.apply(
        CreateViewOperation(
          view: const MigrationViewDefinition(
            name: 'users_view',
            query: 'SELECT * FROM users',
          ),
        ),
      ),
      throwsA(isA<MigrationUnsupportedException>()),
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
  test('document adapter backfills and removes fields', () async {
    final _DocumentsBackend backend = _DocumentsBackend({
      'users': [
        const MigrationDocument(key: '1', data: {'name': 'Ada'}),
        const MigrationDocument(
          key: '2',
          data: {'name': 'Grace', 'active': false},
        ),
        const MigrationDocument(
          key: '3',
          data: {'name': 'Linus', 'active': null},
        ),
      ],
    });
    final MigrationRunner runner = MigrationRunner(
      DocumentMigrationAdapter(backend),
      destructivePolicy: MigrationDestructivePolicy.allow,
    );

    await runner.run([
      const Migration(
        version: 1,
        name: 'active',
        operations: [
          BackfillFieldOperation(
            entityName: 'users',
            field: 'active',
            value: true,
          ),
          RemoveFieldValueOperation(entityName: 'users', field: 'name'),
        ],
      ),
    ]);

    expect(backend.documents('users').first.data, {
      'active': true,
      'name': null,
    });
    expect(backend.documents('users')[1].data, {'name': null, 'active': false});
    expect(backend.documents('users')[2].data, {'name': null, 'active': true});
  });

  test('removes document fields structurally', () async {
    final _DocumentsBackend backend = _DocumentsBackend({
      'users': [
        const MigrationDocument(
          key: '1',
          data: {'name': 'Ada', 'active': true},
        ),
      ],
    });

    await MigrationRunner(
      DocumentMigrationAdapter(backend),
      destructivePolicy: MigrationDestructivePolicy.allow,
    ).run([
      const Migration(
        version: 1,
        name: 'remove-name',
        operations: [RemoveFieldOperation(entityName: 'users', field: 'name')],
      ),
    ]);

    expect(backend.documents('users').single.data, {'active': true});
  });
  test('treats null as missing when copying document fields', () async {
    final _DocumentsBackend backend = _DocumentsBackend({
      'users': [
        const MigrationDocument(
          key: '1',
          data: {'source': 'Ada', 'display': null},
        ),
        const MigrationDocument(key: '2', data: {'source': 'Grace'}),
      ],
    });

    await MigrationRunner(
      DocumentMigrationAdapter(backend),
      destructivePolicy: MigrationDestructivePolicy.allow,
    ).run([
      const Migration(
        version: 1,
        name: 'copy-display',
        operations: [
          CopyFieldOperation(
            entityName: 'users',
            from: 'source',
            to: 'display',
          ),
        ],
      ),
    ]);

    expect(backend.documents('users')[0].data, {
      'source': 'Ada',
      'display': 'Ada',
    });
    expect(backend.documents('users')[1].data, {
      'source': 'Grace',
      'display': 'Grace',
    });
  });
  test(
    'groups a migration and its history record in one transaction',
    () async {
      final _TransactionalAdapter adapter = _TransactionalAdapter(
        MigrationTransactionMode.migration,
      );

      await MigrationRunner(
        adapter,
        destructivePolicy: MigrationDestructivePolicy.allow,
      ).run([
        const Migration(
          version: 1,
          name: 'one-transaction',
          operations: [
            DropEntityOperation(entityName: 'users'),
            DropEntityOperation(entityName: 'posts'),
          ],
        ),
      ]);

      expect(adapter.transactionCount, 1);
      expect(adapter.events, [
        'begin',
        'apply:users',
        'apply:posts',
        'record:1',
        'commit',
      ]);
    },
  );

  test('supports one transaction boundary per operation', () async {
    final _TransactionalAdapter adapter = _TransactionalAdapter(
      MigrationTransactionMode.operation,
    );

    await MigrationRunner(
      adapter,
      destructivePolicy: MigrationDestructivePolicy.allow,
    ).run([
      const Migration(
        version: 1,
        name: 'operation-transactions',
        operations: [
          DropEntityOperation(entityName: 'users'),
          DropEntityOperation(entityName: 'posts'),
        ],
      ),
    ]);

    expect(adapter.transactionCount, 2);
    expect(adapter.events, [
      'begin',
      'apply:users',
      'commit',
      'begin',
      'apply:posts',
      'record:1',
      'commit',
    ]);
  });
  test(
    'uses a persistent lease when a document backend provides one',
    () async {
      final _LeasedDocumentsBackend backend = _LeasedDocumentsBackend();
      final DocumentMigrationAdapter adapter = DocumentMigrationAdapter(
        backend,
      );

      await MigrationRunner(
        adapter,
        destructivePolicy: MigrationDestructivePolicy.allow,
      ).run([
        const Migration(
          version: 1,
          name: 'leased',
          operations: [DropEntityOperation(entityName: 'users')],
        ),
      ]);

      expect(backend.acquired, isTrue);
      expect(backend.released, isTrue);
      expect(backend.localLockUsed, isFalse);
      expect(backend.verifyCount, greaterThanOrEqualTo(3));
    },
  );
  test('resumes a paginated backfill from its persisted checkpoint', () async {
    final _PagedDocumentsBackend backend = _PagedDocumentsBackend({
      'users': [
        const MigrationDocument(key: '1', data: {'name': 'Ada'}),
        const MigrationDocument(key: '2', data: {'name': 'Grace'}),
        const MigrationDocument(key: '3', data: {'name': 'Linus'}),
        const MigrationDocument(key: '4', data: {'name': 'Katherine'}),
      ],
    })..failKey = '3';
    final DocumentMigrationAdapter adapter = DocumentMigrationAdapter(
      backend,
      pageSize: 2,
    );
    final Migration migration = const Migration(
      version: 1,
      name: 'active',
      operations: [
        BackfillFieldOperation(
          entityName: 'users',
          field: 'active',
          value: true,
        ),
      ],
    );
    final MigrationRunner runner = MigrationRunner(
      adapter,
      destructivePolicy: MigrationDestructivePolicy.allow,
    );

    await expectLater(runner.run([migration]), throwsA(isA<StateError>()));
    expect(backend.documents('users')[1].data['active'], true);
    expect(backend.documents('users')[2].data['active'], isNull);

    final MigrationRunResult retry = await runner.run([migration]);

    expect(retry.applied, [migration]);
    expect(
      backend
          .documents('users')
          .every((document) => document.data['active'] == true),
      isTrue,
    );
    expect(backend.pageCursors, [null, '2', '2']);
    expect(backend.documents('__dorm_migration_checkpoints'), isEmpty);
  });
  test('sql adapter emits portable DDL and backfill statements', () async {
    final _SqlBackend backend = _SqlBackend();
    final SqlMigrationAdapter adapter = SqlMigrationAdapter(
      backend,
      dialect: SqlMigrationDialect.sqlite,
    );

    await adapter.apply(
      const AddFieldOperation(
        entityName: 'users',
        field: MigrationFieldDefinition(
          fieldName: 'active',
          columnName: 'active',
          type: MigrationValueType.boolean,
        ),
      ),
    );
    await adapter.apply(
      const BackfillFieldOperation(
        entityName: 'users',
        field: 'active',
        value: true,
      ),
    );

    expect(backend.statements, contains(contains('ALTER TABLE')));
    expect(backend.statements, contains(contains('UPDATE')));
    expect(backend.parameters, contains(contains(true)));
  });
  test('applies a filtered typed transformation in batches', () async {
    final _PagedDocumentsBackend backend = _PagedDocumentsBackend({
      'users': [
        const MigrationDocument(
          key: '1',
          data: {'status': 'pending', 'name': 'Ada'},
        ),
        const MigrationDocument(
          key: '2',
          data: {'status': 'done', 'name': 'Grace'},
        ),
        const MigrationDocument(
          key: '3',
          data: {'status': 'pending', 'name': 'LINUS'},
        ),
      ],
    });
    const Migration migration = Migration(
      version: 1,
      name: 'normalize-names',
      operations: [
        TransformFieldOperation(
          entityName: 'users',
          field: 'name',
          transform: TextMigrationValue(
            sourceField: 'name',
            operation: MigrationTextTransform.lowerCase,
          ),
          filter: ValueFilterExpression('status', 'pending'),
          batchSize: 1,
          onlyMissing: false,
        ),
      ],
    );

    await MigrationRunner(
      DocumentMigrationAdapter(backend),
      destructivePolicy: MigrationDestructivePolicy.allow,
    ).run([migration]);

    expect(
      backend.documents('users').map((document) => document.data['name']),
      ['ada', 'Grace', 'linus'],
    );
    expect(backend.pageCursors, [null, '1', '2']);
  });
  test('converts typed values before a field is tightened', () async {
    final _DocumentsBackend backend = _DocumentsBackend({
      'users': [
        const MigrationDocument(
          key: '1',
          data: {'score_text': '42', 'status': 'ready'},
        ),
      ],
    });
    const Migration migration = Migration(
      version: 1,
      name: 'convert-score',
      operations: [
        TransformFieldOperation(
          entityName: 'users',
          field: 'score',
          transform: ConvertMigrationValue(
            sourceField: 'score_text',
            outputType: MigrationValueType.integer,
          ),
          filter: ValueFilterExpression('status', 'ready'),
        ),
      ],
    );

    await MigrationRunner(DocumentMigrationAdapter(backend)).run([migration]);

    expect(backend.documents('users').single.data['score'], 42);
  });
  test('emits a filtered SQL transformation with typed output', () async {
    final _SqlBackend backend = _SqlBackend();
    final SqlMigrationAdapter adapter = SqlMigrationAdapter(
      backend,
      dialect: SqlMigrationDialect.sqlite,
    );

    await adapter.apply(
      const TransformFieldOperation(
        entityName: 'users',
        field: 'name',
        transform: TextMigrationValue(
          sourceField: 'legacy_name',
          operation: MigrationTextTransform.trim,
        ),
        filter: ValueFilterExpression('status', 'pending'),
        batchSize: 25,
        onlyMissing: true,
      ),
    );

    expect(backend.statements.single, contains('TRIM'));
    expect(backend.statements.single, contains('WHERE'));
    expect(backend.statements.single, contains('status'));
    expect(backend.parameters.single, contains('pending'));
  });
  test('reports progress, structured logs, and durations', () async {
    final MemoryMigrationAdapter adapter = MemoryMigrationAdapter();
    final List<MigrationProgress> progress = [];
    final List<MigrationLogEntry> logs = [];
    final List<MigrationMetric> metrics = [];
    const Migration migration = Migration(
      version: 1,
      name: 'first',
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

    final MigrationRunResult result = await MigrationRunner(
      adapter,
      onProgress: progress.add,
      onLog: logs.add,
      onMetric: metrics.add,
    ).run([migration]);

    expect(result.duration, isNotNull);
    expect(progress.map((event) => event.stage), [
      MigrationProgressStage.started,
      MigrationProgressStage.migrationStarted,
      MigrationProgressStage.operationStarted,
      MigrationProgressStage.operationCompleted,
      MigrationProgressStage.migrationCompleted,
      MigrationProgressStage.completed,
    ]);
    expect(progress.last.completedMigrations, 1);
    expect(progress.last.totalOperations, 1);
    expect(
      logs.map((entry) => entry.event),
      progress.map((event) => event.stage.name),
    );
    expect(
      metrics.map((metric) => metric.name),
      containsAll(['operation', 'migration', 'run']),
    );
  });
  test('ignores failures from observability callbacks', () async {
    const Migration migration = Migration(
      version: 1,
      name: 'observed',
      operations: [],
    );

    final MigrationRunResult result = await MigrationRunner(
      MemoryMigrationAdapter(),
      onProgress: (_) => throw StateError('progress sink failed'),
      onLog: (_) => throw StateError('log sink failed'),
      onMetric: (_) => throw StateError('metric sink failed'),
    ).run([migration]);

    expect(result.applied, [migration]);
  });
  test('orders branch and merge dependencies deterministically', () async {
    final MemoryMigrationAdapter adapter = MemoryMigrationAdapter();
    const Migration base = Migration(
      version: 1,
      id: 'base',
      name: 'base',
      operations: [],
    );
    const Migration left = Migration(
      version: 3,
      id: 'left',
      name: 'left',
      dependsOn: ['base'],
      operations: [],
    );
    const Migration right = Migration(
      version: 2,
      id: 'right',
      name: 'right',
      dependsOn: ['base'],
      operations: [],
    );
    const Migration merge = Migration(
      version: 4,
      id: 'merge',
      name: 'merge',
      dependsOn: ['left', 'right'],
      operations: [],
    );

    await MigrationRunner(adapter).run([merge, left, right, base]);

    expect(adapter.recordedMigrations.map((migration) => migration.id), [
      'base',
      'right',
      'left',
      'merge',
    ]);
  });

  test(
    'compacts completed history without executing replacement operations',
    () async {
      final MemoryMigrationAdapter adapter = MemoryMigrationAdapter();
      const Migration first = Migration(
        version: 1,
        name: 'first',
        operations: [],
      );
      const Migration second = Migration(
        version: 2,
        name: 'second',
        operations: [],
      );
      const Migration replacement = Migration(
        version: 3,
        name: 'squashed',
        operations: [DropEntityOperation(entityName: 'not-executed')],
      );
      final MigrationRunner runner = MigrationRunner(adapter);

      await runner.run([first, second]);
      final MigrationRunResult result = await runner.compact(
        [first, second],
        replacement: replacement,
        through: 2,
      );

      expect(result.applied, [replacement]);
      expect(adapter.operations, isEmpty);
      expect(
        (await adapter.appliedMigrations()).map((entry) => entry.version),
        [3],
      );
      final MigrationRunResult retry = await runner.compact(
        [first, second],
        replacement: replacement,
        through: 2,
      );
      expect(retry.skipped, [replacement]);
    },
  );

  test('limits document pages after checkpointing them', () async {
    final _PagedDocumentsBackend backend = _PagedDocumentsBackend({
      'users': [
        const MigrationDocument(key: '1', data: {}),
        const MigrationDocument(key: '2', data: {}),
        const MigrationDocument(key: '3', data: {}),
      ],
    });
    final DocumentMigrationAdapter adapter = DocumentMigrationAdapter(
      backend,
      pageSize: 1,
      performance: const DocumentMigrationPerformanceOptions(
        maxPagesPerOperation: 1,
      ),
    );
    const Migration migration = Migration(
      version: 1,
      name: 'backfill-active',
      operations: [
        BackfillFieldOperation(
          entityName: 'users',
          field: 'active',
          value: true,
        ),
      ],
    );

    await expectLater(
      () => MigrationRunner(adapter).run([migration]),
      throwsA(isA<DocumentMigrationBatchLimitException>()),
    );
    expect(
      backend
          .documents('users')
          .any((document) => document.data['active'] == true),
      isTrue,
    );
    expect(
      backend.documents('__dorm_migration_checkpoints').single.data['cursor'],
      '1',
    );
  });
}

class _DocumentsBackend implements DocumentMigrationBackend {
  _DocumentsBackend(Map<String, List<MigrationDocument>> initial)
    : _data = {
        for (final MapEntry<String, List<MigrationDocument>> entry
            in initial.entries)
          entry.key: {
            for (final MigrationDocument document in entry.value)
              document.key: document,
          },
      };

  final Map<String, Map<String, MigrationDocument>> _data;

  List<MigrationDocument> documents(String entityName) => [
    ...(_data[entityName]?.values ?? const <MigrationDocument>[]),
  ];

  @override
  Future<List<MigrationDocument>> read(String entityName) async =>
      documents(entityName);

  @override
  Future<void> write(String entityName, MigrationDocument document) async {
    (_data[entityName] ??= {})[document.key] = document;
  }

  @override
  Future<void> delete(String entityName, String key) async {
    _data[entityName]?.remove(key);
  }

  @override
  Future<void> clear(String entityName) async => _data.remove(entityName);

  @override
  Future<T> lock<T>(Future<T> Function() action) => action();
}

final class _LeasedDocumentsBackend extends _DocumentsBackend
    implements DocumentMigrationLeaseBackend {
  _LeasedDocumentsBackend()
    : super({
        'users': [
          const MigrationDocument(key: '1', data: {'name': 'Ada'}),
        ],
      });

  bool acquired = false;
  bool released = false;
  bool localLockUsed = false;
  int verifyCount = 0;
  _TestLease? _lease;

  @override
  Future<T> lock<T>(Future<T> Function() action) async {
    localLockUsed = true;
    return action();
  }

  @override
  Future<MigrationLease> acquireLease(
    String lockEntity, {
    required Duration ttl,
  }) async {
    acquired = true;
    final _TestLease lease = _TestLease(this, lockEntity, ttl);
    _lease = lease;
    return lease;
  }

  @override
  Future<void> verifyLease(String lockEntity, MigrationLease lease) async {
    verifyCount++;
    if (!identical(_lease, lease) || !acquired || released) {
      throw const MigrationLeaseException('Test lease is not valid.');
    }
  }

  @override
  Future<void> releaseLease(String lockEntity, MigrationLease lease) async {
    released = true;
  }
}

final class _TestLease implements MigrationLease {
  _TestLease(this.backend, this.lockEntity, Duration ttl)
    : _expiresAt = DateTime.now().toUtc().add(ttl);

  final _LeasedDocumentsBackend backend;
  final String lockEntity;
  DateTime _expiresAt;

  @override
  String get owner => 'test-owner';

  @override
  int get fencingToken => 1;

  @override
  DateTime get expiresAt => _expiresAt;

  @override
  Future<void> renew() async {
    _expiresAt = DateTime.now().toUtc().add(const Duration(minutes: 5));
  }

  @override
  Future<void> release() => backend.releaseLease(lockEntity, this);
}

final class _PagedDocumentsBackend extends _DocumentsBackend
    implements DocumentMigrationPagingBackend {
  _PagedDocumentsBackend(Map<String, List<MigrationDocument>> initial)
    : super(initial);

  final List<String?> pageCursors = [];
  String? failKey;
  String? failDeleteKey;

  @override
  Future<MigrationDocumentPage> readPage(
    String entityName, {
    required String? cursor,
    required int limit,
  }) async {
    pageCursors.add(cursor);
    final List<MigrationDocument> all = documents(entityName);
    final int start = cursor == null
        ? 0
        : (() {
            final int exact = all.indexWhere(
              (document) => document.key == cursor,
            );
            if (exact >= 0) return exact + 1;
            final int afterMissing = all.indexWhere(
              (document) => document.key.compareTo(cursor) > 0,
            );
            return afterMissing < 0 ? all.length : afterMissing;
          })();
    if (start >= all.length) {
      return const MigrationDocumentPage(documents: [], nextCursor: null);
    }
    final int end = (start + limit).clamp(0, all.length);
    final List<MigrationDocument> page = all.sublist(start, end);
    return MigrationDocumentPage(
      documents: page,
      nextCursor: end < all.length ? page.last.key : null,
    );
  }

  @override
  Future<void> write(String entityName, MigrationDocument document) {
    if (entityName == 'users' && document.key == failKey) {
      failKey = null;
      return Future.error(StateError('temporary page failure'));
    }
    return super.write(entityName, document);
  }

  @override
  Future<void> delete(String entityName, String key) {
    if (entityName == 'users' && key == failDeleteKey) {
      failDeleteKey = null;
      return Future.error(StateError('temporary delete failure'));
    }
    return super.delete(entityName, key);
  }
}

final class _SqlBackend implements SqlMigrationBackend {
  final List<String> statements = [];
  final List<List<Object?>> parameters = [];

  @override
  Future<List<Map<String, Object?>>> query(
    String sql, [
    Object? parameters = const [],
  ]) async => const [];

  @override
  Future<void> execute(String sql, [Object? parameters = const []]) async {
    statements.add(sql);
    this.parameters.add(parameters is List<Object?> ? parameters : const []);
  }

  @override
  Future<T> lock<T>(Future<T> Function() action) => action();
}

final class _TransactionalAdapter
    implements MigrationAdapter, TransactionalMigrationAdapter {
  _TransactionalAdapter(this.transactionMode);

  @override
  final MigrationTransactionMode transactionMode;

  final List<String> events = [];
  final List<MigrationHistoryEntry> history = [];
  int transactionCount = 0;

  @override
  Future<List<MigrationHistoryEntry>> appliedMigrations() async => [...history];

  @override
  Future<T> lock<T>(Future<T> Function() action) => action();

  @override
  Future<T> transaction<T>(Future<T> Function() action) async {
    transactionCount++;
    events.add('begin');
    try {
      final T result = await action();
      events.add('commit');
      return result;
    } catch (_) {
      events.add('rollback');
      rethrow;
    }
  }

  @override
  Future<void> apply(MigrationOperation operation) async {
    events.add('apply:' + operation.entityName);
  }

  @override
  Future<void> record(Migration migration, {required String checksum}) async {
    events.add('record:' + migration.version.toString());
    history.add(
      MigrationHistoryEntry(
        version: migration.version,
        name: migration.name,
        checksum: checksum,
      ),
    );
  }
}

final class _LegacyHistoryAdapter implements MigrationAdapter {
  @override
  Future<List<MigrationHistoryEntry>> appliedMigrations() async => const [
    MigrationHistoryEntry(version: 1, name: 'first'),
  ];

  @override
  Future<T> lock<T>(Future<T> Function() action) => action();

  @override
  Future<void> apply(MigrationOperation operation) async {}

  @override
  Future<void> record(Migration migration, {required String checksum}) async {}
}
