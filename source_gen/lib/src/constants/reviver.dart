import 'dart:mirrors';

import 'package:analyzer/dart/constant/value.dart';

import '../type_checker.dart';
import 'reader.dart';

/// Revives a [ConstantReader] to an instance in memory using Dart mirrors.
///
/// Converts a serialized [DartObject] and transforms it into a fully qualified
/// instance of the object to be consumed.
///
/// An intended usage of this is to provide those creating Generators a simpler
/// way to initialize their annotations as in memory instances. This allows for
/// cleaner and smaller implementations that don't have an underlying knowledge
/// of the [ConstantReader]. This simplfies cases like the following:
///
/// ```dart
/// // Defined within a builder library and exposed for consumers to extend.
/// /// This [Delegator] delegates some complex processing.
/// abstract class Delegator<T> {
///   const Delegator();
///
///   T call([dynamic]);
/// }
///
/// // Consumer library
/// /// My CustomDelegate callable to be used in a builder
/// class CustomDelegate implements Delegator<ReturnType> {
///   const CustomDelegate();
///
///   @override
///   ReturnType call(Map<String,String> args) async {
///     // My implementation details.
///   }
/// }
/// ```
///
/// Where a library exposes an interface that the user is to implement by
/// the library doesn't need to know all of the implementation details.
class Reviver {
  final ConstantReader reader;
  const Reviver(this.reader);
  Reviver.fromDartObject(DartObject? object) : this(ConstantReader(object));

  /// Recurively build the instance and return it.
  ///
  /// This may return null when the declaration doesn't exist within the
  /// system or the [reader] is null.
  ///
  /// In the event the reader is a primative type it returns that value.
  /// Collections are iterated and revived.
  /// Otherwise a fully qualified instance is returned.
  dynamic toInstance() {
    if (reader.isPrimative) {
      return primativeValue;
    } else if (reader.isCollection) {
      if (reader.isList) {
        // ignore: omit_local_variable_types
        Type t = dynamic;
        if (reader.listValue.isNotEmpty) {
          // ignore: avoid_dynamic_calls
          t = Reviver.fromDartObject(reader.listValue.first)
              .toInstance()
              .runtimeType;
        }
        return toTypedList(t);
      } else if (reader.isSet) {
        // ignore: omit_local_variable_types
        Type t = dynamic;
        if (reader.setValue.isNotEmpty) {
          // ignore: avoid_dynamic_calls
          t = Reviver.fromDartObject(reader.setValue.first)
              .toInstance()
              .runtimeType;
        }
        return toTypedSet(t);
      } else {
        // ignore: omit_local_variable_types
        Type kt = dynamic;
        // ignore: omit_local_variable_types
        Type vt = dynamic;
        if (reader.mapValue.isNotEmpty) {
          // ignore: avoid_dynamic_calls
          kt = Reviver.fromDartObject(reader.mapValue.keys.first)
              .toInstance()
              .runtimeType;
          // ignore: avoid_dynamic_calls
          vt = Reviver.fromDartObject(reader.mapValue.values.first)
              .toInstance()
              .runtimeType;
        }
        return toTypedMap(kt, vt);
      }
    } else if (reader.isLiteral) {
      return reader.literalValue;
    } else if (reader.isType) {
      return reader.typeValue;
    } else if (reader.isSymbol) {
      return reader.symbolValue;
    } else {
      final decl = classMirror;
      if (decl.isEnum) {
        final values = decl.getField(const Symbol('values')).reflectee as List;
        return values[reader.objectValue.getField('index')!.toIntValue()!];
      }

      final pv = positionalValues;
      final nv = namedValues;

      return decl
          .newInstance(Symbol(reader.revive().accessor), pv, nv)
          .reflectee;
    }
  }

  dynamic get primativeValue {
    if (reader.isNull) {
      return null;
    } else if (reader.isBool) {
      return reader.boolValue;
    } else if (reader.isDouble) {
      return reader.doubleValue;
    } else if (reader.isInt) {
      return reader.intValue;
    } else if (reader.isString) {
      return reader.stringValue;
    }
  }

  List<dynamic> get positionalValues => reader
      .revive()
      .positionalArguments
      .map(
        (value) => Reviver.fromDartObject(value).toInstance(),
      )
      .toList();

  Map<Symbol, dynamic> get namedValues => reader.revive().namedArguments.map(
        (key, value) {
          final k = Symbol(key);
          final v = Reviver.fromDartObject(value).toInstance();
          return MapEntry(k, v);
        },
      );

  ClassMirror get classMirror {
    final revivable = reader.revive();

    // Flatten the list of libraries
    final entries = Map.fromEntries(currentMirrorSystem().libraries.entries)
        .map((key, value) => MapEntry(key.pathSegments.first, value));

    // Grab the library from the system
    final libraryMirror = entries[revivable.source.pathSegments.first];
    if (libraryMirror == null || libraryMirror.simpleName == Symbol.empty) {
      throw Exception('Library missing');
    }

    // Determine the declaration being requested. Split on . when an enum is passed in.
    var declKey = Symbol(revivable.source.fragment);
    if (reader.isEnum) {
      // The accessor when the entry is an enum is the ClassName.value
      declKey = Symbol(revivable.accessor.split('.')[0]);
    }

    final decl = libraryMirror.declarations[declKey] as ClassMirror?;
    if (decl == null) {
      throw Exception('Declaration missing');
    }
    return decl;
  }

  List<T>? toTypedList<T>(T t) => reader.listValue
      .map((e) => Reviver.fromDartObject(e).toInstance() as T)
      .toList() as List<T>?;

  Map<KT, VT>? toTypedMap<KT, VT>(KT kt, VT vt) => reader.mapValue.map(
        (key, value) => MapEntry(
          Reviver.fromDartObject(key).toInstance() as KT,
          Reviver.fromDartObject(value).toInstance() as VT,
        ),
      ) as Map<KT, VT>?;

  Set<T>? toTypedSet<T>(T t) => reader.setValue
      .map((e) => Reviver.fromDartObject(e).toInstance() as T)
      .toSet() as Set<T>?;
}

extension IsChecks on ConstantReader {
  bool get isCollection => isList || isMap || isSet;
  bool get isEnum => instanceOf(const TypeChecker.fromRuntime(Enum));
  bool get isPrimative => isBool || isDouble || isInt || isString || isNull;
}
