// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: comment_references
// Note: Should be importing the below libs instead, but we are avoiding imports
// in this file to speed up analyzer parsing!
// import 'package:source_gen/source_gen.dart';
// import 'test_annotated_classes.dart';

/// Non-public, implementation base class of  [ShouldGenerate] and
/// [ShouldThrow].
abstract class TestExpectation {
  final Iterable<String> configurations;
  final List<String> expectedLogItems;

  const TestExpectation._(this.configurations, List<String> expectedLogItems)
      : expectedLogItems = expectedLogItems ?? const [];

  TestExpectation replaceConfiguration(Iterable<String> newConfiguration);
}

/// Specifies the expected output for code generation on the annotated member.
///
/// Must be used with [testAnnotatedElements].
class ShouldGenerate extends TestExpectation {
  final String expectedOutput;
  final bool contains;

  const ShouldGenerate(
    this.expectedOutput, {
    this.contains = false,
    Iterable<String> configurations,
    List<String> expectedLogItems,
  }) : super._(configurations, expectedLogItems);

  @override
  TestExpectation replaceConfiguration(Iterable<String> newConfiguration) {
    assert(newConfiguration != null);
    return ShouldGenerate(
      expectedOutput,
      contains: contains,
      configurations: newConfiguration,
      expectedLogItems: expectedLogItems,
    );
  }
}

/// Specifies that an [InvalidGenerationSourceError] is expected to be thrown
/// when running generation for the annotated member.
///
/// Must be used with [testAnnotatedElements].
class ShouldThrow extends TestExpectation {
  final String errorMessage;
  final String todo;

  /// Defaults to `true`.
  final bool elementShouldMatchAnnotated;

  const ShouldThrow(
    this.errorMessage, {
    this.todo,
    bool elementShouldMatchAnnotated = true,
    Iterable<String> configurations,
    List<String> expectedLogItems,
  })  : elementShouldMatchAnnotated = elementShouldMatchAnnotated ?? true,
        super._(configurations, expectedLogItems);

  @override
  TestExpectation replaceConfiguration(Iterable<String> newConfiguration) {
    assert(newConfiguration != null);
    return ShouldThrow(
      errorMessage,
      todo: todo,
      configurations: newConfiguration,
      expectedLogItems: expectedLogItems,
    );
  }
}
