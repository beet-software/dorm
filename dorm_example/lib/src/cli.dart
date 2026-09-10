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
    ..addFlag('help', abbr: 'h', negatable: false, help: 'Show this help.');

  late ArgResults results;
  try {
    results = parser.parse(arguments);
  } on FormatException catch (error) {
    stderr.writeln(error.message);
    stderr.writeln(parser.usage);
    exitCode = 64;
    return;
  }

  if (results['help'] as bool) {
    stdout.writeln('Generate a dORM showcase project.');
    stdout.writeln(parser.usage);
    return;
  }

  final String? engine = results['engine'] as String?;
  if (engine == null) {
    stderr.writeln('An engine is required. Use --engine or -e.');
    stderr.writeln(parser.usage);
    exitCode = 64;
    return;
  }

  final String output = p.normalize(results['output'] as String? ?? engine);
  final String projectName = p.basename(p.absolute(output));
  try {
    final ExampleProfile profile = ExampleProfiles.byName(engine);
    final GenerationResult result = await ExampleGenerator().generate(
      profile,
      Directory(output),
      projectName: projectName,
    );
    stdout.writeln(
      'Generated ${result.profile.name} example in ${result.path}.',
    );
    stdout.writeln();
    for (final String instruction in result.instructions) {
      stdout.writeln(instruction);
    }
  } on Object catch (error) {
    stderr.writeln('Could not generate the project: $error');
    exitCode = 1;
  }
}
