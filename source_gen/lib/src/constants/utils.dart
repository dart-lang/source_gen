// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: deprecated_member_use until analyzer 7 support is dropped.

import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element2.dart';

/// Throws a [FormatException] if [root] does not have a given field [name].
///
/// Super types [InterfaceElement2.supertype] are also checked before throwing.
void assertHasField(InterfaceElement2 root, String name) {
  InterfaceElement2? element = root;
  while (element != null) {
    final field = element.getField2(name);
    if (field != null) {
      return;
    }
    element = element.supertype?.element3;
  }
  final allFields = {
    ...root.fields2,
    for (var t in root.allSupertypes) ...t.element3.fields2,
  };

  throw FormatException(
    'Class ${root.name3} does not have field "$name".',
    'Fields: \n  - ${allFields.map((e) => e.name3).join('\n  - ')}',
  );
}

/// Returns whether or not [object] is or represents a `null` value.
bool isNullLike(DartObject? object) => object?.isNull != false;

/// Similar to [DartObject.getField], but traverses super classes.
///
/// Returns `null` if ultimately [field] is never found.
DartObject? getFieldRecursive(DartObject? object, String field) {
  if (isNullLike(object)) {
    return null;
  }
  final result = object!.getField(field);
  if (isNullLike(result)) {
    return getFieldRecursive(object.getField('(super)'), field);
  }
  return result;
}
