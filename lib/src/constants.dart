// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/constant/value.dart';

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
abstract class ConstantReader {
  factory ConstantReader(DartObject object) =>
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

  /// Returns whether this constant represents a `List` literal.
  ///
  /// If `true`, [listValue] will return a `List` (not throw).
  bool get isList;

  /// Returns this constant as a `List` value.
  ///
  /// Throws [FormatException] if [isList] is `false`.
  List<DartObject> get listValue;

  /// Returns whether this constant represents a `Map` literal.
  ///
  /// If `true`, [listValue] will return a `Map` (not throw).
  bool get isMap;

  /// Returns this constant as a `Map` value.
  ///
  /// Throws [FormatException] if [isMap] is `false`.
  Map<DartObject, DartObject> get mapValue;

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
  ConstantReader read(String field);
}

dynamic _throw(String expected, [dynamic object]) {
  throw new FormatException('Not a $expected', '$object');
}

/// Implements a [ConstantReader] representing a `null` value.
class _NullConstant implements ConstantReader {
  const _NullConstant();

  @override
  bool get boolValue => _throw('bool');

  @override
  int get intValue => _throw('int');

  @override
  String get stringValue => _throw('String');

  @override
  List<DartObject> get listValue => _throw('List');

  @override
  Map<DartObject, DartObject> get mapValue => _throw('Map');

  @override
  bool get isBool => false;

  @override
  bool get isInt => false;

  @override
  bool get isList => false;

  @override
  bool get isMap => false;

  @override
  bool get isNull => true;

  @override
  bool get isString => false;

  @override
  ConstantReader read(_) => this;
}

/// Default implementation of [ConstantReader].
class _Constant implements ConstantReader {
  final DartObject _object;

  const _Constant(this._object);

  @override
  bool get boolValue => isBool
      ? _object.toBoolValue()
      : _throw('bool', _object);

  @override
  int get intValue => isInt
      ? _object.toIntValue()
      : _throw('int', _object);

  @override
  String get stringValue => isString
      ? _object.toStringValue()
      : _throw('String', _object);

  @override
  List<DartObject> get listValue => isList
      ? _object.toListValue()
      : _throw('List', _object);

  @override
  Map<DartObject, DartObject> get mapValue => isMap
      ? _object.toListValue()
      : _throw('Map', _object);

  @override
  bool get isBool => _object.toBoolValue() != null;

  @override
  bool get isInt => _object.toIntValue() != null;

  @override
  bool get isList => _object?.toListValue() != null;

  @override
  bool get isNull => _isNull(_object);

  @override
  bool get isMap => _isNull(_object);

  @override
  bool get isString => _object.toStringValue() != null;

  @override
  ConstantReader read(String field) =>
      new ConstantReader(_getFieldRecursive(_object, field));
}
