import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:dorm_framework/dorm_framework.dart';

import 'runner.dart';
import 'schema.dart';

/// Resources required to execute a migration command.
final class MigrationRuntime {
  const MigrationRuntime({
    required this.adapter,
    this.close,
    this.validateSchema,
    this.operationValidator,
    this.onProgress,
    this.onLog,
    this.onMetric,
  });

  /// Adapter used by [MigrationRunner].
  final MigrationAdapter adapter;

  /// Releases connections and other process-owned resources.
  final FutureOr<void> Function()? close;

  /// Optionally validates a backend schema against the project's expected schema.
  ///
  /// The project owns construction of the expected snapshot because the
  /// framework cannot discover generated schema files safely at runtime.
  final Future<MigrationSchemaValidationResult> Function()? validateSchema;

  /// Checks a pending operation before the adapter applies it.
  final MigrationOperationValidator? operationValidator;

  /// Receives typed lifecycle events from the migration runner.
  final MigrationProgressCallback? onProgress;

  /// Receives structured lifecycle records from the migration runner.
  final MigrationLogCallback? onLog;

  /// Receives completed duration measurements from the migration runner.
  final MigrationMetricCallback? onMetric;
}

/// Opens the adapter and any resources required by a migration process.
typedef MigrationRuntimeFactory = FutureOr<MigrationRuntime> Function();

/// Runs the project-owned migration command.
///
/// The command accepts [apply], [status], [validate], [baseline], [resolve],
/// and [--help]. Migration source files must be imported explicitly by the
/// project entrypoint.
Future<int> runMigrationCommand(
  List<String> arguments, {
  required MigrationRuntimeFactory open,
  required Iterable<Migration> migrations,
}) async {
  final ArgParser parser = ArgParser()
    ..addFlag('help', abbr: 'h', negatable: false)
    ..addCommand(
      'apply',
      ArgParser()
        ..addFlag('help', abbr: 'h', negatable: false)
        ..addFlag('allow-destructive', negatable: false),
    )
    ..addCommand(
      'status',
      ArgParser()..addFlag('help', abbr: 'h', negatable: false),
    )
    ..addCommand(
      'validate',
      ArgParser()..addFlag('help', abbr: 'h', negatable: false),
    )
    ..addCommand(
      'baseline',
      ArgParser()
        ..addFlag('help', abbr: 'h', negatable: false)
        ..addOption('through', mandatory: true)
        ..addFlag('confirm', negatable: false),
    )
    ..addCommand(
      'resolve',
      ArgParser()
        ..addFlag('help', abbr: 'h', negatable: false)
        ..addOption('version', mandatory: true)
        ..addFlag('confirm', negatable: false),
    );

  ArgResults results;
  try {
    results = parser.parse(arguments);
  } on FormatException catch (error) {
    stderr.writeln('Migration command error: ${error}');
    stderr.writeln(_usage);
    return 64;
  }

  final ArgResults? command = results.command;
  if (results['help'] as bool || (command != null && command['help'] as bool)) {
    stdout.writeln(_usage);
    return 0;
  }
  if (command == null) {
    stderr.writeln('Migration command error: choose a command.');
    stderr.writeln(_usage);
    return 64;
  }

  return switch (command.name) {
    'apply' => _withRuntime(open, (runtime) async {
      final bool allowDestructive = command['allow-destructive'] as bool;
      final MigrationRunResult result = await MigrationRunner(
        runtime.adapter,
        destructivePolicy: allowDestructive
            ? MigrationDestructivePolicy.allow
            : MigrationDestructivePolicy.reject,
        operationValidator: runtime.operationValidator,
        onProgress: runtime.onProgress,
        onLog: runtime.onLog,
        onMetric: runtime.onMetric,
      ).run(migrations);
      stdout.writeln(
        'Applied ${result.applied.length} migration(s); skipped '
        '${result.skipped.length}.',
      );
      return 0;
    }),
    'status' => _withRuntime(open, (runtime) async {
      final MigrationStatusReport report = await MigrationRunner(
        runtime.adapter,
      ).status(migrations);
      _printStatus(report);
      return report.isValid ? 0 : 1;
    }),
    'validate' => _withRuntime(open, (runtime) async {
      final MigrationStatusReport report = await MigrationRunner(
        runtime.adapter,
      ).validate(migrations);
      _printStatus(report);
      bool valid = report.isValid;
      final Future<MigrationSchemaValidationResult> Function()? validateSchema =
          runtime.validateSchema;
      if (validateSchema != null) {
        final MigrationSchemaValidationResult schema = await validateSchema();
        if (schema.isValid) {
          stdout.writeln('Backend schema matches the expected schema.');
        } else {
          valid = false;
          stderr.writeln('Backend schema differences:');
          for (final MigrationSchemaDifference difference
              in schema.differences) {
            stderr.writeln('- ${difference}');
          }
        }
      }
      return valid ? 0 : 1;
    }),
    'baseline' => _runBaselineCommand(
      command,
      open: open,
      migrations: migrations,
    ),
    'resolve' => _runResolveCommand(
      command,
      open: open,
      migrations: migrations,
    ),
    _ => _invalidCommand(command.name),
  };
}

