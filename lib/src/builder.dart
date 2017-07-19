// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:dart_style/dart_style.dart';

import 'generated_output.dart';
import 'generator.dart';
import 'utils.dart';

/// Returns [generatedCode] formatted, usually with something like `dartfmt`.
typedef String OutputFormatter(String generatedCode);

class _Builder extends Builder {
  /// Function that determines how the generated code is formatted.
  final OutputFormatter formatOutput;

  /// What underlying generators are wrapped to form this [Builder].
  final List<Generator> generators;

  /// For a given `.dart` file what extension is used to generate code.
  ///
  /// Defaults to `.g.dart`.
  final String generatedExtension;

  _Builder(this.generators,
      {OutputFormatter formatOutput, this.generatedExtension: '.g.dart'})
      : formatOutput = formatOutput ?? _formatter.format {
    if (generatedExtension == null) {
      throw new ArgumentError.notNull('generatedExtension');
    }
    if (generatedExtension.isEmpty || !generatedExtension.startsWith('.')) {
      throw new ArgumentError.value(generatedExtension, 'generatedExtension',
          'Extension must be in the format of .*');
    }
  }

  @override
  Future build(BuildStep buildStep) async {
    var resolver = await buildStep.resolver;
    if (!resolver.isLibrary(buildStep.inputId)) return;
    var lib = resolver.getLibrary(buildStep.inputId);
    await _generateForLibrary(lib, buildStep);
  }

  @override
  Map<String, List<String>> get buildExtensions => {
        '.dart': [generatedExtension]
      };

  AssetId _generatedFile(AssetId input) =>
      input.changeExtension(generatedExtension);

  Future _generateForLibrary(
      LibraryElement library, BuildStep buildStep) async {
    log.fine('Running $generators for ${buildStep.inputId}');
    var generatedOutputs =
        await _generate(library, generators, buildStep).toList();

    // Don't output useless files.
    //
    // NOTE: It is important to do this check _before_ checking for valid
    // library/part definitions because users expect some files to be skipped
    // therefore they do not have "library".
    if (generatedOutputs.isEmpty) return;
    final outputId = _generatedFile(buildStep.inputId);

    var contentBuffer = new StringBuffer();
    _addPreamble(library, buildStep, outputId, contentBuffer);

    for (GeneratedOutput output in generatedOutputs) {
      contentBuffer.writeln('');
      contentBuffer.writeln(_headerLine);
      contentBuffer.writeln('// Generator: ${output.generator}');
      contentBuffer
          .writeln('// Target: ${friendlyNameForElement(output.sourceMember)}');
      contentBuffer.writeln(_headerLine);
      contentBuffer.writeln('');

      contentBuffer.writeln(output.output);
    }

    var genPartContent = contentBuffer.toString();

    try {
      genPartContent = formatOutput(genPartContent);
    } catch (e, stack) {
      log.severe(
          'Error formatting generated source code for ${library.identifier}'
          'which was output to ${outputId.path}.\n'
          'This may indicate an issue in the generated code or in the '
          'formatter.\n'
          'Please check the generated code and file an issue on source_gen if '
          'appropriate.',
          e,
          stack);
    }

    buildStep.writeAsString(outputId, '$_topHeader$genPartContent');
  }

  void _addPreamble(LibraryElement library, BuildStep buildStep,
      AssetId outputId, StringBuffer contentBuffer) {}
}

Stream<GeneratedOutput> _generate(LibraryElement unit,
    List<Generator> generators, BuildStep buildStep) async* {
  var elements = safeIterate(getElementsFromLibraryElement(unit), (e, [_]) {
    log.fine('Resolve error details:\n$e');
    log.severe('Failed to resolve ${buildStep.inputId}.');
  });
  for (var element in elements) {
    yield* _processUnitMember(element, generators, buildStep);
  }
}

Stream<GeneratedOutput> _processUnitMember(
    Element element, List<Generator> generators, BuildStep buildStep) async* {
  for (var gen in generators) {
    try {
      log.finer('Running $gen for $element');
      var createdUnit = await gen.generate(element, buildStep);

      if (createdUnit != null) {
        log.finest(() => 'Generated $createdUnit for $element');
        yield new GeneratedOutput(element, gen, createdUnit);
      }
    } catch (e, stack) {
      log.severe('Error running $gen for $element.', e, stack);
      yield new GeneratedOutput.fromError(element, gen, e, stack);
    }
  }
}

/// Wraps multiple [Generator]s and exposes them as a [Builder] which produces
/// Dart `part` files.
///
/// ```dart
/// // Creates a new builder that runs the following two generators.
/// new PartBuilder([
///   new JsonSerializableGenerator(),
///   new JsonLiteralGenerator(),
/// ]);
/// ```
class PartBuilder extends _Builder {
  final bool _requireLibraryDirective;

  /// Wrap [generators] in a [Builder]-compatible API.
  ///
  /// May set [requireLibraryDirective] to `false` in order to opt-in to
  /// supporting a `1.25.0` feature of `part of` being usable without an
  /// explicit `library` directive. Developers should restrict their `pubspec`
  /// accordingly:
  /// ```yaml
  /// sdk: '>=1.25.0 <2.0.0'
  /// ```
  PartBuilder(List<Generator> generators,
      {OutputFormatter formatOutput,
      String generatedExtension: '.g.dart',
      bool requireLibraryDirective: true})
      : _requireLibraryDirective = requireLibraryDirective,
        super(generators,
            generatedExtension: generatedExtension, formatOutput: formatOutput);

  @override
  void _addPreamble(LibraryElement library, BuildStep buildStep,
      AssetId outputId, StringBuffer contentBuffer) {
    var asset = buildStep.inputId;
    var name = nameOfPartial(
      library,
      asset,
      allowUnnamedPartials: !_requireLibraryDirective,
    );
    if (name == null) {
      var suggest = suggestLibraryName(asset);
      throw new InvalidGenerationSourceError(
          'Could not find library identifier so a "part of" cannot be built.',
          todo: ''
              'Consider adding the following to your source file:\n\n'
              'library $suggest;');
    }
    final part = computePartUrl(buildStep.inputId, outputId);
    if (!library.parts.map((c) => c.uri).contains(part)) {
      // TODO: Upgrade to error in a future breaking change?
      log.warning('Missing "part \'$part\';".');
    }
    contentBuffer.writeln('part of $name;');
    contentBuffer.writeln();
  }

  @override
  String toString() => 'PartBuilder:$generators';
}

/// Wraps a [Generator] and exposes it as a [Builder] which produces a Dart
/// library file.
class SourceBuilder extends _Builder {
  SourceBuilder(Generator generator,
      {OutputFormatter formatOutput,
      String generatedExtension: '.g.dart',
      bool requireLibraryDirective: true})
      : super([generator],
            generatedExtension: generatedExtension, formatOutput: formatOutput);

  @override
  String toString() => 'SourceBuilder:${generators.first}';
}

final _formatter = new DartFormatter();

const _topHeader = '''// GENERATED CODE - DO NOT MODIFY BY HAND

''';

final _headerLine = '// '.padRight(77, '*');
