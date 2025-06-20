// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element2.dart';
import 'package:source_gen/source_gen.dart';

/// Returns all [TopLevelVariableElement2] members in [reader]'s library that
/// have a type of [num].
Iterable<TopLevelVariableElement2> topLevelNumVariables(LibraryReader reader) =>
    reader.allElements.whereType<TopLevelVariableElement2>().where(
      (element) =>
          element.type.isDartCoreNum ||
          element.type.isDartCoreInt ||
          element.type.isDartCoreDouble,
    );
