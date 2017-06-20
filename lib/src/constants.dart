// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:collection/collection.dart';

/// Always return `null`.
Null _alwaysNull() => null;

/// Throws an exception if [root] or its super(s) does not contain [name].
void _assertHasField(ClassElement root, String name) {
  var element = root;
  while (element != null) {
    final field = element.getField(name);
    if (field != null) {
      return;
    }
    element = element.supertype?.element;
  }
  final allFields = root.fields.toSet();
  root.allSupertypes.forEach((t) => allFields.addAll(t.element.fields));
  throw new FormatException(
    'Class ${root.name} does not have field "$name".',
    'Fields: $allFields',
  );
}

/// Returns whether or not [object] is or represents a `null` value.
bool _isNull(DartObject object) => object == null || object.isNull;

/// Similar to [DartObject.getField], but traverses super classes.
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
  factory Constant(DartObject object) {
    return _isNull(object) ? const _NullConstant() : new _Constant(object);
  }

  /// Returns whether this constant represents a `bool` literal.
  ///
  /// If `true`, [boolValue] will return either `true` or `false` (not throw).
  bool get isBool;

  /// Returns this constant as a `bool` value.
  ///
  /// Throws [FormatException] if [isBool] is `false`.
  bool get boolValue;

  /// Returns whether this constant represents an `int` literal.
  ///
  /// If `true`, [intValue] will return an `int` (not throw).
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
  List<Constant> get listValue;

  /// Returns whether this constant represents a `Map` literal.
  ///
  /// If `true`, [listValue] will return a `Map` (not throw).
  bool get isMap;

  /// Returns this constant as a `Map` value.
  ///
  /// Throws [FormatException] if [isMap] is `false`.
  Map<Constant, Constant> get mapValue;

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

  /// Reads [field] from the constant as a List.
  ///
  /// If the resulting value is `null`, uses [defaultTo] if defined.
  List<Constant> readList(String field, {List<Constant> defaultTo()});

  /// Reads [field] from the constant as a Map.
  ///
  /// If the resulting value is `null`, uses [defaultTo] if defined.
  Map<Constant, Constant> readMap(String field,
      {Map<Constant, Constant> defaultTo()});

  /// Reads [field] from the constant as a string.
  ///
  /// If the resulting value is `null`, uses [defaultTo] if defined.
  String readString(String field, {String defaultTo()});
}

/// Implements a [Constant] representing a `null` value.
class _NullConstant implements Constant {
  final DartObject _object;

  const _NullConstant([this._object]);

  @override
  String get stringValue =>
      throw new FormatException('Not a String', '$_object');

  @override
  bool get isBool => false;

  @override
  bool get boolValue => throw new FormatException('Not a bool', '$_object');

  @override
  bool get isInt => false;

  @override
  int get intValue => throw new FormatException('Not an int', '$_object');

  @override
  bool get isList => false;

  @override
  List<Constant> get listValue =>
      throw new FormatException('Not a List', '$_object');

  @override
  bool get isMap => false;

  @override
  Map<Constant, Constant> get mapValue =>
      throw new FormatException('Not a Map', '$_object');

  @override
  bool get isNull => true;

  @override
  bool get isString => false;

  @override
  Constant read(_) => this;

  T _readFailure<T>(String field, {T defaultTo()}) {
    final result = defaultTo();
    if (result != null) {
      return result;
    }
    throw new FormatException(
        'Object does not have field "$field".', '$_object');
  }

  @override
  bool readBool(String field, {bool defaultTo()}) =>
      _readFailure(field, defaultTo: defaultTo);

  @override
  int readInt(String field, {int defaultTo()}) =>
      _readFailure(field, defaultTo: defaultTo);

  @override
  List<Constant> readList(String field, {List<Constant> defaultTo()}) =>
      _readFailure(field, defaultTo: defaultTo);

  @override
  Map<Constant, Constant> readMap(String field,
          {Map<Constant, Constant> defaultTo()}) =>
      _readFailure(field, defaultTo: defaultTo);

  @override
  String readString(String field, {String defaultTo()}) =>
      _readFailure(field, defaultTo: defaultTo);

  @override
  String toString() => 'Constant ${_object}';
}

/// Default implementation of [Constant].
class _Constant extends _NullConstant {
  const _Constant(DartObject object) : super(object);

  @override
  bool get isBool => _object.toBoolValue() != null;

  @override
  bool get boolValue => isBool ? _object.toBoolValue() : super.boolValue;

  @override
  bool get isInt => _object.toIntValue() != null;

  @override
  int get intValue => isInt ? _object.toIntValue() : super.intValue;

  @override
  bool get isList => _object.toListValue() != null;

  @override
  List<Constant> get listValue => isList
      ? _object.toListValue().map((c) => new Constant(c)).toList()
      : super.listValue;

  @override
  bool get isMap => _object.toMapValue() != null;

  @override
  Map<Constant, Constant> get mapValue => isMap
      ? mapMap(_object.toMapValue(),
          key: (k, _) => new Constant(k), value: (_, v) => new Constant(v))
      : super.mapValue;

  @override
  bool get isNull => _object.isNull;

  @override
  bool get isString => _object.toStringValue() != null;

  @override
  String get stringValue =>
      isString ? _object.toStringValue() : super.stringValue;

  @override
  Constant read(String field) =>
      new Constant(_getFieldRecursive(_object, field));

  /// Reads [field] from this constant, and returns as value [T].
  ///
  /// [toValue]: Coerces the [Constant] into the expected value type.
  /// [defaultTo]: If the field exists, but it is not provided, is invoked.
  ///
  /// This method simplifies common functionality required by most read methods.
  T _readDeep<T>(
    String field,
    T toValue(Constant c), [
    T defaultTo() = _alwaysNull,
  ]) {
    final result = read(field);
    if (result.isNull) {
      _assertHasField(_object.type.element, field);
      return defaultTo() ?? super._readFailure(field);
    }
    return toValue(result);
  }

  @override
  bool readBool(String field, {bool defaultTo()}) =>
      _readDeep(field, (c) => c.boolValue, defaultTo);

  @override
  int readInt(String field, {int defaultTo()}) =>
      _readDeep(field, (c) => c.intValue, defaultTo);

  @override
  List<Constant> readList(String field, {List<Constant> defaultTo()}) =>
      _readDeep(field, (c) => c.listValue, defaultTo);

  @override
  Map<Constant, Constant> readMap(String field,
          {Map<Constant, Constant> defaultTo()}) =>
      _readDeep(field, (c) => c.mapValue, defaultTo);

  @override
  String readString(String field, {String defaultTo()}) =>
      _readDeep(field, (c) => c.stringValue, defaultTo);
}
