// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:source_gen_test/src/init_library_reader.dart';
import 'package:test/test.dart';

// TODO: test initializeLibraryReader - but since
//  `initializeLibraryReaderForDirectory` wraps it, not a big hurry
void main() {
  group('initializeLibraryReaderForDirectory', () {
    test('valid', () async {
      final reader = await initializeLibraryReaderForDirectory(
          'test/src', 'test_library.dart');

      expect(
        reader.allElements.map((e) => e.name),
        unorderedMatches([
          'TestClass1',
          'TestClass2',
          'BadTestClass',
          'badTestFunc',
        ]),
      );
    });

    test('bad library name', () async {
      await expectLater(
        () => initializeLibraryReaderForDirectory(
            'test/src', 'test_library_bad.dart'),
        throwsA(isArgumentError
            .having((ae) => ae.message, 'message',
                'Must exist as a file in `sourceDirectory`.')
            .having((ae) => ae.name, 'name', 'targetLibraryFileName')),
      );
    });

    test('non-existant directory', () async {
      await expectLater(
          () => initializeLibraryReaderForDirectory(
              'test/not_src', 'test_library.dart'),
          throwsA(const TypeMatcher<FileSystemException>()));
    });

    test('part instead', () async {
      await expectLater(
        () => initializeLibraryReaderForDirectory('test/src', 'test_part.dart'),
        throwsA(isArgumentError
            .having((ae) => ae.message, 'message',
                'Does not seem to reference a Dart library.')
            .having((ae) => ae.name, 'name', 'targetLibraryFileName')),
      );
    });
  });
}
