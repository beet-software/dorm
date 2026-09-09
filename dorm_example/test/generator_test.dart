import 'dart:io';

import 'package:dorm_example/dorm_example.dart';
import 'package:test/test.dart';

void main() {
  group('ExampleProfiles', () {
    test('lists every supported engine', () {
      expect(
        ExampleProfiles.all.map((profile) => profile.name),
        containsAll(<String>[
          'memory',
          'bloc',
          'firebase',
          'firestore',
          'http',
          'postgres',
          'mysql',
          'mongo',
          'sqlite',
        ]),
      );
    });

    test('rejects unknown engines', () {
      expect(() => ExampleProfiles.byName('unknown'), throwsArgumentError);
    });
  });

  group('ExampleGenerator', () {
    late Directory temporaryDirectory;

    setUp(() async {
      temporaryDirectory = await Directory.systemTemp.createTemp(
        'dorm_example_',
      );
    });

    tearDown(() async {
      if (temporaryDirectory.existsSync()) {
        await temporaryDirectory.delete(recursive: true);
      }
    });

    test('generates the portable Flutter profile', () async {
      final Directory output = Directory(
        '${temporaryDirectory.path}${Platform.pathSeparator}memory_app',
      );
      await ExampleGenerator().generate(
        ExampleProfiles.byName('memory'),
        output,
        projectName: 'memory_app',
      );

      expect(File('${output.path}/pubspec.yaml').existsSync(), isTrue);
      expect(File('${output.path}/.gitignore').existsSync(), isTrue);
      expect(File('${output.path}/lib/models.dart').existsSync(), isTrue);
      expect(File('${output.path}/lib/main.dart').existsSync(), isTrue);
      expect(File('${output.path}/web/index.html').existsSync(), isTrue);
      expect(File('${output.path}/bin/main.dart').existsSync(), isFalse);
      expect(
        File('${output.path}/lib/models.dart').readAsStringSync(),
        contains('@DerivedField'),
      );
    });

    test('keeps SQL profiles relational and adds Docker setup', () async {
      final Directory output = Directory(
        '${temporaryDirectory.path}${Platform.pathSeparator}postgres_app',
      );
      await ExampleGenerator().generate(
        ExampleProfiles.byName('postgres'),
        output,
        projectName: 'postgres_app',
      );

      final String models = File(
        '${output.path}/lib/models.dart',
      ).readAsStringSync();
      expect(models, isNot(contains('@DerivedField')));
      expect(models, isNot(contains('@ModelField')));
      expect(models, isNot(contains('@PolymorphicField')));
      expect(File('${output.path}/docker-compose.yml').existsSync(), isTrue);
      expect(File('${output.path}/.env.example').existsSync(), isTrue);
      expect(File('${output.path}/sql/schema.sql').existsSync(), isTrue);
      expect(File('${output.path}/lib/main.dart').existsSync(), isFalse);
      expect(File('${output.path}/bin/main.dart').existsSync(), isTrue);
      expect(File('${output.path}/.gitignore').existsSync(), isTrue);
    });

    test('does not overwrite a non-empty output directory', () async {
      final Directory output = Directory(
        '${temporaryDirectory.path}${Platform.pathSeparator}existing',
      )..createSync();
      File('${output.path}/keep.txt').writeAsStringSync('keep');

      expect(
        () => ExampleGenerator().generate(
          ExampleProfiles.byName('memory'),
          output,
          projectName: 'existing',
        ),
        throwsStateError,
      );
      expect(File('${output.path}/keep.txt').readAsStringSync(), 'keep');
    });

    test('uses Docker only for service-backed profiles', () {
      expect(ExampleProfiles.byName('postgres').docker, isTrue);
      expect(ExampleProfiles.byName('mongo').docker, isTrue);
      expect(ExampleProfiles.byName('firebase').docker, isTrue);
      expect(ExampleProfiles.byName('firestore').docker, isTrue);
      expect(ExampleProfiles.byName('http').docker, isTrue);
      expect(ExampleProfiles.byName('memory').docker, isFalse);
      expect(ExampleProfiles.byName('sqlite').docker, isFalse);
    });

    test('generates local Firebase emulator profiles', () async {
      for (final String engine in <String>['firebase', 'firestore']) {
        final String name = '${engine}_app';
        final Directory output = Directory(
          '${temporaryDirectory.path}${Platform.pathSeparator}$name',
        );
        await ExampleGenerator().generate(
          ExampleProfiles.byName(engine),
          output,
          projectName: name,
        );

        final String compose = File(
          '${output.path}/docker-compose.yml',
        ).readAsStringSync();
        final String options = File(
          '${output.path}/lib/firebase_options.dart',
        ).readAsStringSync();
        final String main = File(
          '${output.path}/lib/main.dart',
        ).readAsStringSync();
        expect(compose, contains('spine3/firebase-emulator:latest'));
        expect(compose, contains("'9000:9000'"));
        expect(compose, contains("'8080:8080'"));
        expect(compose, contains("'4000:4000'"));
        expect(options, isNot(contains('UnsupportedError')));
        expect(
          main,
          contains(
            engine == 'firebase'
                ? 'useDatabaseEmulator'
                : 'useFirestoreEmulator',
          ),
        );
        expect(File('${output.path}/.env.example').existsSync(), isFalse);
      }
    });

    test('generates the local HTTP server profile', () async {
      const String name = 'http_app';
      final Directory output = Directory(
        '${temporaryDirectory.path}${Platform.pathSeparator}$name',
      );
      await ExampleGenerator().generate(
        ExampleProfiles.byName('http'),
        output,
        projectName: name,
      );

      final String compose = File(
        '${output.path}/docker-compose.yml',
      ).readAsStringSync();
      final String main = File(
        '${output.path}/lib/main.dart',
      ).readAsStringSync();
      expect(compose, contains('http-api:'));
      expect(compose, contains('build: ./server'));
      expect(File('${output.path}/server/pubspec.yaml').existsSync(), isTrue);
      expect(File('${output.path}/server/Dockerfile').existsSync(), isTrue);
      expect(File('${output.path}/server/bin/main.dart').existsSync(), isTrue);
      expect(main, contains('http://localhost:8080/api/'));
    });

    test('uses the rendered schema for SQLite setup', () async {
      const String name = 'sqlite_app';
      final Directory output = Directory(
        '${temporaryDirectory.path}${Platform.pathSeparator}$name',
      );
      await ExampleGenerator().generate(
        ExampleProfiles.byName('sqlite'),
        output,
        projectName: name,
      );

      final String main = File(
        '${output.path}/bin/main.dart',
      ).readAsStringSync();
      expect(main, contains("File('sql/schema.sql')"));
      expect(main, contains('executeMultiple(schema)'));
      expect(main, isNot(contains('CREATE TABLE')));
    });

    test(
      'does not require a manually declared polymorphic type getter',
      () async {
        const String name = 'memory_models_app';
        final Directory output = Directory(
          '${temporaryDirectory.path}${Platform.pathSeparator}$name',
        );
        await ExampleGenerator().generate(
          ExampleProfiles.byName('memory'),
          output,
          projectName: name,
        );

        final String models = File(
          '${output.path}/lib/models.dart',
        ).readAsStringSync();
        expect(models, isNot(contains('ReviewContentType get type')));
      },
    );

    test('renders every profile without unresolved template tags', () async {
      for (final ExampleProfile profile in ExampleProfiles.all) {
        final String name = '${profile.name}_app';
        final Directory output = Directory(
          '${temporaryDirectory.path}${Platform.pathSeparator}$name',
        );
        await ExampleGenerator().generate(profile, output, projectName: name);

        final String models = File(
          '${output.path}/lib/models.dart',
        ).readAsStringSync();
        expect(models, isNot(contains('{{')));
        expect(
          File('${output.path}/pubspec.yaml').readAsStringSync(),
          isNot(contains('{{')),
        );
        expect(
          File(
            '${output.path}${Platform.pathSeparator}${profile.isFlutter ? 'lib/main.dart' : 'bin/main.dart'}',
          ).existsSync(),
          isTrue,
        );
      }
    });
  });
}
