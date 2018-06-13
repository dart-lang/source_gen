// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:build/build.dart';
import 'package:glob/glob.dart';
import 'src/builder.dart';

const _outputExtensions = '.g.dart';
const _partFiles = '.g.part';

/// A [Builder] which combines part files generated from [SharedPartBuilder].
///
/// This will glob all files of the form `.*.g.part`.
class CombiningBuilder extends Builder {
  @override
  final Map<String, List<String>> buildExtensions = const {
    '.dart': const [_outputExtensions]
  };

  @override
  Future build(BuildStep buildStep) async {
    var assets = await Future.wait(await buildStep
        .findAssets(
            new Glob(buildStep.inputId.changeExtension('.*$_partFiles').path))
        .map(buildStep.readAsString)
        .toList());
    final outputId = buildStep.inputId.changeExtension(_outputExtensions);
    if (assets.isEmpty) return;
    await buildStep.writeAsString(outputId, assets.join('\n'));
  }
}
