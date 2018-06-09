// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:logging/logging.dart';
import 'package:source_gen/source_gen.dart';
import 'package:test/test.dart';

void main() {
  test('validate exported log', () async {
    expect(log.fullName, startsWith('build.'));

    var sub = Logger.root.onRecord.listen(expectAsync1((record) {
      expect(record.level, Level.INFO);
      expect(record.message, 'test');
      expect(record.loggerName, log.fullName);
    }, count: 1, reason: 'log.info should be called once'));

    addTearDown(sub.cancel);

    log.info('test');
  });
}
