// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:source_gen/source_gen.dart';
import 'package:test/test.dart';

/// Returns a [Matcher] that matches a thrown [InvalidGenerationSourceError]
/// with [InvalidGenerationSourceError.message] that matches [messageMatcher],
/// and [InvalidGenerationSourceError.todo] that matches [todoMatcher] and
/// [InvalidGenerationSourceError.element] that [isNotNull].
Matcher throwsInvalidGenerationSourceError(messageMatcher, todoMatcher) =>
    throwsA(
      const TypeMatcher<InvalidGenerationSourceError>()
          .having((e) => e.message, 'message', messageMatcher)
          .having((e) => e.todo, 'todo', todoMatcher)
          .having((e) => e.element, 'element', isNotNull),
    );
