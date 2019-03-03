// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:source_gen_test/annotations.dart';

import 'test_annotation.dart';

part 'test_part.dart';

@ShouldGenerate(
  r'''
const TestClass1NameLength = 10;

const TestClass1NameLowerCase = testclass1;
''',
  configurations: ['default', 'no-prefix-required'],
)
@ShouldThrow(
  'Uh...',
  configurations: ['vague'],
  elementShouldMatchAnnotated: false,
)
@TestAnnotation()
class TestClass1 {}

@ShouldThrow(
  'All classes must start with `TestClass`.',
  todo: 'Rename the type or remove the `TestAnnotation` from class.',
  configurations: ['default'],
  expectedLogItems: ['This member might be not good.'],
)
@ShouldGenerate(
  r'''
const BadTestClassNameLength = 12;

const BadTestClassNameLowerCase = badtestclass;
''',
  configurations: ['no-prefix-required'],
  expectedLogItems: ['This member might be not good.'],
)
@ShouldThrow(
  'Uh...',
  configurations: ['vague'],
  elementShouldMatchAnnotated: false,
)
@TestAnnotation()
class BadTestClass {}

@ShouldThrow(
  'Only supports annotated classes.',
  todo: 'Remove `TestAnnotation` from the associated element.',
)
@ShouldThrow(
  'Uh...',
  configurations: ['vague'],
  elementShouldMatchAnnotated: false,
)
@TestAnnotation()
int badTestFunc() => 42;

// TODO: investigate annotated fields
/*
BUGGY!

@ShouldThrow(
  'All classes must start with `TestClass`.',
  todo: 'Rename the type or remove the `TestAnnotation` from class.',
)
@TestAnnotation()
final badTestField = 42;
*/
