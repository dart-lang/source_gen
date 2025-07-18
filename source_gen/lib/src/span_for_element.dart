// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:source_span/source_span.dart';

import 'utils.dart';

/// Returns a source span that spans the location where [element] is defined.
///
/// May be used to emit user-friendly warning and error messages:
/// ```dart
/// void invalidClass(ClassElement class) {
///   log.warning(spanForElement.message('Cannot implement "Secret"'));
/// }
/// ```
///
/// Not all results from the analyzer API may return source information as part
/// of the element, so [file] may need to be manually provided in those cases.
SourceSpan spanForElement(Element2 element, [SourceFile? file]) {
  final fragment = element.firstFragment;
  final url = assetToPackageUrl(fragment.libraryFragment!.source.uri);
  if (file == null) {
    final contents = fragment.libraryFragment?.source.contents;
    if (contents == null) {
      return SourceSpan(
        SourceLocation(fragment.nameOffset2!, sourceUrl: url),
        SourceLocation(
          fragment.nameOffset2! + fragment.name2!.length,
          sourceUrl: url,
        ),
        fragment.name2!,
      );
    }
    file = SourceFile.fromString(contents.data, url: url);
  }
  if (fragment.nameOffset2 == null) {
    if (element is PropertyInducingElement2) {
      if (element.getter2 != null) {
        return spanForElement(element.getter2!);
      }

      if (element.setter2 != null) {
        return spanForElement(element.setter2!);
      }
    }
  }

  return file.span(
    fragment.nameOffset2!,
    fragment.nameOffset2! + fragment.name2!.length,
  );
}

/// Returns a source span that spans the location where [node] is written.
SourceSpan spanForNode(AstNode node) {
  final unit = node.thisOrAncestorOfType<CompilationUnit>()!;
  final unitFragment = unit.declaredFragment!;
  final contents = unitFragment.source.contents.data;
  final url = assetToPackageUrl(unitFragment.source.uri);
  final file = SourceFile.fromString(contents, url: url);
  return file.span(node.offset, node.offset + node.length);
}
