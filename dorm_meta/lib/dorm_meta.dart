import 'dart:convert';
import 'dart:io';

import 'package:change/change.dart';
import 'package:glob/glob.dart';
import 'package:glob/list_local_fs.dart';
import 'package:logging/logging.dart';
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

const int _flagUpdateChangelog = 1;
const int _flagUpdateLicense = 2;
const int _flagUpdateLicenseHeader = 4;
const int _flagUpdateRootVersion = 8;
const int _flagUpdateDependenciesVersion = 16;

final Logger _logger = Logger('dorm_meta');

class RunConfig {
  /// Whether to copy the root 'CHANGELOG.md' file to the subdirectory.
  final bool shouldWriteChangelogFile;

  /// Whether to copy the root 'LICENSE' file to the subdirectory;
  final bool shouldWriteLicenseFile;

  /// Whether to write the default license header to all the .dart files on the
  /// subdirectory.
  final bool shouldWriteLicenseHeader;

  /// Whether to replace the `version` key on the subdirectory's 'pubspec.yaml'
  /// file with the latest version defined on the root 'CHANGELOG.md' file.
  final bool shouldWritePubspecVersionKey;

  /// Whether to replace the values inside the `dependencies` section on the
  /// subdirectory's 'pubspec.yaml' file with the latest version defined on the
  /// root 'CHANGELOG.md' file, affecting only the dORM packages.
  final bool shouldWritePubspecSiblingDependenciesValues;

  const RunConfig({
    required this.shouldWriteChangelogFile,
    required this.shouldWriteLicenseFile,
    required this.shouldWriteLicenseHeader,
    required this.shouldWritePubspecVersionKey,
    required this.shouldWritePubspecSiblingDependenciesValues,
  });
}

Future<bool> execute(
  RunConfig config,
  Directory rootDir,
  String dirName,
) async {
  final Directory tempDir;
  try {
    tempDir = await Directory.systemTemp.createTemp();
  } catch (e, s) {
    _logger.severe("could not create temporary directory", e, s);
    return false;
  }

  final Glob dartGlob = Glob('**.dart');

  final File expectedLicenseFile = File(p.join(rootDir.path, 'LICENSE'));
  final File expectedChangelogFile = File(p.join(rootDir.path, 'CHANGELOG.md'));

  bool hasErrors = false;
  final Directory dir = Directory(p.join(rootDir.path, dirName));
  if (!await dir.exists()) {
    stderr.writeln('package $dirName does not exist');
    return false;
  }

  if (config.shouldWriteLicenseFile) {
    final File actualLicenseFile = File(p.join(dir.path, 'LICENSE'));
    await expectedLicenseFile.copy(actualLicenseFile.path);
  }

  final File actualChangelogFile = File(p.join(dir.path, 'CHANGELOG.md'));
  if (config.shouldWriteChangelogFile) {
    await expectedChangelogFile.copy(actualChangelogFile.path);
  }

  if (config.shouldWritePubspecVersionKey ||
      config.shouldWritePubspecSiblingDependenciesValues) {
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

              if (config.shouldWritePubspecVersionKey &&
                  line.startsWith('version:')) {
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

              if (config.shouldWritePubspecSiblingDependenciesValues &&
                  match != null) {
                final String indent = match.group(1)!;
                final String packageName = match.group(2)!;
                updatedLine = '$indent$packageName: ^${release.version}';
              } else {
                updatedLine = line;
              }
            }
        }
        sink.writeln(updatedLine);
      }
      await sink.close();
      await newPubspecFile.copy(actualPubspecFile.path);
    } finally {
      await newPubspecFile.delete(recursive: true);
    }
  }

  if (config.shouldWriteLicenseHeader) {
    final Directory libDir = Directory(p.join(dir.path, 'lib'));
    await for (FileSystemEntity dartFile in dartGlob.list(root: libDir.path)) {
      if (dartFile is! File) continue;

      final bool hasLicenseHeader = await checkLicenseHeader(dartFile);
      if (hasLicenseHeader) continue;

      final File newDartFile =
          File(p.join(tempDir.path, p.basename(dartFile.path)));
      try {
        final IOSink sink = newDartFile.openWrite();
        for (String line in const LineSplitter().convert(_licenseHeader)) {
          sink.writeln(line.isEmpty ? '//' : '// $line');
        }
        sink.writeln();
        await dartFile
            .openRead()
            .transform(utf8.decoder)
            .transform(LineSplitter())
            .forEach(sink.writeln);
        await sink.close();
        await newDartFile.copy(dartFile.path);
      } finally {
        await newDartFile.delete(recursive: true);
      }
    }
  }
  return true;
}

void main(List<String> args) async {
  final RunConfig config = RunConfig(
    shouldWriteChangelogFile: true,
    shouldWriteLicenseFile: true,
    shouldWriteLicenseHeader: true,
    shouldWritePubspecVersionKey: true,
    shouldWritePubspecSiblingDependenciesValues: args.contains('--outdated'),
  );

  final int pathLength = Platform.script.pathSegments.length;
  final Directory rootDir = Directory(
    p.joinAll(Platform.script.pathSegments.sublist(0, pathLength - 3)),
  );
  _logger.info("root directory defined at ${rootDir.path}");

  bool hadErrors = false;
  for (String dirName in _packageNames) {
    final bool ok = await execute(config, rootDir, dirName);
    if (!ok) {
      hadErrors = true;
      continue;
    }
  }
  exit(hadErrors ? 1 : 0);
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
