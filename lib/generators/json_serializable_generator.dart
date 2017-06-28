// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/analyzer.dart';
import 'package:source_gen/source_gen.dart';
import 'package:source_gen/src/json_serializable/type_helper.dart';
import 'package:source_gen/src/utils.dart';

import 'json_serializable.dart';

export 'package:source_gen/src/json_serializable/type_helper.dart';

// TODO: toJson option to omit null/empty values
class JsonSerializableGenerator
    extends GeneratorForAnnotation<JsonSerializable> {
  static const _defaultHelpers = const [
    const JsonHelper(),
    const DateTimeHelper()
  ];

  final List<TypeHelper> _typeHelpers;

  /// Creates an instance of [JsonSerializableGenerator].
  ///
  /// If [typeHelpers] is not provided, two built-in helpers are used:
  /// [JsonHelper] and [DateTimeHelper].
  const JsonSerializableGenerator({List<TypeHelper> typeHelpers})
      : this._typeHelpers = typeHelpers ?? _defaultHelpers;

  /// Creates an instance of [JsonSerializableGenerator].
  ///
  /// [typeHelpers] provides a set of [TypeHelper] that will be used along with
  /// the built-in helpers: [JsonHelper] and [DateTimeHelper].
  factory JsonSerializableGenerator.withDefaultHelpers(
          Iterable<TypeHelper> typeHelpers) =>
      new JsonSerializableGenerator(
          typeHelpers: new List.unmodifiable(
              [typeHelpers, _defaultHelpers].expand((e) => e)));

  @override
  Future<String> generateForAnnotatedElement(
      Element element, JsonSerializable annotation, _) async {
    if (element is! ClassElement) {
      var friendlyName = friendlyNameForElement(element);
      throw new InvalidGenerationSourceError(
          'Generator cannot target `$friendlyName`.',
          todo: 'Remove the JsonSerializable annotation from `$friendlyName`.');
    }

    var classElement = element as ClassElement;
    var className = classElement.name;

    // Get all of the fields that need to be assigned
    // TODO: support overriding the field set with an annotation option
    var fieldsList = classElement.fields.toList();

    // Sort these in the order in which they appear in the class
    // Sadly, `classElement.fields` puts properties after fields
    fieldsList.sort((a, b) => a.nameOffset.compareTo(b.nameOffset));

    // Explicitly using `LinkedHashMap` – we want these ordered.
    var fields = new LinkedHashMap<String, FieldElement>.fromIterable(
        fieldsList,
        key: (f) => f.name);

    // Get the constructor to use for the factory

    var prefix = '_\$${className}';

    var buffer = new StringBuffer();

    if (annotation.createFactory) {
      var toSkip = _writeFactory(buffer, classElement, fields, prefix);

      // If there are fields that are final – that are not set via the generated
      // constructor, then don't output them when generating the `toJson` call.
      for (var field in toSkip) {
        fields.remove(field.name);
      }
    }

    if (annotation.createToJson) {
      //
      // Generate the mixin class
      //
      buffer.writeln('abstract class ${prefix}SerializerMixin {');

      // write fields
      fields.forEach((name, field) {
        //TODO - handle aliased imports
        buffer.writeln('  ${field.type} get $name;');
      });

      // write toJson method
      buffer.writeln('  Map<String, dynamic> toJson() => <String, dynamic>{');

      var pairs = <String>[];
      fields.forEach((fieldName, field) {
        pairs.add("'${_fieldToJsonMapKey(fieldName, field)}': "
            "${_fieldToJsonMapValue(fieldName, field.type)}");
      });
      buffer.writeln(pairs.join(','));

      buffer.writeln('  };');

      buffer.write('}');
    }

    return buffer.toString();
  }

  /// Returns the set of fields that are not written to via constructors.
  Set<FieldElement> _writeFactory(
      StringBuffer buffer,
      ClassElement classElement,
      Map<String, FieldElement> fields,
      String prefix) {
    // creating a copy so it can be mutated
    var fieldsToSet = new Map<String, FieldElement>.from(fields);
    var className = classElement.displayName;
    // Create the factory method

    // Get the default constructor
    // TODO: allow overriding the ctor used for the factory
    var ctor = classElement.unnamedConstructor;

    var ctorArguments = <ParameterElement>[];
    var ctorNamedArguments = <ParameterElement>[];

    for (var arg in ctor.parameters) {
      var field = fields[arg.name];

      if (field == null) {
        if (arg.parameterKind == ParameterKind.REQUIRED) {
          throw new UnsupportedError('Cannot populate the required constructor '
              'argument: ${arg.displayName}.');
        }
        continue;
      }

      // TODO: validate that the types match!
      if (arg.parameterKind == ParameterKind.NAMED) {
        ctorNamedArguments.add(arg);
      } else {
        ctorArguments.add(arg);
      }
      fieldsToSet.remove(arg.name);
    }

    // these are fields to skip – now to find them
    var finalFields =
        fieldsToSet.values.where((field) => field.isFinal).toSet();

    for (var finalField in finalFields) {
      var value = fieldsToSet.remove(finalField.name);
      assert(value == finalField);
    }

    //
    // Generate the static factory method
    //
    buffer.writeln();
    buffer.writeln('$className ${prefix}FromJson(Map json) =>');
    buffer.write('    new $className(');
    buffer.writeAll(
        ctorArguments.map((paramElement) => _jsonMapAccessToField(
            paramElement.name, fields[paramElement.name],
            ctorParam: paramElement)),
        ', ');
    if (ctorArguments.isNotEmpty && ctorNamedArguments.isNotEmpty) {
      buffer.write(', ');
    }
    buffer.writeAll(
        ctorNamedArguments.map((paramElement) =>
            '${paramElement.name}: ' +
            _jsonMapAccessToField(paramElement.name, fields[paramElement.name],
                ctorParam: paramElement)),
        ', ');

    buffer.write(')');
    if (fieldsToSet.isEmpty) {
      buffer.writeln(';');
    } else {
      fieldsToSet.forEach((name, field) {
        buffer.writeln();
        buffer.write("      ..${name} = ");
        buffer.write(_jsonMapAccessToField(name, field));
      });
      buffer.writeln(';');
    }
    buffer.writeln();

    return finalFields;
  }

  /// [expression] may be just the name of the field or it may an expression
  /// representing the serialization of a value.
  String _fieldToJsonMapValue(String expression, DartType fieldType,
      [int depth = 0]) {
    for (var helper in _typeHelpers) {
      if (helper.canSerialize(fieldType)) {
        return helper.serialize(fieldType, expression);
      }
    }

    if (_coreIterableChecker.isAssignableFromType(fieldType)) {
      // This block will yield a regular list, which works fine for JSON
      // Although it's possible that child elements may be marked unsafe

      var isList = _coreListChecker.isAssignableFromType(fieldType);
      var substitute = "v$depth";
      var subFieldValue = _fieldToJsonMapValue(substitute,
          _getIterableGenericType(fieldType as InterfaceType), depth + 1);

      // In the case of trivial JSON types (int, String, etc), `subFieldValue`
      // will be identical to `substitute` – so no explicit mapping is needed.
      // If they are not equal, then we to write out the substitution.
      if (subFieldValue != substitute) {
        // TODO: the type could be imported from a library with a prefix!
        expression = "${expression}?.map(($substitute) => $subFieldValue)";

        // expression now represents an Iterable (even if it started as a List
        // ...resetting `isList` to `false`.
        isList = false;
      }

      if (!isList) {
        // Then we need to add `?.toList()
        expression += "?.toList()";
      }

      return expression;
    } else if (_coreMapChecker.isAssignableFromType(fieldType)) {
      var args = _getTypeArguments(fieldType, _coreMapChecker);
      assert(args.length == 2);

      var keyArg = args.first;
      var valueType = args.last;

      // We're not going to handle converting key types at the moment
      // So the only safe types for key are dynamic/Object/String
      var safeKey = keyArg.isDynamic ||
          keyArg.isObject ||
          _coreStringChecker.isExactlyType(keyArg);

      var safeValue = false;
      if (valueType.isDynamic || valueType.isObject) {
        safeValue = true;
      } else {
        safeValue = _isStringBoolNum(valueType);
      }

      if (safeKey) {
        if (safeValue) {
          return expression;
        }

        // convert

        var substitute = "v$depth";
        var subFieldValue =
            _fieldToJsonMapValue(substitute, valueType, depth + 1);

        // In this case, we're going to create a new Map with matching reified
        // types.
        return "$expression == null ? null :"
            "new Map<String, dynamic>.fromIterables("
            "$expression.keys,"
            "$expression.values.map(($substitute) => $subFieldValue))";
      }
    } else if (fieldType.isDynamic ||
        fieldType.isObject ||
        _isStringBoolNum(fieldType)) {
      return expression;
    }

    return "$expression /* unsafe */";
  }

  String _jsonMapAccessToField(String name, FieldElement field,
      {ParameterElement ctorParam}) {
    name = _fieldToJsonMapKey(name, field);
    var result = "json['$name']";
    return _writeAccessToJsonValue(result, field.type, ctorParam: ctorParam);
  }

  String _writeAccessToJsonValue(String varExpression, DartType searchType,
      {ParameterElement ctorParam, int depth: 0}) {
    if (ctorParam != null) {
      searchType = ctorParam.type as InterfaceType;
    }

    for (var helper in _typeHelpers) {
      if (helper.canDeserialize(searchType)) {
        return "$varExpression == null ? null : "
            "${helper.deserialize(searchType, varExpression)}";
      }
    }

    if (_coreIterableChecker.isAssignableFromType(searchType)) {
      var iterableGenericType =
          _getIterableGenericType(searchType as InterfaceType);

      var itemVal = "v$depth";
      var itemSubVal = _writeAccessToJsonValue(itemVal, iterableGenericType,
          depth: depth + 1);

      // If `itemSubVal` is the same, then we don't need to do anything fancy
      if (itemVal == itemSubVal) {
        return varExpression;
      }

      var output = "($varExpression as List)?.map(($itemVal) => $itemSubVal)";

      if (_coreListChecker.isAssignableFromType(searchType)) {
        output += "?.toList()";
      }

      return output;
    } else if (_coreMapChecker.isAssignableFromType(searchType)) {
      // Just pass through if
      //    key:   dynamic, Object, String
      //    value: dynamic, Object
      var typeArgs = _getTypeArguments(searchType, _coreMapChecker);
      assert(typeArgs.length == 2);
      var keyArg = typeArgs.first;
      var valueArg = typeArgs.last;

      // We're not going to handle converting key types at the moment
      // So the only safe types for key are dynamic/Object/String
      var safeKey = keyArg.isDynamic ||
          keyArg.isObject ||
          _coreStringChecker.isExactlyType(keyArg);

      if (!safeKey) {
        return "$varExpression /* unsafe key type */";
      }

      // this is the trivial case. Do a runtime cast to the known type of JSON
      // map values - `Map<String, dynamic>`
      if (valueArg.isDynamic || valueArg.isObject) {
        return "$varExpression as Map<String, dynamic>";
      }

      var itemVal = "v$depth";
      var itemSubVal =
          _writeAccessToJsonValue(itemVal, valueArg, depth: depth + 1);

      // In this case, we're going to create a new Map with matching reified
      // types.
      return "$varExpression == null ? null :"
          "new Map<String, $valueArg>.fromIterables("
          "($varExpression as Map).keys,"
          "($varExpression as Map).values.map(($itemVal) => $itemSubVal))";
    } else if (searchType.isDynamic || searchType.isObject) {
      // just return it as-is. We'll hope it's safe.
      return varExpression;
    } else if (_isStringBoolNum(searchType)) {
      return "$varExpression as $searchType";
    }

    return "$varExpression /* unsafe */";
  }
}

