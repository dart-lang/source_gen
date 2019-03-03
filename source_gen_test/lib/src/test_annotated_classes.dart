// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';
import 'package:source_gen/source_gen.dart';
import 'package:source_gen_test/source_gen_test.dart';
import 'package:test/test.dart';

import 'annotations.dart';
import 'build_log_tracking.dart';
import 'expectation_element.dart';
import 'generate_for_element.dart';

const _defaultConfigurationName = 'default';

/// If [defaultConfiguration] is not provided or `null`, "default" and the keys
/// from [additionalGenerators] (if provided) are used.
///
/// Tests registered by this function assume [initializeBuildLogTracking] has
/// been called.
///
/// If [expectedAnnotatedTests] is provided, it should contain the names of the
/// members in [libraryReader] that are annotated for testing. If the same
/// element is annotated for multiple tests, it should appear in the list
/// the same number of times.
void testAnnotatedElements(
  LibraryReader libraryReader,
  GeneratorForAnnotation defaultGenerator, {
  Map<String, GeneratorForAnnotation> additionalGenerators,
  Iterable<String> expectedAnnotatedTests,
  Iterable<String> defaultConfiguration,
}) {
  for (var entry in getAnnotatedClasses(
    libraryReader,
    defaultGenerator,
    additionalGenerators: additionalGenerators,
    expectedAnnotatedTests: expectedAnnotatedTests,
    defaultConfiguration: defaultConfiguration,
  ).toList()) {
    entry._registerTest();
  }
}

/// An implementation member only exposed to make it easier to test
/// [testAnnotatedElements] without registering any tests.
@visibleForTesting
Iterable<_AnnotatedTest> getAnnotatedClasses(
  LibraryReader libraryReader,
  GeneratorForAnnotation defaultGenerator, {
  @required Map<String, GeneratorForAnnotation> additionalGenerators,
  @required Iterable<String> expectedAnnotatedTests,
  @required Iterable<String> defaultConfiguration,
}) sync* {
  final generators = {_defaultConfigurationName: defaultGenerator};
  if (additionalGenerators != null) {
    for (var invalidKey in const [_defaultConfigurationName, '']) {
      if (additionalGenerators.containsKey(invalidKey)) {
        throw ArgumentError.value(additionalGenerators, 'additionalGenerators',
            'Contained an unsupported key "$invalidKey".');
      }
    }
    if (additionalGenerators.containsKey(null)) {
      throw ArgumentError.value(additionalGenerators, 'additionalGenerators',
          'Contained an unsupported key `null`.');
    }
    generators.addAll(additionalGenerators);
  }

  Set<String> defaultConfigSet;

  if (defaultConfiguration != null) {
    defaultConfigSet = defaultConfiguration.toSet();
    if (defaultConfigSet.isEmpty) {
      throw ArgumentError.value(
        defaultConfiguration,
        'defaultConfiguration',
        'Cannot be empty.',
      );
    }

    final unknownShouldThrowDefaults =
        defaultConfigSet.where((v) => !generators.containsKey(v)).toSet();
    if (unknownShouldThrowDefaults.isNotEmpty) {
      throw ArgumentError.value(
        defaultConfiguration,
        'defaultConfiguration',
        'Contains values not associated with provided generators: '
            '${unknownShouldThrowDefaults.map((v) => '"$v"').join(', ')}.',
      );
    }
  } else {
    defaultConfigSet = generators.keys.toSet();
  }

  final annotatedElements =
      genAnnotatedElements(libraryReader, defaultConfigSet);

  final unusedConfigurations = generators.keys.toSet();
  for (var annotatedElement in annotatedElements) {
    unusedConfigurations.removeAll(annotatedElement.expectation.configurations);
  }
  if (unusedConfigurations.isNotEmpty) {
    throw ArgumentError(
      'Some of the specified generators were not used for their corresponding '
          'configurations: '
          '${unusedConfigurations.map((c) => '"$c"').join(', ')}.\n'
          'Remove the entry from `additinalGenerators` or update '
          '`defaultConfiguration`.',
    );
  }

  if (expectedAnnotatedTests != null) {
    final expectedList = expectedAnnotatedTests.toList();

    final missing = <String>[];

    for (var elementName in annotatedElements.map((e) => e.elementName)) {
      if (!expectedList.remove(elementName)) {
        missing.add(elementName);
      }
    }

    if (expectedList.isNotEmpty) {
      print('Extra items:\n${expectedList.map((s) => '  $s').join('\n')}');
      throw ArgumentError.value(expectedAnnotatedTests,
          'expectedAnnotatedTests', 'There are unexpected items.');
    }
    if (missing.isNotEmpty) {
      print('Missing items:\n${missing.map((s) => '  $s').join('\n')}');
      throw ArgumentError.value(
          missing, 'expectedAnnotatedTests', 'There are items missing.');
    }
  }

  for (final entry in annotatedElements) {
    for (var configuration in entry.expectation.configurations) {
      final generator = generators[configuration];

      if (generator == null) {
        throw ArgumentError.value(
          additionalGenerators,
          'additionalGenerators',
          'The "$configuration" configuration was specified for the '
              '`${entry.elementName}` element, but no there is no associated '
              'generator.',
        );
      }

      yield _AnnotatedTest._(
        libraryReader,
        generator,
        configuration,
        entry.elementName,
        entry.expectation,
      );
    }
  }
}

class _AnnotatedTest {
  final GeneratorForAnnotation generator;
  final String configuration;
  final LibraryReader _libraryReader;
  final TestExpectation expectation;
  final String _elementName;

  String get _testName {
    var value = _elementName;
    if (configuration != _defaultConfigurationName) {
      value += ' with configuration "$configuration"';
    }
    return value;
  }

  _AnnotatedTest._(
    this._libraryReader,
    this.generator,
    this.configuration,
    this._elementName,
    this.expectation,
  );

  void _registerTest() {
    if (expectation is ShouldGenerate) {
      test(_testName, _shouldGenerateTest);
      return;
    } else if (expectation is ShouldThrow) {
      test(_testName, _shouldThrowTest);
      return;
    }
    throw StateError('Should never get here.');
  }

  Future<String> _generate() =>
      generateForElement(generator, _libraryReader, _elementName);

  Future<Null> _shouldGenerateTest() async {
    final output = await _generate();
    final exp = expectation as ShouldGenerate;

    try {
      expect(
        output,
        exp.contains
            ? contains(exp.expectedOutput)
            : equals(exp.expectedOutput),
      );
    } on TestFailure {
      printOnFailure("ACTUAL CONTENT:\nr'''\n$output'''");
      rethrow;
    }

    expect(
      buildLogItems,
      exp.expectedLogItems,
      reason: 'The expected log items do not match.',
    );
    clearBuildLog();
  }

  Future<Null> _shouldThrowTest() async {
    final exp = expectation as ShouldThrow;
    final messageMatcher = exp.errorMessage;
    final todoMatcher = exp.todo ?? isEmpty;

    await expectLater(_generate,
        throwsInvalidGenerationSourceError(messageMatcher, todoMatcher));

    expect(
      buildLogItems,
      exp.expectedLogItems,
      reason: 'The expected log items do not match.',
    );
    clearBuildLog();
  }
}
