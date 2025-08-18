// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:source_span/source_span.dart';

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

  /// The `Element2` associated with this error, if any.
  final Element? element;

  /// The [ElementDirective] associated with this error, if any.
  final ElementDirective? elementDirective;

  /// The [AstNode] associated with this error, if any.
  final AstNode? node;

  /// The [Fragment] associated with this error, if any.
  final Fragment? fragment;

  InvalidGenerationSource(
    this.message, {
    this.todo = '',
    this.element,
    this.elementDirective,
    this.fragment,
    this.node,
  });

  @override
  String toString() {
    final buffer = StringBuffer(message);

    // If possible render a span, if a span can't be computed show any cause
    // object.
    SourceSpan? span;
    Object? cause;

    if (element case final element?) {
      try {
        span = spanForElement(element);
      } catch (_) {
        cause = element;
      }
    }

    if (elementDirective case final elementDirective?) {
      try {
        span = spanForElementDirective(elementDirective);
      } catch (_) {
        cause = elementDirective;
      }
    }

    if (span == null) {
      if (node case final node?) {
        try {
          span = spanForNode(node);
        } catch (_) {
          cause = node;
        }
      }
    }

    if (span == null) {
      if (fragment case final fragment?) {
        try {
          span = spanForFragment(fragment);
        } catch (_) {
          cause = fragment;
        }
      }
    }

    if (span != null) {
      buffer
        ..writeln()
        ..writeln(span.start.toolString)
        ..write(span.highlight());
    } else if (cause != null) {
      buffer
        ..writeln()
        ..writeln('Cause: $cause');
    }

    return buffer.toString();
  }
}
