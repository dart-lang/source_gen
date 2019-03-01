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
  group('bad code', () {
    test('thing', () async {
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
          'There are multiple annotations configured for "c" for '
              'element `TestClass`.',
          'Ensure each configuration is only represented once per member.',
        ),
      );
    });

    test('thing', () async {
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
          '`configuration`cannot be empty.',
          'Leave it `null`.',
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
        'Rename the type or remove the `TestAnnotation` from class.',
      ),
    );
  });

  group('testAnnotatedClasses integration test', () {
    initializeBuildLogTracking();
    testAnnotatedElements(
      reader,
      const TestGenerator(),
      additionalGenerators: const {
        'no-prefix-required': TestGenerator(requireTestClassPrefix: false),
      },
      expectedAnnotatedTests: [
        'TestClass1',
        'TestClass2',
        'BadTestClass',
        'BadTestClass',
        'badTestFunc',
      ],
    );
  });

  group('testAnnotatedElements', () {
    group('test counts', () {
      test('valid configuration', () {
        final list = getAnnotatedClasses(
          reader,
          const TestGenerator(),
          additionalGenerators: const {
            'no-prefix-required': TestGenerator(requireTestClassPrefix: false),
          },
          expectedAnnotatedTests: [
            'TestClass1',
            'TestClass2',
            'BadTestClass',
            'BadTestClass',
            'badTestFunc',
          ],
          defaultConfiguration: ['default', 'no-prefix-required'],
        );

        expect(list, hasLength(8));
      });

      test('valid configuration', () {
        final list = getAnnotatedClasses(
          reader,
          const TestGenerator(),
          additionalGenerators: const {
            'no-prefix-required': TestGenerator(requireTestClassPrefix: false),
          },
          expectedAnnotatedTests: [
            'TestClass1',
            'TestClass2',
            'BadTestClass',
            'BadTestClass',
            'badTestFunc',
          ],
          defaultConfiguration: null,
        );

        expect(list, hasLength(8));
      });

      test('valid configuration', () {
        final list = getAnnotatedClasses(
          reader,
          const TestGenerator(),
          additionalGenerators: const {
            'no-prefix-required': TestGenerator(requireTestClassPrefix: false),
          },
          expectedAnnotatedTests: [
            'TestClass1',
            'TestClass2',
            'BadTestClass',
            'BadTestClass',
            'badTestFunc',
          ],
          defaultConfiguration: ['default'],
        );

        expect(list, hasLength(6));
      });

      test('valid configuration', () {
        final list = getAnnotatedClasses(
          reader,
          const TestGenerator(),
          additionalGenerators: const {
            'no-prefix-required': TestGenerator(requireTestClassPrefix: false),
          },
          expectedAnnotatedTests: [
            'TestClass1',
            'TestClass2',
            'BadTestClass',
            'BadTestClass',
            'badTestFunc',
          ],
          defaultConfiguration: ['no-prefix-required'],
        );

        expect(list, hasLength(6));
      });
    });
    group('defaultConfiguration', () {
      test('empty', () {
        expect(
          () => testAnnotatedElements(
                reader,
                const TestGenerator(),
                additionalGenerators: const {
                  'no-prefix-required':
                      TestGenerator(requireTestClassPrefix: false),
                },
                shouldThrowDefaults: [],
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
                shouldThrowDefaults: ['unknown'],
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
            'There are unexpected items.',
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
            'There are items missing.',
            'expectedAnnotatedTests',
          ),
        );
      });
    });

    group('additionalGenerators', () {
      test('missing a specified generator fails', () {
        expect(
          () => testAnnotatedElements(
                reader,
                const TestGenerator(),
              ),
          _throwsArgumentError(
              'The "no-prefix-required" configuration was specified for the '
              '`TestClass1` element, but no there is no associated generator.',
              'additionalGenerators'),
        );
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

Matcher _throwsArgumentError(matcher, String name) => throwsA(
      isArgumentError
          .having((e) => e.message, 'message', matcher)
          .having((ae) => ae.name, 'name', name),
    );
