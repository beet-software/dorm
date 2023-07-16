import 'dart:convert';
import 'dart:io';

import 'package:change/change.dart';
import 'package:glob/glob.dart';
import 'package:glob/list_local_fs.dart';
import 'package:path/path.dart' as p;
import 'package:rxdart/rxdart.dart';

const List<String> _packageNames = [
  'dorm_annotations',
  'dorm_bloc_database',
  'dorm_firebase_database',
  'dorm_framework',
  'dorm_generator',
];
const String _licenseHeader = """\
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
along with this program.  If not, see <https://www.gnu.org/licenses/>.""";

enum PubspecSection { dependencies }

Future<bool> execute(Directory tempDir) async {
  final Glob dartGlob = Glob('**.dart');

  final int pathLength = Platform.script.pathSegments.length;
  final Directory rootDir = Directory(
      p.joinAll(Platform.script.pathSegments.sublist(0, pathLength - 3)));
  final File expectedLicenseFile = File(p.join(rootDir.path, 'LICENSE'));
  final File expectedChangelogFile = File(p.join(rootDir.path, 'CHANGELOG.md'));

  bool hasErrors = false;
  for (String dirName in _packageNames) {
    final Directory dir = Directory(p.join(rootDir.path, dirName));
    if (!await dir.exists()) {
      stderr.writeln('package $dirName does not exist');
      hasErrors = true;
      continue;
    }

    final File actualLicenseFile = File(p.join(dir.path, 'LICENSE'));
    await expectedLicenseFile.copy(actualLicenseFile.path);

    final File actualChangelogFile = File(p.join(dir.path, 'CHANGELOG.md'));
    await expectedChangelogFile.copy(actualChangelogFile.path);

    final Changelog changelog =
        parseChangelog(await actualChangelogFile.readAsString());
    final Release release = changelog.history().last;

    final File newPubspecFile = File(p.join(tempDir.path, 'pubspec.yaml'));
    final File actualPubspecFile = File(p.join(dir.path, 'pubspec.yaml'));
    try {
      PubspecSection? section;
      final IOSink sink = newPubspecFile.openWrite();
      await for (String line in actualPubspecFile
          .openRead()
          .transform(utf8.decoder)
          .transform(const LineSplitter())) {
        final String updatedLine;
        switch (section) {
          case null:
            {
              if (line.startsWith('dependencies:')) {
                section = PubspecSection.dependencies;
              }

              if (line.startsWith('version:')) {
                updatedLine = 'version: ${release.version}';
              } else {
                updatedLine = line;
              }
            }
          case PubspecSection.dependencies:
            {
              if (line.startsWith(RegExp(r'[a-z]'))) {
                section = null;
              }
              final Match? match =
                  // ignore: prefer_interpolation_to_compose_strings
                  RegExp(r'(\s+)(' + _packageNames.join('|') + '):')
                      .matchAsPrefix(line);

              if (match == null) {
                updatedLine = line;
              } else {
                final String indent = match.group(1)!;
                final String packageName = match.group(2)!;
                updatedLine = '$indent$packageName: ^${release.version}';
              }
            }
        }
        sink.writeln(updatedLine);
      }
      await newPubspecFile.copy(actualPubspecFile.path);
      await sink.close();
    } finally {
      await newPubspecFile.delete(recursive: true);
    }

    final bool hasLicenseFile = await checkLicenseFile(dir);
    if (!hasLicenseFile) {
      stderr.writeln('packages with no license file: $dirName');
      hasErrors = true;
    }

    final Directory libDir = Directory(p.join(dir.path, 'lib'));
    await for (FileSystemEntity entity in dartGlob.list(root: libDir.path)) {
      if (entity is! File) continue;

      final bool hasLicenseHeader = await checkLicenseHeader(entity);
      if (!hasLicenseHeader) {
        stderr.writeln('Files with no license header: ${entity.path}');
        hasErrors = true;
      }
    }
  }
  exit(hasErrors ? 1 : 0);
}

void main() async {
  final Directory tempDir = await Directory.systemTemp.createTemp();
  try {
    await execute(tempDir);
  } finally {
    await tempDir.delete(recursive: true);
  }
}

Future<bool> checkLicenseFile(Directory dir) async {
  final String expectedContents =
      await File(p.join(dir.parent.path, 'LICENSE')).readAsString();
  try {
    final String actualContents =
        await File(p.join(dir.path, 'LICENSE')).readAsString();
    return expectedContents == actualContents;
  } on PathNotFoundException {
    return false;
  }
}

Future<bool> checkLicenseHeader(File file) async {
  final List<String> licenseHeaderContents =
      LineSplitter().convert(_licenseHeader);

  return !await file
      .openRead()
      .transform(utf8.decoder)
      .transform(LineSplitter())
      .bufferCount(licenseHeaderContents.length)
      .where((lines) {
        for (int i = 0; i < licenseHeaderContents.length; i++) {
          final String licenseHeaderLine = licenseHeaderContents[i];

          final String actualLine = lines[i];
          final String expectedLine =
              '//${licenseHeaderLine.isEmpty ? '' : ' '}$licenseHeaderLine';

          if (actualLine != expectedLine) return false;
        }
        return true;
      })
      .take(1)
      .isEmpty;
}
