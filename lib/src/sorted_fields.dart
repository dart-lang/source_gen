// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';

// ignore: implementation_imports
import 'package:analyzer/src/dart/resolver/inheritance_manager.dart'
    show InheritanceManager;

import 'package:source_gen/source_gen.dart';

final _dartCoreObjectChecker = const TypeChecker.fromRuntime(Object);

/// Returns a [List] of all instance [FieldElement] items for [element] and
/// super classes, sorted first by their location in the inheritance hierarchy
/// (super first) and then by their location in the source file.
List<FieldElement> sortedFields(ClassElement element) {
  // Get all of the fields that need to be assigned
  var fieldSet = element.fields.where((e) => !e.isStatic).toSet();

  var manager = new InheritanceManager(element.library);

  for (var v in manager.getMembersInheritedFromClasses(element).values) {
    assert(v is! FieldElement);
    if (_dartCoreObjectChecker.isExactly(v.enclosingElement)) {
      continue;
    }

    if (v is PropertyAccessorElement && v.variable is FieldElement) {
      fieldSet.add(v.variable as FieldElement);
    }
  }

  var undefinedFields = fieldSet.where((fe) => fe.type.isUndefined).toList();
  if (undefinedFields.isNotEmpty) {
    var description =
        undefinedFields.map((fe) => '`${fe.displayName}`').join(', ');

    throw new InvalidGenerationSourceError(
        'At least one field has an invalid type: $description.',
        todo: 'Check names and imports.',
        element: undefinedFields.first);
  }

  var fieldList = fieldSet.toList();

  // Sort these in the order in which they appear in the class.
  // Sadly, `classElement.fields` puts properties after fields
  fieldList.sort(_sortByLocation);

  return fieldList;
}

int _sortByLocation(FieldElement a, FieldElement b) {
  var checkerA = new TypeChecker.fromStatic(a.enclosingElement.type);

  if (!checkerA.isExactly(b.enclosingElement)) {
    // in this case, you want to prioritize the enclosingElement that is more
    // "super".

    if (checkerA.isSuperOf(b.enclosingElement)) {
      return -1;
    }

    var checkerB = new TypeChecker.fromStatic(b.enclosingElement.type);

    if (checkerB.isSuperOf(a.enclosingElement)) {
      return 1;
    }
  }

  /// Returns the offset of given field/property in its source file – with a
  /// preference for the getter if it's defined.
  int _offsetFor(FieldElement e) {
    if (e.getter != null && e.getter.nameOffset != e.nameOffset) {
      assert(e.nameOffset == -1);
      return e.getter.nameOffset;
    }
    return e.nameOffset;
  }

  return _offsetFor(a).compareTo(_offsetFor(b));
}
