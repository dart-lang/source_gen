// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'test_library.dart';

@ShouldGenerate(r'''
const TestClass2NameLength = 10;

const TestClass2NameLowerCase = testclass2;
''')
@ShouldThrow(
  'Uh...',
  configurations: ['vague'],
  elementShouldMatchAnnotated: false,
)
@TestAnnotation()
class TestClass2 {}
