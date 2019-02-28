// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';

import 'constants/reader.dart';
import 'generator.dart';
import 'library.dart';
import 'output_helpers.dart';
import 'type_checker.dart';

/// Extend this type to create a [Generator] that invokes
/// [generateForAnnotatedElement] for every element in the source file annotated
/// with [T].
///
/// When all annotated elements have been processed, the results will be
/// combined into a single output with duplicate items collapsed.
///
/// For example, this will allow code generated for all elements which are
/// annotated with `@Deprecated`:
///
/// ```dart
/// class DeprecatedGenerator extends GeneratorForAnnotation<Deprecated> {
///   @override
///   Future<String> generateForAnnotatedElement(
///       Element element,
///       ConstantReader annotation,
///       BuildStep buildStep) async {
///     // Return a string representing the code to emit.
///   }
/// }
/// ```
///
/// Note: this class should only be extended, not implemented. Subclasses should
/// provide an implementation for [generateForAnnotatedElement] and avoid
/// overriding the other members.
abstract class GeneratorForAnnotation<T> extends Generator {
  const GeneratorForAnnotation();

  TypeChecker get typeChecker => TypeChecker.fromRuntime(T);

  @override
  FutureOr<String> generate(LibraryReader library, BuildStep buildStep) async {
    final values = Set<String>();

    for (var annotatedElement in library.annotatedWith(typeChecker)) {
      await for (var value in generateForAnnotatedElementStream(
          annotatedElement.element, annotatedElement.annotation, buildStep)) {
        assert(value == null || (value.length == value.trim().length));
        values.add(value);
      }
    }

    return values.join('\n\n');
  }

  /// Normalizes the value returned by [generateForAnnotatedElement].
  ///
  /// See [generateForAnnotatedElement] for details on the parameters.
  Stream<String> generateForAnnotatedElementStream(
          Element element, ConstantReader annotation, BuildStep buildStep) =>
      normalizeGeneratorOutput(
          generateForAnnotatedElement(element, annotation, buildStep));

  /// Implement to return source code to generate for [element].
  ///
  /// This method is invoked based on finding elements annotated with an
  /// instance of [T]. The [annotation] is provided as a [ConstantReader].
  ///
  /// Supported return values include a single [String] or multiple [String]
  /// instances within an [Iterable] or [Stream]. It is also valid to return a
  /// [Future] of [String], [Iterable], or [Stream].
  ///
  /// Implementations should return `null` when no content is generated. Empty
  /// or whitespace-only [String] instances are also ignored.
  dynamic generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep);
}
