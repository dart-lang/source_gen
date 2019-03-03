// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:source_gen/source_gen.dart';
import 'package:source_gen_test/source_gen_test.dart';

import 'annotations.dart';

List<_ExpectationElement> genAnnotatedElements(
        LibraryReader libraryReader, Set<String> configDefaults) =>
    libraryReader.allElements.expand((element) {
      // NOTE: toList is intentional here. Ensures the items are enumerated
      // only once
      final initialValues = _expectationElements(element).toList();

      final explicitConfigSet = Set<String>();

      for (var initialValue
          in initialValues.where((te) => te.configurations != null)) {
        if (initialValue.configurations.isEmpty) {
          throw InvalidGenerationSourceError(
            '`configuration` cannot be empty.',
            todo: 'Leave it `null`.',
            element: element,
          );
        }
        for (var config in initialValue.configurations) {
          if (!explicitConfigSet.add(config)) {
            throw InvalidGenerationSourceError(
              'There are multiple annotations configured for "$config" for '
                  'element `${element.name}`.',
              todo: 'Ensure each configuration is only represented once '
                  'per member.',
              element: element,
            );
          }
        }
      }

      return initialValues.map((te) {
        if (te.configurations == null) {
          final newConfigSet = configDefaults.difference(explicitConfigSet);
          // TODO: need testing and a "real" error here!
          assert(newConfigSet.isNotEmpty,
              '$element $configDefaults $explicitConfigSet');
          te = te.replaceConfiguration(newConfigSet);
        }
        assert(te.configurations.isNotEmpty);

        return _ExpectationElement._(te, element.name);
      });
    }).toList();

const _mappers = {
  TypeChecker.fromRuntime(ShouldGenerate): _shouldGenerate,
  TypeChecker.fromRuntime(ShouldThrow): _shouldThrow,
};

Iterable<TestExpectation> _expectationElements(Element element) sync* {
  for (var entry in _mappers.entries) {
    for (var annotation in entry.key.annotationsOf(element)) {
      yield entry.value(annotation);
    }
  }
}

class _ExpectationElement {
  final TestExpectation expectation;
  final String elementName;

  _ExpectationElement._(this.expectation, this.elementName)
      : assert(expectation != null),
        assert(elementName != null);
}

ShouldGenerate _shouldGenerate(DartObject obj) {
  final reader = ConstantReader(obj);
  return ShouldGenerate(
    reader.read('expectedOutput').stringValue,
    contains: reader.read('contains').boolValue,
    expectedLogItems: _expectedLogItems(reader),
    configurations: _configurations(reader),
  );
}

ShouldThrow _shouldThrow(DartObject obj) {
  final reader = ConstantReader(obj);
  return ShouldThrow(
    reader.read('errorMessage').stringValue,
    todo: reader.read('todo').literalValue as String,
    elementShouldMatchAnnotated:
        reader.read('elementShouldMatchAnnotated').literalValue as bool,
    expectedLogItems: _expectedLogItems(reader),
    configurations: _configurations(reader),
  );
}

List<String> _expectedLogItems(ConstantReader reader) => reader
    .read('expectedLogItems')
    .listValue
    .map((obj) => obj.toStringValue())
    .toList();

Set<String> _configurations(ConstantReader reader) {
  final field = reader.read('configurations');
  if (field.isNull) {
    return null;
  }

  return field.listValue.map((obj) => obj.toStringValue()).toSet();
}
