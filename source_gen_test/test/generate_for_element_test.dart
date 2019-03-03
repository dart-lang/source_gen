// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:source_gen_test/src/build_log_tracking.dart';
import 'package:source_gen_test/src/generate_for_element.dart';
import 'package:source_gen_test/src/init_library_reader.dart';
import 'package:source_gen_test/src/matchers.dart';
import 'package:source_gen_test/src/test_annotated_classes.dart';
import 'package:test/test.dart';

import 'test_generator.dart';

const _testAnnotationContent = r'''
class TestAnnotation {
  const TestAnnotation();
}''';

void main() async {
  group('Bad annotations', () {
    test('duplicate configurations for the same member', () async {
      final badReader = await initializeLibraryReader({
        'bad_lib.dart': r"""
import 'package:source_gen_test/annotations.dart';
import 'annotations.dart';
@ShouldGenerate('', configurations: ['c'])
@ShouldGenerate('', configurations: ['c'])
@TestAnnotation()
class TestClass() {}
""",
        'annotations.dart': _testAnnotationContent,
      }, 'bad_lib.dart');

      expect(
        () => testAnnotatedElements(badReader, const TestGenerator()),
        throwsInvalidGenerationSourceError(
          'There are multiple annotations for these configurations: "c".',
          todoMatcher:
              'Ensure each configuration is only represented once per member.',
        ),
      );
    });

    test('annotation with no configuration', () async {
      final badReader = await initializeLibraryReader({
        'bad_lib.dart': r"""
import 'package:source_gen_test/annotations.dart';
import 'annotations.dart';
@ShouldGenerate('', configurations: [])
@TestAnnotation()
class EmptyConfig() {}
""",
        'annotations.dart': _testAnnotationContent,
      }, 'bad_lib.dart');

      expect(
        () => testAnnotatedElements(badReader, const TestGenerator()),
        throwsInvalidGenerationSourceError(
          '`configuration` cannot be empty.',
          todoMatcher: 'Leave it `null`.',
        ),
      );
    });
  });

  final reader = await initializeLibraryReaderForDirectory(
      'test/src', 'test_library.dart');

  group('generateForElement', () {
    test('TestClass1', () async {
      final output =
          await generateForElement(const TestGenerator(), reader, 'TestClass1');
      printOnFailure(output);
      expect(output, r'''
const TestClass1NameLength = 10;

const TestClass1NameLowerCase = testclass1;
''');
    });

    test('TestClass2', () async {
      final output =
          await generateForElement(const TestGenerator(), reader, 'TestClass2');
      printOnFailure(output);
      expect(output, r'''
const TestClass2NameLength = 10;

const TestClass2NameLowerCase = testclass2;
''');
    });
  });

  test('throwsInvalidGenerationSourceError', () async {
    await expectLater(
      () => generateForElement(const TestGenerator(), reader, 'BadTestClass'),
      throwsInvalidGenerationSourceError(
        'All classes must start with `TestClass`.',
        todoMatcher:
            'Rename the type or remove the `TestAnnotation` from class.',
      ),
    );
  });

  group('testAnnotatedElements', () {
    final validAdditionalGenerators = const {
      'no-prefix-required': TestGenerator(requireTestClassPrefix: false),
      'vague': TestGenerator(alwaysThrowVagueError: true),
    };

    final validExpectedAnnotatedTests = const [
      'BadTestClass',
      'BadTestClass',
      'BadTestClass',
      'badTestFunc',
      'badTestFunc',
      'TestClass1',
      'TestClass1',
      'TestClass2',
      'TestClass2',
      'TestClassWithBadMember',
    ];

    group('[integration tests]', () {
      initializeBuildLogTracking();
      testAnnotatedElements(
        reader,
        const TestGenerator(),
        additionalGenerators: validAdditionalGenerators,
        expectedAnnotatedTests: validExpectedAnnotatedTests,
      );
    });

    group('test counts', () {
      test('nul defaultConfiguration', () {
        final list = getAnnotatedClasses(
          reader,
          const TestGenerator(),
          additionalGenerators: validAdditionalGenerators,
          expectedAnnotatedTests: validExpectedAnnotatedTests,
          defaultConfiguration: null,
        );

        expect(list, hasLength(13));
      });

      test('valid configuration', () {
        final list = getAnnotatedClasses(
          reader,
          const TestGenerator(),
          additionalGenerators: validAdditionalGenerators,
          expectedAnnotatedTests: validExpectedAnnotatedTests,
          defaultConfiguration: ['default', 'no-prefix-required', 'vague'],
        );

        expect(list, hasLength(13));
      });

      test('different defaultConfiguration', () {
        final list = getAnnotatedClasses(
          reader,
          const TestGenerator(),
          additionalGenerators: validAdditionalGenerators,
          expectedAnnotatedTests: validExpectedAnnotatedTests,
          defaultConfiguration: ['default'],
        );

        expect(list, hasLength(11));
      });

      test('different defaultConfiguration', () {
        final list = getAnnotatedClasses(
          reader,
          const TestGenerator(),
          additionalGenerators: validAdditionalGenerators,
          expectedAnnotatedTests: validExpectedAnnotatedTests,
          defaultConfiguration: ['no-prefix-required'],
        );

        expect(list, hasLength(11));
      });
    });
    group('defaultConfiguration', () {
      test('empty', () {
        expect(
          () => testAnnotatedElements(
                reader,
                const TestGenerator(),
                additionalGenerators: validAdditionalGenerators,
                defaultConfiguration: [],
              ),
          _throwsArgumentError(
            'Cannot be empty.',
            'defaultConfiguration',
          ),
        );
      });

      test('unknown item', () {
        expect(
          () => testAnnotatedElements(
                reader,
                const TestGenerator(),
                additionalGenerators: const {
                  'no-prefix-required':
                      TestGenerator(requireTestClassPrefix: false),
                },
                defaultConfiguration: ['unknown'],
              ),
          _throwsArgumentError(
            'Contains values not associated with provided generators: '
                '"unknown".',
            'defaultConfiguration',
          ),
        );
      });
    });

    group('expectedAnnotatedTests', () {
      test('too many', () {
        expect(
          () => testAnnotatedElements(
                reader,
                const TestGenerator(),
                expectedAnnotatedTests: [
                  'TestClass1',
                  'TestClass2',
                  'BadTestClass',
                  'extra'
                ],
              ),
          _throwsArgumentError(
            'There are unexpected items',
            'expectedAnnotatedTests',
          ),
        );
      });

      test('too few', () {
        expect(
          () => testAnnotatedElements(
                reader,
                const TestGenerator(),
                expectedAnnotatedTests: [
                  'TestClass1',
                  'TestClass2',
                ],
              ),
          _throwsArgumentError(
            'There are items missing',
            'expectedAnnotatedTests',
          ),
        );
      });
    });

    group('additionalGenerators', () {
      test('unused generator fails', () {
        expect(
          () => testAnnotatedElements(
                reader,
                const TestGenerator(),
                additionalGenerators: {'extra': const TestGenerator()}
                  ..addAll(validAdditionalGenerators),
                expectedAnnotatedTests: [
                  'TestClass1',
                  'TestClass2',
                  'BadTestClass',
                  'BadTestClass',
                  'badTestFunc',
                  'badTestFunc',
                ],
                // 'vague' is excluded here!
                defaultConfiguration: ['default', 'no-prefix-required'],
              ),
          _throwsArgumentError(
              'Some of the specified generators were not used for their '
              'corresponding configurations: "extra".\n'
              'Remove the entry from `additinalGenerators` or update '
              '`defaultConfiguration`.'),
        );
      });

      test('missing a specified generator fails', () {
        expect(
            () => testAnnotatedElements(
                  reader,
                  const TestGenerator(),
                ),
            _throwsArgumentError(
                'There are elements defined with configurations with no '
                'associated generator provided.\n'
                '`BadTestClass`: "no-prefix-required", "vague"; '
                '`TestClass1`: "no-prefix-required", "vague"; '
                '`TestClass2`: "vague"; '
                '`badTestFunc`: "vague"'));
      });

      test('key "default" not allowed', () {
        expect(
          () => testAnnotatedElements(
                reader,
                const TestGenerator(),
                additionalGenerators: const {
                  'default': TestGenerator(requireTestClassPrefix: false)
                },
              ),
          _throwsArgumentError(
            'Contained an unsupported key "default".',
            'additionalGenerators',
          ),
        );
      });

      test('key "" not allowed', () {
        expect(
          () => testAnnotatedElements(
                reader,
                const TestGenerator(),
                additionalGenerators: const {
                  '': TestGenerator(requireTestClassPrefix: false)
                },
              ),
          _throwsArgumentError(
            'Contained an unsupported key "".',
            'additionalGenerators',
          ),
        );
      });

      test('key `null` not allowed', () {
        expect(
          () => testAnnotatedElements(
                reader,
                const TestGenerator(),
                additionalGenerators: const {
                  null: TestGenerator(requireTestClassPrefix: false)
                },
              ),
          _throwsArgumentError(
            'Contained an unsupported key `null`.',
            'additionalGenerators',
          ),
        );
      });
    });
  });
}

Matcher _throwsArgumentError(matcher, [String name]) => throwsA(
      isArgumentError
          .having((e) => e.message, 'message', matcher)
          .having((ae) => ae.name, 'name', name),
    );
