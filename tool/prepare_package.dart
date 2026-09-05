import 'dart:convert';
import 'dart:io';

const String _licenseHeader = '''\
dORM
Copyright (C) 2023  Beet Software

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.''';

Future<void> main(List<String> args) async {
  final String? packageName = _option(args, '--package');
  if (packageName == null || packageName.isEmpty) {
    stderr.writeln('Usage: dart run tool/prepare_package.dart --package <name>');
    exitCode = 64;
    return;
  }

  final Directory root = Directory.current;
  final Directory package = Directory(_join(root.path, packageName));
  if (!await package.exists() ||
      !await File(_join(package.path, 'pubspec.yaml')).exists()) {
    stderr.writeln('Package directory does not exist: ${package.path}');
    exitCode = 1;
    return;
  }

  final File rootLicense = File(_join(root.path, 'LICENSE'));
  if (!await rootLicense.exists()) {
    stderr.writeln('Root LICENSE file does not exist: ${rootLicense.path}');
    exitCode = 1;
    return;
  }

  await rootLicense.copy(_join(package.path, 'LICENSE'));
  await _prependHeaders(Directory(_join(package.path, 'lib')));
}

String? _option(List<String> args, String name) {
  final int index = args.indexOf(name);
  if (index >= 0 && index + 1 < args.length) return args[index + 1];

  final String prefix = '$name=';
  for (final String arg in args) {
    if (arg.startsWith(prefix)) return arg.substring(prefix.length);
  }
  return null;
}

Future<void> _prependHeaders(Directory libDirectory) async {
  if (!await libDirectory.exists()) return;

  final List<String> expected = const LineSplitter().convert(_licenseHeader);
  await for (final FileSystemEntity entity
      in libDirectory.list(recursive: true, followLinks: false)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;

    final List<String> lines = await entity.readAsLines();
    if (_hasHeader(lines, expected)) continue;

    final StringBuffer output = StringBuffer();
    for (final String line in expected) {
      output.writeln(line.isEmpty ? '//' : '// $line');
    }
    output.writeln();
    output.write(await entity.readAsString());
    await entity.writeAsString(output.toString());
  }
}

bool _hasHeader(List<String> actual, List<String> expected) {
  if (actual.length < expected.length) return false;
  for (int index = 0; index < expected.length; index++) {
    final String expectedLine =
        '//${expected[index].isEmpty ? '' : ' '}${expected[index]}';
    if (actual[index] != expectedLine) return false;
  }
  return true;
}

String _join(String first, String second) {
  return '$first${Platform.pathSeparator}$second';
}
