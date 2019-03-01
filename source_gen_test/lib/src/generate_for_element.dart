// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: implementation_imports

import 'dart:async';

import 'package:analyzer/src/dart/element/element.dart';
import 'package:dart_style/dart_style.dart' as dart_style;
import 'package:source_gen/source_gen.dart';

final _formatter = dart_style.DartFormatter();

Future<String> generateForElement(
  GeneratorForAnnotation generator,
  LibraryReader libraryReader,
  String name,
) async {
  final element = libraryReader.allElements.singleWhere(
    (e) => e is! ConstVariableElement && e.name == name,
    orElse: () => null,
  );

  if (element == null) {
    throw ArgumentError.value(
        name, 'name', 'Could not find an element with name `$name`.');
  }
  final annotation = generator.typeChecker.firstAnnotationOf(element);

  final generatedStream = generator.generateForAnnotatedElementStream(
      element, ConstantReader(annotation), null);

  final generated = await generatedStream.join('\n\n');

  return _formatter.format(generated);
}
