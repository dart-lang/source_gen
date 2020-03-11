// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'generator.dart';

class GeneratedOutput {
  final String output;
  final Generator generator;

  @Deprecated('Always null. Will be removed in the next release.')
  final dynamic error;

  @Deprecated('Always null. Will be removed in the next release.')
  final StackTrace stackTrace;

  @Deprecated('Always false. Will be removed in the next release.')
  bool get isError => error != null;

  GeneratedOutput(this.generator, this.output)
      :
        // ignore: deprecated_member_use_from_same_package
        error = null,
        // ignore: deprecated_member_use_from_same_package
        stackTrace = null,
        assert(output != null),
        assert(output.isNotEmpty),
        // assuming length check is cheaper than simple string equality
        assert(output.length == output.trim().length);

  @override
  String toString() {
    final output = generator.toString();
    if (output.endsWith('Generator')) {
      return output;
    }
    return 'Generator: $output';
  }
}
