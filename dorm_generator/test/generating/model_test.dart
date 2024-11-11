import 'dart:io';

import 'package:dorm_annotations/dorm_annotations.dart';
import 'package:dorm_generator/src/generator.dart';
import 'package:dorm_generator/src/utils/custom_types.dart';
import 'package:dorm_generator/src/utils/orm_node.dart';
import 'package:dorm_generator/src/visitors.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

const OrmCodeProvider provider = OrmCodeProvider();

void testSuccess(String name, String filename, ParsingContext context) {
  test(name, () async {
    final File file = File(
      p.join(Directory.current.path, 'test', 'generating', 'tests', filename),
    );
    final String actualText = provider.provide(context);
    final String expectedText = await file.readAsString();
    print(actualText);
    expect(actualText, expectedText);
  });
}

void testFailure(String name, ParsingContext context, DormError error) {
  test(name, () async {
    expect(
      () => provider.provide(context),
      throwsA(
        isA<DormError>()
            .having((e) => e.summary, 'summary', error.summary)
            .having((e) => e.description, 'description', error.description)
            .having((e) => e.hint, 'hint', error.hint)
            .having((e) => e.exampleCode, 'exampleCode',
                orderedEquals(error.exampleCode)),
      ),
    );
  });
}

void main() {
  group('Model', () {
    testSuccess(
      '[success] no arguments',
      'model.txt',
      ParsingContext(
        polymorphicGroups: {},
        monomorphicNodes: {
          '_User': ModelOrmNode(
            annotation: Model(),
            fields: {},
          ),
        },
      ),
    );
    testSuccess(
      '[success] with name',
      'model-name.txt',
      ParsingContext(
        polymorphicGroups: {},
        monomorphicNodes: {
          '_User': ModelOrmNode(
            annotation: Model(name: '___user'),
            fields: {},
          ),
        },
      ),
    );
    testSuccess(
      '[success] with primaryKeyGenerator',
      'model-primary_key_generator.txt',
      ParsingContext(
        polymorphicGroups: {},
        monomorphicNodes: {
          '_User': ModelOrmNode(
            annotation: Model(primaryKeyGenerator: (_, __) => '_onGenerateUid'),
            fields: {},
          ),
        },
      ),
    );
    testSuccess(
      '[success] with as',
      'model-as.txt',
      ParsingContext(
        polymorphicGroups: {},
        monomorphicNodes: {
          '_User': ModelOrmNode(
            annotation: Model(as: $Symbol.of('___users')),
            fields: {},
          ),
        },
      ),
    );
    testFailure(
      'invalid primaryKeyGenerator',
      ParsingContext(
        polymorphicGroups: {},
        monomorphicNodes: {
          '_User': ModelOrmNode(
            annotation: Model(
              name: '___user',
              primaryKeyGenerator: _foo,
            ),
            fields: {},
          ),
        },
      ),
      DormError(
        summary: 'Invalid primary key generator function signature.',
        description: 'The class _User annotated with @Model() references a '
            'function with an incorrect signature: Closure: (int, String) => int '
            'from Function \'_foo@20402049\': static.. The primary key generator '
            'function must accept exactly two parameters: the abstract class '
            'being annotated (_User) and a String with a fresh ID, and it should '
            'return a String representing the generated primary key.',
        hint: 'Update the function signature to match the required format.',
        exampleCode: [
          'static String _yourFunction(_User model, String id) {',
          '  // TODO Implementation here',
          '}',
        ],
      ),
    );
  });
}

int _foo(int foo, String bar) => 2;
