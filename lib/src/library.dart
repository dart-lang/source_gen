// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/standard_resolution_map.dart';
import 'package:analyzer/dart/element/element.dart';
// ignore: implementation_imports
import 'package:analyzer/src/dart/resolver/scope.dart';

import 'constants/reader.dart';
import 'type_checker.dart';

/// Result of finding an [annotation] on [element] through [LibraryReader].
class AnnotatedElement {
  final ConstantReader annotation;
  final Element element;

  const AnnotatedElement(this.annotation, this.element);
}

/// A high-level wrapper API with common functionality for [LibraryElement].
class LibraryReader {
  final LibraryElement element;

  Namespace _namespaceCache;

  LibraryReader(this.element);

  Namespace get _namespace => _namespaceCache ??=
      new NamespaceBuilder().createExportNamespaceForLibrary(element);

  /// Returns a top-level [ClassElement] publicly visible in by [name].
  ///
  /// Unlike [LibraryElement.getType], this also correctly traverses identifiers
  /// that are accessible via one or more `export` directives.
  ClassElement findType(String name) =>
      element.getType(name) ?? _namespace.get(name) as ClassElement;

  /// All of the declarations in this library.
  Iterable<Element> get allElements sync* {
    for (var cu in element.units) {
      for (var compUnitMember in cu.unit.declarations) {
        yield* _getElements(compUnitMember);
      }
    }
  }

  /// All of the declarations in this library annotated with [checker].
  Iterable<AnnotatedElement> annotatedWith(TypeChecker checker,
      {bool throwOnUnresolved}) sync* {
    for (final element in allElements) {
      final annotation = checker.firstAnnotationOf(element,
          throwOnUnresolved: throwOnUnresolved);
      if (annotation != null) {
        yield new AnnotatedElement(new ConstantReader(annotation), element);
      }
    }
  }

  /// All of the declarations in this library annotated with exactly [checker].
  Iterable<AnnotatedElement> annotatedWithExact(TypeChecker checker,
      {bool throwOnUnresolved}) sync* {
    for (final element in allElements) {
      final annotation = checker.firstAnnotationOfExact(element,
          throwOnUnresolved: throwOnUnresolved);
      if (annotation != null) {
        yield new AnnotatedElement(new ConstantReader(annotation), element);
      }
    }
  }

  /// All of the `class` elements in this library.
  Iterable<ClassElement> get classElements =>
      element.definingCompilationUnit.types;

  static Iterable<Element> _getElements(CompilationUnitMember member) {
    if (member is TopLevelVariableDeclaration) {
      return member.variables.variables
          .map(resolutionMap.elementDeclaredByVariableDeclaration);
    }
    var element = resolutionMap.elementDeclaredByDeclaration(member);
    if (element == null) {
      throw new StateError(
          'Could not find any elements for the provided unit.');
    }
    return [element];
  }

  /// Returns the identifier prefix of [element] if it is referenced by one.
  ///
  /// For example in the following file:
  /// ```
  /// import 'bar.dart' as bar;
  ///
  /// bar.Bar b;
  /// ```
  ///
  /// ... we'd assume that `b`'s type has a prefix of `bar`.
  ///
  /// If there is no prefix, one could not be computed, `null` is returned.
  ///
  /// If there is an attempt to read a prefix of a file _other_ than the current
  /// library being read this will throw [StateError], as it is not always
  /// possible to read details of the source file from other inputs.
  String _prefixForType(Element element) {
    final astNode = element.computeNode();
    if (astNode is VariableDeclaration) {
      final parentNode = astNode.parent as VariableDeclarationList;
      return _prefixForTypeAnnotation(parentNode.type);
    }
    return null;
  }

  static String _prefixForTypeAnnotation(TypeAnnotation astNode) {
    if (astNode is NamedType) {
      return _prefixForIdentifier(astNode.name);
    }
    return null;
  }

  static String _prefixForIdentifier(Identifier id) {
    return id is PrefixedIdentifier ? id.prefix.name : null;
  }
}

// Testing-only access to LibraryReader._prefixFor.
//
// This is used to iterate on the tests without launching the feature.
// Additionally it looks ike `computeNode()` will be deprecated, so we might
// have to rewrite the entire body of the function in the near future; at least
// the tests can help for correctness.
String testingPrefixForType(LibraryReader r, Element e) => r._prefixForType(e);
