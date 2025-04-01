// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element2.dart';
import 'package:build_test/build_test.dart';
import 'package:source_gen/source_gen.dart';
import 'package:test/test.dart';

const _source = r'''
  library test_lib;

  export 'dart:collection' show LinkedHashMap;
  export 'package:source_gen/source_gen.dart' show Generator;
  import 'dart:async' show Stream;

  part 'part.dart';

  class Example {}
  enum Enum{A,B}
''';

const _partSource = r'''
part of 'source.dart';

class PartClass {}

enum PartEnum{A,B}
''';

void main() {
  late LibraryReader library;

  setUpAll(() async {
    library = await resolveSources(
      {'a|source.dart': _source, 'a|part.dart': _partSource},
      (r) async => LibraryReader.v2((await r.findLibraryByName2('test_lib'))!),
    );
  });

  test('class count', () {
    expect(library.classes2.map((c) => c.name3), ['Example', 'PartClass']);
  });

  test('enum count', () {
    expect(library.enums2.map((e) => e.name3), ['Enum', 'PartEnum']);
  });

  test('should return a type not exported', () {
    expect(library.findType2('Example'), _isClassElement);
  });

  test('should return a type from a part', () {
    expect(library.findType2('PartClass'), _isClassElement);
  });

  test('should return a type exported from dart:', () {
    expect(library.findType2('LinkedHashMap'), _isClassElement);
  });

  test('should return a type exported from package:', () {
    expect(library.findType2('Generator'), _isClassElement);
  });

  test('should not return a type imported', () {
    expect(library.findType2('Stream'), isNull);
  });
}

const _isClassElement = TypeMatcher<ClassElement2>();
