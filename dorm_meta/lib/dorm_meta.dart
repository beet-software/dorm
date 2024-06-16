import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
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

  @override
  String toString() {
    return 'RunConfig{'
        'shouldWriteChangelogFile: $shouldWriteChangelogFile, '
        'shouldWriteLicenseFile: $shouldWriteLicenseFile, '
        'shouldWriteLicenseHeader: $shouldWriteLicenseHeader, '
        'shouldWritePubspecVersionKey: $shouldWritePubspecVersionKey, '
        'shouldWritePubspecSiblingDependenciesValues: $shouldWritePubspecSiblingDependenciesValues,'
        '}';
  }
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

  final Directory dir = Directory(p.join(rootDir.path, dirName));
  if (!await dir.exists()) {
    _logger.severe("subdirectory ${dir.path} does not exist");
    return false;
  }

  if (config.shouldWriteLicenseFile) {
    _logger.info("writing license file");
    final File actualLicenseFile = File(p.join(dir.path, 'LICENSE'));
    try {
      await expectedLicenseFile.copy(actualLicenseFile.path);
    } catch (e, s) {
      _logger.severe("could not create LICENSE file", e, s);
      return false;
    }
  }

  final File actualChangelogFile = File(p.join(dir.path, 'CHANGELOG.md'));
  if (config.shouldWriteChangelogFile) {
    _logger.info("writing changelog file");
    try {
      await expectedChangelogFile.copy(actualChangelogFile.path);
    } catch (e, s) {
      _logger.severe("could not create LICENSE file", e, s);
      return false;
    }
  }

  if (config.shouldWritePubspecVersionKey ||
      config.shouldWritePubspecSiblingDependenciesValues) {
    _logger.info("updating pubspec file");
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
                _logger.info("updating package version to ${release.version}");
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
                _logger.info(
                  "updating dependency $packageName's version to ${release.version}",
                );
                updatedLine = '$indent$packageName: ^${release.version}';
              } else {
                updatedLine = line;
              }
            }
        }
        sink.writeln(updatedLine);
      }
      await sink.close();
      try {
        await newPubspecFile.copy(actualPubspecFile.path);
      } catch (e, s) {
        _logger.severe("could not update pubspec file", e, s);
        return false;
      }
    } finally {
      try {
        await newPubspecFile.delete(recursive: true);
      } catch (e, s) {
        _logger.warning("could not delete temporary pubspec file", e, s);
      }
    }
  }

  if (config.shouldWriteLicenseHeader) {
    _logger.info("updating license headers");

    final Directory libDir = Directory(p.join(dir.path, 'lib'));
    await for (FileSystemEntity dartFile in dartGlob.list(root: libDir.path)) {
      if (dartFile is! File) continue;

      final bool hasLicenseHeader = await checkLicenseHeader(dartFile);
      if (hasLicenseHeader) {
        _logger.info("file ${dartFile.path} already has a license header");
        continue;
      }
      _logger.info("updating file ${dartFile.path}'s license header");

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
        try {
          await newDartFile.copy(dartFile.path);
        } catch (e, s) {
          _logger.severe("could not create updated dart file", e, s);
          return false;
        }
      } finally {
        try {
          await newDartFile.delete(recursive: true);
        } catch (e, s) {
          _logger.warning("could not delete temporary dart file", e, s);
        }
      }
    }
  }
  return true;
}

void main(List<String> args) async {
  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen((record) {
    print('[${record.level.name}] ${record.time}: ${record.message}');
  });

  final ArgParser parser = ArgParser();
  parser.addOption(
    "input",
    abbr: "i",
    help: "the subdirectory to act on",
    valueHelp: "SUBDIR",
    allowed: _packageNames,
    mandatory: true,
  );
  parser.addFlag(
    "changelog",
    help: "whether to create a CHANGELOG.md file from the root directory",
    defaultsTo: true,
    negatable: true,
  );
  parser.addFlag(
    "license",
    help: "whether to create a LICENSE file from the root directory",
    defaultsTo: true,
    negatable: true,
  );
  parser.addFlag(
    "dart-licenses",
    help: "whether to prepend a license header on Dart files",
    defaultsTo: true,
    negatable: true,
  );
  parser.addFlag(
    "pubspec-version-key",
    help: "whether to update the pubspec.yaml's version key",
    defaultsTo: true,
    negatable: true,
  );
  parser.addFlag(
    "pubspec-dependencies-values",
    help: "whether to update the pubspec.yaml's sibling dependencies values",
    defaultsTo: false,
    negatable: true,
  );

  final ArgResults results = parser.parse(args);
  final RunConfig config = RunConfig(
    shouldWriteChangelogFile: results["changelog"] as bool,
    shouldWriteLicenseFile: results["license"] as bool,
    shouldWriteLicenseHeader: results["dart-licenses"] as bool,
    shouldWritePubspecVersionKey: results["pubspec-version-key"],
    shouldWritePubspecSiblingDependenciesValues:
        results["pubspec-dependencies-values"] as bool,
  );
  _logger.info("running command using $config");

  final Directory rootDir = Directory.current;
  _logger.info("root directory defined at ${rootDir.path}");

  final String dirName = results["input"] as String;
  _logger.info("running command for $dirName");
  final bool ok = await execute(config, rootDir, dirName);
  exit(ok ? 0 : 1);
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
