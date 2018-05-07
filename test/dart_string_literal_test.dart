// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:test_descriptor/test_descriptor.dart' as d;
import 'package:source_gen/src/dart_string_literal.dart';

void main() {
  group('targetted values', () {
    void testValue(String name, String value, String expectedLiteral,
        {String expectedValue,
        String expectedWithoutEscapedDollar,
        String expectedValueWithoutEscapedDollar,
        bool unescapedThrows: false}) {
      unescapedThrows ??= false;

      assert(expectedLiteral != expectedWithoutEscapedDollar,
          'Just leave `withoutEscaped\$` unassigned! for `$expectedWithoutEscapedDollar`');

      expectedWithoutEscapedDollar ??= expectedLiteral;

      assert(expectedValue != value, 'Just leave it null');
      expectedValue ??= value;

      test(name, () async {
        var output = dartStringLiteral(value);
        expect(output, expectedLiteral);

        expect(await _echoLiteral(value), expectedValue);
      });
      test('$name - explicit escape\$ true', () async {
        var output = dartStringLiteral(value, escapeDollar: true);
        expect(output, expectedLiteral);

        expect(await _echoLiteral(value, escapeDollar: true), expectedValue);
      });

      assert(expectedValueWithoutEscapedDollar != expectedValue);
      expectedValueWithoutEscapedDollar ??= expectedValue;

      test('$name - explicit escape\$ false', () async {
        var output = dartStringLiteral(value, escapeDollar: false);
        expect(output, expectedWithoutEscapedDollar);

        if (unescapedThrows) {
          expect(() async => await _echoLiteral(value, escapeDollar: false),
              throwsA(new isInstanceOf<IsolateSpawnException>()));
        } else {
          expect(await _echoLiteral(value, escapeDollar: false),
              expectedValueWithoutEscapedDollar);
        }
      });
    }

    testValue('single quotes', "'", '"\'"');
    testValue('double and single quotes', "'\"", "'\\'\\\"'");
    testValue('single and double quotes', '\'"\'', '\'\\\'\\"\\\'\'');

    testValue('single quotes and \$', r"$ENV{'HOME'}", 'r"\$ENV{\'HOME\'}"',
        expectedWithoutEscapedDollar: '"\$ENV{\'HOME\'}"',
        unescapedThrows: true);

    testValue('backslash', '\\', "\'\\\\\'");
    testValue('newlines', '\n', "\'\\n\'");
    testValue('carriage returns', '\r', "\'\\r\'");
    testValue('\$', '\$', r"r'$'",
        expectedWithoutEscapedDollar: "'\$'", unescapedThrows: true);

    testValue('dollar interpolation', '\$x', r"r'$x'",
        expectedWithoutEscapedDollar: r"'$x'",
        expectedValueWithoutEscapedDollar: 'xyz');
  });

  group('bad strings', () {
    var count = 0;
    for (var badString in _badStrings) {
      test('${++count}', () async {
        var value = await _echoLiteral(badString);
        expect(value, badString);
      });
    }
  });
}

final _badStrings = (jsonDecode(
        new File('test/big-list-of-naughty-strings.json')
            .readAsStringSync()) as List)
    .cast<String>();

Future<String> _echoLiteral(String value, {bool escapeDollar: true}) async {
  escapeDollar ??= true;
  var literal = dartStringLiteral(value, escapeDollar: escapeDollar);
  var script = _echoScript(literal);

  Uri uri;
  if (value.contains('../../../../etc/')) {
    // TODO: stop creating temp files once dart-lang/sdk#33056 is fixed
    await d.file('file.dart', script).create();
    uri = p.toUri(p.join(d.sandbox, 'file.dart'));
  } else {
    uri = new Uri.dataFromString(script, encoding: utf8);
  }

  var messagePort = new ReceivePort();
  var exitPort = new ReceivePort();
  var errorPort = new ReceivePort();

  try {
    await Isolate.spawnUri(uri, [], messagePort.sendPort,
        onExit: exitPort.sendPort,
        onError: errorPort.sendPort,
        checked: false,
        errorsAreFatal: true);

    var allErrorsFuture = errorPort.forEach((error) {
      var errorList = error as List;
      var message = errorList[0] as String;
      var stack = new StackTrace.fromString(errorList[1] as String);

      printOnFailure(message);
      printOnFailure(stack.toString());
    });

    var items = await Future.wait([
      messagePort.toList(),
      allErrorsFuture,
      exitPort.first.whenComplete(() {
        messagePort.close();
        errorPort.close();
      })
    ]);

    var messages = items[0] as List;
    if (messages.isEmpty) {
      throw new IsolateSpawnException('An error occurred while bootstrapping.');
    }

    assert(messages.length == 1);
    return messages.single as String;
  } finally {
    messagePort.close();
    exitPort.close();
    errorPort.close();
  }
}

String _echoScript(String literal) => '''
import 'dart:isolate';

void main(List<String> args, [SendPort sendPort]) async {
  // Allows testing of unescaped `\$`
  var x = 'xyz';
  sendPort.send($literal);  
}
''';
