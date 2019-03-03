// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'src/test_annotation.dart';

class TestGenerator extends GeneratorForAnnotation<TestAnnotation> {
  final bool requireTestClassPrefix;
  final bool alwaysThrowVagueError;

  const TestGenerator({
    bool requireTestClassPrefix = true,
    bool alwaysThrowVagueError = false,
  })  : alwaysThrowVagueError = alwaysThrowVagueError ?? false,
        requireTestClassPrefix = requireTestClassPrefix ?? true;

  @override
  Iterable<String> generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) sync* {
    if (alwaysThrowVagueError) {
      throw InvalidGenerationSourceError('Uh...');
    }

    if (element.name.contains('Bad')) {
      log.info('This member might be not good.');
    }

    if (element is! ClassElement) {
      throw InvalidGenerationSourceError(
        'Only supports annotated classes.',
        todo: 'Remove `TestAnnotation` from the associated element.',
        element: element,
      );
    }

    if (requireTestClassPrefix && !element.name.startsWith('TestClass')) {
      throw InvalidGenerationSourceError(
        'All classes must start with `TestClass`.',
        todo: 'Rename the type or remove the `TestAnnotation` from class.',
        element: element,
      );
    }

    yield 'const ${element.name}NameLength = ${element.name.length};';
    yield 'const ${element.name}NameLowerCase = ${element.name.toLowerCase()};';
  }

  @override
  String toString() =>
      'TestGenerator (requireTestClassPrefix:$requireTestClassPrefix)';
}
