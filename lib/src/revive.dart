// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/constant/value.dart';

import 'utils.dart';

/// Base interface for a meta-analyzed [DartObject].
abstract class Revivable {}

/// Returns a revivable instance of [object].
///
/// Optionally specify the [clazz] type that contains the constructor.
///
/// Returns [null] if not revivable.
RevivableInstance reviveInstance(DartObject object, [ClassElement clazz]) {
  clazz ??= object.type.element;
  final url = Uri.parse(urlOfElement(clazz));
  ClassMemberElement element = _findPublicConstField(object, clazz);
  if (element != null) {
    return new RevivableInstance._(source: url, accessor: element.name);
  }
  final invocation = _findPublicConstConstructor(object, clazz);
  if (invocation != null) {
    return new RevivableInstance._(
      source: url,
      accessor: invocation.constructor.name,
      namedArguments: invocation.namedArguments,
      positionalArguments: invocation.positionalArguments,
    );
  }
  return null;
}

FieldElement _findPublicConstField(DartObject object, ClassElement clazz) =>
    clazz.fields.firstWhere(
        (f) => f.isConst && f.isPublic && f.computeConstantValue() == object,
        orElse: () => null);

ConstructorInvocation _findPublicConstConstructor(
  DartObject object,
  ClassElement clazz,
) {
  final invocation = (object as DartObjectImpl).getInvocation();
  final constructor = invocation.constructor;
  if (constructor.isConst && constructor.isPublic) {
    return invocation;
  }
  return null;
}

/// Decoded "instructions" for re-creating a const [DartObject] at runtime.
class RevivableInstance implements Revivable {
  /// A URL pointing to the location and class name.
  ///
  /// For example, `LinkedHashMap` looks like: `dart:collection#LinkedHashMap`.
  final Uri source;

  /// Constructor or getter name used to invoke `const Class(...)`.
  ///
  /// Optional - if empty string (`''`) then this means the default constructor.
  final String accessor;

  /// Positional arguments used to invoke the constructor.
  final List<DartObject> positionalArguments;

  /// Named arguments used to invoke the constructor.
  final Map<String, DartObject> namedArguments;

  const RevivableInstance._({
    this.source,
    this.accessor: '',
    this.positionalArguments: const [],
    this.namedArguments: const {},
  });
}
