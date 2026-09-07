import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

Directory _repositoryRoot() {
  Directory directory = Directory.current.absolute;
  while (directory.parent.path != directory.path) {
    if (File(
          '${directory.path}${Platform.pathSeparator}pubspec.yaml',
        ).existsSync() &&
        Directory(
          '${directory.path}${Platform.pathSeparator}dorm_generator',
        ).existsSync()) {
      return directory;
    }
    directory = directory.parent;
  }
  throw StateError('Could not locate the dORM repository root.');
}

String _yamlPath(String path) => path.replaceAll(r'\', '/');

Future<ProcessResult> _runDart(
  Directory workingDirectory,
  List<String> arguments,
) {
  return Process.run(
    Platform.resolvedExecutable,
    arguments,
    workingDirectory: workingDirectory.path,
    stdoutEncoding: utf8,
    stderrEncoding: utf8,
  );
}

void _expectSuccess(ProcessResult result, String command) {
  expect(
    result.exitCode,
    0,
    reason:
        '$command failed.\nstdout:\n${result.stdout}\nstderr:\n${result.stderr}',
  );
}

void main() {
  test(
    'build_runner generates analyzable model and relationship code',
    () async {
      final Directory root = _repositoryRoot();
      final Directory project = await Directory.systemTemp.createTemp(
        'dorm_generator_fixture_',
      );

      try {
        await File(
          '${project.path}${Platform.pathSeparator}pubspec.yaml',
        ).writeAsString('''
name: generator_fixture
publish_to: none
environment:
  sdk: '>=3.11.5 <4.0.0'

dependencies:
  dorm_annotations:
    path: '${_yamlPath('${root.path}${Platform.pathSeparator}dorm_annotations')}'
  dorm_bloc_database:
    path: '${_yamlPath('${root.path}${Platform.pathSeparator}dorm_bloc_database')}'
  dorm_framework:
    path: '${_yamlPath('${root.path}${Platform.pathSeparator}dorm_framework')}'
  json_annotation: ^4.12.0

dev_dependencies:
  build_runner: ^2.16.1
  dorm_generator:
    path: '${_yamlPath('${root.path}${Platform.pathSeparator}dorm_generator')}'
  json_serializable: ^6.14.1

dependency_overrides:
  dorm_annotations:
    path: '${_yamlPath('${root.path}${Platform.pathSeparator}dorm_annotations')}'
  dorm_bloc_database:
    path: '${_yamlPath('${root.path}${Platform.pathSeparator}dorm_bloc_database')}'
  dorm_framework:
    path: '${_yamlPath('${root.path}${Platform.pathSeparator}dorm_framework')}'
  dorm_generator:
    path: '${_yamlPath('${root.path}${Platform.pathSeparator}dorm_generator')}'
''');

        final Directory lib = await Directory(
          '${project.path}${Platform.pathSeparator}lib',
        ).create();
        await File(
          '${lib.path}${Platform.pathSeparator}models.dart',
        ).writeAsString('''
import 'package:dorm_annotations/dorm_annotations.dart';
import 'package:dorm_bloc_database/dorm_bloc_database.dart';
import 'package:dorm_framework/dorm_framework.dart';

part 'models.dorm.dart';
part 'models.g.dart';

@Model(name: 'users', as: #users)
abstract class _User {
  @Field()
  String get name;

  @Field()
  DateTime get createdAt;

  @DerivedField(
    name: '_query/created-date',
    referTo: [DerivedToken(#createdAt, DerivedTransform.date)],
  )
  // ignore: unused_element
  String get _createdDate;

  @DerivedField(
    name: '_query/created-datetime',
    referTo: [DerivedToken(#createdAt, DerivedTransform.datetime)],
  )
  // ignore: unused_element
  String get _createdDateTime;
}

@Model(name: 'posts', as: #posts)
abstract class _Post {
  @Field()
  String get title;

  @ForeignField(referTo: _User, inverseAs: #posts)
  String get userId;
}
''');

        _expectSuccess(await _runDart(project, ['pub', 'get']), 'dart pub get');
        _expectSuccess(
          await _runDart(project, ['run', 'build_runner', 'build']),
          'dart run build_runner build',
        );

        final File generated = File(
          '${lib.path}${Platform.pathSeparator}models.dorm.dart',
        );
        final String generatedCode = await generated.readAsString();
        expect(generatedCode, contains('class UserData'));
        expect(generatedCode, contains('class UserEntity'));
        expect(generatedCode, contains('class PostEntity'));
        expect(generatedCode, contains('SimpleCreation<UserData, String>'));
        expect(generatedCode, contains('toMany('));
        expect(generatedCode, contains(r'$normalizeDate(createdAt)'));
        expect(generatedCode, contains(r'$normalizeDateTime(createdAt)'));

        _expectSuccess(await _runDart(project, ['analyze']), 'dart analyze');
      } finally {
        await project.delete(recursive: true);
      }
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
