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
import 'package:dorm_framework/dorm_framework.dart';

part 'models.dorm.dart';
part 'models.g.dart';

@Model(name: 'users', as: #users)
abstract class _User {
  static String \$dorm\$generateId(_User model, String generatedId) {
    return model.name;
  }

  @Field()
  String get name;

  @Field()
  DateTime get createdAt;

  @DerivedField(name: '_query/created-date')
  static String \$dorm\$derived\$createdDate(
    _User model,
    DerivedTransformations transformations,
  ) => transformations.date(model.createdAt) ?? '';

  @DerivedField(name: '_query/created-datetime')
  static String \$dorm\$derived\$createdDateTime(
    _User model,
    DerivedTransformations transformations,
  ) => transformations.datetime(model.createdAt) ?? '';
}

@Model(name: 'posts', as: #posts)
abstract class _Post {
  @Field()
  String get title;

  @DerivedField(name: 'title-length')
  static int \$dorm\$derived\$titleLength(
    _Post model,
    DerivedTransformations transformations,
  ) => model.title.length;

  @ForeignField(referTo: _User, inverseAs: #posts)
  String get userId;
}

@Model(
  name: 'sequences',
  as: #sequences,
  primaryKey: [DatabaseGeneratedIdSpec(type: int)],
)
abstract class _Sequence {
  @Field()
  String get name;
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
        expect(generatedCode, contains('class SequenceEntity'));
        expect(generatedCode, contains('IdentityGenerationStrategy.database'));
        expect(generatedCode, contains('_User.\$dorm\$generateId('));
        expect(
          generatedCode,
          contains('class Dorm<Q extends BaseQuery<Q>, P extends PageRequest>'),
        );
        expect(generatedCode, contains('BaseEngine<Q, P>'));
        expect(generatedCode, contains('DormRelations<Q, P>'));
        expect(
          generatedCode,
          contains(
            'class TransactionalDorm<Q extends BaseQuery<Q>, '
            'P extends PageRequest>',
          ),
        );
        expect(generatedCode, contains('TransactionalEngine<Q, P>'));
        expect(generatedCode, contains('Future<T> transaction<T>'));
        expect(generatedCode, contains('RelationPath<Dorm<Q, P>'));
        expect(generatedCode, isNot(contains('BaseEngine<Query, P>')));
        expect(generatedCode, contains('SimpleCreation<UserData, String>'));
        expect(generatedCode, contains('toMany('));
        expect(generatedCode, contains(r'_User.$dorm$derived$createdDate'));
        expect(generatedCode, contains(r'_User.$dorm$derived$createdDateTime'));
        expect(generatedCode, contains('int get titleLength'));

        _expectSuccess(await _runDart(project, ['analyze']), 'dart analyze');

        await File(
          '${lib.path}${Platform.pathSeparator}valid_page.dart',
        ).writeAsString('''
import 'package:dorm_framework/dorm_framework.dart';
import 'package:dorm_bloc_database/dorm_bloc_database.dart' as dorm_bloc;

import 'models.dart';

Future<Page<User>> readPage(
  Dorm<dorm_bloc.Query, OffsetPageRequest> dorm,
) {
  return dorm.users.repository.peekPage(
    const BaseFilter.empty(),
    const OffsetPageRequest(size: 1),
  );
}

Dorm<dorm_bloc.Query, OffsetPageRequest> createDorm() {
  return Dorm(dorm_bloc.Engine());
}
''');
        _expectSuccess(
          await _runDart(project, ['analyze']),
          'dart analyze with an offset page request',
        );

        await File(
          '${lib.path}${Platform.pathSeparator}valid_transaction.dart',
        ).writeAsString('''
import 'package:dorm_bloc_database/dorm_bloc_database.dart' as dorm_bloc;
import 'package:dorm_framework/dorm_framework.dart';

import 'models.dart';

Future<User> createUser() async {
  final TransactionalDorm<dorm_bloc.Query, OffsetPageRequest> dorm =
      TransactionalDorm(dorm_bloc.Engine());
  return dorm.transaction((tx) async {
    return tx.users.repository.put(
      Creation.explicit(
        dependency: const UserDependency(),
        data: UserData(
          name: 'transactional',
          createdAt: DateTime.utc(2026),
        ),
        identity: 'transaction-user',
      ),
    );
  });
}
''');
        _expectSuccess(
          await _runDart(project, ['analyze']),
          'dart analyze with a transactional engine',
        );

        await File(
          '${lib.path}${Platform.pathSeparator}invalid_advanced_filter.dart',
        ).writeAsString('''
import 'package:dorm_framework/dorm_framework.dart';

class _BasicQuery implements BaseQuery<_BasicQuery> {
  @override
  _BasicQuery whereValue(String key, Object? value) => this;

  @override
  _BasicQuery whereText(String key, String prefix) => this;

  @override
  _BasicQuery whereDate(String key, DateTime date, DateFilterUnit unit) => this;

  @override
  _BasicQuery whereRange<R>(String key, FilterRange<R> range) => this;

  @override
  _BasicQuery limit(int count) => this;

  @override
  _BasicQuery offset(int count) => this;

  @override
  _BasicQuery sorted(String key, {bool ascending = true}) => this;
}

BaseFilter<_BasicQuery> invalidFilter() {
  return BaseFilter.anyOf<_BasicQuery>(const [BaseFilter.empty()]);
}

BaseFilter<_BasicQuery> invalidNegation() {
  return BaseFilter.not<_BasicQuery>(const BaseFilter.empty());
}

BaseFilter<_BasicQuery> invalidCollection() {
  return BaseFilter.contains<_BasicQuery>(
    'value',
    field: const FieldSchema(fieldName: 'values', columnName: 'values'),
  );
}

BaseFilter<_BasicQuery> invalidComparison() {
  return BaseFilter.greaterThan<_BasicQuery>(
    1,
    field: const FieldSchema(fieldName: 'value', columnName: 'value'),
  );
}
''');
        final ProcessResult invalidFilterAnalysis = await _runDart(project, [
          'analyze',
        ]);
        expect(invalidFilterAnalysis.exitCode, isNot(0));
        expect(
          '${invalidFilterAnalysis.stdout}\n${invalidFilterAnalysis.stderr}',
          contains('LogicalQuery'),
        );
        expect(
          '${invalidFilterAnalysis.stdout}\n${invalidFilterAnalysis.stderr}',
          contains('NegationQuery'),
        );
        expect(
          '${invalidFilterAnalysis.stdout}\n${invalidFilterAnalysis.stderr}',
          contains('CollectionQuery'),
        );
        expect(
          '${invalidFilterAnalysis.stdout}\n${invalidFilterAnalysis.stderr}',
          contains('ComparisonQuery'),
        );

        await File(
          '${lib.path}${Platform.pathSeparator}invalid_transaction.dart',
        ).writeAsString('''
import 'package:dorm_bloc_database/dorm_bloc_database.dart' as dorm_bloc;
import 'package:dorm_framework/dorm_framework.dart';

import 'models.dart';

TransactionalDorm<dorm_bloc.Query, OffsetPageRequest> invalidTransaction() {
  final BaseEngine<dorm_bloc.Query, OffsetPageRequest> engine =
      dorm_bloc.Engine();
  return TransactionalDorm(engine);
}
''');
        final ProcessResult invalidTransactionAnalysis = await _runDart(
          project,
          ['analyze'],
        );
        expect(invalidTransactionAnalysis.exitCode, isNot(0));
        expect(
          '${invalidTransactionAnalysis.stdout}\n'
          '${invalidTransactionAnalysis.stderr}',
          contains('TransactionalEngine'),
        );

        await File(
          '${lib.path}${Platform.pathSeparator}invalid_cursor_page.dart',
        ).writeAsString('''
import 'package:dorm_framework/dorm_framework.dart';
import 'package:dorm_bloc_database/dorm_bloc_database.dart' as dorm_bloc;

import 'models.dart';

Future<Page<User>> readCursor(
  Dorm<dorm_bloc.Query, OffsetPageRequest> dorm,
) {
  return dorm.users.repository.peekPage(
    const BaseFilter.empty(),
    const CursorPageRequest(size: 1),
  );
}
''');
        final ProcessResult invalidPageAnalysis = await _runDart(project, [
          'analyze',
        ]);
        expect(invalidPageAnalysis.exitCode, isNot(0));
        expect(
          '${invalidPageAnalysis.stdout}\n${invalidPageAnalysis.stderr}',
          contains('CursorPageRequest'),
        );

        await File(
          '${lib.path}${Platform.pathSeparator}invalid_identity_generator.dart',
        ).writeAsString('''
import 'package:dorm_annotations/dorm_annotations.dart';

part 'invalid_identity_generator.dorm.dart';

@Model(name: 'invalid-users')
abstract class _InvalidUser {
  String \$dorm\$generateId(_InvalidUser model, String generatedId) {
    return generatedId;
  }

  @Field()
  String get name;
}
''');
        final ProcessResult invalidGeneratorBuild = await _runDart(project, [
          'run',
          'build_runner',
          'build',
        ]);
        expect(invalidGeneratorBuild.exitCode, isNot(0));
        expect(
          '${invalidGeneratorBuild.stdout}\n${invalidGeneratorBuild.stderr}',
          contains('must be static'),
        );

        await File(
          '${lib.path}${Platform.pathSeparator}invalid_derived.dart',
        ).writeAsString('''
import 'package:dorm_annotations/dorm_annotations.dart';

part 'invalid_derived.dorm.dart';

@Model(name: 'invalid-derived')
abstract class _InvalidDerived {
  @Field()
  String get name;

  @DerivedField(name: 'search-name')
  static String \$dorm\$derived\$searchName(_InvalidDerived model, Object _) {
    return model.name;
  }
}
''');
        final ProcessResult invalidDerivedBuild = await _runDart(project, [
          'run',
          'build_runner',
          'build',
        ]);
        expect(invalidDerivedBuild.exitCode, isNot(0));
        expect(
          '${invalidDerivedBuild.stdout}\n${invalidDerivedBuild.stderr}',
          contains('DerivedTransformations'),
        );
      } finally {
        await project.delete(recursive: true);
      }
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
