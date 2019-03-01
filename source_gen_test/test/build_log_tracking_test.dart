// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:source_gen_test/src/build_log_tracking.dart';
import 'package:test/test.dart';

void main() {
  group('after calling initializeBuildLogTracking', () {
    initializeBuildLogTracking();
    test('calling init again throws', () {
      expect(initializeBuildLogTracking, throwsStateError);
    });

    // TODO: actually test something
    // TODO: test a build with log items that are not cleared
  });

  group('without calling initializeBuildLogTracking', () {
    test('accessing buildLogItems throws', () {
      expect(() => buildLogItems, throwsStateError);
    });

    test('calling clearBuildLog throws', () {
      expect(clearBuildLog, throwsStateError);
    });
  });
}
