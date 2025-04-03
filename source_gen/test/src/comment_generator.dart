// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element2.dart';
import 'package:source_gen/source_gen.dart';

/// Generates a single-line comment for each class
class CommentGenerator extends Generator {
  final bool forClasses, forLibrary;

  const CommentGenerator({this.forClasses = true, this.forLibrary = false});

  @override
  Future<String> generate(LibraryReader library, _) async {
    final output = <String>[];
    if (forLibrary) {
      var name = library.element.name3!;
      if (name.isEmpty) {
        name = library.element.uri.pathSegments.last;
      }
      output.add('// Code for "$name"');
    }
    if (forClasses) {
      for (var classElement in library.allElements.whereType<ClassElement2>()) {
        if (classElement.displayName.contains('GoodError')) {
          throw InvalidGenerationSourceError.v2(
            "Don't use classes with the word 'Error' in the name",
            todo: 'Rename ${classElement.displayName} to something else.',
            element: classElement,
          );
        }
        output.add('// Code for "$classElement"');
      }
    }
    return output.join('\n');
  }
}

// Runs for anything annotated as deprecated
class DeprecatedGeneratorForAnnotation
    extends GeneratorForAnnotation<Deprecated> {
  @override
  String generateForAnnotatedElement(Element2 element, _, __) =>
      '// "$element" is deprecated!';
}
