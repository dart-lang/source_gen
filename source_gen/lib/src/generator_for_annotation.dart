// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/dart/element/element2.dart';
import 'package:build/build.dart';

import 'constants/reader.dart';
import 'generator.dart';
import 'library.dart';
import 'output_helpers.dart';
import 'type_checker.dart';

/// Extend this type to create a [Generator] that invokes
/// [generateForAnnotatedElement] for every top level element in the source file
/// annotated with [T].
///
/// When all annotated elements have been processed, the results will be
/// combined into a single output with duplicate items collapsed.
///
/// For example, this will allow code generated for all top level elements which
/// are annotated with `@Deprecated`:
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
/// Elements which are not at the top level, such as the members of a class or
/// extension, are not searched for annotations. To operate on, for instance,
/// annotated fields of a class ensure that the class itself is annotated with
/// [T] and use the [Element2] to iterate over fields. The [TypeChecker] utility
/// may be helpful to check which elements have a given annotation.
abstract class GeneratorForAnnotation<T> extends Generator {
  final bool throwOnUnresolved;

  /// By default, this generator will throw if it encounters unresolved
  /// annotations. You can override this by setting [throwOnUnresolved] to
  /// `false`.
  const GeneratorForAnnotation({this.throwOnUnresolved = true});

  TypeChecker get typeChecker => TypeChecker.fromRuntime(T);

  @override
  FutureOr<String> generate(LibraryReader library, BuildStep buildStep) async {
    final values = <String>{};

    for (var annotatedDirective in library.libraryDirectivesAnnotatedWith(
      typeChecker,
      throwOnUnresolved: throwOnUnresolved,
    )) {
      final generatedValue = generateForAnnotatedDirective(
        annotatedDirective.directive,
        annotatedDirective.annotation,
        buildStep,
      );
      await for (var value in normalizeGeneratorOutput(generatedValue)) {
        assert(value.length == value.trim().length);
        values.add(value);
      }
    }

    for (var annotatedElement in library.annotatedWith(
      typeChecker,
      throwOnUnresolved: throwOnUnresolved,
    )) {
      final generatedValue = generateForAnnotatedElement(
        annotatedElement.element,
        annotatedElement.annotation,
        buildStep,
      );
      await for (var value in normalizeGeneratorOutput(generatedValue)) {
        assert(value.length == value.trim().length);
        values.add(value);
      }
    }

    return values.join('\n\n');
  }

  /// Implement to return source code to generate for [element].
  ///
  /// This method is invoked based on finding elements annotated with an
  /// instance of [T]. The [annotation] is provided as a [ConstantReader].
  ///
  /// Supported return values include a single [String] or multiple [String]
  /// instances within an [Iterable] or [Stream]. It is also valid to return a
  /// [Future] of [String], [Iterable], or [Stream]. When multiple values are
  /// returned through an iterable or stream they will be deduplicated.
  /// Typically each value will be an independent unit of code and the
  /// deduplication prevents re-defining the same member multiple times. For
  /// example if multiple annotated elements may need a specific utility method
  /// available it can be output for each one, and the single deduplicated
  /// definition can be shared.
  ///
  /// Implementations should return `null` when no content is generated. Empty
  /// or whitespace-only [String] instances are also ignored.
  dynamic generateForAnnotatedElement(
    Element2 element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {}

  /// Implement to return source code to generate for [directive]:
  ///   - [LibraryImport]
  ///   - [LibraryExport]
  ///   - [PartInclude]
  ///
  /// This method is invoked based on finding directives annotated with an
  /// instance of [T]. The [annotation] is provided as a [ConstantReader].
  ///
  /// Supported return values include a single [String] or multiple [String]
  /// instances within an [Iterable] or [Stream]. It is also valid to return a
  /// [Future] of [String], [Iterable], or [Stream]. When multiple values are
  /// returned through an iterable or stream they will be deduplicated.
  /// Typically each value will be an independent unit of code and the
  /// deduplication prevents re-defining the same member multiple times. For
  /// example if multiple annotated elements may need a specific utility method
  /// available it can be output for each one, and the single deduplicated
  /// definition can be shared.
  ///
  /// Implementations should return `null` when no content is generated. Empty
  /// or whitespace-only [String] instances are also ignored.
  dynamic generateForAnnotatedDirective(
    ElementDirective directive,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {}
}
