// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: deprecated_member_use until analyzer 7 support is dropped.

import 'package:analyzer/dart/element/element2.dart';
import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:source_gen/src/span_for_element.dart';
import 'package:term_glyph/term_glyph.dart' as glyph;
import 'package:test/test.dart';

void main() {
  glyph.ascii = true;
  late LibraryElement2 library;
  late Resolver resolver;

  setUpAll(() async {
    library = await resolveSource(
      r'''
library test_lib;

abstract class Example implements List {
  List<A> get getter => null;
  set setter(int value) {}
  int field;
  int get fieldProp => field;
  set fieldProp(int value) {
    field = value;
  }
}
''',
      (r) async {
        resolver = r;
        return (await resolver.findLibraryByName('test_lib'))!;
      },
      inputId: AssetId('test_lib', 'lib/test_lib.dart'),
    );
  });

  test('should highlight the use of "class Example"', () async {
    expect(
      spanForElement(library.getClass2('Example')!).message('Here it is'),
      r"""
line 3, column 16 of package:test_lib/test_lib.dart: Here it is
  ,
3 | abstract class Example implements List {
  |                ^^^^^^^
  '""",
    );
  });

  test('should correctly highlight getter', () async {
    expect(
      spanForElement(
        library.getClass2('Example')!.getField2('getter')!,
      ).message('Here it is'),
      r"""
line 4, column 15 of package:test_lib/test_lib.dart: Here it is
  ,
4 |   List<A> get getter => null;
  |               ^^^^^^
  '""",
    );
  });

  test('should correctly highlight setter', () async {
    expect(
      spanForElement(
        library.getClass2('Example')!.getField2('setter')!,
      ).message('Here it is'),
      r"""
line 5, column 7 of package:test_lib/test_lib.dart: Here it is
  ,
5 |   set setter(int value) {}
  |       ^^^^^^
  '""",
    );
  });

  test('should correctly highlight field', () async {
    expect(
      spanForElement(
        library.getClass2('Example')!.getField2('field')!,
      ).message('Here it is'),
      r"""
line 6, column 7 of package:test_lib/test_lib.dart: Here it is
  ,
6 |   int field;
  |       ^^^^^
  '""",
    );
  });

  test('highlight getter with getter/setter property', () async {
    expect(
      spanForElement(
        library.getClass2('Example')!.getField2('fieldProp')!,
      ).message('Here it is'),
      r"""
line 7, column 11 of package:test_lib/test_lib.dart: Here it is
  ,
7 |   int get fieldProp => field;
  |           ^^^^^^^^^
  '""",
    );
  });

  test('highlights based on AstNode source location', () async {
    final element =
        library.getClass2('Example')!.getField2('field')!.firstFragment;
    final node = (await resolver.astNodeFor(element, resolve: true))!;
    expect(spanForNode(node).message('Here it is'), r"""
line 6, column 7 of package:test_lib/test_lib.dart: Here it is
  ,
6 |   int field;
  |       ^^^^^
  '""");
  });
}
