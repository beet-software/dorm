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

const List<String> _excludedPackages = <String>['dorm_test'];

Future<void> main() async {
  final Directory root = Directory.current;
  final String version = _readVersion(_pubspec(root, 'dorm_example'));
  final List<Directory> packages = root
      .listSync()
      .whereType<Directory>()
      .where(
        (directory) => directory.path
            .split(Platform.pathSeparator)
            .last
            .startsWith('dorm_'),
      )
      .where(
        (directory) => !_excludedPackages.contains(
          directory.path.split(Platform.pathSeparator).last,
        ),
      )
      .where((directory) => File(_pubspecPath(directory.path)).existsSync())
      .toList();

  for (final Directory package in packages) {
    final String packageVersion = _readVersion(_pubspec(package, null));
    if (packageVersion != version) {
      throw StateError(
        '${package.path} declares $packageVersion, expected $version.',
      );
    }
  }

  final File releaseFile = File(
    '${root.path}${Platform.pathSeparator}dorm_example${Platform.pathSeparator}'
    'lib${Platform.pathSeparator}src${Platform.pathSeparator}release.dart',
  );
  final String source = releaseFile.readAsStringSync();
  final String updated = source.replaceFirst(
    RegExp(r"const String dormReleaseVersion = '[^']*';"),
    "const String dormReleaseVersion = '$version';",
  );
  if (source == updated) {
    throw StateError(
      'Could not find dormReleaseVersion in ${releaseFile.path}.',
    );
  }
  releaseFile.writeAsStringSync(updated);

  stdout.writeln('Synchronized dorm_example with dORM $version.');
}

File _pubspec(Directory root, String? packageName) {
  final String path = packageName == null
      ? _pubspecPath(root.path)
      : '${root.path}${Platform.pathSeparator}$packageName${Platform.pathSeparator}'
            'pubspec.yaml';
  return File(path);
}

String _pubspecPath(String directory) =>
    '$directory${Platform.pathSeparator}pubspec.yaml';

String _readVersion(File pubspec) {
  if (!pubspec.existsSync()) {
    throw StateError('Missing package manifest: ${pubspec.path}');
  }
  final RegExpMatch? match = RegExp(
    r'^version:\s*(\S+)\s*$',
    multiLine: true,
  ).firstMatch(pubspec.readAsStringSync());
  if (match == null) {
    throw StateError('Missing version in ${pubspec.path}.');
  }
  return match.group(1)!;
}
