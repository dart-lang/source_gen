// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build_test/build_test.dart';
import 'package:collection/collection.dart';
import 'package:source_gen/source_gen.dart';
import 'package:test/test.dart';

void main() {
  group('Constant', () {
    List<Constant> constants;

    setUpAll(() async {
      constants = (await resolveSource(r'''
        library test_lib;
        
        const aString = 'Hello';
        const aInt = 1234;
        const aBool = true;
        const aNull = null;
        const aList = const [1, 2, 3];
        const aMap = const {1: 'A', 2: 'B'};
        
        @aString    // [0]
        @aInt       // [1]
        @aBool      // [2]
        @aNull      // [3]
        @Example(   // [4]
          aString: aString,
          aInt: aInt,
          aBool: aBool,
          nested: const Example(),
        )
        @Super()    // [5]
        @aList      // [6]
        @aMap       // [7]
        class Example {
          final String aString;
          final int aInt;
          final bool aBool;
          final Example nested;
          
          const Example({this.aString, this.aInt, this.aBool, this.nested});
        }
        
        class Super extends Example {
          const Super() : super(aString: 'Super Hello');
        }
      '''))
          .getLibraryByName('test_lib')
          .getType('Example')
          .metadata
          .map((e) => new Constant(e.computeConstantValue()))
          .toList();
    });

    test('should read a String', () {
      expect(constants[0].isString, isTrue);
      expect(constants[0].stringValue, 'Hello');
    });

    test('should read an Int', () {
      expect(constants[1].isInt, isTrue);
      expect(constants[1].intValue, 1234);
    });

    test('should read a Bool', () {
      expect(constants[2].isBool, isTrue);
      expect(constants[2].boolValue, true);
    });

    test('should read a Null', () {
      expect(constants[3].isNull, isTrue, reason: '${constants[3]}');
    });

    test('should read an arbitrary object', () {
      final constant = constants[4];
      expect(constant.readString('aString'), 'Hello');
      expect(constant.readInt('aInt'), 1234);
      expect(constant.readBool('aBool'), true);
      expect(constant.read('aNull').isNull, isTrue);

      final nested = constant.read('nested');
      expect(nested.readString('aString', defaultTo: () => 'Nope'), 'Nope');
      expect(nested.readInt('aInt', defaultTo: () => 5678), 5678);
      expect(nested.readBool('aBool', defaultTo: () => false), isFalse);
    });

    test('should read from a super object', () {
      final constant = constants[5];
      expect(constant.readString('aString'), 'Super Hello');
    });

    test('should read a list', () {
      expect(constants[6].isList, isTrue, reason: '${constants[6]}');
      expect(constants[6].listValue.map((c) => c.intValue), [1, 2, 3]);
    });

    test('should read a map', () {
      expect(constants[7].isMap, isTrue, reason: '${constants[7]}');
      expect(
          mapMap<Constant, Constant, int, String>(constants[7].mapValue,
              key: (k, _) => k.intValue, value: (_, v) => v.stringValue),
          {1: 'A', 2: 'B'});
    });
  });
}
