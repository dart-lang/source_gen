// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Non-public, implementation base class of  [ShouldGenerate] and
/// [ShouldThrow].
abstract class TestExpectation {
  final Iterable<String> configurations;
  final List<String> expectedLogItems;

  const TestExpectation._(this.configurations, List<String> expectedLogItems)
      : expectedLogItems = expectedLogItems ?? const [];

  TestExpectation replaceConfiguration(Iterable<String> newConfiguration);
}

const defaultConfigurationName = 'default';

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

class ShouldThrow extends TestExpectation {
  final String errorMessage;
  final String todo;

  const ShouldThrow(
    this.errorMessage, {
    this.todo,
    Iterable<String> configurations,
    List<String> expectedLogItems,
  }) : super._(configurations, expectedLogItems);

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
