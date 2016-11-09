// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:build/build.dart';
import 'package:path/path.dart' as path;

import 'generator.dart';

/// A generator that will try to generate recursively until 2 consecutive
/// generations output the same result.
abstract class IncrementalGenerator extends Generator {
  final int maxIterations;

  const IncrementalGenerator({this.maxIterations: 1000});

  Future<String> generateForLibraryElement(
      LibraryElement library, BuildStep buildStep);

  @override
  Future<String> generate(Element element, BuildStep buildStep) async {
    if (element is! LibraryElement) return null;
    final lib = element as LibraryElement;
    final generatedPart = getGeneratedPart(lib);

    if (generatedPart == null) return null;

    // back up the initial content of the part to restore at the end
    String genContent, initialContent;
    try {
      initialContent = lib.context.getContents(generatedPart.source).data;
      genContent = initialContent;
    } on StateError {
      genContent = '';
    }

    // generate content several times until 2 consecutive contents are equals
    int iterationsLeft = maxIterations;
    while (true) {
      if (iterationsLeft-- < 0)
        throw new StateError(
            'No stable content after $maxIterations generations');

      final nextGenContent = await generateForLibraryElement(lib, buildStep);

      // exit if stable
      if (nextGenContent == genContent) break;

      genContent = nextGenContent;

      // next increment : add current genContent to initial content
      lib.context.applyChanges(
          new ChangeSet()..changedContent(generatedPart.source, genContent));
    }

    // reset part to its initial content
    lib.context.applyChanges(initialContent == null
        ? (new ChangeSet()..removedSource(generatedPart.source))
        : (new ChangeSet()
          ..changedContent(generatedPart.source, initialContent)));

    return genContent;
  }

  CompilationUnitElement getGeneratedPart(LibraryElement lib) {
    final genPartName = _getGeneratedPartName(lib);
    final genPartPath = path
        .normalize(path.join(path.dirname(lib.source.uri.path), genPartName));
    return lib.units.firstWhere((u) => u.source.uri.path == genPartPath,
        orElse: () => null);
  }

  /// Returns the file name of the generated part
  String _getGeneratedPartName(LibraryElement lib) {
    final name = lib.source.shortName;
    return name.substring(0, name.length - '.dart'.length) + '.g.dart';
  }
}
