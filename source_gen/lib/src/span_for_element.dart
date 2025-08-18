// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
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
SourceSpan spanForElement(Element element, [SourceFile? file]) {
  final fragment = element.firstFragment;
  final url = assetToPackageUrl(fragment.libraryFragment!.source.uri);
  if (file == null) {
    final contents = fragment.libraryFragment?.source.contents;
    if (contents == null) {
      return SourceSpan(
        SourceLocation(fragment.nameOffset!, sourceUrl: url),
        SourceLocation(
          fragment.nameOffset! + fragment.name!.length,
          sourceUrl: url,
        ),
        fragment.name!,
      );
    }
    file = SourceFile.fromString(contents.data, url: url);
  }
  if (fragment.nameOffset == null) {
    if (element is PropertyInducingElement) {
      if (element.getter != null) {
        return spanForElement(element.getter!);
      }

      if (element.setter != null) {
        return spanForElement(element.setter!);
      }
    }
  }

  return file.span(
    fragment.nameOffset!,
    fragment.nameOffset! + fragment.name!.length,
  );
}

/// Returns a source span for the start character of [elementDirective].
SourceSpan spanForElementDirective(ElementDirective elementDirective) {
  final libraryFragment = elementDirective.libraryFragment;
  final contents = libraryFragment.source.contents.data;
  final url = assetToPackageUrl(libraryFragment.source.uri);
  final file = SourceFile.fromString(contents, url: url);
  var offset = 0;
  if (elementDirective is LibraryExport) {
    offset = elementDirective.exportKeywordOffset;
  } else if (elementDirective is LibraryImport) {
    offset = elementDirective.importKeywordOffset;
  } else if (elementDirective is PartInclude) {
    // TODO(davidmorgan): no way to get this yet, see
    // https://github.com/dart-lang/source_gen/issues/769#issuecomment-3157032889
  }
  return file.span(offset, offset);
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

/// Returns a source span for the start character of [fragment].
///
/// If the fragment has a name, the start character is the start of the name.
SourceSpan spanForFragment(Fragment fragment) {
  final libraryFragment = fragment.libraryFragment!;
  final contents = libraryFragment.source.contents.data;
  final url = assetToPackageUrl(libraryFragment.source.uri);
  final file = SourceFile.fromString(contents, url: url);
  return file.span(fragment.offset, fragment.offset);
}
