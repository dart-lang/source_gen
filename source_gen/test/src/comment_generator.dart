// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:source_gen/source_gen.dart';

/// Generates a single-line comment for each class
class CommentGenerator extends Generator {
  final bool forClasses, forLibrary;

  const CommentGenerator({this.forClasses = true, this.forLibrary = false});

  @override
  Future<String> generate(LibraryReader library, _) async {
    final output = <String>[];
    if (forLibrary) {
      var name = library.element.name!;
      if (name.isEmpty) {
        name = library.element.uri.pathSegments.last;
      }
      output.add('// Code for "$name"');
    }
    if (forClasses) {
      for (var classElement in library.classes) {
        if (classElement.displayName.contains('GoodError')) {
          throw InvalidGenerationSourceError(
            "Don't use classes with the word 'Error' in the name",
            todo: 'Rename ${classElement.displayName} to something else.',
            element: classElement,
          );
        }
        if (classElement.displayName.contains('FragmentError')) {
          throw InvalidGenerationSourceError(
            "Don't use classes with the word 'Error' in the name",
            todo: 'Rename ${classElement.displayName} to something else.',
            fragment: classElement.firstFragment,
          );
        }
        if (classElement.displayName.contains('ElementDirectiveError')) {
          throw InvalidGenerationSourceError(
            "Don't use classes with the word 'Error' in the name",
            todo: 'Rename ${classElement.displayName} to something else.',
            // No directive relates to the class, just throw with the first
            // export.
            elementDirective:
                classElement.library.firstFragment.libraryExports.first,
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
  String generateForAnnotatedElement(Element element, _, _) =>
      '// "$element" is deprecated!';
}
