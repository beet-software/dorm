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

const int _flagUpdateChangelog = 1;
const int _flagUpdateLicense = 2;
const int _flagUpdateLicenseHeader = 4;
const int _flagUpdateRootVersion = 8;
const int _flagUpdateDependenciesVersion = 16;

extension _Flags on int {
  bool flagAt(int index) => this >> index & 1 == 1;
}

Future<bool> execute(Directory tempDir, int flags) async {
  final bool updateChangelog = flags.flagAt(0);
  final bool updateLicense = flags.flagAt(1);
  final bool updateLicenseHeader = flags.flagAt(2);
  final bool updateRootVersion = flags.flagAt(3);
  final bool updateChildrenVersion = flags.flagAt(4);

  final Glob dartGlob = Glob('**.dart');

  final int pathLength = Platform.script.pathSegments.length;
  final Directory rootDir = Directory(
      p.joinAll(Platform.script.pathSegments.sublist(0, pathLength - 3)));
  stdout.writeln('script located at ${Platform.script.path}');
  stdout.writeln('root set at ${rootDir.path}');

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

    if (updateLicense) {
      final File actualLicenseFile = File(p.join(dir.path, 'LICENSE'));
      await expectedLicenseFile.copy(actualLicenseFile.path);
    }

    final File actualChangelogFile = File(p.join(dir.path, 'CHANGELOG.md'));
    if (updateChangelog) {
      await expectedChangelogFile.copy(actualChangelogFile.path);
    }

    if (updateRootVersion || updateChildrenVersion) {
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

                if (updateRootVersion && line.startsWith('version:')) {
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

                if (updateChildrenVersion && match != null) {
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

    if (updateLicenseHeader) {
      final Directory libDir = Directory(p.join(dir.path, 'lib'));
      await for (FileSystemEntity dartFile
          in dartGlob.list(root: libDir.path)) {
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
  }
  return !hasErrors;
}

void main(List<String> args) async {
  int flags = 0;
  flags |= _flagUpdateChangelog;
  flags |= _flagUpdateLicense;
  flags |= _flagUpdateLicenseHeader;
  flags |= _flagUpdateRootVersion;
  if (args.contains('--outdated')) {
    flags |= _flagUpdateDependenciesVersion;
  }

  final Directory tempDir = await Directory.systemTemp.createTemp();
  final bool hadErrors;
  try {
    hadErrors = await execute(tempDir, flags);
  } finally {
    await tempDir.delete(recursive: true);
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
