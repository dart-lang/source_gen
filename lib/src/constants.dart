// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/constant/value.dart';

/// Always returns `null` (used as a default for `defaultTo` methods).
Null _alwaysNull() => null;

/// Returns whether or not [object] is or represents a `null` value.
bool _isNull(DartObject object) => object?.isNull != false;

/// Similar to [DartObject.getField], but traverses super classes.
///
/// Returns `null` if ultimately [field] is never found.
DartObject _getFieldRecursive(DartObject object, String field) {
  if (_isNull(object)) {
    return null;
  }
  final result = object.getField(field);
  if (_isNull(result)) {
    return _getFieldRecursive(object.getField('(super)'), field);
  }
  return result;
}

/// A wrapper for analyzer's [DartObject] with a predictable high-level API.
///
/// Unlike [DartObject.getField], all `readX` methods attempt to access super
/// classes for the field value if not found.
abstract class Constant {
  factory Constant(DartObject object) =>
      _isNull(object) ? const _NullConstant() : new _Constant(object);

  /// Returns whether this constant represents a `bool` literal.
  bool get isBool;

  /// Returns this constant as a `bool` value.
  bool get boolValue;

  /// Returns whether this constant represents an `int` literal.
  bool get isInt;

  /// Returns this constant as an `int` value.
  ///
  /// Throws [FormatException] if [isInt] is `false`.
  int get intValue;

  /// Returns whether this constant represents a `String` literal.
  ///
  /// If `true`, [stringValue] will return a `String` (not throw).
  bool get isString;

  /// Returns this constant as an `String` value.
  ///
  /// Throws [FormatException] if [isString] is `false`.
  String get stringValue;

  /// Returns whether this constant represents `null`.
  bool get isNull;

  /// Reads[ field] from the constant as another constant value.
  Constant read(String field);

  /// Reads [field] from the constant as a boolean.
  ///
  /// If the resulting value is `null`, uses [defaultTo] if defined.
  bool readBool(String field, {bool defaultTo()});

  /// Reads [field] from the constant as an int.
  ///
  /// If the resulting value is `null`, uses [defaultTo] if defined.
  int readInt(String field, {int defaultTo()});

  /// Reads [field] from the constant as a string.
  ///
  /// If the resulting value is `null`, uses [defaultTo] if defined.
  String readString(String field, {String defaultTo()});
}

/// Implements a [Constant] representing a `null` value.
class _NullConstant implements Constant {
  const _NullConstant();

  @override
  bool get boolValue => throw new FormatException('Not a bool', 'null');

  @override
  int get intValue => throw new FormatException('Not an int', 'null');

  @override
  String get stringValue => throw new FormatException('Not a String', 'null');

  @override
  bool get isBool => false;

  @override
  bool get isInt => false;

  @override
  bool get isNull => true;

  @override
  bool get isString => false;

  @override
  Constant read(_) => this;

  @override
  bool readBool(_, {bool defaultTo(): _alwaysNull}) => defaultTo();

  @override
  int readInt(_, {int defaultTo(): _alwaysNull}) => defaultTo();

  @override
  String readString(_, {String defaultTo(): _alwaysNull}) => defaultTo();
}

/// Default implementation of [Constant].
class _Constant implements Constant {
  final DartObject _object;

  const _Constant(this._object);

  @override
  bool get boolValue => isBool
      ? _object.toBoolValue()
      : throw new FormatException('Not a bool', _object);

  @override
  int get intValue => isInt
      ? _object.toIntValue()
      : throw new FormatException('Not an int', _object);

  @override
  String get stringValue => isString
      ? _object.toStringValue()
      : throw new FormatException('Not a String', _object);

  @override
  bool get isBool => _object.toBoolValue() != null;

  @override
  bool get isInt => _object.toIntValue() != null;

  @override
  bool get isNull => _isNull(_object);

  @override
  bool get isString => _object.toStringValue() != null;

  @override
  Constant read(String field) =>
      new Constant(_getFieldRecursive(_object, field));

  @override
  bool readBool(String field, {bool defaultTo()}) =>
      _getFieldRecursive(_object, field)?.toBoolValue() ?? defaultTo();

  @override
  int readInt(String field, {int defaultTo()}) =>
      _getFieldRecursive(_object, field)?.toIntValue() ?? defaultTo();

  @override
  String readString(String field, {String defaultTo()}) =>
      _getFieldRecursive(_object, field)?.toStringValue() ?? defaultTo();
}
