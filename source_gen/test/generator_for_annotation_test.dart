// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// The first test that runs `testBuilder` takes a LOT longer than the rest.
@Timeout.factor(3)
library;

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:source_gen/source_gen.dart';
import 'package:source_gen/src/builder.dart';
import 'package:test/test.dart';

void main() {
  group('skips output if per-annotation output is', () {
    for (var entry
        in {
          '`null`': null,
          'empty string': '',
          'only whitespace': '\n \t',
          'empty list': <Object>[],
          'list with null, empty, and whitespace items': [null, '', '\n \t'],
        }.entries) {
      test(entry.key, () async {
        final generator = _StubGenerator<Deprecated>(
          'Value',
          elementBehavior: (_) => entry.value,
        );
        final builder = LibraryBuilder(generator);
        await testBuilder(builder, _inputMap, outputs: {});
      });
    }
  });

  test('Supports and dedupes multiple return values', () async {
    final generator = _StubGenerator<Deprecated>(
      'Repeating',
      elementBehavior: (element) sync* {
        yield '// There are deprecated values in this library!';
        yield '// ${element.name}';
      },
    );
    final builder = LibraryBuilder(generator);
    await testBuilder(
      builder,
      _inputMap,
      outputs: {
        'a|lib/file.g.dart': '''
// GENERATED CODE - DO NOT MODIFY BY HAND
$dartFormatWidth

// **************************************************************************
// Generator: Repeating
// **************************************************************************

// There are deprecated values in this library!

// foo

// bar

// baz
''',
      },
    );
  });

  group('handles errors correctly', () {
    for (var entry
        in {
          'sync errors': _StubGenerator<Deprecated>(
            'Failing',
            elementBehavior: (_) {
              throw StateError('not supported!');
            },
          ),
          'from iterable': _StubGenerator<Deprecated>(
            'FailingIterable',
            elementBehavior: (_) sync* {
              yield '// There are deprecated values in this library!';
              throw StateError('not supported!');
            },
          ),
        }.entries) {
      test(entry.key, () async {
        final builder = LibraryBuilder(entry.value);
        final logs = <String>[];
        await testBuilder(
          builder,
          _inputMap,
          onLog: (r) => logs.add(r.toString()),
        );
        expect(logs, contains(contains('Bad state: not supported!')));
      });
    }
  });

  test('Does not resolve the library if there are no interesting top level '
      'annotations', () async {
    final builder = LibraryBuilder(
      _StubGenerator<Deprecated>('Deprecated', elementBehavior: (_) => null),
    );
    final result = await testBuilder(builder, {
      'a|lib/a.dart': '''
@Deprecated()
@deprecated
@override
@pragma('')
main() {}''',
    });

    expect(result.readerWriter.testing.resolverEntrypointsTracked, isEmpty);
  });

  test(
    'Does resolve the library if there is an interesting top level annotation',
    () async {
      final builder = LibraryBuilder(
        _StubGenerator<Deprecated>('Deprecated', elementBehavior: (_) => null),
      );
      final result = await testBuilder(builder, {
        'a|lib/a.dart': '''
@override
@someInterestingAnnotation
main() {}''',
      });

      expect(result.readerWriter.testing.resolverEntrypointsTracked, {
        AssetId('a', 'lib/a.dart'),
      });
    },
  );

  test('applies to annotated libraries', () async {
    final builder = LibraryBuilder(
      _StubGenerator<Deprecated>(
        'Deprecated',
        elementBehavior: (element) => '// ${element.displayName}',
      ),
    );
    await testBuilder(
      builder,
      {
        'a|lib/file.dart': '''
      @deprecated
      library foo;
      ''',
      },
      outputs: {
        'a|lib/file.g.dart': '''
// GENERATED CODE - DO NOT MODIFY BY HAND
$dartFormatWidth

// **************************************************************************
// Generator: Deprecated
// **************************************************************************

// foo
''',
      },
    );
  });

  test('applies to annotated directives', () async {
    final builder = LibraryBuilder(
      _StubGenerator<Deprecated>(
        'Deprecated',
        directiveBehavior:
            (element) => switch (element) {
              LibraryImport() => '// LibraryImport',
              LibraryExport() => '// LibraryExport',
              PartInclude() => '// PartInclude',
              ElementDirective() => '// ElementDirective',
            },
        elementBehavior: (element) => '// ${element.runtimeType}',
      ),
    );
    await testBuilder(
      builder,
      {
        'a|lib/imported.dart': '',
        'a|lib/part.dart': 'part of \'file.dart\';',
        'a|lib/file.dart': '''
      library;
      @deprecated
      import 'imported.dart';
      @deprecated
      export 'imported.dart';
      @deprecated
      part 'part.dart';
      ''',
      },
      outputs: {
        'a|lib/file.g.dart': '''
// GENERATED CODE - DO NOT MODIFY BY HAND
$dartFormatWidth

// **************************************************************************
// Generator: Deprecated
// **************************************************************************

// LibraryImport

// LibraryExport

// PartInclude
''',
      },
    );
  });

  group('Unresolved annotations', () {
    test('cause an error by default', () async {
      final builder = LibraryBuilder(
        _StubGenerator<Deprecated>(
          'Deprecated',
          elementBehavior: (element) => '// ${element.displayName}',
        ),
      );
      final logs = <String>[];

      await testBuilder(
        builder,
        {
          'a|lib/file.dart': '''
      @doesNotExist
      library foo;
      ''',
        },
        outputs: {},
        onLog: (r) => logs.add(r.toString()),
      );
      expect(
        logs,
        contains(
          contains(
            'Could not resolve annotation for `library package:a/file.dart`.',
          ),
        ),
      );
    });

    test('do not cause an error if disabled', () async {
      final builder = LibraryBuilder(
        _StubGenerator<Deprecated>(
          'Deprecated',
          elementBehavior: (element) => '// ${element.displayName}',
          throwOnUnresolved: false,
        ),
      );
      expect(
        testBuilder(builder, {
          'a|lib/file.dart': '''
      @doesNotExist
      library foo;
      ''',
        }, outputs: {}),
        completes,
      );
    });
  });
}

class _StubGenerator<T> extends GeneratorForAnnotation<T> {
  final String _name;
  final Object? Function(ElementDirective) directiveBehavior;
  final Object? Function(Element) elementBehavior;

  const _StubGenerator(
    this._name, {
    this.directiveBehavior = _returnNull,
    required this.elementBehavior,
    super.throwOnUnresolved,
  });

  @override
  Object? generateForAnnotatedDirective(
    ElementDirective directive,
    ConstantReader annotation,
    BuildStep buildStep,
  ) => directiveBehavior(directive);

  @override
  Object? generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) => elementBehavior(element);

  @override
  String toString() => _name;

  static Null _returnNull(Object _) => null;
}

const _inputMap = {
  'a|lib/file.dart': '''
     // Use this to avoid the short circuit.
     const deprecated2 = deprecated;

     @deprecated2
     final foo = 'foo';

     @deprecated2
     final bar = 'bar';

     @deprecated2
     final baz = 'baz';
     ''',
};