Future<int> _runBaselineCommand(
  ArgResults command, {
  required MigrationRuntimeFactory open,
  required Iterable<Migration> migrations,
}) async {
  if (!(command['confirm'] as bool)) {
    stderr.writeln('Migration command error: baseline requires --confirm.');
    return 64;
  }
  final int? through = int.tryParse(command['through'] as String);
  if (through == null || through <= 0) {
    stderr.writeln(
      'Migration command error: --through must be a positive integer.',
    );
    return 64;
  }
  return _withRuntime(open, (runtime) async {
    final MigrationRunResult result = await MigrationRunner(
      runtime.adapter,
    ).baseline(migrations, through: through);
    stdout.writeln(
      'Baselined ${result.applied.length} migration(s); skipped '
      '${result.skipped.length}.',
    );
    return 0;
  });
}

Future<int> _runResolveCommand(
  ArgResults command, {
  required MigrationRuntimeFactory open,
  required Iterable<Migration> migrations,
}) async {
  if (!(command['confirm'] as bool)) {
    stderr.writeln('Migration command error: resolve requires --confirm.');
    return 64;
  }
  final int? version = int.tryParse(command['version'] as String);
  if (version == null || version <= 0) {
    stderr.writeln(
      'Migration command error: --version must be a positive integer.',
    );
    return 64;
  }
  return _withRuntime(open, (runtime) async {
    final MigrationRunResult result = await MigrationRunner(
      runtime.adapter,
    ).resolve(migrations, version: version);
    stdout.writeln(
      'Resolved ${result.applied.length} migration(s); skipped '
      '${result.skipped.length}.',
    );
    return 0;
  });
}

Future<int> _withRuntime(
  MigrationRuntimeFactory open,
  Future<int> Function(MigrationRuntime runtime) action,
) async {
  MigrationRuntime? runtime;
  int resultCode = 0;
  try {
    runtime = await open();
    resultCode = await action(runtime);
  } on Object catch (error, stackTrace) {
    resultCode = 1;
    stderr.writeln('Migration command failed: ${error}');
    stderr.writeln(stackTrace);
  } finally {
    final FutureOr<void> Function()? close = runtime?.close;
    if (close != null) {
      try {
        await close();
      } on Object catch (error, stackTrace) {
        resultCode = 1;
        stderr.writeln('Could not close migration resources: ${error}');
        stderr.writeln(stackTrace);
      }
    }
  }
  return resultCode;
}

int _invalidCommand(String? command) {
  stderr.writeln('Migration command error: unknown command $command.');
  stderr.writeln(_usage);
  return 64;
}

void _printStatus(MigrationStatusReport report) {
  stdout.writeln('Pending: ${report.pending.length}.');
  stdout.writeln('Applied: ${report.applied.length}.');
  if (report.checksumMismatches.isNotEmpty) {
    stderr.writeln(
      'Checksum mismatches: ${report.checksumMismatches.map((value) => value.version).join(', ')}.',
    );
  }
  if (report.legacyHistory.isNotEmpty) {
    stderr.writeln(
      'Legacy history without checksums: '
      '${report.legacyHistory.map((value) => value.version).join(', ')}.',
    );
  }
  if (report.unknownApplied.isNotEmpty) {
    stderr.writeln(
      'Applied versions missing from the source list: '
      '${report.unknownApplied.map((value) => value.version).join(', ')}.',
    );
  }
}

const String _usage =
    '''Usage: dart run tool/migrations.dart <command> [options]

Commands:
  apply       Apply pending migrations.
  status      Show pending, applied, and inconsistent history entries.
  validate    Validate history and the optional backend schema.
  baseline    Record migrations without executing them; requires --confirm.
  resolve     Record one externally completed migration; requires --confirm.

Options:
  apply --allow-destructive
  baseline --through <version> --confirm
  resolve --version <version> --confirm
''';
