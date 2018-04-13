// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Increase timeouts on this test which resolves source code and can be slow.
@Timeout.factor(2.0)
import 'package:analyzer/dart/element/element.dart';
import 'package:build_test/build_test.dart';
import 'package:source_gen/source_gen.dart';
import 'package:test/test.dart';

const _source = r'''
abstract class Example extends SuperExample {
  int f2;

  // methods should not be included
  ClassType classType();  

  // Putting a getter in the middle. The analyzer API returns these after fields 
  int get f3;

  int f4;
  
  // Adding a setter in a subclass shouldn't change order
  int set f1;
}

abstract class SuperExample {
  // Inherited fields come first
  int f0;
  
  int get f1;
}
''';

void main() {
  ClassElement example;

  setUpAll(() async {
    example = await resolveSource(
        _source,
        (resolver) =>
            resolver.libraries.first.then((e) => e.getType('Example')));
  });

  test('should return fields sorted correctly', () {
    var fields = sortedFields(example);

    expect(fields.map((fe) => fe.name), ['f0', 'f1', 'f2', 'f3', 'f4']);
  });
}