/// Returns the JSON map `key` to be used when (de)serializing [field].
///
/// [fieldName] is used, unless [field] is annotated with [JsonKey], in which
/// case [JsonKey.jsonName] is used.
String _fieldToJsonMapKey(String fieldName, FieldElement field) {
  const $JsonKey = const TypeChecker.fromRuntime(JsonKey);
  var jsonKey = $JsonKey.firstAnnotationOf(field);
  if (jsonKey != null) {
    var jsonName = jsonKey.getField('jsonName').toStringValue();
    return jsonName;
  }
  return fieldName;
}

DartType _getIterableGenericType(InterfaceType type) =>
    _getTypeArguments(type, _coreIterableChecker).single;

List<DartType> _getTypeArguments(InterfaceType type, TypeChecker checker) {
  var iterableImplementation =
      _getImplementationType(type, checker) as InterfaceType;

  return iterableImplementation?.typeArguments;
}

DartType _getImplementationType(DartType type, TypeChecker checker) {
  if (checker.isExactlyType(type)) return type;

  if (type is InterfaceType) {
    var match = [type.interfaces, type.mixins]
        .expand((e) => e)
        .map((type) => _getImplementationType(type, checker))
        .firstWhere((value) => value != null, orElse: () => null);

    if (match != null) {
      return match;
    }

    if (type.superclass != null) {
      return _getImplementationType(type.superclass, checker);
    }
  }
  return null;
}

final _coreIterableChecker = const TypeChecker.fromUrl('dart:core#Iterable');

final _coreListChecker = const TypeChecker.fromUrl('dart:core#List');

final _coreMapChecker = const TypeChecker.fromUrl('dart:core#Map');

final _coreStringChecker = const TypeChecker.fromUrl('dart:core#String');

bool _isStringBoolNum(DartType type) =>
    _stringBoolNumCheckers.any((tc) => tc.isAssignableFromType(type));

final _stringBoolNumCheckers = new List<TypeChecker>.unmodifiable([
  _coreStringChecker
]..addAll(['bool', 'num'].map((s) => new TypeChecker.fromUrl('dart:core#$s'))));
