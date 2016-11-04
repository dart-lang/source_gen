// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/src/builder/build_step.dart';
import 'package:source_gen/src/incremental_generator.dart';

/// Generates a single-line comment incrementally that looks like `// count 5`
class MyIncrementalGenerator extends IncrementalGenerator {
  const MyIncrementalGenerator(this.count);

  final int count;

  @override
  Future<String> generateForLibraryElement(
      LibraryElement library, BuildStep buildStep) async {
    final genPartCU =
        library.units.firstWhere((u) => u.source.uri.path.endsWith('.g.dart'));

    final linePrefix = '// count ';

    String content;
    try {
      content = library.context.getContents(genPartCU.source).data;
    } on StateError {
      content = linePrefix + '0';
    }

    final lastLine =
        LineSplitter.split(content).lastWhere((l) => l.startsWith(linePrefix));
    final num = int.parse(lastLine.substring(linePrefix.length));
    return linePrefix + '${min(num + 1, count)}';
  }

  String toString() => 'MyIncrementalGenerator';
}
