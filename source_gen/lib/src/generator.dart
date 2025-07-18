// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:build/build.dart';

import 'library.dart';
import 'span_for_element.dart';

/// A tool to generate Dart code based on a Dart library source.
///
/// During a build [generate] is called once per input library.
abstract class Generator {
  const Generator();

  /// Generates Dart code for an input Dart library.
  ///
  /// May create additional outputs through the `buildStep`, but the 'primary'
  /// output is Dart code returned through the Future. If there is nothing to
  /// generate for this library may return null, or a Future that resolves to
  /// null or the empty string.
  FutureOr<String?> generate(LibraryReader library, BuildStep buildStep) =>
      null;

  @override
  String toString() => runtimeType.toString();
}

typedef InvalidGenerationSourceError = InvalidGenerationSource;

/// A description of a problem in the source input to code generation.
///
/// May be thrown by generators during [Generator.generate] to communicate a
/// problem to the codegen user.
class InvalidGenerationSource implements Exception {
  /// What failure occurred.
  final String message;

  /// What could have been changed in the source code to resolve this error.
  ///
  /// May be an empty string if unknown.
  final String todo;

  /// The code element associated with this error.
  ///
  /// May be `null` if the error had no associated element, or if the location
  /// was passed with [node].
  final Element2? element;

  /// The AST Node associated with this error.
  ///
  /// May be `null` if the error has no associated node in the input source
  /// code, or if the location was passed with [element].
  final AstNode? node;

  InvalidGenerationSource(
    this.message, {
    this.todo = '',
    this.element,
    this.node,
  });

  @override
  String toString() {
    final buffer = StringBuffer(message);

    if (element case final element?) {
      try {
        final span = spanForElement(element);
        buffer
          ..writeln()
          ..writeln(span.start.toolString)
          ..write(span.highlight());
      } catch (_) {
        // Source for `element` wasn't found, it must be in a summary with no
        // associated source. We can still give the name.
        buffer
          ..writeln()
          ..writeln('Cause: $element');
      }
    }

    if (node case final node?) {
      try {
        final span = spanForNode(node);
        buffer
          ..writeln()
          ..writeln(span.start.toolString)
          ..write(span.highlight());
      } catch (_) {
        buffer
          ..writeln()
          ..writeln('Cause: $node');
      }
    }

    return buffer.toString();
  }
}
