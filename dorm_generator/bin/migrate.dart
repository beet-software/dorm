import 'dart:io';

import 'package:dorm_generator/src/migration_cli.dart';

Future<void> main(List<String> arguments) async {
  exitCode = await runMigrationCli(arguments);
}
