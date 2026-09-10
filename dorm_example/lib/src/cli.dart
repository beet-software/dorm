// dORM
// Copyright (C) 2023  Beet Software
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as p;

import 'generator.dart';
import 'profile.dart';

/// Parses command-line arguments and generates the selected dORM showcase project.
Future<void> runCli(List<String> arguments) async {
  final ArgParser parser = ArgParser()
    ..addOption(
      'engine',
      abbr: 'e',
      allowed: ExampleProfiles.all.map((profile) => profile.name).toList(),
      help: 'Engine profile to generate.',
    )
    ..addOption(
      'output',
      abbr: 'o',
      help:
          'Directory where the project will be created (defaults to the engine name).',
    )
    ..addFlag('help', abbr: 'h', negatable: false, help: 'Show this help.')
    ..addFlag('no-color', negatable: false, help: 'Disable colored output.');

  late ArgResults results;
  try {
    results = parser.parse(arguments);
  } on FormatException catch (error) {
    stderr.writeln(error.message);
    stderr.writeln(parser.usage);
    exitCode = 64;
    return;
  }

  final _Console console = _Console(noColor: results['no-color'] as bool);
  if (results['help'] as bool) {
    stdout.writeln('Generate a dORM showcase project.');
    stdout.writeln(parser.usage);
    return;
  }

  final String? engine = results['engine'] as String?;
  if (engine == null) {
    console.error('An engine is required. Use --engine or -e.');
    stderr.writeln(parser.usage);
    exitCode = 64;
    return;
  }

  final ExampleProfile profile;
  try {
    profile = ExampleProfiles.byName(engine);
  } on Object catch (error) {
    console.error('Could not select the engine: $error');
    exitCode = 64;
    return;
  }

  final String output = p.normalize(results['output'] as String? ?? engine);
  final String projectName = p.basename(p.absolute(output));
  console.info('Generating the ${profile.name} example...');

  try {
    final GenerationResult result = await ExampleGenerator().generate(
      profile,
      Directory(output),
      projectName: projectName,
    );
    console.success('Generated the ${result.profile.name} example.');
    console.info('Location: ${result.path}');
    console.info('Next steps:');
    for (final String instruction in result.instructions) {
      console.command(instruction);
    }
  } on Object catch (error) {
    console.error('Could not generate the project: $error');
    exitCode = 1;
  }
}

class _Console {
  final bool _colorAllowed;
  final bool _useColor;

  _Console({required bool noColor})
    : _colorAllowed = !noColor && !Platform.environment.containsKey('NO_COLOR'),
      _useColor =
          !noColor &&
          stdout.hasTerminal &&
          !Platform.environment.containsKey('NO_COLOR');

  void info(String message) {
    stdout.writeln(_paint('ℹ $message', '\x1B[36m'));
  }

  void success(String message) {
    stdout.writeln(_paint('✓ $message', '\x1B[32m'));
  }

  void command(String command) {
    stdout.writeln('  ${_paint('\$ ', '\x1B[32m')}$command');
  }

  void error(String message) {
    final bool useColor = stderr.hasTerminal && _colorAllowed;
    stderr.writeln(_paint('✗ $message', '\x1B[31m', enabled: useColor));
  }

  String _paint(String message, String color, {bool? enabled}) {
    if (!(enabled ?? _useColor)) return message;
    return '$color$message\x1B[0m';
  }
}
