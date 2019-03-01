// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

export 'annotations.dart' show ShouldGenerate, ShouldThrow;
export 'src/build_log_tracking.dart'
    show buildLogItems, clearBuildLog, initializeBuildLogTracking;
export 'src/generate_for_element.dart' show generateForElement;
export 'src/init_library_reader.dart'
    show initializeLibraryReader, initializeLibraryReaderForDirectory;
export 'src/matchers.dart' show throwsInvalidGenerationSourceError;
export 'src/test_annotated_classes.dart' show testAnnotatedElements;
